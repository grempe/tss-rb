require 'test_helper'

describe TSS do
  describe 'end-to-end test with a UTF-8 multi-byte string and NONE hash' do
    it 'must split and combine the secret properly' do
      secret = 'I love secrets with multi-byte unicode characters ½ ♥ 💩'
      shares = TSS.split(secret: secret, hash_alg: 'NONE')
      shares.first.encoding.name.must_equal 'ASCII-8BIT'
      recovered_secret = TSS.combine(shares: shares.sample(3))
      recovered_secret[:secret].must_equal secret
      recovered_secret[:secret].encoding.name.must_equal 'UTF-8'
    end
  end

  describe 'end-to-end test with a UTF-8 multi-byte string and SHA1 hash' do
    it 'must split and combine the secret properly' do
      secret = 'I love secrets with multi-byte unicode characters ½ ♥ 💩'
      shares = TSS.split(secret: secret, hash_alg: 'SHA1')
      shares.first.encoding.name.must_equal 'ASCII-8BIT'
      recovered_secret = TSS.combine(shares: shares.sample(3))
      recovered_secret[:secret].must_equal secret
      recovered_secret[:secret].encoding.name.must_equal 'UTF-8'
    end
  end

  describe 'end-to-end test with a UTF-8 multi-byte string and SHA256 hash' do
    it 'must split and combine the secret properly' do
      secret = 'I love secrets with multi-byte unicode characters ½ ♥ 💩'
      shares = TSS.split(secret: secret, hash_alg: 'SHA256')
      shares.first.encoding.name.must_equal 'ASCII-8BIT'
      recovered_secret = TSS.combine(shares: shares.sample(3))
      recovered_secret[:secret].must_equal secret
      recovered_secret[:secret].encoding.name.must_equal 'UTF-8'
    end
  end

  describe 'end-to-end test with a US-ASCII string' do
    it 'must split and combine the secret properly' do
      secret = 'US-ASCII chars'.force_encoding('US-ASCII')
      shares = TSS.split(secret: secret, hash_alg: 'SHA256')
      shares.first.encoding.name.must_equal 'ASCII-8BIT'
      recovered_secret = TSS.combine(shares: shares.sample(3))
      recovered_secret[:secret].must_equal secret
      recovered_secret[:secret].encoding.name.must_equal 'UTF-8'
    end
  end

  describe 'end-to-end test with a single char string and NONE hash (shortest)' do
    it 'must split and combine the secret properly' do
      secret = 'a'
      shares = TSS.split(secret: secret, hash_alg: 'NONE')
      shares.first.encoding.name.must_equal 'ASCII-8BIT'
      recovered_secret = TSS.combine(shares: shares.sample(3))
      recovered_secret[:secret].must_equal secret
      recovered_secret[:secret].encoding.name.must_equal 'UTF-8'
    end
  end

  describe 'end-to-end test with *Rule of 64* settings' do
    it 'must split and combine the secret properly' do
      secret = SecureRandom.hex(32)
      shares = TSS.split(secret: secret, threshold: 64, num_shares: 64, identifier: SecureRandom.hex(8), hash_alg: 'SHA256', select_by: 'first')
      shares.first.encoding.name.must_equal 'ASCII-8BIT'
      recovered_secret = TSS.combine(shares: shares)
      recovered_secret[:secret].must_equal secret
      recovered_secret[:secret].encoding.name.must_equal 'UTF-8'
    end
  end
end
