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
# inconsistent. A `Tss::Error` exception should be raised,
# and processing must halt.
#
# If any two elements of the shares array have the same value then the
# input is inconsistent. A `Tss::Error` exception should be raised,
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
# `:strict_first_x` : If X shares are required by the threshold, then the
# first X shares in the Array of shares provided will be used. All others will
# be discarded and the operation will fail if those selected shares cannot
# recreate the secret.
#
# `:strict_sample_x` : If X shares are required, then X shares will be randomly
# selected from the Array of shares provided.  All others will be discarded and
# the operation will fail if those selected shares cannot recreate the secret.
#
# `:any_combination` : If X shares are required, and more than X shares are
# provided, then all possible combinations of the shares provided will be
# tried to see if the secret can be recreated. This is a more flexible, but
# possibly less-safe approach.
#
# output: :string_utf8
# output: :array_bytes
#
# `output:` : The value for the hash key `output:` can be the Symbol
# `:string_utf8` or `:array_bytes` which will return
# the recombined secret as either a UTF-8 String (default) or
# an Array of Bytes.
#
# If the combine operation can not be completed successfully, then a
# `Tss::Error` exception should be raised.
#
# After the procedure is done, the String (or Bytes) returned contain
# one fewer octet than do the original shares.
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
      unless value.key?(:output) && value.key?(:share_selection)
        record.errors.add attr, 'must have expected keys'
      end

      unless [:string_utf8, :array_bytes].include?(value[:output])
        record.errors.add attr, ':output arg must have valid values'
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

  # FIXME : implement strict_first_x, sample_first_x, and any_combination

  def initialize(shares, args = {})
    raise Tss::ArgumentError, 'optional args must be a Hash' unless args.is_a?(Hash)
    @opts = { share_selection: :strict_first_x, output: :string_utf8 }
    @opts.merge!(args)
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
  #  After the procedure is done, the string that is returned contains one
  #  fewer octet than do the shares.
  #
  def combine
    raise Tss::ArgumentError, @errors.messages unless valid?

    # the size in Bytes of the defined binary header
    share_header_size = Splitter::SHARE_HEADER_STRUCT.size

    # error if the shares are not *all* equal length
    # or don't have the exact same binary header values
    first_share_header = extract_share_header(shares.first)

    shares.each do |s|
      unless s.bytesize == shares.first.bytesize
        raise Tss::ArgumentError, 'invalid shares, different byte lengths'
      end

      unless extract_share_header(s) == first_share_header
        raise Tss::ArgumentError, 'invalid shares, different headers'
      end

      unless s.bytesize > share_header_size
        raise Tss::ArgumentError, 'invalid shares, too short'
      end
    end

    # initialize the empty output secret Array of Bytes
    secret = []

    # slice out the data after the header bytes in each share
    # and unpack the byte string into an Array of Byte Arrays
    shares_bytes = shares.collect do |s|
      bytestring = s.byteslice(share_header_size..s.bytesize)
      bytestring.unpack('C*') if bytestring.present?
    end

    # build up an Array of index values from each share
    # u[i] equal to the first octet of the ith share
    u = shares_bytes.collect do |s|
      index = s[0]
      raise Tss::ArgumentError, 'invalid shares, no index value' if index.blank?
      raise Tss::ArgumentError, 'invalid shares, illegal zero index value' if index == 0
      index
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

    # return the secret as a UTF-8 String or an Array of Bytes
    case @opts[:output]
    when :string_utf8
      Util.bytes_to_utf8(secret)
    when :array_bytes
      secret
    end
  end

  private

  def extract_share_header(share)
    Splitter::SHARE_HEADER_STRUCT.decode(share)
  end
end
