#!/bin/sh

# Ensure homebrew
if [ ! $(which brew) ]; then
  source $(dirname -- "$0")/../homebrew/install.sh
fi

if [ $(brew cask ls --versions docker > /dev/null 2>&1) ]; then
  echo "  Installing Docker Mac for you."
  brew cask install docker > /tmp/docker-install.log
fi
