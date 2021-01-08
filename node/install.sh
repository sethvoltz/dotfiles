# Ensure homebrew
if [ ! $(which brew) ]; then
  source $(dirname -- "$0")/../homebrew/install.sh
fi

if [ ! $(which yarn) ]; then
  # Node is no longer bundled with macOS, this will install brew node as well
  brew install yarn > /tmp/yarn-install.log
fi

if [ $(which nvm > /dev/null 2>&1) ]; then
  # Use official install instead of Homebrew, which is no longer supported
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash
fi
