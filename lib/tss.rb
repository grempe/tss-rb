require 'digest'
require 'base64'
require 'binary_struct'
require 'dry-types'
require 'tss/version'
require 'tss/blank'
require 'tss/types'
require 'tss/errors'
require 'tss/util'
require 'tss/hasher'
require 'tss/splitter'
require 'tss/combiner'

module TSS
  def self.split(args)
    unless args.is_a?(Hash) && args.key?(:secret)
      raise TSS::ArgumentError, 'TSS.split takes a Hash of arguments with at least a :secret key'
    end
    TSS::Splitter.new(args).split
  end

  def self.combine(args)
    unless args.is_a?(Hash) && args.key?(:shares)
      raise TSS::ArgumentError, 'TSS.combine takes a Hash of arguments with at least a :shares key'
    end
    TSS::Combiner.new(args).combine
  end
end
