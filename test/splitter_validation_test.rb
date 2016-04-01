require 'test_helper'

describe Splitter do
  before do
    @s = Splitter.new('my secret', 3, 5, SecureRandom.hex(8), Tss::SecretHash::SHA256)
  end

  describe 'secret' do
    describe 'when given a valid object' do
      it 'must respond positively' do
        @s.must_be :valid?
      end
    end

    describe 'when given a nil secret' do
      it 'must not be valid?' do
        @s.secret = nil
        @s.wont_be :valid?
      end

      it 'must return an error message?' do
        @s.secret = nil
        @s.valid?
        @s.errors.messages[:secret].first.must_match "can't be blank"
      end
    end

    describe 'when given a non String or Array secret' do
      it 'must not be valid?' do
        @s.secret = {}
        @s.wont_be :valid?
      end

      it 'must return an error message?' do
        @s.secret = {}
        @s.valid?
        @s.errors.messages[:secret].first.must_match "can't be blank"
      end
    end

    describe 'when given a non-UTF-8 String secret' do
      it 'must not be valid?' do
        @s.secret = 'foo'.force_encoding('ASCII-8BIT')
        @s.wont_be :valid?
      end

      it 'must return an error message?' do
        @s.secret = 'foo'.force_encoding('ASCII-8BIT')
        @s.valid?
        @s.errors.messages[:secret].first.must_match 'must be a UTF-8 or US-ASCII String'
      end
    end

    describe 'when given a blank String secret' do
      it 'must not be valid?' do
        @s.secret = ''
        @s.wont_be :valid?
      end

      it 'must return an error message?' do
        @s.secret = ''
        @s.valid?
        @s.errors.messages[:secret].first.must_match "can't be blank"
      end
    end

    describe 'when given a min size one byte String secret' do
      it 'must be valid?' do
        @s.secret = 'a'
        @s.must_be :valid?
      end
    end

    describe 'when given a max size 2**16 - 2 byte String secret' do
      it 'must be valid?' do
        @s.secret = 'a' * (2**16 - 2)
        @s.must_be :valid?
      end
    end

    describe 'when given a larger than max size 2**16 - 1 byte String secret' do
      it 'must not be valid?' do
        @s.secret = 'a' * (2**16 - 1)
        @s.wont_be :valid?
      end
    end

    describe 'when given a blank Array secret' do
      it 'must not be valid?' do
        @s.secret = []
        @s.wont_be :valid?
      end

      it 'must return an error message?' do
        @s.secret = []
        @s.valid?
        @s.errors.messages[:secret].first.must_match "can't be blank"
      end
    end

    describe 'when given a min size one byte Array secret' do
      it 'must be valid?' do
        @s.secret = 'a'.bytes.to_a
        @s.must_be :valid?
      end
    end

    describe 'when given a max size 2**16 - 2 byte Array secret' do
      it 'must be valid?' do
        @s.secret = ('a' * (2**16 - 2)).bytes.to_a
        @s.must_be :valid?
      end
    end

    describe 'when given a larger than max size 2**16 - 1 byte Array secret' do
      it 'must not be valid?' do
        @s.secret = ('a' * (2**16 - 1)).bytes.to_a
        @s.wont_be :valid?
      end
    end
  end # secret

  describe 'threshold' do
    describe 'when given a nil' do
      it 'must not be valid?' do
        @s.threshold = nil
        @s.wont_be :valid?
      end

      it 'must return an error message?' do
        @s.threshold = nil
        @s.valid?
        @s.errors.messages[:threshold].first.must_match "can't be blank"
      end
    end

    describe 'when given an non-Integer' do
      it 'must not be valid?' do
        @s.threshold = '5'
        @s.wont_be :valid?
      end

      it 'must return an error message?' do
        @s.threshold = '5'
        @s.valid?
        @s.errors.messages[:threshold].first.must_match 'must be an Integer between'
      end
    end

    describe 'when given a 0 value' do
      it 'must not be valid?' do
        @s.threshold = 0
        @s.wont_be :valid?
      end

      it 'must return an error message?' do
        @s.threshold = 0
        @s.valid?
        @s.errors.messages[:threshold].first.must_match 'must be an Integer between'
      end
    end

    describe 'when given a too large value' do
      it 'must not be valid?' do
        @s.threshold = 255 + 1
        @s.wont_be :valid?
      end

      it 'must return an error message?' do
        @s.threshold = 255 + 1
        @s.valid?
        @s.errors.messages[:threshold].first.must_match 'must be an Integer between'
      end
    end

    describe 'when given valid min value' do
      it 'must be valid?' do
        @s.threshold = 1
        @s.must_be :valid?
      end
    end

    describe 'when given valid max value' do
      it 'must be valid?' do
        @s.threshold = 255
        @s.num_shares = 255
        @s.must_be :valid?
      end
    end
  end # threshold

  describe 'num_shares' do
    describe 'when given a nil' do
      it 'must not be valid?' do
        @s.num_shares = nil
        @s.wont_be :valid?
      end

      it 'must return an error message?' do
        @s.num_shares = nil
        @s.valid?
        @s.errors.messages[:num_shares].first.must_match "can't be blank"
      end
    end

    describe 'when given an non-Integer' do
      it 'must not be valid?' do
        @s.num_shares = '5'
        @s.wont_be :valid?
      end

      it 'must return an error message?' do
        @s.num_shares = '5'
        @s.valid?
        @s.errors.messages[:num_shares].first.must_match 'must be an Integer between'
      end
    end

    describe 'when given a 0 value' do
      it 'must not be valid?' do
        @s.num_shares = 0
        @s.wont_be :valid?
      end

      it 'must return an error message?' do
        @s.num_shares = 0
        @s.valid?
        @s.errors.messages[:num_shares].first.must_match 'must be an Integer between'
      end
    end

    describe 'when given a too large value' do
      it 'must not be valid?' do
        @s.num_shares = 255 + 1
        @s.wont_be :valid?
      end

      it 'must return an error message?' do
        @s.num_shares = 255 + 1
        @s.valid?
        @s.errors.messages[:num_shares].first.must_match 'must be an Integer between'
      end
    end

    describe 'when given valid min value' do
      it 'must be valid?' do
        @s.threshold = 1
        @s.num_shares = 1
        @s.must_be :valid?
      end
    end

    describe 'when given valid max value' do
      it 'must be valid?' do
        @s.num_shares = 255
        @s.must_be :valid?
      end
    end
  end # num_shares

  describe 'identifier' do
    describe 'when given an non-String' do
      it 'must not be valid?' do
        @s.identifier = 222
        @s.wont_be :valid?
      end

      it 'must return an error message?' do
        @s.identifier = 222
        @s.valid?
        @s.errors.messages[:identifier].first.must_match 'must be a String'
      end
    end

    describe 'when given a nil arg' do
      it 'must be valid?' do
        @s.identifier = nil
        @s.must_be :valid?
      end
    end

    describe 'when given an empty String' do
      it 'must be valid?' do
        @s.identifier = ''
        @s.must_be :valid?
      end
    end

    describe 'when given an 1 Byte String' do
      it 'must be valid?' do
        @s.identifier = 'a'
        @s.must_be :valid?
      end
    end

    describe 'when given an 16 Byte String' do
      it 'must be valid?' do
        @s.identifier = 'a' * 16
        @s.must_be :valid?
      end
    end

    describe 'when given a random 16 Byte Hex String' do
      it 'must be valid?' do
        @s.identifier = SecureRandom.hex(8)
        @s.must_be :valid?
      end
    end

    describe 'when given a too large String' do
      it 'must not be valid?' do
        @s.identifier = 'a' * 17
        @s.wont_be :valid?
      end

      it 'must return an error message?' do
        @s.identifier = 'a' * 17
        @s.valid?
        @s.errors.messages[:identifier].first.must_match 'must be a String'
      end
    end
  end # identifier

  describe 'hash_id' do
    describe 'when given a nil' do
      it 'must not be valid?' do
        @s.hash_id = nil
        @s.wont_be :valid?
      end

      it 'must return an error message?' do
        @s.hash_id = nil
        @s.valid?
        @s.errors.messages[:hash_id].first.must_match "can't be blank"
      end
    end

    describe 'when given an non-Integer' do
      it 'must not be valid?' do
        @s.hash_id = '2'
        @s.wont_be :valid?
      end

      it 'must return an error message?' do
        @s.hash_id = '2'
        @s.valid?
        @s.errors.messages[:hash_id].first.must_match 'must be an Integer and in'
      end
    end

    describe 'when given an invalid hash_id code' do
      it 'must not be valid?' do
        @s.hash_id = 99
        @s.wont_be :valid?
      end

      it 'must return an error message?' do
        @s.hash_id = 99
        @s.valid?
        @s.errors.messages[:hash_id].first.must_match 'must be an Integer and in'
      end
    end

    describe 'when given valid hash_id for NONE' do
      it 'must be valid?' do
        @s.hash_id = Tss::SecretHash::NONE
        @s.must_be :valid?
      end
    end

    describe 'when given valid hash_id for SHA1' do
      it 'must be valid?' do
        @s.hash_id = Tss::SecretHash::SHA1
        @s.must_be :valid?
      end
    end

    describe 'when given valid hash_id for SHA256' do
      it 'must be valid?' do
        @s.hash_id = Tss::SecretHash::SHA256
        @s.must_be :valid?
      end
    end
  end # hash_id
end
