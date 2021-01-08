#!/bin/sh

# Ensure homebrew
if [ ! $(which brew) ]; then
  source $(dirname -- "$0")/../homebrew/install.sh
fi

if [ $(brew list --cask --versions docker > /dev/null 2>&1) ]; then
  echo "  Installing Docker Mac for you."
  brew install --cask docker > /tmp/docker-install.log
fi
