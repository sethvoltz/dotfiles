#!/bin/sh

# Ensure homebrew
if [ ! $(which brew) ]; then
  source $(dirname -- "$0")/../homebrew/install.sh
fi

# Ensure all taps required
if [ ! $(brew tap | grep 'homebrew/dupes') ]; then
  brew tap homebrew/dupes
fi

# CLI applications to install
cli_apps=(coreutils spark git mercurial wtf ack grc htop-osx iftop mtr nmap p0f trafshow wtf ngrep wget tree ctags graphviz jq)
cli_exec=(gsort     spark git hg        wtf ack grc htop     iftop mtr nmap p0f trafshow wtf ngrep wget tree ctags dot      jq)

for (( i = 0; i < ${#cli_apps[*]}; i++ )) do
  if [ ! $(which ${cli_exec[i]}) ]; then
    app=${cli_apps[i]}
    echo "  Installing $app for you."
    brew install $app > /tmp/$app-install.log
  fi
done

iftop_path=$(which iftop)

if [ $iftop_path ]; then
  echo "  Updating iftop to run set UID root, you may be asked for your password..."
  printf "  " # indent password prompt, if any
  sudo chown root:wheel $iftop_path
  sudo chmod u+s $iftop_path
  echo
fi

# Python applications to install
python_apps=(httpie)
python_exec=(http  )

# Ensure Python(s) are installed
source $(dirname -- "$0")/../python/install.sh

for (( i = 0; i < ${#python_apps[*]}; i++ )) do
  if [ ! $(which ${python_exec[i]}) ]; then
    app=${python_apps[i]}
    echo "  Installing $app for you."
    brew install $app > /tmp/$app-install.log
  fi
done
