module TSS
  # Warning, you probably don't want to use this directly. Instead
  # see the TSS module.
  #
  # TSS::Splitter has responsibility for splitting a secret into an Array of String shares.
  class Splitter
    include Contracts::Core
    include Util

    C = Contracts

    attr_reader :secret, :threshold, :num_shares, :identifier, :hash_alg, :format, :padding

    Contract ({ :secret => C::SecretArg, :threshold => C::Maybe[C::ThresholdArg], :num_shares => C::Maybe[C::NumSharesArg], :identifier => C::Maybe[C::IdentifierArg], :hash_alg => C::Maybe[C::HashAlgArg], :format => C::Maybe[C::FormatArg], :padding => C::Maybe[C::Bool] }) => C::Any
    def initialize(opts = {})
      @secret = opts.fetch(:secret)
      @threshold = opts.fetch(:threshold, 3)
      @num_shares = opts.fetch(:num_shares, 5)
      @identifier = opts.fetch(:identifier, SecureRandom.hex(8))
      @hash_alg = opts.fetch(:hash_alg, 'SHA256')
      @format = opts.fetch(:format, 'HUMAN')
      @padding = opts.fetch(:padding, true)
    end

    SHARE_HEADER_STRUCT = BinaryStruct.new([
                     'a16', :identifier,  # String, 16 Bytes, arbitrary binary string (null padded, count is width)
                     'C', :hash_id,
                     'C', :threshold,
                     'n', :share_len
                    ])

    # Warning, you probably don't want to use this directly. Instead
    # see the TSS module.
    #
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
    # @return an Array of formatted String shares
    # @raise [ParamContractError, TSS::ArgumentError] if the options Types or Values are invalid
    Contract C::None => C::ArrayOfShares
    def split
      num_shares_not_less_than_threshold!(threshold, num_shares)

      # Append needed PKCS#7 padding to the string
      secret_padded = padding ? Util.pad(secret) : secret

      # Calculate the cryptographic hash of the secret string
      secret_hash = Hasher.byte_array(hash_alg, secret)

      # RTSS : Combine the secret with a hash digest before splitting. When
      # recombine the two will be separated again and the hash will be used
      # to validate the correct secret was returned.
      # secret || padding || hash(secret)
      secret_pad_hash_bytes = Util.utf8_to_bytes(secret_padded) + secret_hash

      secret_bytes_is_smaller_than_max_size!(secret_pad_hash_bytes)

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
      secret_pad_hash_bytes.each do |byte|
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

        # Prefer unpadded Base64 output. The 'padding' option was
        # only added to Ruby later and Ruby <= 2.2.x barfs on it still.
        binary_b64 = begin
          Base64.urlsafe_encode64(binary, padding: false)
        rescue
          Base64.urlsafe_encode64(binary)
        end

        # join with URL safe '~'
        human = ['tss', 'v1', identifier, threshold, binary_b64].join('~')
        format == 'BINARY' ? binary : human
      end

      return shares
    end

    private

    # The num_shares must be greater than or equal to the threshold or it is invalid.
    #
    # @param threshold the threshold value
    # @param num_shares the num_shares value
    # @return returns true if num_shares is >= threshold
    # @raise [ParamContractError, TSS::ArgumentError] if invalid
    Contract C::ThresholdArg, C::NumSharesArg => C::Bool
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
    # @param secret_bytes the Byte Array containing the secret
    # @return returns true if num_shares is >= threshold
    # @raise [ParamContractError, TSS::ArgumentError] if invalid
    Contract C::ArrayOf[C::Int] => C::Bool
    def secret_bytes_is_smaller_than_max_size!(secret_bytes)
      if secret_bytes.size > TSS::MAX_SECRET_SIZE
        raise TSS::ArgumentError, 'invalid secret, combined padded and hashed secret is too large'
      else
        return true
      end
    end

    # Construct a binary share header from its constituent parts.
    #
    # @param identifier the unique identifier String
    # @param hash_alg the hash algorithm String
    # @param threshold the threshold value
    # @param share_len the length of the share in Bytes
    # @return returns an octet String of Bytes containing the binary header
    # @raise [ParamContractError] if invalid
    Contract C::IdentifierArg, C::HashAlgArg, C::ThresholdArg, C::Int => String
    def share_header(identifier, hash_alg, threshold, share_len)
      SHARE_HEADER_STRUCT.encode(identifier: identifier,
                                 hash_id: Hasher.code(hash_alg),
                                 threshold: threshold,
                                 share_len: share_len)
    end
  end
end
