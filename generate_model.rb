#!/bin/env ruby
#
# Generates model.mp.gz
#

require 'tempfile'
require_relative 'lib/markov.rb'

BLOCK_SIZE = 4096

unless ARGV.size == 1
  puts "Usage ./generate_mode.rb source_file.txt"
  exit(1)
end

# Very simple preprocessing
tmp_out = Tempfile.new('cleaned_data')
open(ARGV[0]) do |f|
  while chunk = f.read(BLOCK_SIZE)
    chunk.gsub!(/(\r\n)+/, "\n")
    chunk.gsub!(/\n+/, "\n")
    chunk.gsub!("'", '')
    chunk.gsub!('"', '')
    chunk.gsub!('--', '')
    chunk.gsub!(/\.\s*/, "\n")
    tmp_out.write(chunk)
    $stdout.write(chunk)
  end
end

tmp_out.close

chain = MarkovChain.new
chain.train_text(tmp_out.path)
chain.save_model('model.mp.gz')

tmp_out.unlink
