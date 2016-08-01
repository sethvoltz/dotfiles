#!/bin/sh

# Ensure homebrew
if [ ! $(which brew) ]; then
  source $(dirname -- "$0")/../homebrew/install.sh
fi

if [ ! $(which python | grep '/usr/local') ]; then
  echo "  Installing homebrew Python for you."
  brew install python > /tmp/python-install.log
fi

if [ ! $(which python3 | grep '/usr/local') ]; then
  echo "  Installing homebrew Python 3 for you."
  brew install python3 > /tmp/python3-install.log
fi

# Python applications to install
python_apps=(httpie)
python_exec=(http  )

for (( i = 0; i < ${#python_apps[*]}; i++ )) do
  if [ ! $(which ${python_exec[i]}) ]; then
    app=${python_apps[i]}
    echo "  Installing $app for you."
    brew install $app > /tmp/$app-install.log
  fi
done
