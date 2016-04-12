module TSS
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

    # The reconstruction, or combining, operation reconstructs the secret from a
    # set of valid shares where the number of shares is >= the threshold when the
    # secret was initially split. All arguments are provided in a single Hash:
    #
    # `shares` : The shares parameter is an Array of String shares.
    #
    # If the number of shares provided as input to the secret
    # reconstruction operation is greater than the threshold M, then M
    # of those shares are selected for use in the operation.  The method
    # used to select the shares can be chosen with the `select_by:` argument
    # which takes the following values:
    #
    # `first` : If X shares are required by the threshold and more than X
    # shares are provided, then the first X shares in the Array of shares provided
    # will be used. All others will be discarded and the operation will fail if
    # those selected shares cannot recreate the secret.
    #
    # `sample` : If X shares are required by the threshold and more than X
    # shares are provided, then X shares will be randomly selected from the Array
    # of shares provided.  All others will be discarded and the operation will
    # fail if those selected shares cannot recreate the secret.
    #
    # `combinations` : If X shares are required, and more than X shares are
    # provided, then all possible combinations of the threshold number of shares
    # will be tried to see if the secret can be recreated.
    # This flexibility comes with a cost. All combinations of `threshold` shares
    # must be generated. Due to the math associated with combinations it is possible
    # that the system would try to generate a number of combinations that could never
    # be generated or processed in many times the life of the Universe. This option
    # can only be used if the possible combinations for the number of shares and the
    # threshold needed to reconstruct a secret result in a number of combinations
    # that is small enough to have a chance at being processed. If the number
    # of combinations will be too large then the an Exception will be raised before
    # processing has started.
    #
    # If the combine operation does not result in a secret being successfully
    # extracted, then a `TSS::Error` exception will be raised.
    #
    #
    # How it works:
    #
    #  To reconstruct a secret from a set of shares, the following
    #  procedure, or any equivalent method, is used:
    #
    #     If the number of shares provided as input to the secret
    #     reconstruction operation is greater than the threshold M, then M
    #     of those shares are selected for use in the operation.  The method
    #     used to select the shares can be arbitrary.
    #
    #     If the shares are not equal length, then the input is
    #     inconsistent.  An error should be reported, and processing must
    #     halt.
    #
    #     The output string is initialized to the empty (zero-length) octet
    #     string.
    #
    #     The octet array U is formed by setting U[i] equal to the first
    #     octet of the ith share.  (Note that the ordering of the shares is
    #     arbitrary, but must be consistent throughout this algorithm.)
    #
    #     The initial octet is stripped from each share.
    #
    #     If any two elements of the array U have the same value, then an
    #     error condition has occurred; this fact should be reported, then
    #     the procedure must halt.
    #
    #     For each octet of the shares, the following steps are performed.
    #     An array V of M octets is created, in which the array element V[i]
    #     contains the octet from the ith share.  The value of I(U, V) is
    #     computed, then appended to the output string.
    #
    #     The output string is returned.
    #
    def combine
      # unwrap 'human' share format
      if shares.first.start_with?('tss~')
        shares.collect! do |s|
          matcher = /^tss~v1~*[a-zA-Z0-9\.\-\_]{0,16}~[0-9]{1,3}~([a-zA-Z0-9\-\_]+\={0,2})$/
          s_b64 = s.match(matcher)
          if s_b64.present?
            # puts s_b64.to_a[1].inspect
            Base64.urlsafe_decode64(s_b64.to_a[1])
          else
            raise TSS::ArgumentError, 'invalid shares, human format shares do not match expected pattern'
          end
        end
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
          share_combinations_mode_allowed?(hash_id)
          share_combinations_out_of_bounds?(shares, threshold)
        end
      end

      # slice out the data after the header bytes in each share
      # and unpack the byte string into an Array of Byte Arrays
      shares_bytes = shares.collect do |s|
        bytestring = s.byteslice(Splitter::SHARE_HEADER_STRUCT.size..s.bytesize)
        bytestring.unpack('C*') unless bytestring.nil?
      end.compact

      shares_bytes_have_valid_indexes?(shares_bytes)

      if select_by == 'combinations'
        # Build an Array of all possible `threshold` size combinations.
        share_combos = shares_bytes.combination(threshold).to_a

        secret = nil
        while secret.nil? && share_combos.present?
          # Check a combination and shift it off the Array
          result = extract_secret_from_shares(hash_id, share_combos.shift)
          next if result.nil?
          secret = result
        end
      else
        secret = extract_secret_from_shares(hash_id, shares_bytes)
      end

      if secret.present?
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
      else
        raise TSS::Error, 'unable to recombine shares into a verifiable secret'
      end
    end

    private

    def extract_secret_from_shares(hash_id, shares_bytes)
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

        # return the secret only if the hash test passed
        new_hash_bytes == orig_hash_bytes ? secret : nil
      else
        secret
      end
    end

    # strip off leading padding chars ("\u001F", decimal 31)
    def strip_left_pad(secret)
      secret.shift while secret.first == 31
    end

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

    def shares_have_same_bytesize?(shares)
      shares.each do |s|
        unless s.bytesize == shares.first.bytesize
          raise TSS::ArgumentError, 'invalid shares, different byte lengths'
        end
      end
    end

    def shares_have_valid_headers?(shares)
      fh = Util.extract_share_header(shares.first)
      shares.each do |s|
        h = Util.extract_share_header(s)
        unless valid_header?(h) && h == fh
          raise TSS::ArgumentError, 'invalid shares, bad headers'
        end
      end
    end

    def shares_have_expected_length?(shares)
      shares.each do |s|
        unless s.bytesize > Splitter::SHARE_HEADER_STRUCT.size + 1
          raise TSS::ArgumentError, 'invalid shares, too short'
        end
      end
    end

    def shares_meet_threshold_min?(shares)
      fh = Util.extract_share_header(shares.first)
      unless shares.size >= fh[:threshold]
        raise TSS::ArgumentError, 'invalid shares, fewer than threshold'
      end
    end

    def validate_all_shares(shares)
      shares_have_valid_headers?(shares)
      shares_have_same_bytesize?(shares)
      shares_have_expected_length?(shares)
      shares_meet_threshold_min?(shares)
    end

    def shares_bytes_have_valid_indexes?(shares_bytes)
      u = shares_bytes.collect do |s|
        raise TSS::ArgumentError, 'invalid shares, no index' if s[0].blank?
        raise TSS::ArgumentError, 'invalid shares, zero index' if s[0] == 0
        s[0]
      end

      unless u.uniq.size == shares_bytes.size
        raise TSS::ArgumentError, 'invalid shares, duplicate indexes'
      end
    end

    def share_combinations_mode_allowed?(hash_id)
      unless Hasher.codes_without_none.include?(hash_id)
        raise TSS::ArgumentError, 'invalid options, combinations mode can only be used with hashed shares.'
      end
    end

    def share_combinations_out_of_bounds?(shares, threshold, max_combinations = 1_000_000)
      # Raise if the number of combinations is too high.
      # If this is not checked, the number of combinations can quickly grow into
      # numbers that cannot be calculated before the end of the universe.
      # e.g. 255 total shares, with threshold of 128, results in # combinations of:
      # 2884329411724603169044874178931143443870105850987581016304218283632259375395
      #
      combinations = Util.calc_combinations(shares.size, threshold)
      if combinations > max_combinations
        raise TSS::ArgumentError, "invalid options, too many combinations (#{Util.int_commas(combinations)})"
      end
    end
  end
end
