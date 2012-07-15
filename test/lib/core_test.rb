require_relative '../../lib/spellchecker'
require 'test/unit'
require 'set'

# NOTE: Converting things to sets to test if order is not important

class TestCore < Test::Unit::TestCase
  def test_case_fixes
    assert_equal Set.new(["Foo", "FOO", "foo"]) , SpellChecker.case_fixes("fOo").to_set
  end

  def test_word_check_with_case_variations
    words_dict = Set.new ["Isak"]
    upcased_words = Set.new ["ISAK"]
    assert_equal "Isak", SpellChecker.word_check_with_case_variations("iSaK", words_dict, upcased_words)
  end

  def test_vowel_mistake_fixes
    # 1 vowel
    vowel_mistake_fixes = SpellChecker.vowel_mistake_fixes("bed").map(&:upcase)
    %w{BAD BED BUD BID BOD}.each do |s|
      assert vowel_mistake_fixes.include? s
    end
    # Many vowels..
    vowel_mistake_fixes = SpellChecker.vowel_mistake_fixes("foo").map(&:upcase).to_set
    %w{FOA FOI FUI FIO}.each do |s|
      assert vowel_mistake_fixes.include? s
    end
  end

  def test_repeated_letter_fixes
    max_consec_letters = Hash.new {|h, k| h[k] = 1 }
    max_consec_letters['O'] = 3
    max_consec_letters['B'] = 2
    max_consec_letters['J'] = 2
    repeated_letter_fixes = SpellChecker.repeated_letter_fixes("jjoooobbb", max_consec_letters).map(&:upcase).to_set
    (%w{JJOOOBB JOOBB JOB JOOB JOBB JJOOBB}).to_set.each do |s|
      assert repeated_letter_fixes.include? s
    end
  end

  def test_spellcheck
    assert SpellChecker.spellcheck("PhytoterattollogoCAL") != "NO SUGGESTION"
  end
end
