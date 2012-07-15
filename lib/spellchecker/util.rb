module SpellChecker
  class << self
    def split_by_letter s
      letter_groups = []
      s.chars.each do |c|
        if letter_groups.last && letter_groups.last.chars.first == c
          letter_groups[letter_groups.count - 1] += c # letter_groups.last =  does not work (gg ruby)
        else
          letter_groups << c
        end
      end
      letter_groups
    end

    def lazy_cartesian_product colls
      colls.first.enum_for :product, *colls.drop(1)
    end
  end
end
