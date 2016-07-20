#!/bin/sh

# Ensure homebrew
if [ ! $(which brew) ]; then
  source $(dirname -- "$0")/../homebrew/install.sh
fi

if [ ! $(which pianobar) ]; then
  echo "  Installing pianobar for you."
  brew install pianobar > /tmp/pianobar-install.log
fi

if [ ! $(which terminal-notifier) ]; then
  echo "  Installing terminal-notifier for you, this may require your password."
  brew install terminal-notifier > /tmp/terminal-notifier-install.log
fi

# if [ ! $(which lpass) ]; then
#   echo "  Installing lpass for you, this may require your password."
#   brew cask install lpass > /tmp/lpass-install.log
# fi
