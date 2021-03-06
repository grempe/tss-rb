require 'test_helper'

# Test interoperability with Python TSS library shares:
# See : https://github.com/seb-m/tss
describe TSS do

  # Python Code:
  # >>> secret = 'I love Python secrets too!'
  # >>> shares = tss.share_secret(2, 3, secret, 'id', tss.Hash.NONE)
  #
  describe 'decoding the tss Python module shares with Hash NONE' do
    it 'must return the expected secret' do
      secret = 'I love Python secrets too!'

      # Python tss shares. Only thing changed was to replace single quotes with double quotes.
      shares = ["id\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x1b\x01\xe15\xaf:\xe1L\xcc\xa7U$\xaf&\x9b\xe47\x89\x10\xfb\x1aY\xa2hj\x17\xfd\xbf",
              "id\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x1b\x02\x02\n\xf1\xc5C7\xe3\xa5!\xd4\xfd\xfd\x9f\xb3\xfb\xa6\x85{\x9b.\xca\xb0H\x9fP\x06",
              "id\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x1b\x03\xaa\x1f2\x90\xd4\x1e\x0fR\r\x84:\xb4jw\xbfJ\xf6\xf2\xe4\x03\x1b\xf8V\xe7\xc2\x98"]

      header = TSS::Util.extract_share_header(shares.first)
      header[:identifier].must_equal 'id'
      header[:hash_id].must_equal 0
      header[:threshold].must_equal 2
      header[:share_len].must_equal 27
      recovered_secret = TSS::Combiner.new(shares: shares, padding: false).combine
      recovered_secret[:secret].must_equal secret
      recovered_secret[:secret].encoding.name.must_equal 'UTF-8'
    end
  end

  # Python Code:
  # >>> secret = 'I love Python secrets too!'
  # >>> shares = tss.share_secret(2, 3, secret, 'id', tss.Hash.SHA1)
  #
  describe 'decoding the tss Python module shares with Hash SHA1' do
    it 'must return the expected secret' do
      secret = 'I love Python secrets too!'

      # Python tss shares. Only thing changed was to replace single quotes with double quotes.
      shares = ["id\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x02\x00/\x01\xb9w.d\xbf\x8d\xfa\x16\xa1\xdd~`%7Km\rN\x0b\xbd)\\\xea\x1c\xc6|\x9c\\\xb1\xff\xea@\x07d\x8f\xe06\xf9B5\xf6\xed\x93\x11k\xe0",
              "id\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x02\x00/\x02\xb2\x8e\xe8y\xff\xae\x8f\xdc\xd2=Dq\xf8\x0e\x03u\xbf\n\xb9\xfd\xc7\xd8S\x89&\x9b\xc1!\x82\xeb\xcfZ\x18\x1bS\xd0<\xb9]\xfc\x85\x9b\xe1;\xc2\xc1",
              "id\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x02\x00/\x03B\xd9\xaar6FU\x9a\n\x94R~\xb3\x19;}\xd16\xd74\x9d\xa4\xcd\xfa\x8f\xc6\x03\n\x93\xe7%\xa5\xe4\xc7\xee\xc0:p\xa1\xbb]@\xcf\xd4\xa5\xde"]

      header = TSS::Util.extract_share_header(shares.first)
      header[:identifier].must_equal 'id'
      header[:hash_id].must_equal 1
      header[:threshold].must_equal 2
      header[:share_len].must_equal 47
      recovered_secret = TSS::Combiner.new(shares: shares, padding: false).combine
      recovered_secret[:secret].must_equal secret
      recovered_secret[:secret].encoding.name.must_equal 'UTF-8'
    end
  end

  # Python Code:
  # >>> secret = 'I love Python secrets too!'
  # >>> shares = tss.share_secret(2, 3, secret, 'id', tss.Hash.SHA256)
  #
  describe 'decoding the tss Python module shares with Hash SHA256' do
    it 'must return the expected secret' do
      secret = 'I love Python secrets too!'

      # Python tss shares. Only thing changed was to replace single quotes with double quotes.
      # had to \ escape a double-quote in the first share
      shares = ["id\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x02\x00;\x01\xd5\xefx=\x1fw\xf0\xe1\x82B\xc4\x00\xc1\"&\xd8\xf8\x0b\xbc\xa0\xae\x14\xea\xab\x8cI\x90vR\xea\xc1-p\x87<\xb5q\x87<>\xe2\xd9\xee\'\xbb\xf7\xbb\xe9\x9b\'\xb9C1\x01HuK\xad",
              "id\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x02\x00;\x02j\xa5D\xcb\xa4A\x9b)\x94\x18+\xb1+$\xd9\x04N\x80\xcc\xc7\xd2HS\xfc\xb2\xf10\x0e\x85\xec\x9c\xf5\xc7L\x81\xe1\xe4\xae=G\xc4G\xe5\xd5\x9f\xe1n\xbeo\xd3\xda\xfan\xf2\xb2\xdd>\xd0",
              "id\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x02\x00;\x03\xf6jP\x99\xcdSK\x98o.\x87\xde\x84&\x8c\xb9\xd5\xf9\x15\x13\x0f|\xcd8Q\x99P&\xc8\xee^\xbd\xaa\xfc\xea$\x97@\xcb\x99/\xc4\x15r\x83\x1a\xd4z\xcav\xfbd[\xa3\xe4L\xe4\xfb"]
      header = TSS::Util.extract_share_header(shares.first)
      header[:identifier].must_equal 'id'
      header[:hash_id].must_equal 2
      header[:threshold].must_equal 2
      header[:share_len].must_equal 59
      recovered_secret = TSS::Combiner.new(shares: shares, padding: false).combine
      recovered_secret[:secret].must_equal secret
      recovered_secret[:secret].encoding.name.must_equal 'UTF-8'
    end
  end

  # Python Code:
  # >>> secret = 'I love Python secrets too!'
  # >>> shares = tss.share_secret(2, 3, secret, 'id', tss.Hash.SHA256)
  #
  describe 'decoding the tss Python module shares with multi-byte unicode secret and Hash SHA256' do
    it 'must return the expected secret' do
      secret = 'I love secrets with multi-byte unicode characters ½ ♥ 💩'

      # Python tss shares. Only thing changed was to replace single quotes with double quotes.
      # had to \ escape a double-quote in the some shares
      shares = [ "id\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x02\x00^\x01\x82q\xb4\x83\xa1\xdf\x9e$\xf53\xfaQ\x92\x8c#UbV\x11>\xbbo\x9c\x8c\xd7\xc9K\xfb\xab\xf3\xd4\xbav[l\xd5A\x94&?\xab\xca\x1d2\xa2\x94f\xb8\x1a\xd9\xc8;\xba\xe6\xdc\xeb\xb6\xa7\x85\xca\xce6f5Jx\xf4\xb3&\rt\x9dr\xbd$\x82c\xa0\x9cS\xa4\x12\x91XH\xdd\x15r\xd5\x11\x8b\x8cs",
              "id\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x02\x00^\x02\xc4\x82\xc7\xac\xc3\nG\xdd^\xc3y\r\xa3\x96&3\x7f0\x9a\x1c\xdaA\x97\x9f\x0e\xfe0f\xd1R\xd3\xf0^\r}\x00.\x9c,\xdb\xf5,\xac\xc7\xfa\xafc\xfd\xa1\xc9\xd6\xaa\x0f\xea\x139\x17^\xab\"g\x0e\xd9e\x16\xcf\x93\xf3\xe0f\xacc\xda\x82\xfd7M\xa7\x18:\xa1\x19\x82\x93\xd3\xf1#\x91:v\xc6\\?",
              "id\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x02\x00^\x03\x0f\xd3\x1f@\x14\xb0\xf9\x8a\xce\x93\xf19Ei%\x11t\x12\xe3\x02\x0c[gg\xb0\x1a\x19\xe4\x0e\xc4\'?F?r\xba\x0bm*\x876\x87\xc3\x94;O`7\xc80\xdc,\x95\xeeVw\x81\t\xb1z\x00\xefEU\"\xa2G:\xa2\xb6\xe4\xc0K\x97C\xadWSd\x1d\xa2\xe9z#S\x1c19\x96\xa2\xfd\xe5\xf2"]

      header = TSS::Util.extract_share_header(shares.first)
      header[:identifier].must_equal 'id'
      header[:hash_id].must_equal 2
      header[:threshold].must_equal 2
      header[:share_len].must_equal 94
      recovered_secret = TSS::Combiner.new(shares: shares, padding: false).combine
      recovered_secret[:secret].must_equal secret
      recovered_secret[:secret].encoding.name.must_equal 'UTF-8'
    end
  end
end
