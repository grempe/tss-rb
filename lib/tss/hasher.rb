module TSS
  class Hasher
    HASHES = { NONE: { code: 0, bytesize: 0, hasher: nil },
               SHA1: { code: 1, bytesize: 20, hasher: Digest::SHA1 },
               SHA256: { code: 2, bytesize: 32, hasher: Digest::SHA256 }
           }.freeze

    def self.key_from_code(code)
      return nil unless Hasher.codes.include?(code)
      HASHES.each do |k, v|
        return k if v[:code] == code
      end
    end

    def self.code(hash_key)
      HASHES[hash_key.upcase.to_sym][:code]
    end

    # All valid hash codes, including NONE
    def self.codes
      HASHES.collect do |_k, v|
        v[:code]
      end
    end

    # All valid hash codes that actually do hashing
    def self.codes_without_none
      HASHES.collect do |_k, v|
        v[:code] if v[:code] > 0
      end.compact
    end

    def self.bytesize(hash_key)
      HASHES[hash_key.upcase.to_sym][:bytesize]
    end

    def self.hex_string(hash_key, str)
      hash_key = hash_key.upcase.to_sym
      return '' if hash_key == :NONE
      HASHES[hash_key][:hasher].send(:hexdigest, str)
    end

    def self.byte_string(hash_key, str)
      hash_key = hash_key.upcase.to_sym
      return '' if hash_key == :NONE
      HASHES[hash_key][:hasher].send(:digest, str)
    end

    def self.byte_array(hash_key, str)
      hash_key = hash_key.upcase.to_sym
      return [] if hash_key == :NONE
      HASHES[hash_key][:hasher].send(:digest, str).unpack('C*')
    end
  end
end
