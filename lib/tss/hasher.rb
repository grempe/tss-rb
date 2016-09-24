module TSS
  # Hasher is responsible for managing access to the various one-way hash
  # functions that can be used to validate a secret.
  class Hasher
    include Contracts::Core
    C = Contracts

    HASHES = { NONE: { code: 0, bytesize: 0, hasher: nil },
               SHA1: { code: 1, bytesize: 20, hasher: Digest::SHA1 },
               SHA256: { code: 2, bytesize: 32, hasher: Digest::SHA256 }}.freeze

    # Lookup the Symbol key for a Hash with the code.
    #
    # @param code [Integer] the hash code to convert to a Symbol key
    # @return [Symbol,nil] the hash key Symbol or nil if not found
    Contract C::Int => C::Maybe[Symbol]
    def self.key_from_code(code)
      return nil unless Hasher.codes.include?(code)
      HASHES.each do |k, v|
        return k if v[:code] == code
      end
    end

    # Lookup the hash code for the hash matching hash_key.
    #
    # @param hash_key [Symbol, String] the hash key to convert to an Integer code
    # @return [Integer] the hash key code
    Contract C::Maybe[C::Enum['NONE', 'SHA1', 'SHA256'], C::Enum[:NONE, :SHA1, :SHA256]] => C::Maybe[C::Int]
    def self.code(hash_key)
      HASHES[hash_key.upcase.to_sym][:code]
    end

    # Lookup all valid hash codes, including NONE.
    #
    # @return [Array<Integer>] all hash codes including NONE
    Contract C::None => C::ArrayOf[C::Int]
    def self.codes
      HASHES.map do |_k, v|
        v[:code]
      end
    end

    # All valid hash codes that actually do hashing, excluding NONE.
    #
    # @return [Array<Integer>] all hash codes excluding NONE
    Contract C::None => C::ArrayOf[C::Int]
    def self.codes_without_none
      HASHES.map do |_k, v|
        v[:code] if v[:code] > 0
      end.compact
    end

    # Lookup the size in Bytes for a specific hash_key.
    #
    # @param hash_key [Symbol, String] the hash key to lookup
    # @return [Integer] the size in Bytes for a specific hash_key
    Contract C::Or[C::Enum['NONE', 'SHA1', 'SHA256'], C::Enum[:NONE, :SHA1, :SHA256]] => C::Int
    def self.bytesize(hash_key)
      HASHES[hash_key.to_sym][:bytesize]
    end

    # Return a hexdigest hash for a String using hash_key hash algorithm.
    # Returns '' if hash_key == :NONE
    #
    # @param hash_key [Symbol, String] the hash key to use to hash a String
    # @param str [String] the String to hash
    # @return [String] the hex digest for str
    Contract C::Or[C::Enum['NONE', 'SHA1', 'SHA256'], C::Enum[:NONE, :SHA1, :SHA256]], String => String
    def self.hex_string(hash_key, str)
      hash_key = hash_key.upcase.to_sym
      return '' if hash_key == :NONE
      HASHES[hash_key][:hasher].send(:hexdigest, str)
    end

    # Return a Byte String hash for a String using hash_key hash algorithm.
    # Returns '' if hash_key == :NONE
    #
    # @param hash_key [Symbol, String] the hash key to use to hash a String
    # @param str [String] the String to hash
    # @return [String] the Byte String digest for str
    Contract C::Or[C::Enum['NONE', 'SHA1', 'SHA256'], C::Enum[:NONE, :SHA1, :SHA256]], String => String
    def self.byte_string(hash_key, str)
      hash_key = hash_key.upcase.to_sym
      return '' if hash_key == :NONE
      HASHES[hash_key][:hasher].send(:digest, str)
    end

    # Return a Byte Array hash for a String using hash_key hash algorithm.
    # Returns [] if hash_key == :NONE
    #
    # @param hash_key [Symbol, String] the hash key to use to hash a String
    # @param str [String] the String to hash
    # @return [Array<Integer>] the Byte Array digest for str
    Contract C::Or[C::Enum['NONE', 'SHA1', 'SHA256'], C::Enum[:NONE, :SHA1, :SHA256]], String => C::ArrayOf[C::Int]
    def self.byte_array(hash_key, str)
      hash_key = hash_key.upcase.to_sym
      return [] if hash_key == :NONE
      HASHES[hash_key][:hasher].send(:digest, str).unpack('C*')
    end
  end
end
