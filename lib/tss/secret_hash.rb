# A utility class for validating hash ID's and creating hash digests with
# different output formats.
class SecretHash
  NONE           = 0
  SHA1           = 1
  SHA256         = 2
  VALID_HASH_IDS = [NONE, SHA1, SHA256].freeze

  def self.valid_id?(id)
    id.is_a?(Integer) && VALID_HASH_IDS.include?(id)
  end

  def self.bytesize_for_id(id)
    return 0 unless valid_id?(id)

    case id
    when NONE then 0
    when SHA1 then 20
    when SHA256 then 32
    end
  end

  def self.hex_string(id, str)
    return '' if id == NONE
    hasher(id).send(:hexdigest, str)
  end

  def self.byte_string(id, str)
    return '' if id == NONE
    hasher(id).send(:digest, str)
  end

  def self.byte_array(id, str)
    return [] if id == NONE
    hasher(id).send(:digest, str).unpack('C*')
  end

  # PRIVATE CLASS METHODS

  # Test for valid hash ID types and return a Digest class to operate on.
  def self.hasher(id)
    unless id.is_a?(Integer) && id >= 0
      raise Tss::ArgumentError, 'invalid hash_id, must be a positive Integer'
    end

    case id
    when SHA1 then Digest::SHA1
    when SHA256 then Digest::SHA256
    when 3..127
      raise Tss::ArgumentError, 'invalid hash_id, 3-127 is RESERVED'
    when 128..255
      raise Tss::ArgumentError, 'invalid hash_id, 128-255 is Vendor Specific'
    else
      raise Tss::ArgumentError, 'invalid hash_id, > 255'
    end
  end
  private_class_method :hasher
end
