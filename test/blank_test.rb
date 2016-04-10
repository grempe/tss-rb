require 'test_helper'

class EmptyTrue
  def empty?
    0
  end
end

class EmptyFalse
  def empty?
    nil
  end
end

BLANK = [ EmptyTrue.new, nil, false, '', '   ', "  \n\t  \r ", '　', "\u00a0", [], {} ]
NOT   = [ EmptyFalse.new, Object.new, true, 0, 1, 'a', [nil], { nil => 0 }, Time.now ]

# extracted tests from rails/activesupport
# See : https://github.com/rails/rails/blob/52ce6ece8c8f74064bb64e0a0b1ddd83092718e1/activesupport/test/core_ext/object/blank_test.rb
describe 'blank' do
  describe 'activesupport tests for blank' do
    it 'must return a correct result' do
      BLANK.each { |v| assert v.blank?.must_equal true }
      NOT.each   { |v| assert v.blank?.must_equal false }

      BLANK.each { |v| assert v.present?.must_equal false }
      NOT.each   { |v| assert v.present?.must_equal true }

      BLANK.each { |v| assert v.presence.must_equal nil }
      NOT.each   { |v| assert v.presence.must_equal v }
    end
  end
end
