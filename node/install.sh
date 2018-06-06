# Ensure homebrew
if [ ! $(which brew) ]; then
  source $(dirname -- "$0")/../homebrew/install.sh
fi

if [ ! $(which nvm) ]; then
  brew install nvm > /tmp/nvm-install.log
fi

if [ ! $(which yarn) ]; then
  brew install yarn --without-node > /tmp/yarn-install.log
fi
