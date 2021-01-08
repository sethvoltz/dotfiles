#!/bin/bash

# Ensure SSH keys from Keychain are used and added to ssh-agent
# See: https://openradar.appspot.com/27348363
# See: https://developer.apple.com/library/archive/technotes/tn2449/_index.html
# TODO: Make this automatically detected and added
# touch ~/.ssh/config 
# Host *
#     AddKeysToAgent yes
#     UseKeychain yes

# Ensure homebrew
if [ ! $(which brew) ]; then
  source $(dirname -- "$0")/../homebrew/install.sh
fi

# CLI applications to install
cli_apps=(coreutils gnu-sed ack htop iftop mtr nmap p0f trafshow ngrep wget tree ctags graphviz jq grv rg z)
cli_exec=(gsort     gsed    ack htop iftop mtr nmap p0f trafshow ngrep wget tree ctags dot      jq grv rg z)

for (( i = 0; i < ${#cli_apps[*]}; i++ )) do
  if [ $(which ${cli_exec[i]} > /dev/null 2>&1) ]; then
    app=${cli_apps[i]}
    echo "  Installing $app for you."
    brew install $app > /tmp/$app-install.log
  fi
done

# Update permissions if needed
iftop_path=$(which iftop)
if [ $iftop_path ] && [ ! $(find -L $iftop_path -user root -perm -4000) ]; then
  echo "  Updating iftop to run set UID root, you may be asked for your password..."
  printf "  " # indent password prompt, if any
  sudo chown root:wheel $iftop_path
  sudo chmod u+s $iftop_path
  echo
fi

# Cask applications to install
brew tap homebrew/cask-fonts
brew tap buo/cask-upgrade
brew tap dteoh/sqa
cask_apps=(
  1password
  adobe-creative-cloud
  alfred
  bartender
  bettertouchtool
  dropbox
  font-hack
  imageoptim
  istat-menus
  iterm2
  karabiner-elements
  qmk-toolbox
  slowquitapps
  ubersicht
  visual-studio-code
)
  # google-chrome
  # highsierramediakeyenabler

for app in ${cask_apps[@]}; do
  brew list --cask --versions $app > /dev/null 2>&1
  if (( $? )); then
    echo "  Installing $app for you."
    brew install --cask $app > /tmp/$app-cask-install.log
  fi
done

# Clean up your room!
echo "  Cleaning up Homebrew..."
brew cleanup
