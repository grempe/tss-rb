module TSS
  # Splitter has responsibility for splitting a secret into an Array of String shares.
  class Splitter
    include Contracts::Core
    include Util

    C = Contracts

    attr_reader :secret, :threshold, :num_shares, :identifier, :hash_alg, :format, :pad_blocksize

    Contract ({ :secret => String, :threshold => C::Maybe[C::Int], :num_shares => C::Maybe[C::Int], :identifier => C::Maybe[String], :hash_alg => C::Maybe[C::Enum['NONE', 'SHA1', 'SHA256']], :format => C::Maybe[C::Enum['binary', 'human']], :pad_blocksize => C::Maybe[C::Int] }) => C::Any
    def initialize(opts = {})
      @secret = opts.fetch(:secret)
      raise TSS::ArgumentError, 'Invalid secret length. Must be between 1 and 65502' unless @secret.size.between?(1,65502)

      @threshold = opts.fetch(:threshold, 3)
      raise TSS::ArgumentError, 'Invalid threshold size. Must be between 1 and 255' unless @threshold.between?(1,255)

      @num_shares = opts.fetch(:num_shares, 5)
      raise TSS::ArgumentError, 'Invalid num_shares size. Must be between 1 and 255' unless @num_shares.between?(1,255)

      @identifier = opts.fetch(:identifier, SecureRandom.hex(8))
      raise TSS::ArgumentError, 'Invalid identifier characters' unless @identifier =~ /^[a-zA-Z0-9\-\_\.]*$/i
      raise TSS::ArgumentError, 'Invalid identifier size. Must be between 0 and 16' unless @identifier.size.between?(0,16)

      @hash_alg = opts.fetch(:hash_alg, 'SHA256')
      @format = opts.fetch(:format, 'human')

      @pad_blocksize = opts.fetch(:pad_blocksize, 0)
      raise TSS::ArgumentError, 'Invalid pad_blocksize size. Must be between 0 and 255' unless @pad_blocksize.between?(0,255)
    end

    SHARE_HEADER_STRUCT = BinaryStruct.new([
                     'a16', :identifier,  # String, 16 Bytes, arbitrary binary string (null padded, count is width)
                     'C', :hash_id,
                     'C', :threshold,
                     'n', :share_len
                    ])

    # To split a secret into a set of shares, the following
    # procedure, or any equivalent method, is used:
    #
    #   This operation takes an octet string S, whose length is L octets, and
    #   a threshold parameter M, and generates a set of N shares, any M of
    #   which can be used to reconstruct the secret.
    #
    #   The secret S is treated as an unstructured sequence of octets.  It is
    #   not expected to be null-terminated.  The number of octets in the
    #   secret may be anywhere from zero up to 65,534 (that is, two less than
    #   2^16).
    #
    #   The threshold parameter M is the number of shares that will be needed
    #   to reconstruct the secret.  This value may be any number between one
    #   and 255, inclusive.
    #
    #   The number of shares N that will be generated MUST be between the
    #   threshold value M and 255, inclusive.  The upper limit is particular
    #   to the TSS algorithm specified in this document.
    #
    #   If the operation can not be completed successfully, then an error
    #   code should be returned.
    #
    def split
      secret_has_acceptable_encoding!(secret)
      secret_does_not_begin_with_padding_char!(secret)
      num_shares_not_less_than_threshold!(threshold, num_shares)

      # RTSS : Combine the secret with a hash digest before splitting. On recombine
      # the two will be separated again and the hash used to validate the
      # correct secret was returned. secret || hash(secret). You can also
      # optionally pad the secret first.
      padded_secret = Util.left_pad(pad_blocksize, secret)
      hashed_secret = Hasher.byte_array(hash_alg, secret)
      secret_bytes = Util.utf8_to_bytes(padded_secret) + hashed_secret

      secret_bytes_is_smaller_than_max_size!(secret_bytes)

      # For each share, a distinct Share Index is generated. Each Share
      # Index is an octet other than the all-zero octet. All of the Share
      # Indexes used during a share generation process MUST be distinct.
      # Each share is initialized to the Share Index associated with that
      # share.
      shares = []
      (1..num_shares).each { |n| shares << [n] }

      # For each octet of the secret, the following steps are performed.
      #
      # An array A of M octets is created, in which the array element A[0]
      # contains the octet of the secret, and the array elements A[1],
      # ..., A[M-1] contain octets that are selected independently and
      # uniformly at random.
      #
      # For each share, the value of f(X,A) is
      # computed, where X is the Share Index of the share, and the
      # resulting octet is appended to the share.
      #
      # After the procedure is done, each share contains one more octet than
      # does the secret.  The share format can be illustrated as
      #
      # +---------+---------+---------+---------+---------+
      # |    X    | f(X,A)  | f(X,B)  | f(X,C)  |   ...   |
      # +---------+---------+---------+---------+---------+
      #
      # where X is the Share Index of the share, and A, B, and C are arrays
      # of M octets; A[0] is equal to the first octet of the secret, B[0] is
      # equal to the second octet of the secret, and so on.
      #
      secret_bytes.each do |byte|
        # Unpack random Byte String into Byte Array of 8 bit unsigned Integers
        r = SecureRandom.random_bytes(threshold - 1).unpack('C*')

        # Build each share one byte at a time for each byte of the secret.
        shares.map! { |s| s << Util.f(s[0], [byte] + r) }
      end

      # build up a common binary struct header for all shares
      header = share_header(identifier, hash_alg, threshold, shares.first.length)

      # create each binary or human share and return it.
      shares.map! do |s|
        binary = (header + s.pack('C*')).force_encoding('ASCII-8BIT')
        # join with URL safe '~'
        human = ['tss', 'v1', identifier, threshold, Base64.urlsafe_encode64(binary)].join('~')
        format == 'binary' ? binary : human
      end
    end

    private

    # The secret must be encoded with UTF-8 of US-ASCII or it is invalid.
    #
    # @param secret [String] a secret String
    # @return [true] returns true if acceptable encoding
    # @raise [TSS::ArgumentError] if invalid
    def secret_has_acceptable_encoding!(secret)
      unless secret.encoding.name == 'UTF-8' || secret.encoding.name == 'US-ASCII'
        raise TSS::ArgumentError, "invalid secret, must be a UTF-8 or US-ASCII encoded String not '#{secret.encoding.name}'"
      else
        return true
      end
    end

    # The secret must not being with the padding character or it is invalid.
    #
    # @param secret [String] a secret String
    # @return [true] returns true if String does not begin with padding character
    # @raise [TSS::ArgumentError] if invalid
    def secret_does_not_begin_with_padding_char!(secret)
      if secret.slice(0) == "\u001F"
        raise TSS::ArgumentError, 'invalid secret, first byte of secret is the reserved left-pad character (\u001F)'
      else
        return true
      end
    end

    # The num_shares must be greater than or equal to the threshold or it is invalid.
    #
    # @param threshold [Integer] the threshold value
    # @param num_shares [Integer] the num_shares value
    # @return [true] returns true if num_shares is >= threshold
    # @raise [TSS::ArgumentError] if invalid
    def num_shares_not_less_than_threshold!(threshold, num_shares)
      if num_shares < threshold
        raise TSS::ArgumentError, "invalid num_shares, must be >= threshold (#{threshold})"
      else
        return true
      end
    end

    # The total Byte size of the secret, including padding and hash, must be
    # less than the max allowed Byte size or it is invalid.
    #
    # @param secret_bytes [Array<Integer>] the Byte Array containing the secret
    # @return [true] returns true if num_shares is >= threshold
    # @raise [TSS::ArgumentError] if invalid
    def secret_bytes_is_smaller_than_max_size!(secret_bytes)
      if secret_bytes.size >= 65_535
        raise TSS::ArgumentError, 'invalid secret, combined padded secret and hash are too large'
      else
        return true
      end
    end

    # Construct a binary share header from its constituent parts.
    #
    # @param identifier [String] the unique identifier String
    # @param hash_alg [String] the hash algorithm String
    # @param threshold [Integer] the threshold value
    # @param share_len [Integer] the length of the share in Bytes
    # @return [String] returns an octet String of Bytes containing the binary header
    def share_header(identifier, hash_alg, threshold, share_len)
      SHARE_HEADER_STRUCT.encode(identifier: identifier,
                                 hash_id: Hasher.code(hash_alg),
                                 threshold: threshold,
                                 share_len: share_len)
    end
  end
end
