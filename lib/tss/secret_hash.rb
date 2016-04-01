module Tss
  class SecretHash
    NONE           = 0
    SHA1           = 1
    SHA256         = 2
    VALID_HASH_IDS = [NONE, SHA1, SHA256]

    def self.valid?(hash_id)
      hash_id.is_a?(Integer) && VALID_HASH_IDS.include?(hash_id)
    end

    # Returns an Array of 8 bit unsigned Bytes representing the hash digest
    def self.hash(id, str)
      case id
      when NONE
        []
      when SHA1
        Digest::SHA1.digest(str).unpack('C*')
      when SHA256
        Digest::SHA256.digest(str).unpack('C*')
      end
    end
  end
end
