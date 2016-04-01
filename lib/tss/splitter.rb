# A threshold secret sharing system provides two operations: one that
# creates a set of shares given a secret, and one that reconstructs the
# secret, given a set of shares. This section defines the inputs and
# outputs of these operations. The following sections describe the
# details of TSS based on a polynomial interpolation in GF(256).
#
# The secret is treated as an unstructured sequence of octets.  It is
# not expected to be null-terminated. The number of octets in the
# secret may be anywhere from zero up to 65,534 (that is, two
# less than 2^16). It may be provided as an Array of Bytes or a UTF-8 String.
#
# The threshold parameter (M, threshold) is the number of shares that
# will be needed to reconstruct the secret.  This value may be any number
# between one and 255, inclusive.
#
# The number of shares (N, num_shares) that will be generated MUST be
# between the threshold value M and 255, inclusive.  The upper limit is
# particular to the TSS algorithm specified in this code.
#
# The identifier must be a 0-16 bytes String and must be present. This
# identifier will be embedded in each share and should not reveal anything
# about the secret. One method of creating it randomly could be:
#
#   identifier = SecureRandom.hex(8)
#
# Optionally, the secret is hashed with the algorithm specified
# by `hash_id`. Valid values are:
#
#   Tss::SecretHash::NONE                 // code 0
#   Tss::SecretHash::SHA1                 // code 1
#   Tss::SecretHash::SHA256               // code 2
#
# Initializing an instance of this class *must* return an
# Array of formatted shares or raise a `Tss::Error` exception
# if anything has gone wrong.
#
class Splitter
  include ActiveModel::Validations
  include Util

  MAX_SECRET_BYTE_SIZE = 2**16 - 2 # 65534
  MIN_SHARES = 1
  MAX_SHARES = 255

  attr_accessor :secret, :threshold, :num_shares, :identifier, :hash_id
  validates_presence_of :secret, :threshold, :num_shares, :hash_id

  validates_each :secret do |record, attr, value|
    if value.is_a?(String)
      unless (value.encoding.name == 'UTF-8' || value.encoding.name == 'US-ASCII') &&
             value.bytes.to_a.size.between?(1, MAX_SECRET_BYTE_SIZE)
        record.errors.add attr, "must be a UTF-8 or US-ASCII String with a Byte length <= #{MAX_SECRET_BYTE_SIZE}"
      end
    elsif value.is_a?(Array)
      unless value.size.between?(1, MAX_SECRET_BYTE_SIZE) && value.all? { |x| x.is_a?(Integer) && x.between?(0,255) }
        record.errors.add attr, "must be an Array of Bytes representing a UTF-8 or US-ASCII String with a Byte length <= #{MAX_SECRET_BYTE_SIZE}"
      end
    else
      record.errors.add attr, 'must be an Array of Bytes representing a UTF-8 or US-ASCII String or a UTF-8/US-ASCII String'
    end
  end

  validates_each :threshold do |record, attr, value|
    unless value.is_a?(Integer) && value.between?(MIN_SHARES, MAX_SHARES)
      record.errors.add attr, "must be an Integer between min (#{MIN_SHARES}) and max (#{MAX_SHARES}) inclusive"
    end
  end

  validates_each :num_shares, if: Proc.new { threshold.is_a?(Integer) } do |record, attr, value|
    unless value.is_a?(Integer) && value.between?(record.threshold, MAX_SHARES)
      record.errors.add attr, "must be an Integer between threshold value (#{record.threshold}) and max (#{MAX_SHARES}) inclusive"
    end
  end

  validates_each :identifier, allow_blank: true do |record, attr, value|
    unless value.is_a?(String) && value.bytes.to_a.size.between?(0, 16)
      record.errors.add attr, 'must be a String with a Byte length 0..16 inclusive'
    end
  end

  validates_each :hash_id do |record, attr, value|
    unless value.is_a?(Integer) && Tss::SecretHash.valid?(value)
      record.errors.add attr, "must be an Integer and in #{Tss::SecretHash::VALID_HASH_IDS}"
    end
  end

  # Secret arg can be an Array of Bytes derived from a UTF-8 or US-ASCII
  # String ('foo'.bytes.to_a), or just a UTF-8 or US-ASCII String which
  # will be internally converted to an Array of Bytes.
  def initialize(secret, threshold, num_shares, identifier, hash_id)
    @secret     = secret
    @threshold  = threshold
    @num_shares = num_shares
    @identifier = identifier
    @hash_id    = hash_id
  end

  def split
    raise Tss::ArgumentError, @errors.messages unless valid?
    secret_bytes = secret.is_a?(Array) ? secret : Util.utf8_to_bytes(secret)
    # identifier_bytes = Util.utf8_to_bytes(identifier)

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

      # build up each share one byte at a time representing each
      # byte of the secret.
      shares.map! do |s|
        s << Util.f(s[0], [byte] + r)
      end
    end

    shares.map! { |s| Util.bytes_to_hex(s) }
  end
end
