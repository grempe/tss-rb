require 'test_helper'

describe Tss do
  describe 'end-to-end long term burn-in test with fuzzy values' do
    it 'must split and combine the secret properly thousands of times' do
      (0..2).each do |hash_id|
        (1..32).each do |m|
          (m..32).each do |n|
            secret = SecureRandom.hex(rand(1..32))
            identifier = SecureRandom.hex(rand(8))
            shares = Splitter.new(secret, m, n, identifier, hash_id).split
            shares.first.encoding.name.must_equal 'ASCII-8BIT'
            recovered_secret = Combiner.new(shares.sample(m)).combine
            recovered_secret.must_equal secret
            recovered_secret.encoding.name.must_equal 'UTF-8'
          end
        end
      end
    end
  end
end
