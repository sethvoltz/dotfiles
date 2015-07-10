#!/bin/sh

# Ensure homebrew
if [ ! $(which brew) ]; then
  source $(dirname -- "$0")/../homebrew/install.sh
fi

if [ ! $(which pianobar) ]; then
  echo "  Installing rbenv for you."
  brew install pianobar > /tmp/pianobar-install.log
fi
