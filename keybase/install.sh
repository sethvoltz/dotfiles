#!/bin/sh

# Ensure homebrew
if [ ! $(which brew) ]; then
  source $(dirname -- "$0")/../homebrew/install.sh
fi

if [ ! $(which keybase) ]; then
  echo "  Installing keybase for you."
  brew install keybase > /tmp/keybase-install.log
fi
