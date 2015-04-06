#!/bin/sh
#
# Docker / Boot2docker
#
# This installs Docker and Boot2Docker

# Check for VirtualBox
if test ! $(which VirtualBox)
then
  echo "  Installing VirtualBox for you."
  brew cask install virtualbox
fi

# Check for Boot2Docker
if test ! $(which boot2docker)
then
  echo "  Installing boot2docker for you."
  brew install boot2docker
fi

boot2docker init
boot2docker up
