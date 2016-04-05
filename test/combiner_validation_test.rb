require 'test_helper'

describe Combiner do
  before do
    @secret = 'I love secrets with multi-byte unicode characters ½ ♥ 💩'
    @threshold = 3
    @num_shares = 5
    @shares = Splitter.new(@secret, @threshold, @num_shares, SecureRandom.hex(8), SecretHash::SHA256).split
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

    it 'must raise an error if too few shares are passed' do
      assert_raises(Tss::ArgumentError) { Combiner.new(@shares.sample(@threshold - 1)).combine }
    end

    it 'must return the right secret with exactly the right amount of valid shares' do
      secret = Combiner.new(@shares.sample(@threshold)).combine
      assert_kind_of String, secret
      secret.encoding.name.must_equal 'UTF-8'
      secret.must_equal @secret
    end

    it 'must return the right secret with all of the valid shares' do
      secret = Combiner.new(@shares).combine
      assert_kind_of String, secret
      secret.encoding.name.must_equal 'UTF-8'
      secret.must_equal @secret
    end
  end

  describe 'share selection args' do
    it 'must raise an error if a nil is passed' do
      assert_raises(Tss::ArgumentError) { Combiner.new(@shares, nil).combine }
    end

    it 'must raise an error if a an invalid share_selection: value is passed' do
      assert_raises(Tss::ArgumentError) { Combiner.new(@shares, {share_selection: :foo}).combine }
    end

    describe 'when share_selection arg is set to :strict_first_x' do
      it 'must return a secret' do
        secret = Combiner.new(@shares, {share_selection: :strict_first_x}).combine
        secret.must_equal @secret
      end
    end

    describe 'when share_selection arg is set to :strict_sample_x' do
      it 'must return a secret' do
        secret = Combiner.new(@shares, {share_selection: :strict_sample_x}).combine
        secret.must_equal @secret
      end
    end

    describe 'when share_selection arg is set to :any_combination' do
      it 'must return a secret' do
        secret = Combiner.new(@shares, {share_selection: :any_combination}).combine
        secret.must_equal @secret
      end
    end
  end
end
