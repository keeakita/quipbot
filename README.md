# QuipBot

A bot that plays Quiplash with Markov chains.

## Requirements

- Ruby
    - version is in `.ruby-version`
- Firefox > 48
- The beta version 6 of Watir (Bundler should take care for this for you)
- `geckodriver` (available in the AUR)

## Running

1. Install the prereqs above
2. `bundle install`
3. `bundle exec ./quipbot.rb`

## Current Status

The bot can join a game, post a response to a prompt (the current time), and
vote for a random option. No support yet for games that die mid session.

## License

MIT
