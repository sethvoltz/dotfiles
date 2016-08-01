#!/bin/sh

if [ ! $(which git) ]; then
  echo "  Installing git for you."
  brew install git > /tmp/git-install.log
fi

if [ ! $(which cdiff | grep '/usr/local') ]; then
  source $(dirname -- "$0")/../python/install.sh
  echo "  Installing cdiff for you."
  pip install --upgrade cdiff > /tmp/cdiff-install.log
fi
