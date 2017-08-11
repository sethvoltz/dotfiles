#!/bin/sh

# Ensure homebrew
if [ ! $(which brew) ]; then
  source $(dirname -- "$0")/../homebrew/install.sh
fi

if [ $(brew cask ls --versions keybase > /dev/null 2>&1) ]; then
  echo "  Installing keybase for you, this may require your password."
  brew cask install keybase > /tmp/keybase-install.log
fi
