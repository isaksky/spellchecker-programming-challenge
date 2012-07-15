module SpellChecker
  VOWELS = Set.new ['A', 'E', 'I', 'O', 'U']
  MAX_ATTEMPTS = WORDS.length - 1 # ;-)

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
        if num_attempts >= MAX_ATTEMPTS
          return "NO SUGGESTION for #{word}. Num attempts: #{num_attempts}"
        end
      end
      word_checker.call word

      # Word was not trivial to fix. Lets try fixing repeated letters.
      # Only look at the first X, so we don't explode
      repeated_letter_fixes = repeated_letter_fixes(word) #take MAX_REPATED_LETTER_FIXES
      repeated_letter_fixes.each do |word_letter_repeat_fix|
        word_checker.call word_letter_repeat_fix, words_dict
        # Word was not fixed by merely getting rid of a repeated letter.
        # Lets try fixing incorrect vowels.
        # Again, only look at first Y, so we don't explode.
        vowel_fixes = vowel_mistake_fixes(word_letter_repeat_fix) #take MAX_VOWEL_MISTAKE_FIXES
        vowel_fixes.each do |word_vowel_variation|
          word_checker.call word_vowel_variation
        end
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
      return nil unless upcased_words.include? word.upcase
      # Find correct capitalization
      ([word] + case_fixes(word)).find {|w| words_dict.include?(w) }
    end

    # Generate a stream of words based on the initial word with vowels substituted with other vowels.
    # For example: vowel_mistake_fixes("bed").take(2) == ["bed", "bad", "bid"]
    def vowel_mistake_fixes word
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

    # Generate a stream of words based on initial word that chomps repeated letters
    # one at the time. (Except the first one, which strips all repeated letters to
    # the maximum length ever observed in dictionary.)
    # For example: repeated_letter_fixes("jjoooobbb").to_a == ["jjoobb", "joobb", "joob", "job"]
    def repeated_letter_fixes word, max_consec_letters = MAX_CONSEC_LETTERS_COUNT
      letter_groups = split_by_letter(word)
      remove_unseen_letter_repetitions! letter_groups, max_consec_letters

      Enumerator.new do |yielder|
        yielder.yield letter_groups.join # returns the the initial correction done above
        possible_letter_groups_by_index = letter_groups.reduce([]) do |memo, letter_group|
          possible_letter_groups = []
          letter = letter_group[0].upcase
          letter_group.size.downto(1) do |i|
            possible_letter_groups << letter * i
          end
          memo << possible_letter_groups
        end

        letter_group_combinations = lazy_cartesian_product possible_letter_groups_by_index
        letter_group_combinations.each do |letter_group|
          yielder.yield letter_group.join
        end
      end
    end

    def remove_unseen_letter_repetitions! letter_groups, max_consec_letters = MAX_CONSEC_LETTERS_COUNT
      letter_groups.each do |letter_group|
        letter = letter_group[0].upcase
        max = max_consec_letters[letter]
        excess_chars = letter_group.size - max
        excess_chars.times { letter_group.chop! }
      end
    end
  end
end
