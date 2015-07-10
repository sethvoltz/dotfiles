#!/bin/sh

if [ ! $(which cdiff | grep '/usr/local') ]; then
  source $(dirname -- "$0")/../python/install.sh
  echo "  Installing cdiff for you."
  pip install --upgrade cdiff > /tmp/cdiff-install.log
fi
