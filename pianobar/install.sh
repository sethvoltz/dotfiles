#!/bin/sh

# Ensure homebrew
if [ ! $(which brew) ]; then
  source $(dirname -- "$0")/../homebrew/install.sh
fi

if [ ! $(which pianobar) ]; then
  echo "  Installing pianobar for you."
  brew install pianobar > /tmp/pianobar-install.log
fi

# if [ ! $(which growlnotify) ]; then
#   echo "  Installing growlnotify for you, this may require your password."
#   brew cask install growlnotify > /tmp/growlnotify-install.log
# fi

if [ ! $(which lpass) ]; then
  echo "  Installing lpass for you, this may require your password."
  brew cask install lpass > /tmp/lpass-install.log
fi
