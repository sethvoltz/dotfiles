#!/bin/sh

if test ! $(which python | grep '/usr/local')
then
  echo "  Installing homebrew Python for you."
  brew install python > /tmp/python-install.log
fi
