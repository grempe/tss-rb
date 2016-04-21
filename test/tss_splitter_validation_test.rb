require 'test_helper'

describe TSS::Splitter do
  before do
    @s = TSS::Splitter.new(secret: 'my secret')
  end

  describe 'secret' do
    it 'must raise an error if nil' do
      assert_raises(Dry::Types::ConstraintError) { TSS::Splitter.new(secret: nil).split }
    end

    it 'must raise an error if not a string' do
      assert_raises(Dry::Types::ConstraintError) { TSS::Splitter.new(secret: 123).split }
    end

    it 'must raise an error if size < 1' do
      assert_raises(Dry::Types::ConstraintError) { TSS::Splitter.new(secret: '').split }
    end

    it 'must raise an error if size > 65_534' do
      assert_raises(TSS::ArgumentError) { TSS::Splitter.new(secret: 'a' * ((65_534 - 32) + 1)).split }
    end

    it 'must raise an error if first byte of secret is reserved padding char' do
      assert_raises(TSS::ArgumentError) { TSS::Splitter.new(secret: "\u001F" + 'foo').split }
    end

    it 'must raise an error if String encoding is not UTF-8' do
      assert_raises(TSS::ArgumentError) { TSS::Splitter.new(secret: 'a'.force_encoding('ISO-8859-1')).split }
    end

    it 'must return an Array of default shares with US-ASCII encoded secret' do
      s = TSS::Splitter.new(secret: 'a'.force_encoding('US-ASCII')).split
      assert_kind_of Array, s
      assert s.size.must_equal 5
      assert_kind_of String, s.first
    end

    it 'must return an Array of default shares with a min size secret' do
      s = TSS::Splitter.new(secret: 'a').split
      assert_kind_of Array, s
      assert s.size.must_equal 5
      assert_kind_of String, s.first
    end

    it 'must return an Array of default shares with a max size secret' do
      s = TSS::Splitter.new(secret: 'a' * (65_534 - 32)).split
      assert_kind_of Array, s
      assert s.size.must_equal 5
      assert_kind_of String, s.first
    end
  end

  describe 'threshold' do
    it 'must raise an error if size < 1' do
      assert_raises(Dry::Types::ConstraintError) { TSS::Splitter.new(secret: 'a', threshold: 0).split }
    end

    it 'must raise an error if size > 255' do
      assert_raises(Dry::Types::ConstraintError) { TSS::Splitter.new(secret: 'a', threshold: 256).split }
    end

    it 'must accept String Coercible to Integer' do
      s = TSS::Splitter.new(secret: 'a', threshold: '1').split
      secret = TSS::Combiner.new(shares: s.sample(1)).combine
      secret[:threshold].must_equal 1
    end

    it 'must return an Array of default shares with a min size threshold' do
      s = TSS::Splitter.new(secret: 'a', threshold: 1).split
      assert_kind_of Array, s
      assert s.size.must_equal 5
      secret = TSS::Combiner.new(shares: s.sample(1)).combine
      assert_kind_of String, secret[:secret]
      secret[:threshold].must_equal 1
    end

    it 'must return an Array of default threshold (3) shares with no threshold' do
      s = TSS::Splitter.new(secret: 'a').split
      assert_kind_of Array, s
      assert s.size.must_equal 5
      secret = TSS::Combiner.new(shares: s.sample(3)).combine
      assert_kind_of String, secret[:secret]
      secret[:threshold].must_equal 3
    end

    it 'must return an Array of default shares with a max size threshold' do
      s = TSS::Splitter.new(secret: 'a', threshold: 255, num_shares: 255).split
      assert_kind_of Array, s
      assert s.size.must_equal 255
      secret = TSS::Combiner.new(shares: s.sample(255)).combine
      assert_kind_of String, secret[:secret]
      secret[:threshold].must_equal 255
    end
  end

  describe 'num_shares' do
    it 'must raise an error if size < 1' do
      assert_raises(Dry::Types::ConstraintError) { TSS::Splitter.new(secret: 'a', num_shares: 0).split }
    end

    it 'must raise an error if size > 255' do
      assert_raises(Dry::Types::ConstraintError) { TSS::Splitter.new(secret: 'a', num_shares: 256).split }
    end

    it 'must raise an error if num_shares < threshold' do
      assert_raises(TSS::ArgumentError) { TSS::Splitter.new(secret: 'a', threshold: 3, num_shares: 2).split }
    end

    it 'must accept String Coercible to Integer' do
      s = TSS::Splitter.new(secret: 'a', threshold: 1, num_shares: '1').split
      secret = TSS::Combiner.new(shares: s.sample(1)).combine
      secret[:threshold].must_equal 1
    end

    it 'must return an Array of shares with a min size' do
      s = TSS::Splitter.new(secret: 'a', threshold: 1, num_shares: 1).split
      assert_kind_of Array, s
      assert s.size.must_equal 1
      secret = TSS::Combiner.new(shares: s.sample(1)).combine
      assert_kind_of String, secret[:secret]
      secret[:threshold].must_equal 1
    end

    it 'must return an Array of threshold (5) shares with no num_shares' do
      s = TSS::Splitter.new(secret: 'a').split
      assert_kind_of Array, s
      assert s.size.must_equal 5
      secret = TSS::Combiner.new(shares: s).combine
      assert_kind_of String, secret[:secret]
      secret[:threshold].must_equal 3
    end

    it 'must return an Array of shares with a max size' do
      s = TSS::Splitter.new(secret: 'a', threshold: 255, num_shares: 255).split
      assert_kind_of Array, s
      assert s.size.must_equal 255
      secret = TSS::Combiner.new(shares: s.sample(255)).combine
      assert_kind_of String, secret[:secret]
      secret[:threshold].must_equal 255
    end
  end

  describe 'identifier' do
    it 'must raise an error if size > 16' do
      assert_raises(Dry::Types::ConstraintError) { TSS::Splitter.new(secret: 'a', identifier: 'a'*17).split }
    end

    it 'must raise an error if non-whitelisted characters' do
      assert_raises(Dry::Types::ConstraintError) { TSS::Splitter.new(secret: 'a', identifier: '&').split }
    end

    it 'must accept an empty String' do
      s = TSS::Splitter.new(secret: 'a', identifier: '').split
      secret = TSS::Combiner.new(shares: s).combine
      secret[:identifier].must_equal ''
    end

    it 'must accept a String with all whitelisted characters' do
      id = 'abc-ABC_0.9'
      s = TSS::Splitter.new(secret: 'a', identifier: id).split
      secret = TSS::Combiner.new(shares: s).combine
      secret[:identifier].must_equal id
    end

    it 'must accept a 16 Byte String' do
      id = SecureRandom.hex(8)
      s = TSS::Splitter.new(secret: 'a', identifier: id).split
      secret = TSS::Combiner.new(shares: s).combine
      secret[:identifier].must_equal id
    end
  end

  describe 'hash_alg' do
    it 'must raise an error if empty' do
      assert_raises(Dry::Types::ConstraintError) { TSS::Splitter.new(secret: 'a', hash_alg: '').split }
    end

    it 'must raise an error if value is not in the Enum' do
      assert_raises(Dry::Types::ConstraintError) { TSS::Splitter.new(secret: 'a', hash_alg: 'foo').split }
    end

    it 'must accept an NONE String' do
      s = TSS::Splitter.new(secret: 'a', hash_alg: 'NONE').split
      secret = TSS::Combiner.new(shares: s).combine
      secret[:hash_alg].must_equal 'NONE'
    end

    it 'must accept an SHA1 String' do
      s = TSS::Splitter.new(secret: 'a', hash_alg: 'SHA1').split
      secret = TSS::Combiner.new(shares: s).combine
      secret[:hash_alg].must_equal 'SHA1'
    end

    it 'must accept an SHA256 String' do
      s = TSS::Splitter.new(secret: 'a', hash_alg: 'SHA256').split
      secret = TSS::Combiner.new(shares: s).combine
      secret[:hash_alg].must_equal 'SHA256'
    end
  end

  describe 'pad_blocksize' do
    it 'must raise an error if a an invalid negative value is passed' do
      assert_raises(Dry::Types::ConstraintError) { TSS::Splitter.new(secret: 'a', pad_blocksize: -1).split }
    end

    it 'must raise an error if a an invalid too high value is passed' do
      assert_raises(Dry::Types::ConstraintError) { TSS::Splitter.new(secret: 'a', pad_blocksize: 256).split }
    end

    describe 'when padding arg is set' do
      it 'must return a correctly sized share' do
        share_0 = TSS::Splitter.new(secret: 'a', hash_alg: 'NONE', pad_blocksize: 0, format: 'binary').split
        share_0.first.length.must_equal 22

        share_8 = TSS::Splitter.new(secret: 'a', hash_alg: 'NONE', pad_blocksize: 8, format: 'binary').split
        share_8.first.length.must_equal 29

        share_16 = TSS::Splitter.new(secret: 'a', hash_alg: 'NONE', pad_blocksize: 16, format: 'binary').split
        share_16.first.length.must_equal 37
      end
    end
  end
end
