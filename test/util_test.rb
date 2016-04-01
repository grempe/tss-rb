require 'test_helper'

describe Util do
  describe 'gf256_add' do
    it 'must return a correct result' do
      # In GF256 Math A - B == A + B
      Util.gf256_add(15, 6).must_equal 9
    end
  end

  describe 'gf256_sub' do
    it 'must return a correct result' do
      # In GF256 Math A - B == A + B
      Util.gf256_sub(15, 6).must_equal 9
    end
  end

  describe 'gf256_mul' do
    it 'must return 0 if X == 0' do
      Util.gf256_mul(0, 6).must_equal 0
    end

    it 'must return 0 if Y == 0' do
      Util.gf256_mul(15, 0).must_equal 0
    end

    it 'must return a correct result' do
      Util.gf256_mul(5, 10).must_equal 34
    end
  end

  describe 'gf256_div' do
    it 'must return 0 if X == 0' do
      Util.gf256_div(0, 6).must_equal 0
    end

    it 'must raise an error if Y == 0 (divide by zero)' do
      assert_raises(Tss::Error) { Util.gf256_div(15, 0) }
    end

    it 'must return a correct result' do
      Util.gf256_div(5, 10).must_equal 141
    end
  end

  describe 'utf8_to_bytes' do
    it 'must present a correct result' do
      test_str = 'I ½ ♥ 💩'
      Util.utf8_to_bytes(test_str).must_equal test_str.bytes.to_a
    end
  end

  describe 'bytes_to_utf8' do
    it 'must present a correct result' do
      test_str = 'I ½ ♥ 💩'
      Util.bytes_to_utf8(test_str.bytes.to_a).must_equal test_str
    end
  end

  describe 'bytes_to_hex' do
    it 'must present a correct result' do
      test_str = 'I ½ ♥ 💩'
      bytes = test_str.bytes.to_a
      Util.bytes_to_hex(bytes).must_equal '4920C2BD20E299A520F09F92A9'
    end
  end

  describe 'hex_to_bytes' do
    it 'must present a correct result' do
      test_str = 'I ½ ♥ 💩'
      bytes = test_str.bytes.to_a
      Util.hex_to_bytes('4920C2BD20E299A520F09F92A9').must_equal bytes
    end
  end

  describe 'hex_to_utf8' do
    it 'must present a correct result' do
      test_str = 'I ½ ♥ 💩'
      bytes = test_str.bytes.to_a
      hex = Util.bytes_to_hex(bytes)
      Util.hex_to_utf8(hex).must_equal test_str
    end
  end

  describe 'utf8_to_hex' do
    it 'must present a correct result' do
      test_str = 'I ½ ♥ 💩'
      Util.utf8_to_hex(test_str).must_equal '4920C2BD20E299A520F09F92A9'
    end
  end
end
