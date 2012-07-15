module SpellChecker
  # Note: These dictionaries could be by created by going throught the dictionary
  # only once, but since these are not created at runtime, I have not bothered
  # changing them.
  hash_of_ints = Hash.new {|h, k| h[k] = 0}
  MAX_CONSEC_LETTERS_COUNT = UPCASED_WORDS.reduce(hash_of_ints) do |h, word|
    letter_groups = split_by_letter word
    letter_groups.each do |letter_group|
      letter = letter_group[0]
      previous_best = h[letter]
      if letter_group.size > previous_best
        h[letter] = letter_group.size
      end
    end
    h
  end

  puts "MAX_CONSEC_LETTERS_COUNT = #{MAX_CONSEC_LETTERS_COUNT.ai}"

  # This one is not needed anymore

  # LETTER_REPEAT_FREQUENCIES = UPCASED_WORDS.reduce Hash.new do |h, word|
  #   split_by_letter(word).each do |letter_group|
  #     letter = letter_group[0]
  #     h[letter] ||= Hash.new {|h, k| h[k] = 0 }
  #     h[letter][letter_group.size] += 1
  #   end
  #   h
  # end

  # puts "LETTER_REPEAT_FREQUENCIES = #{LETTER_REPEAT_FREQUENCIES.ai}"

end
