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
