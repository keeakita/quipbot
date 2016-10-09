require 'pry'

class ModelMatchError < StandardError
end

class MarkovChain
  NUM_GRAMS = 2 # How many words go in each slot

  # Creates a new Markov chain, training it on the given file
  def initialize(source_filename)
    source_file = File.new(source_filename)

    # The model. This hash maps an array of NUM_GRAMS words to another array of
    # NUM_GRAMS words.
    @grams = Hash.new()

    source_file.each_line do |line|

      # NOTE: Sentences with less than NUM_GRAMS * 2 words will be left out of
      # the model!
      line.split(/\s+/).each_cons(NUM_GRAMS * 2) do |words|
        if @grams[words[0..(NUM_GRAMS-1)]].nil?
          @grams[words[0..(NUM_GRAMS-1)]] = Array.new()
        end

        @grams[words[0..(NUM_GRAMS-1)]] << words[NUM_GRAMS..-1]
      end
    end
  end

  # Generates a phrase from a seed of at most word_limit words
  def gen_seeded_text(seed, word_limit: 15)
    # Look through the seed phrase and attempt to find something in the model
    generated = nil

    seed.split(/\s+/).each_cons(NUM_GRAMS) do |words|
      if @grams.include? words
        generated = words
        break
      end
    end

    if generated.nil?
      raise ModelMatchError.new("Could not find a model match for the string: #{seed}")
    end

    # Generate the phrase
    current_gram = generated.clone
    while @grams.include?(current_gram) && generated.length < word_limit
      current_gram = @grams[current_gram].sample(1)
      generated = generated.concat(current_gram)
      binding.pry
    end

    return generated.join(' ')
  end
end

# TODO: DEBUG CODE REMOVE THIS
chain = MarkovChain.new 'clean_brain.txt'

10.times do
  puts chain.gen_seeded_text 'this is really good'
end
