#!/bin/sh
#
# Homebrew
#
# This installs some of the common dependencies needed (or at least desired)
# using Homebrew.

# Check for Homebrew
if test ! $(which brew)
then
  echo "  Installing Homebrew for you."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Install homebrew packages
brew install grc coreutils spark zsh-completions zsh-syntax-highlighting zsh-lovers

# For shell prompt
brew install --HEAD vcprompt

# Development Tools
brew install git mercurial bazaar tree ctags wtf ack graphviz

# Network Tools
brew install htop-osx iftop mtr nmap p0f trafshow ngrep wget
# brew install wireshark --with-x

iftop_version=$(brew list --versions iftop | head -n 1 | cut -f 2 -d ' ')
sudo chown root:wheel /usr/local/Cellar/iftop/$iftop_version/sbin/iftop
sudo chmod u+s /usr/local/Cellar/iftop/$iftop_version/sbin/iftop

exit 0
