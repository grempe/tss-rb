require 'active_support/core_ext/object/blank'
require 'digest'
require 'base64'
require 'sysrandom/securerandom'
require 'binary_struct'
require 'tss/version'
require 'tss/util'
require 'tss/hasher'
require 'tss/splitter'
require 'tss/combiner'

# Threshold Secret Sharing
#
# @author Glenn Rempe <glenn@rempe.us>
module TSS
  include Contracts::Core
  C = Contracts

  # An unexpected error has occurred.
  class Error < StandardError; end

  # An argument provided is of the wrong type, or has an invalid value.
  class ArgumentError < TSS::Error; end

  # A secret was attmepted to be recovered, but failed due to invalid shares.
  class NoSecretError < TSS::Error; end

  # A secret was attempted to be recovered, but failed due to an invalid verifier hash.
  class InvalidSecretHashError < TSS::Error; end

  # Threshold Secret Sharing (TSS) provides a way to generate N shares
  # from a value, so that any M of those shares can be used to
  # reconstruct the original value, but any M-1 shares provide no
  # information about that value.  This method can provide shared access
  # control on key material and other secrets that must be strongly
  # protected.
  #
  # @param [Hash] opts the options to create a message with.
  # @option opts [String] :secret takes a String (UTF-8 or US-ASCII encoding) with a length between 1..65_534
  # @option opts [Integer] :threshold (3) The number of shares (M) that will be required to recombine the
  #   secret. Must be a value between 1..255 inclusive. Defaults to a threshold of 3 shares.
  # @option opts [Integer] :num_shares (5) The total number of shares (N) that will be created. Must be
  #   a value between the `threshold` value (M) and 255 inclusive.
  #   The upper limit is particular to the TSS algorithm used.
  # @option opts [String] :identifier (SecureRandom.hex(8)) A 1-16 byte String limited to the characters 0-9, a-z, A-Z,
  #   the dash (-), the underscore (_), and the period (.). The identifier will
  #   be embedded in each the binary header of each share and should not reveal
  #   anything about the secret.
  #
  #   If the arg is nil it defaults to the value of `SecureRandom.hex(8)`
  #   which returns a random 16 Byte string which represents a Base10 decimal
  #   between 1 and 18446744073709552000.
  # @option opts [String] :hash_alg ('SHA256') The one-way hash algorithm that will be used to verify the
  #   secret returned by a later recombine operation is identical to what was
  #   split. This value will be concatenated with the secret prior to splitting.
  #
  #   The valid hash algorithm values are `NONE`, `SHA1`, and `SHA256`. Defaults
  #   to `SHA256`. The use of `NONE` is discouraged as it does not allow those
  #   who are recombining the shares to verify if they have in fact recovered
  #   the correct secret.
  # @option opts [String] :format ('BINARY') the format of the String share output, 'BINARY' or 'HUMAN'
  # @option opts [Integer] :pad_blocksize (0) An integer representing the nearest multiple of Bytes
  #   to left pad the secret to. Defaults to not adding any padding (0). Padding
  #   is done with the "\u001F" character (decimal 31 in a Byte Array).
  #
  #   Since TSS share data (minus the header) is essentially the same size as the
  #   original secret, padding smaller secrets may help mask the size of the
  #   contents from an attacker. Padding is not part of the RTSS spec so other
  #   TSS clients won't strip off the padding and may not validate correctly.
  #
  #   If you need this interoperability you should probably pad the secret
  #   yourself prior to splitting it and leave the default zero-length pad in
  #   place. You would also need to manually remove the padding you added after
  #   the share is recombined, or instruct recipients to ignore it.
  #
  # @return an Array of formatted String shares
  # @raise [ParamContractError, TSS::ArgumentError] if the options Types or Values are invalid
  Contract ({ :secret => C::SecretArg, :threshold => C::Maybe[C::ThresholdArg], :num_shares => C::Maybe[C::NumSharesArg], :identifier => C::Maybe[C::IdentifierArg], :hash_alg => C::Maybe[C::HashAlgArg], :format => C::Maybe[C::FormatArg], :pad_blocksize => C::Maybe[C::PadBlocksizeArg] }) => C::ArrayOfShares
  def self.split(opts)
    TSS::Splitter.new(opts).split
  end

  # The reconstruction, or combining, operation reconstructs the secret from a
  # set of valid shares where the number of shares is >= the threshold when the
  # secret was initially split. All options are provided in a single Hash:
  #
  # @param [Hash] opts the options to create a message with.
  # @option opts [Array<String>] :shares an Array of String shares to try to recombine into a secret
  # @option opts [String] :select_by ('FIRST') the method to use for selecting
  #   shares from the Array if more then threshold shares are provided. Can be
  #   upper case 'FIRST', 'SAMPLE', or 'COMBINATIONS'.
  #
  #   If the number of shares provided as input to the secret
  #   reconstruction operation is greater than the threshold M, then M
  #   of those shares are selected for use in the operation.  The method
  #   used to select the shares can be chosen using the following values:
  #
  #   `FIRST` : If X shares are required by the threshold and more than X
  #   shares are provided, then the first X shares in the Array of shares provided
  #   will be used. All others will be discarded and the operation will fail if
  #   those selected shares cannot recreate the secret.
  #
  #   `SAMPLE` : If X shares are required by the threshold and more than X
  #   shares are provided, then X shares will be randomly selected from the Array
  #   of shares provided.  All others will be discarded and the operation will
  #   fail if those selected shares cannot recreate the secret.
  #
  #   `COMBINATIONS` : If X shares are required, and more than X shares are
  #   provided, then all possible combinations of the threshold number of shares
  #   will be tried to see if the secret can be recreated.
  #   This flexibility comes with a cost. All combinations of `threshold` shares
  #   must be generated. Due to the math associated with combinations it is possible
  #   that the system would try to generate a number of combinations that could never
  #   be generated or processed in many times the life of the Universe. This option
  #   can only be used if the possible combinations for the number of shares and the
  #   threshold needed to reconstruct a secret result in a number of combinations
  #   that is small enough to have a chance at being processed. If the number
  #   of combinations will be too large then the an Exception will be raised before
  #   processing has started.
  #
  # @return a Hash containing the now combined secret and other metadata
  # @raise [TSS::NoSecretError] if the secret cannot be re-created from the shares provided
  # @raise [TSS::InvalidSecretHashError] if the embedded hash of the secret does not match the hash of the recreated secret
  # @raise [ParamContractError, TSS::ArgumentError] if the options Types or Values are invalid
  Contract ({ :shares => C::ArrayOfShares, :select_by => C::Maybe[C::SelectByArg] }) => ({ :hash => C::Maybe[String], :hash_alg => C::HashAlgArg, :identifier => C::IdentifierArg, :process_time => C::Num, :secret => C::SecretArg, :threshold => C::ThresholdArg})
  def self.combine(opts)
    TSS::Combiner.new(opts).combine
  end
end
