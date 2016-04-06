require_relative 'util'

# The reconstruction, or combining, operation reconstructs the secret from a
# set of valid shares where the number of shares is >= the threshold when the
# secret was initially split.
#
# `shares` : The shares parameter is an Array of shares. The shares should be
# treated as unstructured octet strings.
#
# If the number of shares provided as input to the secret
# reconstruction operation is greater than the threshold M, then M
# of those shares are selected for use in the operation.  The method
# used to select the shares can be arbitrary.
#
# If the shares are not equal length, then the input is
# inconsistent. A `Tss::ArgumentError` exception should be raised,
# and processing must halt.
#
# If any two elements of the shares array have the same value then the
# input is inconsistent. A `Tss::ArgumentError` exception should be raised,
# and processing must halt.
#
# The following can be provided as optional Hash args.
#
# share_handling: :strict_first_x (default)
# share_handling: :strict_sample_x
# share_handling: :any_combination
#
# `share_selection:` : This option determines how the Array of incoming shares
# to be re-combined should be handled. One of the following options is valid:
#
# `:strict_first_x` : If X shares are required by the threshold and more than X
# shares are provided, then the first X shares in the Array of shares provided
# will be used. All others will be discarded and the operation will fail if
# those selected shares cannot recreate the secret.
#
# `:strict_sample_x` : If X shares are required by the threshold and more than X
# shares are provided, then X shares will be randomly selected from the Array
# of shares provided.  All others will be discarded and the operation will
# fail if those selected shares cannot recreate the secret.
#
# `:any_combination` : If X shares are required, and more than X shares are
# provided, then all possible combinations of the threshold number of shares
# will be tried to see if the secret can be recreated. This is a more flexible,
# and probably slower, but is the best shot at finding a working combination of
# shares. The tradeoff is that this could possibly be a less-safe approach if
# you are collecting shares from cheaters.
#
# If the combine operation cannot be completed successfully, then a
# `Tss::Error` exception should be raised.
#
class Combiner
  include ActiveModel::Validations
  include Util

  attr_reader :shares, :opts

  validates_presence_of :shares, :opts

  validates_each :shares do |record, attr, value|
    if value.is_a?(Array)
      unless value.size.between?(1, Splitter::MAX_SHARES)
        record.errors.add attr, 'invalid shares, too few or too many'
      end

      unless value.all? { |x| x.is_a?(String) }
        record.errors.add attr, 'invalid shares, not a String'
      end
    else
      record.errors.add attr, 'invalid shares, must be an Array of shares'
    end
  end

  validates_each :opts do |record, attr, value|
    if value.is_a?(Hash)
      unless value.key?(:share_selection)
        record.errors.add attr, 'must have expected keys'
      end

      unless [:strict_first_x,
              :strict_sample_x,
              :any_combination].include?(value[:share_selection])
        record.errors.add attr, ':share_selection arg must have valid values'
      end
    else
      record.errors.add attr, 'must be a Hash of args'
    end
  end

  def initialize(shares, args = {})
    raise Tss::ArgumentError, 'optional args must be a Hash' unless args.is_a?(Hash)
    @opts = { share_selection: :strict_first_x }
    @opts.merge!(args) if args.is_a?(Hash)
    @shares = shares
  end

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
    raise Tss::ArgumentError, @errors.messages unless valid?

    # the size in Bytes of the defined binary header
    share_header_size = Splitter::SHARE_HEADER_STRUCT.size

    first_header = Util.extract_share_header(shares.first)

    # ensure the first share header is complete
    unless first_header.is_a?(Hash) &&
           first_header.key?(:identifier) &&
           first_header[:identifier].is_a?(String) &&
           first_header.key?(:hash_id) &&
           first_header[:hash_id].is_a?(Integer) &&
           first_header.key?(:threshold) &&
           first_header[:threshold].is_a?(Integer) &&
           first_header.key?(:share_len) &&
           first_header[:share_len].is_a?(Integer)
      raise Tss::ArgumentError, 'invalid shares, first share does not have a valid header'
    end

    # If there are more shares than the threshold would require
    # then choose a subset of the shares based on preference.
    if shares.size > first_header[:threshold]
      case @opts[:share_selection]
      when :strict_first_x
        # choose the first shares in the Array
        @shares = shares.shift(first_header[:threshold])
      when :strict_sample_x
        # choose a random sample of shares from the Array
        @shares = shares.sample(first_header[:threshold])
      end
    end

    # Error if the shares are not *all* equal length
    # or don't have the exact same binary header values
    shares.each do |s|
      unless s.bytesize == shares.first.bytesize
        raise Tss::ArgumentError, 'invalid shares, different byte lengths'
      end

      unless Util.extract_share_header(s) == first_header
        raise Tss::ArgumentError, 'invalid shares, different headers'
      end

      unless s.bytesize > share_header_size + 1
        raise Tss::ArgumentError, 'invalid shares, too short'
      end
    end

    # Verify that there are enough shares to meet the threshold
    unless shares.size >= first_header[:threshold]
      raise Tss::ArgumentError, 'invalid shares, fewer than required by threshold'
    end

    # slice out the data after the header bytes in each share
    # and unpack the byte string into an Array of Byte Arrays
    shares_bytes = shares.collect do |s|
      bytestring = s.byteslice(share_header_size..s.bytesize)
      bytestring.unpack('C*') unless bytestring.nil?
    end.compact

    # if :any_combination option was chosen, build an Array of all possible
    # combinations of the shares provided and try each combination in turn until
    # one is found that results in a good secret extraction. Otherwise just extract
    # from a single set of shares as normal.
    case @opts[:share_selection]
    when :any_combination
      unless [SecretHash::SHA1, SecretHash::SHA256].include?(first_header[:hash_id])
        raise Tss::ArgumentError, 'invalid options, :any_combination can only be used with SHA1 or SHA256 digest shares.'
      end

      share_combos = shares_bytes.combination(first_header[:threshold]).to_a

      secret = nil
      while secret.nil? && share_combos.present?
        result = extract_secret_from_shares(first_header, share_combos.shift)
        secret = result unless result.nil?
      end
    else
      secret = extract_secret_from_shares(first_header, shares_bytes)
    end

    if secret.present?
      Util.bytes_to_utf8(secret)
    else
      raise Tss::Error, 'unable to recombine shares into a verifiable secret'
    end
  end

  private

  def extract_secret_from_shares(header, shares_bytes)
    secret = []

    # build up an Array of index values from each share
    # u[i] equal to the first octet of the ith share
    u = shares_bytes.collect do |s|
      raise Tss::ArgumentError, 'invalid shares, no index' if s[0].blank?
      raise Tss::ArgumentError, 'invalid shares, zero index' if s[0] == 0
      s[0]
    end

    unless u.uniq.size == shares_bytes.size
      raise Tss::ArgumentError, 'invalid shares, duplicate indexes'
    end

    # loop through each byte in all the shares
    # start at Array index 1 in each share's Byte Array to skip the index
    (1..(shares_bytes.first.length - 1)).each do |i|
      v = shares_bytes.collect { |share| share[i] }
      secret << Util.lagrange_interpolation(u, v)
    end

    strip_left_pad(secret)

    # Only run the hash digest checks if the shares were created with a digest
    if [SecretHash::SHA1, SecretHash::SHA256].include?(header[:hash_id])
      # RTSS : pop off the hash digest bytes from the tail of the secret. This
      # leaves `secret` with only the secret bytes remaining.
      orig_secret_hash_bytes = secret.pop(SecretHash.bytesize_for_id(header[:hash_id]))

      # RTSS : verify that the recombined secret computes the same hash digest now
      # as when it was originally created.
      new_secret_hash_bytes = SecretHash.byte_array(header[:hash_id], Util.bytes_to_utf8(secret))

      # return the secret only if the hash test passed
      new_secret_hash_bytes == orig_secret_hash_bytes ? secret : nil
    else
      secret
    end
  end

  # strip off any leading padding chars ("\u001F", decimal 31)
  def strip_left_pad(secret)
    while secret.first == 31
      secret.shift
    end
  end
end
