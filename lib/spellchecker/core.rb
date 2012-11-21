class Module
  # because some things take too long to compute
  def def_saved_constant name
    serialization_path = "#{Dir.pwd}/#{name}.lolrubby"
    if File.exists? serialization_path
      v = Marshal::load File.read(serialization_path)
    else
      v = yield
      File.open(serialization_path, 'w') {|f| f.write(Marshal::dump(v)) }
    end
    const_set name, v
  end
end

module SpellChecker
  VOWELS = Set.new ['A', 'E', 'I', 'O', 'U']

  self.def_saved_constant "LOWEST_WORD_LETTER_COUNT" do
    WORDS.min_by {|w| w.size}.size
  end

  self.def_saved_constant "HIGHEST_WORD_LETTER_COUNT" do
    WORDS.max_by {|w| w.size}.size
  end

  self.def_saved_constant "LONGEST_WORD_BY_CHAR_SEQUENCE" do
    UPCASED_WORDS.reduce Hash.new do |h, word|
      char_seq = word.chars.to_a.uniq.inspect #convert to string with inspect because we don't need to use it as array
      if h[char_seq]
        h[char_seq] = word if word.size > h[char_seq].size
      else
        h[char_seq] = word
      end
      h
    end
  end

  self.def_saved_constant "MAX_CONSEC_LETTERS_COUNT" do
    UPCASED_WORDS.reduce Hash.new do |h, word|
      letter_groups = split_by_letter word
      letter_groups.each do |letter_group|
        letter = letter_group[0]
        previous_best = h[letter] || 0
        if letter_group.size > previous_best
          h[letter] = letter_group.size
        end
      end
      h
    end
  end

  class << self
    def spellcheck word, words_dict = WORDS, upcased_words = UPCASED_WORDS
      word.strip!
      word.gsub!(/[^a-z]/i, '')
      return if word.nil? || word.empty?
      num_attempts = 0

      word_checker = Proc.new do |attempt|
        real_word = word_check_with_case_variations attempt, words_dict, upcased_words
        num_attempts += 1
        if real_word && real_word == word
          return "OK" # Word was fine
        elsif real_word
          return "#{word} => #{real_word}. Num attempts: #{num_attempts}"
        end
      end
      word = word_without_unseen_letter_repetitions word
      word_checker.call word # trying to break out as early as we can

      # if control reaches this point, fixing the word was not as trivial as just
      # removing the unseen letter repetitions. now we have to try substituting vowels
      vowel_substitutions(word).each do |word_vowel_variation|
        longest_word_with_char_sequence = LONGEST_WORD_BY_CHAR_SEQUENCE[word_vowel_variation.upcase.chars.to_a.uniq.inspect]
        word_checker.call longest_word_with_char_sequence if longest_word_with_char_sequence
      end
      # All variations tried
      return "NO SUGGESTION for #{word}. Num attempts: #{num_attempts}"
    end

    def case_fixes word
      # Assume that all legit words are either all uppercase, all downcase,
      # or all downcase except with the first letter capitalized
      first_capped = word[0].upcase + word[1..-1].downcase
      [word.upcase, word.downcase, first_capped] - [word]
    end

    def word_check_with_case_variations word, words_dict = WORDS, upcased_words = UPCASED_WORDS
      upcased_words.include?(word.upcase) && ([word] + case_fixes(word)).find {|w| words_dict.include?(w) }
    end

    # Generate a stream of words based on the initial word with vowels substituted with other vowels.
    # For example: vowel_substitutions("bed").take(2) == ["bed", "bad", "bid"]
    def vowel_substitutions word
      # Array of arrays that contains the possible letters for each position in the word
      possible_letters_by_pos = Array.new

      word.scan(/./).each do |letter|
        if VOWELS.include? letter.upcase
          letter_candidates = [letter] + (VOWELS - [letter.upcase]).to_a
          possible_letters_by_pos << letter_candidates
        else
          possible_letters_by_pos << [letter]
        end
      end

      Enumerator.new do |yielder|
        lazy_cartesian_product(possible_letters_by_pos).each do |letters_ary|
          yielder.yield letters_ary.join
        end
      end
    end

    def word_without_unseen_letter_repetitions word, max_consec_letters = MAX_CONSEC_LETTERS_COUNT
      letter_groups = split_by_letter word
      letter_groups.each do |letter_group|
        letter = letter_group[0].upcase
        max = max_consec_letters[letter]
        excess_chars = letter_group.size - max
        excess_chars.times { letter_group.chop! }
      end
      letter_groups.join
    end
  end
end
