#!/bin/sh

# Ensure homebrew
if [ ! $(which brew) ]; then
  source $(dirname -- "$0")/../homebrew/install.sh
fi

if [ ! $(which mackup) ]; then
  echo "  Installing Mackup for you."
  brew install mackup > /tmp/mackup-install.log
fi
