require 'test_helper'

describe Tss do
  describe 'end-to-end test with a UTF-8 multi-byte string and NONE hash' do
    it 'must split and combine the secret properly' do
      secret = 'I love secrets with multi-byte unicode characters ½ ♥ 💩'
      shares = Splitter.new(secret, 3, 10, '123abc', SecretHash::NONE).split
      shares.first.encoding.name.must_equal 'ASCII-8BIT'
      recovered_secret = Combiner.new(shares.sample(3)).combine
      recovered_secret.must_equal secret
      recovered_secret.encoding.name.must_equal 'UTF-8'
    end
  end

  describe 'end-to-end test with a UTF-8 multi-byte string and SHA1 hash' do
    it 'must split and combine the secret properly' do
      secret = 'I love secrets with multi-byte unicode characters ½ ♥ 💩'
      shares = Splitter.new(secret, 3, 10, '123abc', SecretHash::SHA1).split
      shares.first.encoding.name.must_equal 'ASCII-8BIT'
      recovered_secret = Combiner.new(shares.sample(3)).combine
      recovered_secret.must_equal secret
      recovered_secret.encoding.name.must_equal 'UTF-8'
    end
  end

  describe 'end-to-end test with a UTF-8 multi-byte string and SHA256 hash' do
    it 'must split and combine the secret properly' do
      secret = 'I love secrets with multi-byte unicode characters ½ ♥ 💩'
      shares = Splitter.new(secret, 3, 10, '123abc', SecretHash::SHA256).split
      shares.first.encoding.name.must_equal 'ASCII-8BIT'
      recovered_secret = Combiner.new(shares.sample(3)).combine
      recovered_secret.must_equal secret
      recovered_secret.encoding.name.must_equal 'UTF-8'
    end
  end

  describe 'end-to-end test with a US-ASCII string' do
    it 'must split and combine the secret properly' do
      secret = 'US-ASCII chars'.force_encoding('US-ASCII')
      shares = Splitter.new(secret, 3, 10, '123abc', SecretHash::SHA256).split
      shares.first.encoding.name.must_equal 'ASCII-8BIT'
      recovered_secret = Combiner.new(shares.sample(3)).combine
      recovered_secret.must_equal secret
      recovered_secret.encoding.name.must_equal 'UTF-8'
    end
  end

  describe 'end-to-end test with a single char string and NONE hash (shortest)' do
    it 'must split and combine the secret properly' do
      secret = 'a'
      shares = Splitter.new(secret, 3, 10, '123abc', SecretHash::NONE).split
      shares.first.encoding.name.must_equal 'ASCII-8BIT'
      recovered_secret = Combiner.new(shares.sample(3)).combine
      recovered_secret.must_equal secret
      recovered_secret.encoding.name.must_equal 'UTF-8'
    end
  end

  describe 'end-to-end test with *Rule of 64* settings' do
    it 'must split and combine the secret properly' do
      secret = SecureRandom.hex(32)
      shares = Splitter.new(secret, 64, 64, SecureRandom.hex(8), SecretHash::SHA256).split
      shares.first.encoding.name.must_equal 'ASCII-8BIT'
      recovered_secret = Combiner.new(shares).combine
      recovered_secret.must_equal secret
      recovered_secret.encoding.name.must_equal 'UTF-8'
    end
  end
end
