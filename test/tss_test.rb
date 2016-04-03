require 'test_helper'

describe Tss do
  describe 'end-to-end test with a UTF-8 multi-byte string' do
    it 'must split and combine the secret properly' do
      secret = 'I love secrets with multi-byte unicode characters ½ ♥ 💩'
      shares = Splitter.new(secret, 3, 10, '123abc', 2).split
      shares.first.encoding.name.must_equal 'ASCII-8BIT'
      recovered_secret = Combiner.new(shares.sample(3)).combine
      recovered_secret.must_equal secret
      recovered_secret.encoding.name.must_equal 'UTF-8'
    end
  end

  describe 'end-to-end test with a US-ASCII string' do
    it 'must split and combine the secret properly' do
      secret = 'I love secrets with US-ASCII characters'.force_encoding('US-ASCII')
      shares = Splitter.new(secret, 3, 10, '123abc', 2).split
      shares.first.encoding.name.must_equal 'ASCII-8BIT'
      recovered_secret = Combiner.new(shares.sample(3)).combine
      recovered_secret.must_equal secret
      recovered_secret.encoding.name.must_equal 'UTF-8'
    end
  end

  describe 'end-to-end test with fuzzy values' do
    it 'must split and combine the secret properly' do
      (1..20).each do |threshold|
        (threshold..20).each do |num_shares|
          secret = SecureRandom.hex(16) # hex has encoding.name 'US-ASCII'
          shares = Splitter.new(secret, threshold, num_shares, '123abc', 2).split
          shares.first.encoding.name.must_equal 'ASCII-8BIT'
          recovered_secret = Combiner.new(shares.sample(threshold)).combine
          recovered_secret.must_equal secret
          recovered_secret.encoding.name.must_equal 'UTF-8'
        end
      end
    end
  end
end
