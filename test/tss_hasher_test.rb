require 'test_helper'

describe TSS::Hasher do
  describe 'HASHES' do
    it 'must return a correct result' do
      TSS::Hasher::HASHES.must_equal({ 'NONE' => { code: 0, bytesize: 0, hasher: nil },
                                       'SHA1' => { code: 1, bytesize: 20, hasher: Digest::SHA1 },
                                       'SHA256' => { code: 2, bytesize: 32, hasher: Digest::SHA256 } })
    end
  end

  describe 'key_from_code for 0' do
    it 'must return NONE' do
      TSS::Hasher.key_from_code(0).must_equal 'NONE'
    end
  end

  describe 'key_from_code for 1' do
    it 'must return SHA1' do
      TSS::Hasher.key_from_code(1).must_equal 'SHA1'
    end
  end

  describe 'key_from_code for 2' do
    it 'must return SHA256' do
      TSS::Hasher.key_from_code(2).must_equal 'SHA256'
    end
  end

  describe 'key_from_code for unknown code' do
    it 'must return nil' do
      TSS::Hasher.key_from_code(99).must_equal nil
    end
  end

  describe 'code for NONE' do
    it 'must return 0' do
      TSS::Hasher.code('NONE').must_equal 0
    end
  end

  describe 'code for SHA1' do
    it 'must return 1' do
      TSS::Hasher.code('SHA1').must_equal 1
    end
  end

  describe 'code for SHA256' do
    it 'must return 2' do
      TSS::Hasher.code('SHA256').must_equal 2
    end
  end

  describe 'codes' do
    it 'must return a correct result' do
      TSS::Hasher.codes.must_equal [0, 1, 2]
    end
  end

  describe 'codes_without_none' do
    it 'must return a correct result' do
      TSS::Hasher.codes_without_none.must_equal [1, 2]
    end
  end

  describe 'bytesize for NONE' do
    it 'must return 0' do
      TSS::Hasher.bytesize('NONE').must_equal 0
    end
  end

  describe 'bytesize for SHA1' do
    it 'must return 20' do
      TSS::Hasher.bytesize('SHA1').must_equal 20
    end
  end

  describe 'bytesize for SHA256' do
    it 'must return 32' do
      TSS::Hasher.bytesize('SHA256').must_equal 32
    end
  end

  describe 'hash NONE to hex_string' do
    it 'must return an empty string' do
      TSS::Hasher.hex_string('NONE', 'a string to hash').must_equal ''
    end
  end

  describe 'hash SHA1 to hex_string' do
    it 'must return a SHA1 hash' do
      TSS::Hasher.hex_string('SHA1', 'a string to hash').must_equal '8632b08226eb79cf5c827bb4708a2615b059a201'
    end
  end

  describe 'hash SHA256 to hex_string' do
    it 'must return a SHA256 hash' do
      TSS::Hasher.hex_string('SHA256', 'a string to hash').must_equal '187c7a6cd902bc520f03015550d735a8e24f00f888c0328c9b6bcbd2d7c90cf7'
    end
  end

  describe 'hash NONE to byte_string' do
    it 'must return an empty string' do
      TSS::Hasher.byte_string('NONE', 'a string to hash').must_equal ''
    end
  end

  describe 'hash SHA1 to byte_string' do
    it 'must return a SHA1 bytestring' do
      # use .unpack('H*') to convert from bytestring to Hex since tests
      # sometimes return different formatted bytestrings
      TSS::Hasher.byte_string('SHA1', 'a string to hash').unpack('H*').must_equal ['8632b08226eb79cf5c827bb4708a2615b059a201']
    end
  end

  describe 'hash SHA256 to byte_string' do
    it 'must return a SHA256 bytestring' do
      # use .unpack('H*') to convert from bytestring to Hex since tests
      # sometimes return different formatted bytestrings
      TSS::Hasher.byte_string('SHA256', 'a string to hash').unpack('H*').must_equal ['187c7a6cd902bc520f03015550d735a8e24f00f888c0328c9b6bcbd2d7c90cf7']
    end
  end

  describe 'hash NONE to byte_array' do
    it 'must return an empty array' do
      TSS::Hasher.byte_array('NONE', 'a string to hash').must_equal []
    end
  end

  describe 'hash SHA1 to byte_array' do
    it 'must return an array of bytes' do
      TSS::Hasher.byte_array('SHA1', 'a string to hash').must_equal [134, 50, 176, 130, 38, 235, 121, 207, 92, 130, 123, 180, 112, 138, 38, 21, 176, 89, 162, 1]
    end
  end

  describe 'hash SHA256 to byte_array' do
    it 'must return an array of bytes' do
      TSS::Hasher.byte_array('SHA256', 'a string to hash').must_equal [24, 124, 122, 108, 217, 2, 188, 82, 15, 3, 1, 85, 80, 215, 53, 168, 226, 79, 0, 248, 136, 192, 50, 140, 155, 107, 203, 210, 215, 201, 12, 247]
    end
  end
end
