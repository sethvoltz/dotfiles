# Move to Homebrew's version of ZSH
brew install zsh

if test ! $(which exa)
then
  echo "  Installing exa for you."
  brew cask install exa > /tmp/exa-install.log
fi
