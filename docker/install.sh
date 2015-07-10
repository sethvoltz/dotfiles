#!/bin/sh
#
# Docker / Boot2docker
#
# This installs Docker and Boot2Docker

# Ensure homebrew
if [ ! $(which brew) ]; then
  source $(dirname -- "$0")/../homebrew/install.sh
fi

# Check for VirtualBox
if test ! $(which VirtualBox)
then
  echo "  Installing VirtualBox for you."
  brew cask install virtualbox > /tmp/virtualbox-install.log
fi

# Check for Boot2Docker
if test ! $(which boot2docker)
then
  echo "  Installing boot2docker for you."
  brew install boot2docker > /tmp/boot2docker-install.log
fi

boot2docker init
boot2docker up
