require_relative './jackbox.rb'
require_relative './drawing.rb'

# A class representing a game of Tee K.O
class TeeKO < JackboxGame
  def initialize(room, name='quipbot', uuid=nil, js_hooks=[])
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

    super(room, name, uuid, js_hooks)
  end

  # Kicks off the game logic event loop.
  def start_playing
    return Thread.new do
      while true
        sleep_time = 2

        puts "checking"

        # Check for a shirt prompt
        if @browser.element(id: 'awshirt-submitdrawing').present?
          puts 'Got drawing page'
          drawing = Drawing.new
          drawing.load_image('/home/william/Desktop/test.png')
          _send_drawing(drawing)
        end

        # Check for a title input
        if @browser.text_field(id: 'awshirt-title-input').present?
          puts 'Got title entry page'
          @browser.text_field(id: 'awshirt-title-input').set('foo bar demo')

          sleep 1 # The button only appears after typing starts

          @browser.button(id: 'awshirt-submittitle').click()

          # Slow down! Give the humans a chance to respond.
          # 80 / (17 + 1) = 4 submissions + some leeway for processing
          sleep_time = 17
        end

        # Check for a vote
        #if @browser.element(class: 'quiplash-vote-button').present?
        #  elements = @browser.elements(class: 'quiplash-vote-button')
        #  choice = (rand * elements.length).to_i
        #  puts "Voting for choice #{choice}"
        #  elements[choice].click
        #end

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
    message = drawing.to_message(@room, @uuid)
    @browser.execute_script("console.log('#{message}');")
    @browser.execute_script("window.__socketList[0].send('#{message}');")
  end
end
