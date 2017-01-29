require 'test_helper'

describe TSS do

  describe 'errors' do
    describe 'split' do
      it 'must raise an error if called without a Hash arg with secret key' do
        assert_raises(ParamContractError) { TSS.split([]) }
        assert_raises(ParamContractError) { TSS.split({}) }
      end
    end

    describe 'combine' do
      it 'must raise an error if called without a Hash arg with shares key' do
        assert_raises(ParamContractError) { TSS.combine([]) }
        assert_raises(ParamContractError) { TSS.combine({}) }
      end
    end
  end

  describe 'with common args' do
    it 'must split and combine the secret properly' do
      ['HUMAN', 'BINARY'].each do |f|
        ['NONE', 'SHA1', 'SHA256'].each do |h|
          ['a', 'unicode ½ ♥ 💩', SecureRandom.hex(32).force_encoding('US-ASCII')].each do |s|
            shares = TSS.split(secret: s, hash_alg: h, format: f)
            shares.first.encoding.name.must_equal f == 'HUMAN' ? 'UTF-8' : 'ASCII-8BIT'
            sec = TSS.combine(shares: shares)
            if h == 'NONE'
              sec[:hash].must_be_nil
            else
              sec[:hash].must_equal TSS::Hasher.hex_string(h, s)
            end
            sec[:hash_alg].must_equal h
            sec[:identifier].length.must_equal 16
            unless sec[:process_time] == 0.0
              sec[:process_time].must_be :>, 0.01
            end
            sec[:secret].must_equal s
            sec[:secret].encoding.name.must_equal 'UTF-8'
            sec[:threshold].must_equal 3
          end
        end
      end
    end
  end

  describe 'end-to-end test with *Rule of 64* max settings' do
    it 'must split and combine the secret properly' do
      # Note : .force_encoding('US-ASCII') only because SecureRandom.hex(32)
      # returns ASCII-8BIT encoding, not US-ASCII as on MRI. Lets tests pass
      # on jRuby.
      secret = SecureRandom.hex(32).force_encoding('US-ASCII')
      shares = TSS.split(secret: secret, threshold: 64, num_shares: 64, identifier: SecureRandom.hex(8), hash_alg: 'SHA256', select_by: 'first')
      shares.first.encoding.name.must_equal 'UTF-8'
      recovered_secret = TSS.combine(shares: shares)
      recovered_secret[:hash].must_equal Digest::SHA256.hexdigest(secret)
      recovered_secret[:hash_alg].must_equal 'SHA256'
      recovered_secret[:identifier].length.must_equal 16
      unless recovered_secret[:process_time] == 0.0
        recovered_secret[:process_time].must_be :>, 0.01
      end
      recovered_secret[:secret].must_equal secret
      recovered_secret[:secret].encoding.name.must_equal 'UTF-8'
      recovered_secret[:threshold].must_equal 64
    end
  end
end
