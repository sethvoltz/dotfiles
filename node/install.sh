if [ $(which nvm > /dev/null 2>&1) ]; then
  # Use official install instead of Homebrew, which is no longer supported
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash
fi
