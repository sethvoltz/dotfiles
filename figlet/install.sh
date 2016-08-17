#!/bin/sh

# Ensure homebrew
if [ ! $(which brew) ]; then
  source $(dirname -- "$0")/../homebrew/install.sh
fi

if [ ! $(which toilet) ]; then
  echo "  Installing toilet for you."
  brew install toilet > /tmp/toilet-install.log
fi
