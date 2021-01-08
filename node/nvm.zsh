# Huzzah! https://github.com/creationix/nvm/issues/1277#issuecomment-394057955

autoload -U add-zsh-hook
load-nvmrc() {
  local nvmrc_path=$(pwd -P 2>/dev/null || command pwd)
  while [ ! -e "$nvmrc_path/.nvmrc" ] && [ ! -e "$nvmrc_path/.node-version" ]; do
    nvmrc_path=${nvmrc_path%/*}
    if [ "$nvmrc_path" = "" ]; then break; fi
  done

  if [ -n "$nvmrc_path" ]; then
    echo "Found nvm version"
    nvm use &> /dev/null
  elif [[ $(nvm version) != $(nvm version default)  ]]; then
    echo "Reverting to nvm default version"
    nvm use default &> /dev/null
  fi
}
add-zsh-hook chpwd load-nvmrc
# load-nvmrc

# Recommended install method for NVM, not using Homebrew
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
