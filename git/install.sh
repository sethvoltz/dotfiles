#!/bin/sh

if test ! $(which cdiff)
then
  source $(dirname -- "$0")/../python/install.sh
  echo "  Installing cdiff for you."
  pip install --upgrade cdiff > /tmp/cdiff-install.log
fi
