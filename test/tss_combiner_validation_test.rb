require 'test_helper'

describe TSS::Combiner do
  before do
    @secret = 'I love secrets with multi-byte unicode characters ½ ♥ 💩'
    @threshold = 3
    @num_shares = 5
    @shares = TSS::Splitter.new(secret: @secret, threshold: @threshold, num_shares: @num_shares, identifier: SecureRandom.hex(8), hash_alg: 'SHA256').split
  end

  describe 'shares argument' do
    it 'must raise an error if a nil is passed' do
      assert_raises(ParamContractError) { TSS::Combiner.new(shares: nil).combine }
    end

    it 'must raise an error if a non-Array is passed' do
      assert_raises(ParamContractError) { TSS::Combiner.new(shares: 'foo').combine }
    end

    it 'must raise an error if any nils are passed in the shares array' do
      assert_raises(ParamContractError) { TSS::Combiner.new(shares: @shares << nil).combine }
    end

    it 'must raise an error if Array with members that are not Strings is passed' do
      assert_raises(ParamContractError) { TSS::Combiner.new(shares: ['foo', :bar]).combine }
      assert_raises(ParamContractError) { TSS::Combiner.new(shares: ['foo', 123]).combine }
    end

    it 'must raise an error if an too small empty Array is passed' do
      assert_raises(ParamContractError) { TSS::Combiner.new(shares: []).combine }
    end

    it 'must raise an error if a too large Array is passed' do
      arr = []
      256.times { arr << 'foo' }
      assert_raises(ParamContractError) { TSS::Combiner.new(shares: arr).combine }
    end

    it 'must raise an error if an invalid share is passed' do
      assert_raises(TSS::ArgumentError) { TSS::Combiner.new(shares: ['foo']).combine }
    end

    it 'must raise an error if too few shares are passed' do
      assert_raises(TSS::ArgumentError) { TSS::Combiner.new(shares: @shares.sample(@threshold - 1)).combine }
    end

    it 'must return the right secret with exactly the right amount of valid shares' do
      secret = TSS::Combiner.new(shares: @shares.sample(@threshold)).combine
      assert_kind_of String, secret[:secret]
      secret[:secret].encoding.name.must_equal 'UTF-8'
      secret[:secret].must_equal @secret
    end

    it 'must return the right secret with all of the valid shares' do
      secret = TSS::Combiner.new(shares: @shares).combine
      assert_kind_of String, secret[:secret]
      secret[:secret].encoding.name.must_equal 'UTF-8'
      secret[:secret].must_equal @secret
    end
  end

  describe 'share selection args' do
    it 'must raise an error if a an invalid share_selection: value is passed' do
      assert_raises(ParamContractError) { TSS::Combiner.new(shares: @shares, select_by: 'foo').combine }
    end

    describe 'when share_selection arg is unset' do
      it 'must return a secret and default to first' do
        secret = TSS::Combiner.new(shares: @shares).combine
        secret[:secret].must_equal @secret
      end
    end

    describe 'when share_selection arg is set to first' do
      it 'must return a secret' do
        secret = TSS::Combiner.new(shares: @shares, select_by: 'FIRST').combine
        secret[:secret].must_equal @secret
      end
    end

    describe 'when share_selection arg is set to sample' do
      it 'must return a secret' do
        secret = TSS::Combiner.new(shares: @shares, select_by: 'SAMPLE').combine
        secret[:secret].must_equal @secret
      end
    end

    describe 'when share_selection arg is set to combinations' do
      it 'must return a secret' do
        secret = TSS::Combiner.new(shares: @shares, select_by: 'COMBINATIONS').combine
        secret[:secret].must_equal @secret
      end
    end
  end
end
