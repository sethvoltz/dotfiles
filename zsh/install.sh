#!/bin/sh

# Ensure homebrew
if [ ! $(which brew) ]; then
  source $(dirname -- "$0")/../homebrew/install.sh
fi

# Move to Homebrew's version of ZSH
if [ ! $(which zsh | grep '/usr/local') ]; then
  echo "  Installing homebrew's ZSH for you."
  brew install zsh zsh-completions zsh-syntax-highlighting zsh-lovers
fi

if [ ! $(which exa) ]; then
  echo "  Installing exa for you."
  brew install exa > /tmp/exa-install.log
fi

if [ ! -f ~/.iterm2_shell_integration.zsh ]; then
  echo "  Installing iTerm shell integrations"
  curl -L https://iterm2.com/shell_integration/zsh -o ~/.iterm2_shell_integration.zsh
fi

# stderred library
# NOTE: See ./stderr.zsh for info
# if [[ ! -f ~/Development/DotfilesBuild/stderred/build/libstderred.dylib ]]; then
#   echo "  Installing stderred for you."
#   mkdir -p ~/Development/DotfilesBuild > /tmp/stderred-install.log
#   cd ~/Development/DotfilesBuild
#   if [ -d stderred ]; then
#     cd stderred
#     git pull >> /tmp/stderred-install.log
#   else
#     git clone https://github.com/sickill/stderred.git >> /tmp/stderred-install.log
#     cd stderred
#   fi
#   make clean >> /tmp/stderred-install.log 2>&1
#   make >> /tmp/stderred-install.log 2>&1
# fi
