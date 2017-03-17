#!/bin/sh

# Ensure homebrew
if [ ! $(which brew) ]; then
  source $(dirname -- "$0")/../homebrew/install.sh
fi

if [ ! $(which tmux) ]; then
  echo "  Installing tmux for you."
  brew install tmux > /tmp/tmux-install.log
fi

if [ ! $(which reattach-to-user-namespace) ]; then
  echo "  Installing reattach-to-user-namespace for you."
  brew install reattach-to-user-namespace > /tmp/reattach-to-user-namespace-install.log
fi

