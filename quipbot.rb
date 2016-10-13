#!/bin/env ruby

require_relative 'lib/markov.rb'
require_relative 'lib/quiplash.rb'

markov_path = './e621_comments.mp.gz'

# Load the markov model
puts 'Loading Markov Chain'
chain = MarkovChain.new markov_path
puts 'Markov chain loaded'

# Load some bot objects
bot_threads = Array.new(4)
bot_threads.each_index do |i|
  # Check for an existing game ID
  if File.exists?("#{i}.game_uuid")
    puts 'Found previous game info, loading saved details'
    game_id = File.read("#{i}.game_uuid")
  end

  bot = Quiplash.new('BBTS', name: "Quipbot#{i}", uuid: game_id)

  game_id = bot.login
  uuid_file = File.new("#{i}.game_uuid", 'w')
  uuid_file.write(game_id)
  uuid_file.close

  bot_threads[i] = bot.start_playing do |prompt|
    begin
      response = chain.gen_seeded_text(prompt, word_limit: 7, include_seed: false)
    rescue ModelMatchError => match_err
      response = chain.gen_random_text(word_limit: 7)
    end
    response
  end
end

bot_threads.each do |thread|
  thread.join
end
