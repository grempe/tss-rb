require 'test_helper'

describe Combiner do
  before do
    @secret = 'I love secrets with multi-byte unicode characters ½ ♥ 💩'
    @shares = Splitter.new(@secret, 3, 5, SecureRandom.hex(8), Tss::SecretHash::SHA256).split
  end

  describe 'shares' do
    # TODO: implement
  end

  describe 'output format' do
    describe 'when output arg is unset' do
      it 'must return a UTF-8 String' do
        secret = Combiner.new(@shares).combine
        assert_kind_of String, secret
        secret.encoding.name.must_equal 'UTF-8'
        secret.must_equal @secret
      end
    end

    describe 'when a bogus arg is set' do
      it 'must ignore it and return a UTF-8 String' do
        secret = Combiner.new(@shares, {foo: :bar}).combine
        assert_kind_of String, secret
        secret.encoding.name.must_equal 'UTF-8'
        secret.must_equal @secret
      end
    end

    describe 'when output arg is set to :string_utf8' do
      it 'must return a UTF-8 String' do
        secret = Combiner.new(@shares, {output: :string_utf8}).combine
        assert_kind_of String, secret
        secret.encoding.name.must_equal 'UTF-8'
        secret.must_equal @secret
      end
    end

    describe 'when output arg is set to :array_bytes' do
      it 'must return a Byte Array' do
        secret = Combiner.new(@shares, {output: :array_bytes}).combine
        assert_kind_of Array, secret
        secret.must_equal @secret.bytes.to_a
      end
    end
  end

  describe 'share handling' do
    # TODO: implement
  end
end
