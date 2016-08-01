#!/bin/sh

# Ensure homebrew
if [ ! $(which brew) ]; then
  source $(dirname -- "$0")/../homebrew/install.sh
fi

if [ ! $(which aws) ]; then
  echo "  Installing AWS CLI for you."
  brew install awscli > /tmp/awscli-install.log
fi
