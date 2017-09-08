# QuipBot

A bot that plays Quiplash, Quiplash2 and Tee K.O. with Markov chains.

## Requirements

- Ruby
    - version is in `.ruby-version`
- Google Chrome (See "Browser Notes")
- `chromedriver` (available in the AUR)
- Linux
    - This uses `Xvfb` via the `headless` Gem, though you may be able to get it
      working on Windows just by removing that part of the code and dealing with
      all the windows that pop up

## Generating the model

Ideally, you want a source file where:
- Each line is a full single sentence with no blanks
- Lines are separated by a newline (\n)
- There are no strange characters (things far outside ASCII, it's up to you to
  figure out what you want)

I've included a script `./generate_mode.rb` that attempts to do some quick,
naive processing, but if you have the technical know-how, you're probably best
off coming up with the sed/awk commands yourself that best transform your
particular data source.

Sample usage:
```
./generate_model.rb don_quixote.txt`
```

This will produce the file `model.mp.gz` in the current directory.

## Running

1. Install the prereqs above
2. `bundle install`
3. `bundle exec ./quipbot.rb -h` to see usage information

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

## License

MIT

## Browser Notes

Technically, this should work with any browser that supports Watir Webdriver and
can run Jackbox. In practice, I had a lot of problems getting it working on the
latest Firefox with `geckodriver` on Arch after a recent update, so by default
it now uses Chrome with `chromedriver`. There's some standardization work
underway for a browser-agnostic control protocol, so hopefully that will improve
the situation in the future.

## Legal Disclaimer

The legal team at my current employer is making me put this in here, in case it
somehow wasn't obvious that no company is responsible for such a stupid and
poorly written project:

*I am providing the code in this repository to you under an open source license.
Because this is my personal repository, the license you receive to my code is
from me and not from my employer (Facebook).*
