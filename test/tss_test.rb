require 'test_helper'

describe TSS do

  describe 'errors' do
    describe 'split' do
      it 'must raise an error if called without a Hash arg with secret key' do
        assert_raises(TSS::ArgumentError) { TSS.split([]) }
        assert_raises(TSS::ArgumentError) { TSS.split({}) }
      end
    end

    describe 'split' do
      it 'must raise an TSS::ArgumentError if a Dry::Types::ConstraintError was raised by Splitter' do
        assert_raises(TSS::ArgumentError) { TSS.split(secret: '') }
        assert_raises(TSS::ArgumentError) { TSS.split(secret: 'foo', threshold: 0) }
      end
    end

    describe 'combine' do
      it 'must raise an error if called without a Hash arg with shares key' do
        assert_raises(TSS::ArgumentError) { TSS.combine([]) }
        assert_raises(TSS::ArgumentError) { TSS.combine({}) }
      end
    end

    describe 'combine' do
      it 'must raise an TSS::ArgumentError if a Dry::Types::ConstraintError was raised by Combiner' do
        assert_raises(TSS::ArgumentError) { TSS.combine(shares: '') }
      end
    end
  end

  describe 'with common args' do
    it 'must split and combine the secret properly' do
      [0, 8, 16].each do |pb|
        ['human', 'binary'].each do |f|
          ['NONE', 'SHA1', 'SHA256'].each do |h|
            ['a', 'unicode ½ ♥ 💩', SecureRandom.hex(32)].each do |s|
              shares = TSS.split(secret: s, hash_alg: h, format: f, pad_blocksize: pb)
              shares.first.encoding.name.must_equal f == 'human' ? 'UTF-8' : 'ASCII-8BIT'
              sec = TSS.combine(shares: shares)
              sec[:hash].must_equal h == 'NONE' ? nil : TSS::Hasher.hex_string(h, s)
              sec[:hash_alg].must_equal h
              sec[:identifier].length.must_equal 16
              sec[:process_time].must_be :>, 0.01
              sec[:secret].must_equal s
              sec[:secret].encoding.name.must_equal 'UTF-8'
              sec[:threshold].must_equal 3
            end
          end
        end
      end
    end
  end

  describe 'end-to-end test with *Rule of 64* max settings' do
    it 'must split and combine the secret properly' do
      secret = SecureRandom.hex(32)
      shares = TSS.split(secret: secret, threshold: 64, num_shares: 64, identifier: SecureRandom.hex(8), hash_alg: 'SHA256', select_by: 'first')
      shares.first.encoding.name.must_equal 'UTF-8'
      recovered_secret = TSS.combine(shares: shares)
      recovered_secret[:hash].must_equal Digest::SHA256.hexdigest(secret)
      recovered_secret[:hash_alg].must_equal 'SHA256'
      recovered_secret[:identifier].length.must_equal 16
      recovered_secret[:process_time].must_be :>, 0.01
      recovered_secret[:secret].must_equal secret
      recovered_secret[:secret].encoding.name.must_equal 'UTF-8'
      recovered_secret[:threshold].must_equal 64
    end
  end
end
