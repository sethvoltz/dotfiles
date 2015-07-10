#!/bin/sh

if test ! $(which python | grep '/usr/local')
then
  echo "  Installing homebrew Python for you."
  brew install python > /tmp/python-install.log
fi

if test ! $(which python | grep '/usr/local')
then
  echo "  Installing homebrew Python 3 for you."
  brew install python3 > /tmp/python3-install.log
fi
