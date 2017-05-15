require_relative './jackbox.rb'

# A class representing a game of Quiplash
class Quiplash < JackboxGame
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

        sleep 2

        # TODO: Check for game end and leave
      end
    end
  end

  def end_game
    @browser.close
  end
end
