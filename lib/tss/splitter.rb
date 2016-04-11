module TSS
  class Splitter < Dry::Types::Struct
    include Util

    SHARE_HEADER_STRUCT = BinaryStruct.new([
                     'a16', :identifier,  # String, 16 Bytes, arbitrary binary string (null padded, count is width)
                     'C', :hash_id,
                     'C', :threshold,
                     'n', :share_len
                    ])

    # dry-types
    constructor_type(:schema)

    attribute :secret, Types::Strict::String
      .constrained(min_size: 1)

    attribute :threshold, Types::Coercible::Int
      .constrained(gteq: 1)
      .constrained(lteq: 255)
      .default(3)

    attribute :num_shares, Types::Coercible::Int
      .constrained(gteq: 1)
      .constrained(lteq: 255)
      .default(5)

    attribute :identifier, Types::Strict::String
      .constrained(min_size: 0)
      .constrained(max_size: 16)
      .default { SecureRandom.hex(8) }
      .constrained(format: /^[a-zA-Z0-9\-\_\.]*$/i) # 0 or more of these chars

    attribute :hash_alg, Types::Strict::String.enum('NONE', 'SHA1', 'SHA256')
      .default('SHA256')

    attribute :pad_blocksize, Types::Coercible::Int
      .constrained(gteq: 0)
      .constrained(lteq: 255)
      .default(0)

    # The `split` method takes a Hash of arguments. The following hash key args
    # may be passed. Only `secret:` is required and the rest will be set to
    # reasonable and secure defaults if unset. All args will be validated for
    # correct type and values on object instantiation.
    #
    # `secret:` (required) takes a String (UTF-8 or US-ASCII encoding) with a
    #           length between 1..65_534
    #
    # `threshold:` The number of shares (M) that will be required to recombine the
    #              secret. Must be a value between 1..255 inclusive. Defaults to
    #              a threshold of 3 shares.
    #
    # `num_shares:` The total number of shares (N) that will be created. Must be
    #               a value between the `threshold` value (M) and 255 inclusive.
    #               The upper limit is particular to the TSS algorithm used.
    #               Defaults to generating 5 total shares.
    #
    # `identifier:` A 0-16 bytes String limited to the characters 0-9, a-z, A-Z,
    # the dash (-), the underscore (_), and the period (.). The identifier will
    # be embedded in each the binary header of each share and should not reveal
    # anything about the secret. It defaults to the value of `SecureRandom.hex(8)`
    # which returns a random 16 Byte string which represents a Base10 decimal
    # between 1 and 18446744073709552000.
    #
    # `hash_alg:` The one-way hash algorithm that will be used to verify the
    # secret returned by a later recombine operation is identical to what was
    # split. This value will be concatenated with the secret prior to splitting.
    # The valid hash algorithm values are `NONE`, `SHA1`, and `SHA256`. Defaults
    # to `SHA256`. The use of `NONE` is discouraged as it does not allow those
    # who are recombining the shares to verify if they have in fact recovered
    # the correct secret.
    #
    # `pad_blocksize:` An integer representing the nearest multiple of Bytes
    # to left pad the secret to. Defaults to not adding any padding (0). Padding
    # is done with the "\u001F" character (decimal 31 in a Byte Array).
    # Since TSS share data (minus the header) is essentially the same size as the
    # original secret, padding smaller secrets may help mask the size of the
    # contents from an attacker. Padding is not part of the RTSS spec so other
    # TSS clients won't strip off the padding and may not validate correctly.
    # If you need this interoperability you should probably pad the secret
    # yourself prior to splitting it and leave the default zero-length pad in
    # place. You would also need to manually remove the padding you added after
    # the share is recombined.
    #
    # Calling `split` *must* return an Array of formatted shares or raise one of
    # `TSS::Error` or `TSS::ArgumentError` exceptions if anything has gone wrong.
    #
    def split
      secret_has_acceptable_encoding(secret)
      secret_does_not_begin_with_padding_char(secret)
      num_shares_not_less_than_threshold(threshold, num_shares)

      # RTSS : Combine the secret with a hash digest before splitting. On recombine
      # the two will be separated again and the hash used to validate the
      # correct secret was returned. secret || hash(secret). You can also
      # optionally pad the secret first.
      padded_secret = Util.left_pad(pad_blocksize, secret)
      hashed_secret = Hasher.byte_array(hash_alg, secret)
      secret_bytes = Util.utf8_to_bytes(padded_secret) + hashed_secret

      secret_bytes_is_smaller_than_max_size(secret_bytes)

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

      # create each binary share and return it.
      shares.map! { |s| (header + s.pack('C*')).force_encoding('ASCII-8BIT') }
    end

    private

    def secret_has_acceptable_encoding(secret)
      unless secret.encoding.name == 'UTF-8' || secret.encoding.name == 'US-ASCII'
        raise TSS::ArgumentError, "invalid secret, must be a UTF-8 or US-ASCII encoded String not '#{secret.encoding.name}'"
      end
    end

    def secret_does_not_begin_with_padding_char(secret)
      if secret.slice(0) == "\u001F"
        raise TSS::ArgumentError, 'invalid secret, first byte of secret is the reserved left-pad character (\u001F)'
      end
    end

    def num_shares_not_less_than_threshold(threshold, num_shares)
      if num_shares < threshold
        raise TSS::ArgumentError, "invalid num_shares, must be >= threshold (#{threshold})"
      end
    end

    def secret_bytes_is_smaller_than_max_size(secret_bytes)
      if secret_bytes.size >= 65_535
        raise TSS::ArgumentError, 'invalid secret, combined padded secret and hash are too large'
      end
    end

    def share_header(identifier, hash_alg, threshold, share_len)
      SHARE_HEADER_STRUCT.encode(identifier: identifier,
                                 hash_id: Hasher.code(hash_alg),
                                 threshold: threshold,
                                 share_len: share_len)
    end
  end
end
