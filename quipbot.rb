#!/bin/env ruby

require 'watir'
require 'pry'

username = 'QUIPBOT'
room = 'TYPE'

browser = Watir::Browser.new :firefox
browser.goto('http://jackbox.tv')

# Check for an existing game ID
if File.exists?('.game_uuid')
  game_id = File.read('.game_uuid')
  browser.execute_script("window.localStorage.setItem('blobcast-uuid', '#{game_id}')")
  puts browser.execute_script('return window.localStorage.getItem(\'blobcast-uuid\')')

  # Oh boy, a loaded session. We saved the roomcode and username, right?
  browser.execute_script("window.localStorage.setItem('blobcast-roomid', '#{room}')")
  browser.execute_script("window.localStorage.setItem('blobcast-username', '#{username}')")

  # Force the javascript to reload and pick up these new values
  browser.refresh
end

browser.text_field(id: 'roomcode').set(room)
browser.text_field(id: 'username').set(username)

browser.button(id: 'button-join').click()

# Pause For join
sleep 2

# Check for an error message
title = browser.element(class: 'modal-title')
if browser.element(class: 'modal-title').exists?
  if title.text == 'Error'
    error_msg = browser.element(class: 'modal-body').text
    STDERR.puts "Could not join game: #{error_msg}"
    browser.close
    exit 254
  end
end

# Save the UUID of the current game
game_id = browser.execute_script('return window.localStorage.getItem(\'blobcast-uuid\')')
uuid_file = File.new('.game_uuid', 'w')
uuid_file.write(game_id)
uuid_file.close

# Main event loop
while true

  # Check for a prompt
  if browser.text_field(id: 'quiplash-answer-input').present?
    prompt = browser.element(id: 'question-text').text
    puts "Got prompt: #{prompt}"

    browser.text_field(id: 'quiplash-answer-input').set(Time.now.to_s)
    browser.button(id: 'quiplash-submit-answer').click()
  end

  # Check for a vote
  if browser.element(class: 'quiplash-vote-button').present?
    elements = browser.elements(class: 'quiplash-vote-button')
    choice = (rand * elements.length).to_i
    puts "Voting for choice #{choice}"
    elements[choice].click
  end

  sleep 5
end

binding.pry
browser.close
