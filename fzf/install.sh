#!/bin/sh

if [ ! -f ~/.fzf.zsh ]; then
  echo "» Running fzf post-install for you."
  `brew --prefix fzf`/install
fi
