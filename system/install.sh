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
cli_apps=(coreutils spark git mercurial wtf ack grc htop iftop mtr nmap p0f trafshow wtf ngrep wget tree ctags graphviz jq brightness switchaudio-osx)
cli_exec=(gsort     spark git hg        wtf ack grc htop iftop mtr nmap p0f trafshow wtf ngrep wget tree ctags dot      jq brightness SwitchAudioSource)

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

# Cask applications to install
cask_apps=(controlplane)
cask_exec=(controlplane)

for (( i = 0; i < ${#cask_apps[*]}; i++ )) do
  if [ ! $(brew cask list ${cask_exec[i]}) ]; then
    app=${cli_apps[i]}
    echo "  Installing $app for you."
    brew cask install $app > /tmp/$app-cask-install.log
  fi
done

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
