require 'test_helper'

describe TSS do
  describe 'end-to-end burn-in test' do
    it 'must split and combine the secret properly using many combinations of options' do
      [0, 32, 128, 255].each do |pb|
        ['human', 'binary'].each do |f|
          ['NONE', 'SHA1', 'SHA256'].each do |h|
            (1..10).each do |m|
              (m..10).each do |n|
                id = SecureRandom.hex(rand(1..8))
                s = SecureRandom.hex(rand(1..8))
                shares = TSS.split(secret: s, identifier: id, threshold: m, num_shares: n, hash_alg: h, format: f, pad_blocksize: pb)
                shares.first.encoding.name.must_equal f == 'human' ? 'UTF-8' : 'ASCII-8BIT'

                ['first', 'sample', 'combinations'].each do |sb|
                  # can't use combinations with NONE
                  sb = (h == 'NONE') ? 'first' : sb
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
end
