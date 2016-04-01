require 'test_helper'

describe Combiner do
  before do
    @secret = 'I love secrets with multi-byte unicode characters ½ ♥ 💩'
    @shares = Splitter.new(@secret, 3, 5, SecureRandom.hex(8), Tss::SecretHash::SHA256).split
  end

  describe 'shares argument' do
    it 'must raise an error if a nil is passed' do
      assert_raises(Tss::ArgumentError) { Combiner.new(nil).combine }
    end

    it 'must raise an error if a non-Array is passed' do
      assert_raises(Tss::ArgumentError) { Combiner.new('foo').combine }
    end

    it 'must raise an error if an invalid share is passed' do
      assert_raises(Tss::ArgumentError) { Combiner.new(['foo']).combine }
    end

    it 'must return the right secret with valid shares' do
      secret = Combiner.new(@shares).combine
      assert_kind_of String, secret
      secret.encoding.name.must_equal 'UTF-8'
      secret.must_equal @secret
    end
  end

  describe 'output format args' do
    it 'must raise an error if a non-Hash is passed' do
      assert_raises(Tss::ArgumentError) { Combiner.new(@shares, 'foo').combine }
    end

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

    it 'must raise an error if a an invalid output: value is passed' do
      assert_raises(Tss::ArgumentError) { Combiner.new(@shares, {output: :foo}).combine }
    end
  end

  describe 'share selection args' do
    it 'must raise an error if a nil is passed' do
      assert_raises(Tss::ArgumentError) { Combiner.new(@shares, nil).combine }
    end

    it 'must raise an error if a an invalid share_selection: value is passed' do
      assert_raises(Tss::ArgumentError) { Combiner.new(@shares, {share_selection: :foo}).combine }
    end
  end
end
