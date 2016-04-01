require 'test_helper'

describe SecretHash do
  describe 'valid? for NONE' do
    it 'must return a correct result' do
      SecretHash.valid?(SecretHash::NONE).must_equal true
    end
  end

  describe 'valid? for SHA1' do
    it 'must return a correct result' do
      SecretHash.valid?(SecretHash::SHA1).must_equal true
    end
  end

  describe 'valid? for SHA256' do
    it 'must return a correct result' do
      SecretHash.valid?(SecretHash::SHA256).must_equal true
    end
  end

  describe 'valid? for bad arg' do
    it 'must return a correct result' do
      SecretHash.valid?(99).must_equal false
    end
  end

  describe 'hash NONE' do
    it 'must return a correct result' do
      SecretHash.hash(SecretHash::NONE, 'a string to hash').must_equal []
    end
  end

  describe 'hash SHA1' do
    it 'must return a correct result' do
      SecretHash.hash(SecretHash::SHA1, 'a string to hash').must_equal [134, 50, 176, 130, 38, 235, 121, 207, 92, 130, 123, 180, 112, 138, 38, 21, 176, 89, 162, 1]
    end
  end

  describe 'hash SHA256' do
    it 'must return a correct result' do
      SecretHash.hash(SecretHash::SHA256, 'a string to hash').must_equal [24, 124, 122, 108, 217, 2, 188, 82, 15, 3, 1, 85, 80, 215, 53, 168, 226, 79, 0, 248, 136, 192, 50, 140, 155, 107, 203, 210, 215, 201, 12, 247]
    end
  end
end
