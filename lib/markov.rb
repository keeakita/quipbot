require 'zlib'
require 'msgpack'

class ModelMatchError < StandardError
end

class MarkovChain
  NUM_GRAMS = 2 # How many words go in each slot

  # Initializes a chain object, optionally loading a saved, gzip compressed,
  # messagepack encoded model
  def initialize(model_file=nil)
    # The model. This hash maps an array of NUM_GRAMS words to another array of
    # NUM_GRAMS words.
    @grams = Hash.new()

    unless model_file.nil?
      packed_compressed_model = Zlib::GzipReader.open(model_file)
      @grams = MessagePack.unpack(packed_compressed_model)
    end
  end

  # Saves the model to a gzip compressed, messagepack encoded file
  def save_model(model_filename)
    file = File.new(model_filename, 'w')
    out = Zlib::GzipWriter.new(file)
    MessagePack.pack(@grams, out)
    out.close
  end

  # Trains the markov chain on the given text file
  def train_text(source_filename)
    source_file = File.new(source_filename)
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

  # Generates a phrase from a seed of at most word_limit words. If no n-gram in
  # the seed can be matched with the chain, raises a ModelMatchError.
  def gen_seeded_text(seed, word_limit: 15, include_seed: true)
    generated = nil
    matching_grams = []

    # Look through the seed phrase and attempt to find something in the model
    seed.split(/\s+/).each_cons(NUM_GRAMS) do |words|
      if @grams.include? words
        matching_grams << words
      end
    end

    if matching_grams.empty?
      raise ModelMatchError.new("Could not find a model match for the string: #{seed}")
    end

    # Choose a matched gram at random
    if (include_seed)
      generated = matching_grams.sample(1)[0]
    else
      generated = @grams[matching_grams.sample(1)[0]].sample(1)[0]
    end

    # Generate the phrase
    current_gram = generated.clone
    while @grams.include?(current_gram) && generated.length < word_limit
      current_gram = @grams[current_gram].sample(1)[0]
      generated = generated.concat(current_gram)
    end

    return generated.join(' ')
  end

  # Picks a random starting point and generates text. Unlike gen_seeded_text,
  # this doesn't have the posibility of generating nothing.
  def gen_random_text(word_limit: 15)
    return gen_seeded_text(@grams.keys.sample(1)[0], word_limit)
  end
end
