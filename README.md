# QuipBot

A bot that plays Quiplash with Markov chains.

## Requirements

- Ruby
    - version is in `.ruby-version`
- Firefox > 48
- The beta version 6 of Watir (Bundler should take care for this for you)
- `geckodriver` (available in the AUR)
- Linux
    - This uses `Xvfb` via the `headless` Gem, though you may be able to get it
      working on Windows just by removing that part of the code and dealing with
      all the windows that pop up

## Running

1. Install the prereqs above
2. `bundle install`
3. `bundle exec ./quipbot.rb`

## Current Status

The bot can:
- Join a game
- Read and respond to prompts using a markov chain
- Vote for random choices
- Resume a game if the program crashes
- Play as multiple players (separation of sessions)

Future plans:
- "Intelligent" voting - the bot somehow uses the Markov model to determine what
  answer it like best
- Better error handling and cleanup. Leaves a lot of stuff lying around `/tmp/`
  and some leftover processes on crash
- Config files instead of embedding all that stuff in the main file

## License

MIT
