require 'test_helper'

describe TSS do
  describe 'end-to-end burn-in test' do
    it 'must split and combine the secret properly using many combinations of options' do
      ['HUMAN', 'BINARY'].each do |f|
        ['NONE', 'SHA1', 'SHA256'].each do |h|
          (1..10).each do |m|
            (m..10).each do |n|
              id = SecureRandom.hex(rand(1..8))
              s = SecureRandom.hex(rand(1..8))
              shares = TSS.split(secret: s, identifier: id, threshold: m, num_shares: n, hash_alg: h, format: f)
              shares.first.encoding.name.must_equal f == 'HUMAN' ? 'UTF-8' : 'ASCII-8BIT'

              ['FIRST', 'SAMPLE', 'COMBINATIONS'].each do |sb|
                # can't use combinations with NONE
                sb = (h == 'NONE') ? 'FIRST' : sb
                sec = TSS.combine(shares: shares, select_by: sb)
                sec[:secret].must_equal s
                sec[:secret].encoding.name.must_equal 'UTF-8'
              end
            end
          end
        end
      end
    end
  end
end
