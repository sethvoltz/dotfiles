#!/bin/sh

if test ! $(which colordiff)
then
  echo "  Installing colordiff for you."
  brew install colordiff > /tmp/colordiff-install.log
fi
