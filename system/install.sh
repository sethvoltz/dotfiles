#!/bin/sh

# Ensure all taps required
if [ ! $(brew tap | grep 'homebrew/dupes') ]; then
  brew tap homebrew/dupes
fi

# CLI applications to install
cli_apps=(pianobar git mercurial ack grc htop-osx iftop mtr nmap p0f trafshow wtf ngrep wget tree ctags graphviz)
cli_exec=(pianobar git hg        ack grc htop     iftop mtr nmap p0f trafshow wtf ngrep wget tree ctags dot)

for (( i = 0; i < ${#cli_apps[*]}; i++ )) do
  if [ ! $(which ${cli_exec[i]}) ]; then
    app=${cli_apps[i]}
    echo "  Installing $app for you."
    brew install $app > /tmp/$app-install.log
  fi
done

if [ $(which iftop) ]; then
  echo "  Setting up iftop permissions, this may require your password..."
  sudo chown root:wheel $(which iftop)
  sudo chmod u+s $(which iftop)
  echo "  Done"
fi

# Python applications to install
python_apps=(httpie)
python_exec=(http  )

# Ensure Python(s) are installed
source $(dirname -- "$0")/../python/install.sh

for (( i = 0; i < ${#python_apps[*]}; i++ )) do
  if [ ! $(which ${python_exec[i]}) ]; then
    app=${cli_apps[i]}
    echo "  Installing $app for you."
    brew install $app > /tmp/$app-install.log
  fi
done
