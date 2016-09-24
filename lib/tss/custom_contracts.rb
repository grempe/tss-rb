module TSS

  # Custom Contracts
  # See : https://egonschiele.github.io/contracts.ruby/
  class SecretArg
    def self.valid? val
      val.present? && val.is_a?(String) &&
      val.length.between?(1,65502) &&
      ['UTF-8', 'US-ASCII'].include?(val.encoding.name) &&
      val.slice(0) != "\u001F"
    end

    def self.to_s
      'must be a UTF-8 or US-ASCII String between 1 and 65,502 characters in length and must not begin with the padding char \u001F'
    end
  end

  class ThresholdArg
    def self.valid? val
      val.present? &&
      val.is_a?(Integer) &&
      val.between?(1,255)
    end

    def self.to_s
      'must be an Integer between 1 and 255'
    end
  end

  class NumSharesArg
    def self.valid? val
      val.present? &&
      val.is_a?(Integer) &&
      val.between?(1,255)
    end

    def self.to_s
      'must be an Integer between 1 and 255'
    end
  end

  class IdentifierArg
    def self.valid? val
      val.present? &&
      val.is_a?(String) &&
      val.length.between?(1,16) &&
      val =~ /^[a-zA-Z0-9\-\_\.]*$/i
    end

    def self.to_s
      'must be a String between 1 and 16 characters in length limited to [a-z, A-Z, -, _, .]'
    end
  end

  class PadBlocksizeArg
    def self.valid? val
      val.present? &&
      val.is_a?(Integer) &&
      val.between?(0,255)
    end

    def self.to_s
      'must be an Integer between 0 and 255'
    end
  end
end
