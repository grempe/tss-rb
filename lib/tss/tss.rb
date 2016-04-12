module TSS
  def self.split(args)
    unless args.is_a?(Hash) && args.key?(:secret)
      raise TSS::ArgumentError, 'TSS.split takes a Hash of arguments with at least a :secret key'
    end

    begin
      TSS::Splitter.new(args).split
    rescue Dry::Types::ConstraintError => e
      raise TSS::ArgumentError, e.message
    end
  end

  def self.combine(args)
    unless args.is_a?(Hash) && args.key?(:shares)
      raise TSS::ArgumentError, 'TSS.combine takes a Hash of arguments with at least a :shares key'
    end

    begin
      TSS::Combiner.new(args).combine
    rescue Dry::Types::ConstraintError => e
      raise TSS::ArgumentError, e.message
    end
  end
end
