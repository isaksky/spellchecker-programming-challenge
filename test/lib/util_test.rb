require_relative '../../lib/spellchecker'
require 'test/unit'
require 'set'

class TestUtil < Test::Unit::TestCase
  def test_split_by_letter
    assert_equal ['S', 'p', 'ee', 'd'], SpellChecker.split_by_letter("Speed")
  end

  def test_lazy_cartesian_product
    assert_equal([[1, "a"], [1, "b"], [2, "a"], [2, "b"]],
                 SpellChecker.lazy_cartesian_product([[1,2], ['a', 'b']]).to_a)
  end
end
