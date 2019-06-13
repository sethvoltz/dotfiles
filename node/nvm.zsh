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

export NVM_DIR="$HOME/.nvm"
nvm_prefix=$(brew --prefix nvm)
[ -s "${nvm_prefix}/nvm.sh" ] && . "${nvm_prefix}/nvm.sh" 
[ -s "${nvm_prefix}/etc/bash_completion" ] && . "${nvm_prefix}/etc/bash_completion"
