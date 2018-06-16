#!/bin/sh

# Ensure homebrew
if [ ! $(which brew) ]; then
  source $(dirname -- "$0")/../homebrew/install.sh
fi

# Ensure all taps required
if [ ! $(brew tap | grep 'homebrew/dupes') ]; then
  brew tap homebrew/dupes
fi

# CLI applications to install
cli_apps=(coreutils spark ack htop iftop mtr nmap p0f trafshow ngrep wget tree ctags graphviz jq grv rg)
cli_exec=(gsort     spark ack htop iftop mtr nmap p0f trafshow ngrep wget tree ctags dot      jq grv rg)

for (( i = 0; i < ${#cli_apps[*]}; i++ )) do
  if [ ! $(which ${cli_exec[i]}) ]; then
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
#cask_apps=(java bartender alfred istat-menus flux skitch adobe-creative-cloud atom bettertouchtool)
cask_apps=(bartender alfred istat-menus flux skitch visual-studio-code bettertouchtool ubersicht)

for app in $cask_apps; do
  if [ $(brew cask ls --versions $app > /dev/null 2>&1) ]; then
    echo "  Installing $app for you."
    brew cask install $app > /tmp/$app-cask-install.log
  fi
done
