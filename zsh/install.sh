#!/bin/sh

# Ensure homebrew
if [ ! $(which brew) ]; then
  source $(dirname -- "$0")/../homebrew/install.sh
fi

# Move to Homebrew's version of ZSH
if [ ! $(which zsh | grep '/usr/local') ]; then
  echo "  Installing homebrew's ZSH for you."
  brew install zsh zsh-completions zsh-syntax-highlighting zsh-lovers

  echo "  Ensuring compaudit is clear... you may be asked for your system password"
  for f in $(compaudit); do sudo chmod -R 755 $f; done
fi

if [ ! $(which exa) ]; then
  echo "  Installing exa for you."
  brew install exa > /tmp/exa-install.log
fi

if [ ! -f ~/.iterm2_shell_integration.zsh ]; then
  echo "  Installing iTerm shell integrations"
  curl -L https://iterm2.com/shell_integration/zsh -o ~/.iterm2_shell_integration.zsh
fi
