require 'test_helper'

describe Tss do
  describe 'end-to-end test with a UTF-8 multi-byte string' do
    it 'must split and combine the secret properly' do
      secret = 'I love secrets with multi-byte unicode characters ½ ♥ 💩'
      shares = Splitter.new(secret, 3, 10, '123abc', 2).split
      recovered_secret = Combiner.new(shares.sample(3)).combine
      recovered_secret.must_equal secret
    end
  end

  describe 'end-to-end test with a UTF-8 multi-byte string as an Array of Bytes' do
    it 'must split and combine the secret properly' do
      secret = 'I love secrets with multi-byte unicode characters ½ ♥ 💩'
      shares = Splitter.new(secret.bytes.to_a, 3, 10, '123abc', 2).split
      recovered_secret = Combiner.new(shares.sample(3)).combine
      recovered_secret.must_equal secret
    end
  end

  describe 'end-to-end test with a US-ASCII string' do
    it 'must split and combine the secret properly' do
      secret = 'I love secrets with US-ASCII characters'.force_encoding('US-ASCII')
      shares = Splitter.new(secret, 3, 10, '123abc', 2).split
      recovered_secret = Combiner.new(shares.sample(3)).combine
      recovered_secret.must_equal secret
    end
  end

  describe 'end-to-end test with fuzzy values' do
    it 'must split and combine the secret properly' do
      (1..20).each do |threshold|
        (threshold..20).each do |num_shares|
          secret = SecureRandom.hex(16) # hex has encoding.name 'US-ASCII'
          shares = Splitter.new(secret, threshold, num_shares, '123abc', 2).split
          recovered_secret = Combiner.new(shares.sample(threshold)).combine
          recovered_secret.must_equal secret
        end
      end
    end
  end

  # As with every crypto algorithm, it is essential to test an
  # implementation of TSS or RTSS for correctness.  This section provides
  # guidance for such testing.
  #
  # The Secret Reconstruction algorithm can be tested using Known Answer
  # Tests (KATs).  Test cases are provided in Section 9.
  #
  # The Share Generation algorithm cannot be directly tested using a KAT.
  # It can be indirectly tested by generating secret values uniformly at
  # random, then applying the Share Generation process to them to
  # generate a set of shares, then applying the Share Reconstruction
  # algorithm to the shares, then finally comparing the reconstructed
  # secret to the original secret.  Implementations SHOULD perform this
  # test, using a variety of thresholds and secret lengths.
  #
  # The Share Index (the initial octet of each share) can never be equal
  # to zero.  This property SHOULD be tested.
  #
  # The random source must be tested to ensure that it has high min-
  # entropy.
  #
  # OFFICIAL TEST CASE
  # algorithm       = TSS
  # secret          = 7465737400
  # threshold (M)   = 2
  # num. shares (N) = 2
  # share index     = 1
  # share           = B9FA07E185
  # share index     = 2
  # share           = F5409B4511
  #
  # describe 'the official ietf-draft test vector' do
  #   it 'must re-create a known secret' do
  #     secret = Util.hex_to_utf8('7465737400')
  #     recovered_secret = Combiner.new(['B9FA07E185', 'F5409B4511']).combine
  #     recovered_secret.must_equal secret
  #   end
  # end
end
