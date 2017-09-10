require 'json'
require 'rmagick'

require_relative './jackbox.rb'
require_relative './drawing.rb'
require_relative './e926.rb'
require_relative './bing.rb'

# A class representing a game of Drawful 2
class Drawful2 < JackboxGame
  @@appid = '8511cbe0-dfff-4ea9-94e0-424daad072c3'

  def initialize(room, name='quipbot', uuid=nil, imagepath=nil, e9_icon=false)
    # Override the WebSocket constructor, so we can get a reference to it in
    # global scope. This is necessary to run code later that will send messages
    # using it.
    js_hooks = [
      'window.__socketList = [];',
      'window.__origWebSocket = WebSocket;',
      "window.WebSocket = function (...args) {\n" +
      "  var socket = new window.__origWebSocket(...args);\n" +
      "  window.__socketList.push(socket);\n" +
      "  return socket;\n" +
      "}",
    ]

    @image_list = Drawing.find_images(imagepath).shuffle
    @e9_icon = e9_icon

    super(room, name, uuid, js_hooks)
  end

  # Kicks off the game logic event loop.
  def start_playing(&block)
    return Thread.new do
      drawn_profile = false

      while true
        sleep_time = 2

        puts 'checking'

        state = @browser.element(css: '#game>div:not(.pt-page-off)')
        state_str = state.attribute_value('class').split(' ').first do |attr_class|
          attr_class.start_with? 'state-'
        end
        puts state_str

        case state_str
        when 'state-draw'
          if @browser.element(id: 'drawful-submitdrawing').present?
            puts 'Got drawing page'
            if drawn_profile
              _send_drawing
            else
              _send_profile_pic
              drawn_profile = true
            end
          else
            puts 'No submit button found in draw state - ????'
          end
        when 'state-enterlie'
          if @browser.text_field(id: 'drawful-lie-input').present?
            _make_lie(&block)
          else
            puts 'cannot make a lie - own drawing, hopefully'
          end
        when 'state-chooselie'
          if @browser.table(id: 'drawful-chooselie').present?
            _choose_lie
          else
            puts 'no lies to vote on - should never happen'
          end
        when 'state-chooselikes'
          if @browser.table(id: 'drawful-chooselikes').present?
            _choose_like
          else
            puts 'no lies to like - should never happen'
          end
        when 'state-lobby'
          # disconnected modal dialog - check for this and if it exists, exit
          if @browser.div(css: '.swa12-modal').present?
            puts "disconnected dialog found?"
            @browser.close
            #Thread.exit
          end
        when 'state-nothing'
          puts 'nothing state; sleeping'
        else
          puts "Other state: #{state_str}"
        end

        sleep sleep_time
      end
    end
  end

  def end_game
    @browser.close
  end

  def _make_lie
    response = yield
    @browser.text_field(id: 'drawful-lie-input').set(response)
    @browser.button(id: 'drawful-submitlie').click
  end

  def _choose_lie
    lies = @browser.elements(css: '#drawful-chooselie tr td').to_a
    chosen = lies.sample
    chosen.click
  end

  def _choose_like
    # pass
    # we only vote at random to speed things along - likes are just filler, so
    # do nothing
  end

  def _send_drawing
    prompt = @browser.element(id: 'drawful-instructions').text

    resp_json = Bing.image_search(prompt, 5)
    result = resp_json['value'].sample

    drawing = Drawing.new
    drawing.load_image(result['thumbnailUrl'])
    message = drawing.to_message(@room, @uuid, @@appid, 'drawingLines', false)
    @browser.execute_script("console.log('#{message}');")
    @browser.execute_script("window.__socketList[0].send('#{message}');")
  end

  def _send_profile_pic
    puts 'Got profile pic page'
    url = nil

    # fallback profile pic in case we encounter api issues
    unless @image_list.nil?
      url = @image_list.shift
    end

    if @e9_icon
      begin
        e9_url = E926.fetch_recent_image()
        url = e9_url unless e9_url.nil?
      rescue StandardError => _
        puts 'Failed to get an e926 image, falling back to local image'
      end
    end

    pic = Drawing.new
    unless url.nil?
      pic.load_image(url)
    end

    message = pic.to_message(@room, @uuid, @@appid, 'pictureLines', false, true)
    @browser.execute_script("console.log('#{message}');")
    @browser.execute_script("window.__socketList[0].send('#{message}');")
  end
end

