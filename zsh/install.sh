# Move to Homebrew's version of ZSH
brew install zsh zsh-completions zsh-syntax-highlighting zsh-lovers

if [ ! $(which vcprompt) ]; then
  brew install --HEAD vcprompt > /tmp/vcprompt-install.log
fi

if [ ! $(which exa) ]; then
  echo "  Installing exa for you."
  brew cask install exa > /tmp/exa-install.log
fi
