#!/bin/sh

# Ensure homebrew
if [ ! $(which brew) ]; then
  source $(dirname -- "$0")/../homebrew/install.sh
fi

if [ ! $(which pianobar) ]; then
  echo "  Installing rbenv for you."
  brew install pianobar > /tmp/pianobar-install.log
fi

if [ ! $(which growlnotify) ]; then
  echo "  Installing growlnotify for you, this may require your password."
  brew cask install growlnotify > /tmp/growlnotify-install.log
fi
