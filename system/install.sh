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
