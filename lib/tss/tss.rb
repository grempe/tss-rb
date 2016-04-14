require 'digest'
require 'base64'
require 'securerandom'
require 'binary_struct'
require 'dry-types'
require 'tss/blank'
require 'tss/version'
require 'tss/types'
require 'tss/util'
require 'tss/hasher'
require 'tss/splitter'
require 'tss/combiner'

# Threshold Secret Sharing
#
# @author Glenn Rempe <glenn@rempe.us>
module TSS
  class Error < StandardError; end
  class ArgumentError < TSS::Error; end
  class NoSecretError < TSS::Error; end
  class InvalidSecretHashError < TSS::Error; end

  # @param [Hash] opts the options to create a message with.
  # @option opts [String] :secret the secret to be split into shares
  # @option opts [String] :threshold (3) how many shares are required to recreate the secret
  # @option opts [String] :num_shares (5) how many total shares will be created
  # @option opts [String] :identifier (SecureRandom.hex(8)) a 16 Byte String to uniquely idenitfy this set of secret shares
  # @option opts [String] :hash_alg ('SHA256') the hash algorithm used to verify a secret
  # @option opts [String] :format ('binary') the format of the String share output, 'binary' or 'human'
  # @option opts [String] :pad_blocksize (0) the multiple of Bytes to use when left-padding a secret
  # @return [Array<String>] an Array of String shares
  # @raise [TSS::ArgumentError] if the options Types or Values are invalid
  def self.split(opts)
    unless opts.is_a?(Hash) && opts.key?(:secret)
      raise TSS::ArgumentError, 'TSS.split takes a Hash of options with at least a :secret key'
    end

    begin
      TSS::Splitter.new(opts).split
    rescue Dry::Types::ConstraintError => e
      raise TSS::ArgumentError, e.message
    end
  end

  # The reconstruction, or combining, operation reconstructs the secret from a
  # set of valid shares where the number of shares is >= the threshold when the
  # secret was initially split. All options are provided in a single Hash:
  #
  # @param [Hash] opts the options to create a message with.
  # @option opts [Array<String>] :shares an Array of String shares to try to recombine into a secret
  # @option opts [String] :select_by ('first') the method to use for selecting
  #   shares from the Array if more then threshold shares are provided. Can be
  #   'first', 'sample', or 'combinations'.
  #
  #   If the number of shares provided as input to the secret
  #   reconstruction operation is greater than the threshold M, then M
  #   of those shares are selected for use in the operation.  The method
  #   used to select the shares can be chosen using the following values:
  #
  #   `first` : If X shares are required by the threshold and more than X
  #   shares are provided, then the first X shares in the Array of shares provided
  #   will be used. All others will be discarded and the operation will fail if
  #   those selected shares cannot recreate the secret.
  #
  #   `sample` : If X shares are required by the threshold and more than X
  #   shares are provided, then X shares will be randomly selected from the Array
  #   of shares provided.  All others will be discarded and the operation will
  #   fail if those selected shares cannot recreate the secret.
  #
  #   `combinations` : If X shares are required, and more than X shares are
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
  # @return [Hash] a Hash containing the ':secret' and other metadata
  # @raise [TSS::NoSecretError] if the secret cannot be re-created from the shares provided
  # @raise [TSS::InvalidSecretHashError] if the embedded hash of the secret does not match the hash of the recreated secret
  # @raise [TSS::ArgumentError] if the options Types or Values are invalid
  def self.combine(opts)
    unless opts.is_a?(Hash) && opts.key?(:shares)
      raise TSS::ArgumentError, 'TSS.combine takes a Hash of options with at least a :shares key'
    end

    begin
      TSS::Combiner.new(opts).combine
    rescue Dry::Types::ConstraintError => e
      raise TSS::ArgumentError, e.message
    end
  end
end
