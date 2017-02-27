#!/bin/sh

# Ensure homebrew
if [ ! $(which brew) ]; then
  source $(dirname -- "$0")/../homebrew/install.sh
fi

if [ $(brew cask list docker > /dev/null) ]; then
  echo "  Installing Docker Mac for you."
  brew cask install docker > /tmp/docker-install.log
fi
