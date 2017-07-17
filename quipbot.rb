#!/bin/env ruby

require 'optparse'

require_relative 'lib/markov.rb'
require_relative 'lib/quiplash.rb'
require_relative 'lib/quiplash2.rb'
require_relative 'lib/teeko.rb'

GAMES = [:quiplash, :quiplash2, :teeko]

# Defaults
options = {
  game: GAMES[0],
  model: './model.mp.gz',
  pic_dir: '~/Pictures',
  instances: 1,
  # room_code: must be set by an argument
}

# Parse command line arguments
optparse = OptionParser.new do |parser|
  parser.banner = "Usage: quibot.rb --code CODE [options]"

  # Mandatory room code, can't join a game without it
  parser.on('-cCODE', '--code=CODE',
          'The Jackbox room code used to join the game') do |code|
    if code.size != 4
      raise OptionParser::InvalidOption.new('Room code must be 4 letters')
    end
    options[:room_code] = code.upcase
  end

  parser.on('-gGAME',
            '--game=GAME',
            GAMES,
            'Which game the bot should attempt to play.',
            "Default: #{options[:game]}",
            "Valid choices: #{GAMES.join(' ')}") do |game|

    options[:game] = game.to_sym
  end

  parser.on('-fMODEL',
            '--file=MODEL',
            'The model file to use for text generation') do |model|
    options[:model] = model
  end

  parser.on('-nINSTANCES',
            '--number=INSTANCES',
            Integer,
            'How many instances of the bot to launch.',
            'Must be between 1 and 8, inclusive.') do |instances|
    if instances < 1 || instances > 8
      raise OptionParser::InvalidOption.new(
        'Number of instances must be between 1 and 8.')
    end
    options[:instances] = instances
  end

  parser.on('-pPICTURE_DIR',
            '--picture-dir=PICTURE_DIR',
            String,
            'Picture directory to use for Tee K.O.',
            'Default is ~/Pictures/.') do |pic_dir|
    unless File.directory? pic_dir
      raise OptionParser::InvalidOption.new(
        'Specified picture directory does not appear to be a directory.')
    end
    options[:pic_dir] = pic_dir
  end

  parser.on('-h', '--help', 'Prints this help') do
    puts parser
    exit
  end
end

begin
  optparse.parse!
  if options[:room_code].nil?
    raise OptionParser::MissingArgument.new('room_code')
  end
rescue OptionParser::InvalidOption, OptionParser::MissingArgument
  # Print the error and usage info, then exit with nonzero status
  puts $!.to_s
  puts
  puts optparse
  abort
end

# Load the markov model
puts 'Loading Markov Chain'
chain = MarkovChain.new options[:model]
puts 'Markov chain loaded'

# Load some bot objects
bot_threads = Array.new(options[:instances])
bot_threads.each_index do |i|
  # Check for an existing game ID
  if File.exists?("#{i}.game_uuid")
    puts 'Found previous game info, loading saved details'
    game_id = File.read("#{i}.game_uuid")
  end

  if options[:game] == :quiplash
    puts "Starting game of Quiplash"
    bot = Quiplash.new(options[:room_code], "Quipbot#{i}", game_id)
  elsif options[:game] == :quiplash2
    puts "Starting game of Quiplash 2"
    bot = Quiplash2.new(options[:room_code], "Quipbot#{i}", game_id)
  elsif options[:game] == :teeko
    puts "Starting game of Tee K.O."
    bot = TeeKO.new(options[:room_code], "Quipbot#{i}", game_id, options[:pic_dir])
  else
    puts 'Error: requested game has no implementation yet.'
    abort
  end

  game_id = bot.login
  uuid_file = File.new("#{i}.game_uuid", 'w')
  uuid_file.write(game_id)
  uuid_file.close

  if options[:game] == :teeko
    bot_threads[i] = bot.start_playing do |prompt|
      chain.gen_random_text(word_limit: 5)
    end
  else
    bot_threads[i] = bot.start_playing do |prompt|
      begin
        response = chain.gen_seeded_text(prompt, word_limit: 7, include_seed: false)
      rescue ModelMatchError
        response = chain.gen_random_text(word_limit: 7)
      end
      response
    end
  end
end

bot_threads.each do |thread|
  thread.join
end
