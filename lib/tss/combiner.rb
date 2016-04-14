module TSS
  # Combiner has responsibility for combining an Array of String shares back
  # into the original secret the shares were split from. It is also responsible
  # for doing extensive validation of user provided shares and ensuring
  # that any recovered secret matches the hash of the original secret..
  class Combiner  < Dry::Types::Struct
    include Util

    # dry-types
    constructor_type(:schema)

    attribute :shares, Types::Strict::Array
      .constrained(min_size: 1)
      .constrained(max_size: 255)
      .member(Types::Strict::String)

    attribute :select_by, Types::Strict::String
      .enum('first', 'sample', 'combinations')
      .default('first')

    # To reconstruct a secret from a set of shares, the following
    # procedure, or any equivalent method, is used:
    #
    #   If the number of shares provided as input to the secret
    #   reconstruction operation is greater than the threshold M, then M
    #   of those shares are selected for use in the operation.  The method
    #   used to select the shares can be arbitrary.
    #
    #   If the shares are not equal length, then the input is
    #   inconsistent.  An error should be reported, and processing must
    #   halt.
    #
    #   The output string is initialized to the empty (zero-length) octet
    #   string.
    #
    #   The octet array U is formed by setting U[i] equal to the first
    #   octet of the ith share.  (Note that the ordering of the shares is
    #   arbitrary, but must be consistent throughout this algorithm.)
    #
    #   The initial octet is stripped from each share.
    #
    #   If any two elements of the array U have the same value, then an
    #   error condition has occurred; this fact should be reported, then
    #   the procedure must halt.
    #
    #   For each octet of the shares, the following steps are performed.
    #   An array V of M octets is created, in which the array element V[i]
    #   contains the octet from the ith share.  The value of I(U, V) is
    #   computed, then appended to the output string.
    #
    #   The output string is returned.
    #
    def combine
      # unwrap 'human' shares into binary shares
      if all_shares_appear_human?(shares)
        @shares = convert_shares_human_to_binary(shares)
      end

      validate_all_shares(shares)
      orig_shares_size = shares.size
      start_processing_time = Time.now

      h          = Util.extract_share_header(shares.sample)
      threshold  = h[:threshold]
      identifier = h[:identifier]
      hash_id    = h[:hash_id]

      # If there are more shares than the threshold would require
      # then choose a subset of the shares based on preference.
      if shares.size > threshold
        case select_by
        when 'first'
          @shares = shares.shift(threshold)
        when 'sample'
          @shares = shares.sample(threshold)
        when 'combinations'
          share_combinations_mode_allowed!(hash_id)
          share_combinations_out_of_bounds!(shares, threshold)
        end
      end

      # slice out the data after the header bytes in each share
      # and unpack the byte string into an Array of Byte Arrays
      shares_bytes = shares.collect do |s|
        bytestring = s.byteslice(Splitter::SHARE_HEADER_STRUCT.size..s.bytesize)
        bytestring.unpack('C*') unless bytestring.nil?
      end.compact

      shares_bytes_have_valid_indexes!(shares_bytes)

      if select_by == 'combinations'
        # Build an Array of all possible `threshold` size combinations.
        share_combos = shares_bytes.combination(threshold).to_a

        secret = nil
        while secret.nil? && share_combos.present?
          # Check a combination and shift it off the Array
          result = extract_secret_from_shares!(hash_id, share_combos.shift)
          next if result.nil?
          secret = result
        end
      else
        secret = extract_secret_from_shares!(hash_id, shares_bytes)
      end

      {
        hash_alg: Hasher.key_from_code(hash_id).to_s,
        identifier: identifier,
        num_shares_provided: orig_shares_size,
        num_shares_used: share_combos.present? ? share_combos.first.size : shares.size,
        processing_started_at: start_processing_time.utc.iso8601,
        processing_finished_at: Time.now.utc.iso8601,
        processing_time_ms: ((Time.now - start_processing_time)*1000).round(2),
        secret: Util.bytes_to_utf8(secret),
        shares_select_by: select_by,
        combinations: share_combos.present? ? share_combos.size : nil,
        threshold: threshold
      }
    end

    private

    # Given a hash ID and an Array of Arrays of Share Bytes, extract a secret
    # and validate it against any one-way hash that was embedded in the shares
    # along with the secret.
    #
    # @param hash_id [Integer] the ID of the one-way hash function to test with
    # @param shares_bytes [Array<Array>] the shares as Byte Arrays to be evaluated
    # @return [Array<Integer>] returns the secret as an Array of Bytes if it was recovered from the shares and validated
    # @raise [TSS::NoSecretError] if the secret was not able to be recovered (with no hash)
    # @raise [TSS::InvalidSecretHashError] if the secret was able to be recovered but the hash test failed
    def extract_secret_from_shares!(hash_id, shares_bytes)
      secret = []

      # build up an Array of index values from each share
      # u[i] equal to the first octet of the ith share
      u = shares_bytes.collect { |s| s[0] }

      # loop through each byte in all the shares
      # start at Array index 1 in each share's Byte Array to skip the index
      (1..(shares_bytes.first.length - 1)).each do |i|
        v = shares_bytes.collect { |share| share[i] }
        secret << Util.lagrange_interpolation(u, v)
      end

      strip_left_pad(secret)

      hash_alg = Hasher.key_from_code(hash_id)

      # Run the hash digest checks if the shares were created with a digest
      if Hasher.codes_without_none.include?(hash_id)
        # RTSS : pop off the hash digest bytes from the tail of the secret. This
        # leaves `secret` with only the secret bytes remaining.
        orig_hash_bytes = secret.pop(Hasher.bytesize(hash_alg))

        # RTSS : verify that the recombined secret computes the same hash
        # digest now as when it was originally created.
        new_hash_bytes = Hasher.byte_array(hash_alg, Util.bytes_to_utf8(secret))

        if Util.secure_compare(Util.bytes_to_hex(orig_hash_bytes), Util.bytes_to_hex(new_hash_bytes))
          return secret
        else
          raise TSS::InvalidSecretHashError, 'invalid shares, hash of secret does not equal embedded hash'
        end
      else
        if secret.present?
          return secret
        else
          raise TSS::NoSecretError, 'invalid shares, unable to recombine into a verifiable secret'
        end
      end
    end

    # Strip off leading padding chars ("\u001F", decimal 31)
    #
    # @param secret [String] the secret to be stripped
    # @return [String] returns the secret, stripped of the leading padding char
    def strip_left_pad(secret)
      secret.shift while secret.first == 31
    end

    # Do all of the shares match the pattern expected of human style shares?
    #
    # @param shares [Array<String>] the shares to be evaluated
    # @return [true,false] returns true if all shares match the patterns, false if not
    def all_shares_appear_human?(shares)
      shares.all? do |s|
        # test for starting with 'tss' since regex match against
        # binary data sometimes throws exceptions.
        s.start_with?('tss~') && s.match(Util::HUMAN_SHARE_RE)
      end
    end

    # Convert an Array of human style shares to binary style
    #
    # @param shares [Array<String>] the shares to be converted
    # @return [Array<String>] returns an Array of String shares in binary octet String format
    # @raise [TSS::ArgumentError] if shares appear invalid
    def convert_shares_human_to_binary(shares)
      shares.collect do |s|
        s_b64 = s.match(Util::HUMAN_SHARE_RE)
        if s_b64.present? && s_b64.to_a[1].present?
          begin
            # the [1] capture group contains the Base64 encoded bin share
            Base64.urlsafe_decode64(s_b64.to_a[1])
          rescue ArgumentError
            raise TSS::ArgumentError, 'invalid shares, some human format shares have invalid Base64 data'
          end
        else
          raise TSS::ArgumentError, 'invalid shares, some human format shares do not match expected pattern'
        end
      end
    end

    # Does the header Hash provided have all expected attributes?
    #
    # @param header [Hash] the header Hash to be evaluated
    # @return [true, false] returns true if all expected keys exist, false if not
    def valid_header?(header)
      header.is_a?(Hash) &&
        header.key?(:identifier) &&
        header[:identifier].is_a?(String) &&
        header.key?(:hash_id) &&
        header[:hash_id].is_a?(Integer) &&
        header.key?(:threshold) &&
        header[:threshold].is_a?(Integer) &&
        header.key?(:share_len) &&
        header[:share_len].is_a?(Integer)
    end

    # Do all shares have a common Byte size? They are invalid if not.
    #
    # @param shares [Array<String>] the shares to be evaluated
    # @return [true] returns true if all shares have the same Byte size
    # @raise [TSS::ArgumentError] if shares appear invalid
    def shares_have_same_bytesize!(shares)
      shares.each do |s|
        unless s.bytesize == shares.first.bytesize
          raise TSS::ArgumentError, 'invalid shares, different byte lengths'
        end
      end
      return true
    end

    # Do all shares have a valid header and match each other? They are invalid if not.
    #
    # @param shares [Array<String>] the shares to be evaluated
    # @return [true] returns true if all shares have the same header
    # @raise [TSS::ArgumentError] if shares appear invalid
    def shares_have_valid_headers!(shares)
      fh = Util.extract_share_header(shares.first)
      shares.each do |s|
        h = Util.extract_share_header(s)
        unless valid_header?(h) && h == fh
          raise TSS::ArgumentError, 'invalid shares, bad headers'
        end
      end
      return true
    end

    # Do all shares have a the expected length? They are invalid if not.
    #
    # @param shares [Array<String>] the shares to be evaluated
    # @return [true] returns true if all shares have the same header
    # @raise [TSS::ArgumentError] if shares appear invalid
    def shares_have_expected_length!(shares)
      shares.each do |s|
        unless s.bytesize > Splitter::SHARE_HEADER_STRUCT.size + 1
          raise TSS::ArgumentError, 'invalid shares, too short'
        end
      end
      return true
    end

    # Were enough shares provided to meet the threshold? They are invalid if not.
    #
    # @param shares [Array<String>] the shares to be evaluated
    # @return [true] returns true if there are enough shares
    # @raise [TSS::ArgumentError] if shares appear invalid
    def shares_meet_threshold_min!(shares)
      fh = Util.extract_share_header(shares.first)
      unless shares.size >= fh[:threshold]
        raise TSS::ArgumentError, 'invalid shares, fewer than threshold'
      else
        return true
      end
    end

    # Were enough shares provided to meet the threshold? They are invalid if not.
    #
    # @param shares [Array<String>] the shares to be evaluated
    # @return [true] returns true if all tests pass
    def validate_all_shares(shares)
      if shares_have_valid_headers!(shares) &&
          shares_have_same_bytesize!(shares) &&
          shares_have_expected_length!(shares) &&
          shares_meet_threshold_min!(shares)
        return true
      else
        return false
      end
    end

    # Do all the shares have a valid first-byte index? They are invalid if not.
    #
    # @param shares_bytes [Array<Array>] the shares as Byte Arrays to be evaluated
    # @return [true] returns true if there are enough shares
    # @raise [TSS::ArgumentError] if shares appear invalid
    def shares_bytes_have_valid_indexes!(shares_bytes)
      u = shares_bytes.collect do |s|
        raise TSS::ArgumentError, 'invalid shares, no index' if s[0].blank?
        raise TSS::ArgumentError, 'invalid shares, zero index' if s[0] == 0
        s[0]
      end

      unless u.uniq.size == shares_bytes.size
        raise TSS::ArgumentError, 'invalid shares, duplicate indexes'
      else
        return true
      end
    end

    # Is it valid to use combinations mode? Only when there is an embedded non-zero
    # hash_id Integer to test the results against. Invalid if not.
    #
    # @param hash_id [Integer] the shares as Byte Arrays to be evaluated
    # @return [true] returns true if OK to use combinations mode
    # @raise [TSS::ArgumentError] if hash_id represents a non hashing type
    def share_combinations_mode_allowed!(hash_id)
      unless Hasher.codes_without_none.include?(hash_id)
        raise TSS::ArgumentError, 'invalid options, combinations mode can only be used with hashed shares.'
      else
        return true
      end
    end

    # Calculate the number of possible combinations when combinations mode is
    # selected. Raise an exception if the possible combinations are too large.
    #
    # If this is not tested, the number of combinations can quickly grow into
    # numbers that cannot be calculated before the end of the universe.
    # e.g. 255 total shares, with threshold of 128, results in # combinations of:
    # 2884329411724603169044874178931143443870105850987581016304218283632259375395
    #
    # @param shares [Array<String>] the shares to be evaluated
    # @param threshold [Integer] the threshold value set in the shares
    # @param max_combinations [Integer] the max (1_000_000) number of combinations allowed
    # @return [true] returns true if a reasonable number of combinations
    # @raise [TSS::ArgumentError] if the number of possible combinations is unreasonably high
    def share_combinations_out_of_bounds!(shares, threshold, max_combinations = 1_000_000)
      combinations = Util.calc_combinations(shares.size, threshold)
      if combinations > max_combinations
        raise TSS::ArgumentError, "invalid options, too many combinations (#{Util.int_commas(combinations)})"
      else
        return true
      end
    end
  end
end
