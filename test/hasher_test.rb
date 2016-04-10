require 'test_helper'

describe Hasher do
  describe 'HASHES' do
    it 'must return a correct result' do
      Hasher::HASHES.must_equal({ NONE: { code: 0, bytesize: 0, hasher: nil },
                          SHA1: { code: 1, bytesize: 20, hasher: Digest::SHA1 },
                          SHA256: { code: 2, bytesize: 32, hasher: Digest::SHA256 } })
    end
  end

  describe 'key_from_code for 99' do
    it 'must return a correct result' do
      Hasher.key_from_code(99).must_equal nil
    end
  end

  describe 'key_from_code for 0' do
    it 'must return a correct result' do
      Hasher.key_from_code(0).must_equal :NONE
    end
  end

  describe 'key_from_code for 1' do
    it 'must return a correct result' do
      Hasher.key_from_code(1).must_equal :SHA1
    end
  end

  describe 'key_from_code for 2' do
    it 'must return a correct result' do
      Hasher.key_from_code(2).must_equal :SHA256
    end
  end

  describe 'code for :NONE' do
    it 'must return a correct result' do
      Hasher.code(:NONE).must_equal 0
    end
  end

  describe 'code for :SHA1' do
    it 'must return a correct result' do
      Hasher.code(:SHA1).must_equal 1
    end
  end

  describe 'code for :SHA256' do
    it 'must return a correct result' do
      Hasher.code(:SHA256).must_equal 2
    end
  end

  describe 'codes' do
    it 'must return a correct result' do
      Hasher.codes.must_equal [0, 1, 2]
    end
  end

  describe 'codes_without_none' do
    it 'must return a correct result' do
      Hasher.codes_without_none.must_equal [1, 2]
    end
  end

  describe 'bytesize for NONE' do
    it 'must return a correct result' do
      Hasher.bytesize('none').must_equal 0
    end
  end

  describe 'bytesize for SHA1' do
    it 'must return a correct result' do
      Hasher.bytesize('sha1').must_equal 20
    end
  end

  describe 'bytesize for SHA256' do
    it 'must return a correct result' do
      Hasher.bytesize('sha256').must_equal 32
    end
  end

  describe 'hash NONE to hex_string' do
    it 'must return a correct result' do
      Hasher.hex_string('none', 'a string to hash').must_equal ''
    end
  end

  describe 'hash SHA1 to hex_string' do
    it 'must return a correct result' do
      Hasher.hex_string('sha1', 'a string to hash').must_equal "8632b08226eb79cf5c827bb4708a2615b059a201"
    end
  end

  describe 'hash SHA256 to hex_string' do
    it 'must return a correct result' do
      Hasher.hex_string('sha256', 'a string to hash').must_equal "187c7a6cd902bc520f03015550d735a8e24f00f888c0328c9b6bcbd2d7c90cf7"
    end
  end

  describe 'hash NONE to byte_string' do
    it 'must return a correct result' do
      Hasher.byte_string('none', 'a string to hash').must_equal ''
    end
  end

  describe 'hash SHA1 to byte_string' do
    it 'must return a correct result' do
      # use .unpack('H*') to convert from bytestring to Hex since tests
      # sometimes return different formatted bytestrings
      Hasher.byte_string('sha1', 'a string to hash').unpack('H*').must_equal ["8632b08226eb79cf5c827bb4708a2615b059a201"]
    end
  end

  describe 'hash SHA256 to byte_string' do
    it 'must return a correct result' do
      # use .unpack('H*') to convert from bytestring to Hex since tests
      # sometimes return different formatted bytestrings
      Hasher.byte_string('sha256', 'a string to hash').unpack('H*').must_equal ["187c7a6cd902bc520f03015550d735a8e24f00f888c0328c9b6bcbd2d7c90cf7"]
    end
  end

  describe 'hash NONE to byte_array' do
    it 'must return a correct result' do
      Hasher.byte_array('none', 'a string to hash').must_equal []
    end
  end

  describe 'hash SHA1 to byte_array' do
    it 'must return a correct result' do
      Hasher.byte_array('sha1', 'a string to hash').must_equal [134, 50, 176, 130, 38, 235, 121, 207, 92, 130, 123, 180, 112, 138, 38, 21, 176, 89, 162, 1]
    end
  end

  describe 'hash SHA256 to byte_array' do
    it 'must return a correct result' do
      Hasher.byte_array('sha256', 'a string to hash').must_equal [24, 124, 122, 108, 217, 2, 188, 82, 15, 3, 1, 85, 80, 215, 53, 168, 226, 79, 0, 248, 136, 192, 50, 140, 155, 107, 203, 210, 215, 201, 12, 247]
    end
  end
end
