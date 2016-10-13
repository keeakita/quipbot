require 'watir'
require 'headless'

class GameJoinError < StandardError
end

# A class representing a game of Quiplash
class Quiplash

  # Bail if the threaded part of this class dies
  Thread.abort_on_exception = true

  # Set up a headless session
  @@headless = Headless.new
  @@headless.start

  def initialize(room, name: 'quipbot', uuid: nil)
    @room = room
    @username = name
    @uuid = uuid

    # Start the browser
    puts 'Starting browser'
    @browser = Watir::Browser.new :firefox
    @browser.goto('http://jackbox.tv')
  end

  def login
    # Restore the saved session, if availible
    unless @uuid.nil?
      @browser.execute_script("window.localStorage.setItem('blobcast-uuid', '#{@uuid}')")
      @browser.execute_script("window.localStorage.setItem('blobcast-roomid', '#{@room}')")
      @browser.execute_script("window.localStorage.setItem('blobcast-username', '#{@username}')")

      # Force the javascript to reload and pick up these new values
      @browser.refresh
    end

    sleep 2

    @browser.text_field(id: 'roomcode').set(@room)
    @browser.text_field(id: 'username').set(@username)

    @browser.button(id: 'button-join').click()

    # Pause For join
    sleep 2

    # Check for an error message
    title = @browser.element(class: 'modal-title')
    if @browser.element(class: 'modal-title').exists?
      if title.text == 'Error'
        error_msg = @browser.element(class: 'modal-body').text
        raise GameJoinError.new("Could not join game: #{error_msg}")
        @browser.close
      end
    end

    puts 'Connected to game'

    # Return the UUID of the current game
    @uuid = @browser.execute_script('return window.localStorage.getItem(\'blobcast-uuid\')')
    return @uuid
  end

  # Kicks off the game logic event loop. Takes a block that is passed the
  # prompt and must return a response to the prompt.
  def start_playing
    return Thread.new do
      while true

        # Check for a prompt
        if @browser.text_field(id: 'quiplash-answer-input').present?
          prompt = @browser.element(id: 'question-text').text
          puts "Got prompt: #{prompt}"

          response = yield(prompt)

          @browser.text_field(id: 'quiplash-answer-input').set(response)
          @browser.button(id: 'quiplash-submit-answer').click()
        end

        # Check for a vote
        if @browser.element(class: 'quiplash-vote-button').present?
          elements = @browser.elements(class: 'quiplash-vote-button')
          choice = (rand * elements.length).to_i
          puts "Voting for choice #{choice}"
          elements[choice].click
        end

        sleep 5

        # TODO: Check for game end and leave
      end
    end
  end

  def end_game
    @browser.close
  end
end
