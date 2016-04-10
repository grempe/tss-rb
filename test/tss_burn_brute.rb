require 'test_helper'

describe TSS do
  describe 'end-to-end long term burn-in test with fuzzy values' do
    it 'must split and combine the secret properly thousands of times' do
      ['NONE', 'SHA1', 'SHA256'].each do |hash_alg|
        (1..32).each do |m|
          (m..32).each do |n|
            secret = SecureRandom.hex(rand(1..32))
            identifier = SecureRandom.hex(rand(8))
            shares = Splitter.new(secret: secret, threshold: m, num_shares: n, identifier: identifier, hash_alg: hash_alg).split
            shares.first.encoding.name.must_equal 'ASCII-8BIT'
            recovered_secret = Combiner.new(shares: shares.sample(m)).combine
            recovered_secret[:secret].must_equal secret
            recovered_secret[:secret].encoding.name.must_equal 'UTF-8'
          end
        end
      end
    end
  end
end
