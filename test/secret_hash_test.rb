require 'test_helper'

describe SecretHash do
  describe 'valid_id? for NONE' do
    it 'must return a correct result' do
      SecretHash.valid_id?(SecretHash::NONE).must_equal true
    end
  end

  describe 'valid_id? for SHA1' do
    it 'must return a correct result' do
      SecretHash.valid_id?(SecretHash::SHA1).must_equal true
    end
  end

  describe 'valid_id? for SHA256' do
    it 'must return a correct result' do
      SecretHash.valid_id?(SecretHash::SHA256).must_equal true
    end
  end

  describe 'valid_id? for bad arg' do
    it 'must return a correct result' do
      SecretHash.valid_id?(99).must_equal false
    end
  end

  describe 'bytesize_for_id for NONE' do
    it 'must return a correct result' do
      SecretHash.bytesize_for_id(SecretHash::NONE).must_equal 0
    end
  end

  describe 'bytesize_for_id for SHA1' do
    it 'must return a correct result' do
      SecretHash.bytesize_for_id(SecretHash::SHA1).must_equal 20
    end
  end

  describe 'bytesize_for_id for SHA256' do
    it 'must return a correct result' do
      SecretHash.bytesize_for_id(SecretHash::SHA256).must_equal 32
    end
  end

  describe 'bytesize_for_id for invalid -1' do
    it 'must return a correct result' do
      SecretHash.bytesize_for_id(-1).must_equal 0
    end
  end

  describe 'bytesize_for_id for invalid 3' do
    it 'must return a correct result' do
      SecretHash.bytesize_for_id(3).must_equal 0
    end
  end

  describe 'hash NONE to byte_array' do
    it 'must return a correct result' do
      SecretHash.byte_array(SecretHash::NONE, 'a string to hash').must_equal []
    end
  end

  describe 'hash SHA1 to byte_array' do
    it 'must return a correct result' do
      SecretHash.byte_array(SecretHash::SHA1, 'a string to hash').must_equal [134, 50, 176, 130, 38, 235, 121, 207, 92, 130, 123, 180, 112, 138, 38, 21, 176, 89, 162, 1]
    end
  end

  describe 'hash SHA256 to byte_array' do
    it 'must return a correct result' do
      SecretHash.byte_array(SecretHash::SHA256, 'a string to hash').must_equal [24, 124, 122, 108, 217, 2, 188, 82, 15, 3, 1, 85, 80, 215, 53, 168, 226, 79, 0, 248, 136, 192, 50, 140, 155, 107, 203, 210, 215, 201, 12, 247]
    end
  end

  describe 'hash NONE to byte_string' do
    it 'must return a correct result' do
      SecretHash.byte_string(SecretHash::NONE, 'a string to hash').must_equal ''
    end
  end

  describe 'hash SHA1 to byte_string' do
    it 'must return a correct result' do
      # use .unpack('H*') to convert from bytestring to Hex since tests
      # sometimes return different formatted bytestrings
      SecretHash.byte_string(SecretHash::SHA1, 'a string to hash').unpack('H*').must_equal ["8632b08226eb79cf5c827bb4708a2615b059a201"]
    end
  end

  describe 'hash SHA256 to byte_string' do
    it 'must return a correct result' do
      # use .unpack('H*') to convert from bytestring to Hex since tests
      # sometimes return different formatted bytestrings
      SecretHash.byte_string(SecretHash::SHA256, 'a string to hash').unpack('H*').must_equal ["187c7a6cd902bc520f03015550d735a8e24f00f888c0328c9b6bcbd2d7c90cf7"]
    end
  end

  describe 'hash NONE to hex_string' do
    it 'must return a correct result' do
      SecretHash.hex_string(SecretHash::NONE, 'a string to hash').must_equal ''
    end
  end

  describe 'hash SHA1 to hex_string' do
    it 'must return a correct result' do
      SecretHash.hex_string(SecretHash::SHA1, 'a string to hash').must_equal "8632b08226eb79cf5c827bb4708a2615b059a201"
    end
  end

  describe 'hash SHA256 to hex_string' do
    it 'must return a correct result' do
      SecretHash.hex_string(SecretHash::SHA256, 'a string to hash').must_equal "187c7a6cd902bc520f03015550d735a8e24f00f888c0328c9b6bcbd2d7c90cf7"
    end
  end

  it 'must raise a RESERVED error if value between 3..127' do
    assert_raises(Tss::ArgumentError) { SecretHash.byte_array(3, 'foo') }
    assert_raises(Tss::ArgumentError) { SecretHash.byte_array(127, 'foo') }
  end

  it 'must raise a Vendor Specific error if value between 128..255' do
    assert_raises(Tss::ArgumentError) { SecretHash.byte_array(128, 'foo') }
    assert_raises(Tss::ArgumentError) { SecretHash.byte_array(255, 'foo') }
  end

  it 'must raise a general error if value > 255' do
    assert_raises(Tss::ArgumentError) { SecretHash.byte_array(256, 'foo') }
  end
end
