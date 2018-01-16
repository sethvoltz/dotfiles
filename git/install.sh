#!/bin/sh

# Ensure homebrew
if [ ! $(which brew) ]; then
  source $(dirname -- "$0")/../homebrew/install.sh
fi

if [ ! $(which git) ]; then
  echo "  Installing git for you."
  brew install git > /tmp/git-install.log
fi

if [ ! $(which diff-so-fancy) ]; then
  echo "  Installing diff-so-fancy for you."
  brew install diff-so-fancy > /tmp/diff-so-fancy-install.log
fi
