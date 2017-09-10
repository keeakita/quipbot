require 'find'

require_relative './jackbox.rb'
require_relative './drawing.rb'

# A class representing a game of Tee K.O
class TeeKO < JackboxGame
  TITLE_ENTRIES = 4

  @@appid = 'c531ca944bf9762cd63a032d87cb96e7'

  def _handle_title_entry(browser)
    begin
      TITLE_ENTRIES.times do |x|
        response = yield

        @browser.text_field(id: 'awshirt-title-input').set(response)
        sleep 1 # The button only appears after typing starts

        @browser.button(id: 'awshirt-submittitle').click()
        sleep 1
      end
    rescue UnknownObjectException
      # Problem: The bot has no idea when to submit 4 (first round) or 2
      # (second round) answers. Sending 4 in the second round isn't a huge
      # deal, but if the humans all finish before the bots, these elements will
      # vanish as the game moves on after 2 submissions from everyone. For some
      # reason checking with .exists? wasn't quite cutting it, so instead the
      # bot silently eats this failure.
      puts "WARNING: Title submission elements vanished. Moving on..."
    end
  end

  def initialize(room, name='quipbot', uuid=nil, js_hooks=[], imagepath)
    # Override the WebSocket constructor, so we can get a reference to it in
    # global scope. This is necessary to run code later that will send messages
    # using it.
    js_hooks = js_hooks.concat([
      'window.__socketList = [];',
      'window.__origWebSocket = WebSocket;',
      "window.WebSocket = function (...args) {\n" +
      "  var socket = new window.__origWebSocket(...args);\n" +
      "  window.__socketList.push(socket);\n" +
      "  return socket;\n" +
      "}",
    ])

    @image_list = Drawing.find_images(imagepath).shuffle

    super(room, name, uuid, js_hooks)
  end

  # Kicks off the game logic event loop.
  def start_playing(&block)
    return Thread.new do
      state = :initial

      while true
        sleep_time = 2

        puts "checking"

        # Check for a shirt prompt
        if @browser.element(id: 'awshirt-submitdrawing').present?
          puts 'Got drawing page'
          state = :drawing
          drawing = Drawing.new
          drawing.load_image(@image_list.shift)
          _send_drawing(drawing)
        end

        # Check for a title input
        if @browser.text_field(id: 'awshirt-title-input').present?
          puts 'Got title entry page'
          puts state

          # Check the previous state. Only act if transitioning into this state.
          if state != :title
            _handle_title_entry(@browser, &block)
          end

          state = :title
        end

        # Check for shirt creation
        if @browser.button(id: 'awshirt-submit-shirt').present?
          puts 'Got shirt selection dialog'
          state = :makeshirt

          design_tabs = @browser.elements(class: 'awshirt-drawing-tab').to_a
          design_tabs.sample.click

          slogan_count_text = @browser.element(id: 'awshirt-slogan-index').text
          slogan_count = slogan_count_text.split('/')[1].to_i

          rand(slogan_count).times do
            puts 'Moving shirt selection right'
            @browser.element(class: 'fa-chevron-right').click
            sleep 1
          end

          sleep 1

          @browser.button(id: 'awshirt-submit-shirt').click
        end

        # Check for a vote
        if @browser.button(class: 'awshirt-vote-button').present?
          elements = @browser.elements(class: 'awshirt-vote-button')
          choice = (rand * elements.length).to_i
          puts "Voting for choice #{choice}"
          elements[choice].click
        end

        sleep sleep_time

        # '#awshirt-submitdrawing .submit-drawing .awshirt-button .awshirt-button-submit submit'
        # '#awshirt-title-input input'
        # '#awshirt-submittitle .awshirt-button .awshirt-button-submit submit'
        # TODO: Check for game end and leave
      end
    end
  end

  def end_game
    @browser.close
  end

  def _send_drawing(drawing)
    message = drawing.to_message(@room, @uuid, @@appid)
    @browser.execute_script("console.log('#{message}');")
    @browser.execute_script("window.__socketList[0].send('#{message}');")
  end
end
