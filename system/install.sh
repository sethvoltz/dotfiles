#!/bin/bash

# Ensure SSH keys from Keychain are used and added to ssh-agent
# See: https://openradar.appspot.com/27348363
# See: https://developer.apple.com/library/archive/technotes/tn2449/_index.html
# TODO: Make this automatically detected and added
# touch ~/.ssh/config 
# Host *
#     AddKeysToAgent yes
#     UseKeychain yes

# Update permissions if needed
iftop_path=$(which iftop)
if [ $iftop_path ] && [ ! $(find -L $iftop_path -user root -perm -4000) ]; then
  echo "  Updating iftop to run set UID root, you may be asked for your password..."
  printf "  " # indent password prompt, if any
  sudo chown root:wheel $iftop_path
  sudo chmod u+s $iftop_path
  echo
fi

# Check if Backblaze manual installer has been run
if [ ! -d /Applications/Backblaze.app ]; then
  echo "  Backblaze installer has not been run, please manually run it here:"
  installer_path=$(find $(brew --prefix)/Caskroom/backblaze -name "Backblaze Installer.app" -print0 | sort | tail -n 1)
  echo "    ${installer_path}"
fi
