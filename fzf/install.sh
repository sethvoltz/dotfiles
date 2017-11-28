#!/bin/sh

# Ensure homebrew
if [ ! $(which brew) ]; then
  source $(dirname -- "$0")/../homebrew/install.sh
fi

if [ ! $(which fzf) ]; then
  echo "  Installing fzf for you."
  brew install fzf > /tmp/fzf-install.log
  # Post-install keybinding setup
  echo "  Running post-install setup."
  /usr/local/opt/fzf/install
fi

if [ ! -f ~/.fzf.zsh ]; then
  echo "  Running fzf post-install for you."
  `brew --prefix fzf`/install
fi
