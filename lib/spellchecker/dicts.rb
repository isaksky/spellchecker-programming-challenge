module SpellChecker
  WORDS = File.read('/usr/share/dict/words').split.to_set
  UPCASED_WORDS = WORDS.map(&:upcase).to_set
end
