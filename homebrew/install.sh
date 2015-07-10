#!/bin/sh
#
# Homebrew
#
# This installs some of the common dependencies needed (or at least desired)
# using Homebrew.

# Check for Homebrew
if [ ! $(which brew) ]; then
  echo "  Installing Homebrew for you."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Check for Homebrew Cask
if [ ! $(which brew-cask) ]; then
  echo "  Installing Homebrew Cask for you."
  brew install caskroom/cask/brew-cask > /tmp/brew-cask-install.log
fi

# Ensure the latest version of all packages is available
echo "  Updating Homebrew definitions..."
brew update > /tmp/brew-update-install.log
