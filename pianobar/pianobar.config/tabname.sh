#!/bin/bash

function tabname {
  printf "\e]1;$1\a"
}

fold="$HOME/.config/pianobar"
ctlf="$fold/ctl"
nowplaying="$fold/lyrics.sh"

while read L; do
  k="`echo "$L" | cut -d '=' -f 1`"
  v="`echo "$L" | cut -d '=' -f 2`"
  export "$k=$v"
done < <(grep -e '^\(title\|artist\|album\|stationName\|pRet\|pRetStr\|wRet\|wRetStr\|songDuration\|songPlayed\|rating\|songDuration\|songPlayed\|coverArt\|stationCount\|station[0-9]\+\)=' /dev/stdin)

case "$1" in
  songstart)
    tabname "P: $title by $artist"
    ;;
esac
