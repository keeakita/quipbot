require 'watir'
#require 'headless'

class GameJoinError < StandardError
end

# Reusable logic for Jackbox games
class JackboxGame

  # Bail if the threaded part of this class dies
  Thread.abort_on_exception = true

  # Set up a headless session
  @@headless = Headless.new
  @@headless.start

  def initialize(room, name='quipbot', uuid=nil, js_hooks=[])
    @room = room
    @username = name
    @uuid = uuid

    # Start the browser
    puts 'Starting browser'
    @browser = Watir::Browser.new :chrome
    @browser.goto('http://jackbox.tv')

    # Restore the saved session, if availible
    unless @uuid.nil?
      @browser.execute_script("window.localStorage.setItem('blobcast-uuid', '#{@uuid}')")
      @browser.execute_script("window.localStorage.setItem('blobcast-roomid', '#{@room}')")
      @browser.execute_script("window.localStorage.setItem('blobcast-username', '#{@username}')")

      # Force the javascript to reload and pick up these new values
      @browser.refresh
    end

    sleep 2

    unless js_hooks.empty?
      js_hooks.each do |hook|
        @browser.execute_script(hook)
      end
    end
  end

  def login
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

  def end_game
    @browser.close
  end
end
