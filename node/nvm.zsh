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

# Defer initialization of nvm until nvm, node or a node-dependent command is
# run. Ensure this block is only run once if .bashrc gets sourced multiple times
# by checking whether __init_nvm is a function.
if [ -s "$HOME/.nvm/nvm.sh" ] && [ ! "$(whence -w __init_nvm)" = function ]; then
  # export NVM_DIR="$HOME/.nvm"
  export NVM_DIR=$(realpath "$HOME/.nvm")
  [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

  declare -a __node_commands=('nvm' 'node' 'npm' 'yarn' 'gulp' 'grunt' 'webpack' 'topgun')

  function __init_nvm() {
    for i in "${__node_commands[@]}"; do unalias $i; done
    . "$NVM_DIR"/nvm.sh
    unset __node_commands
    unset -f __init_nvm
    add-zsh-hook chpwd load-nvmrc
    load-nvmrc
  }

  for i in "${__node_commands[@]}"; do alias $i='__init_nvm && '$i; done
fi
