#!/bin/bash -e

# Copyright (c) 2011
# Artur de S. L. Malabarba
# Modified: Seth Voltz, 2016-Jul-20

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.


###### USAGE: ######
#
# This is an event script. Place it somewhere convenient for you and add the line
# 'event_command = /PATH/TO/pianobar-notify.sh' to your pianobar config file.
#
pianobar_folder="$HOME/.config/pianobar"
blank_icon="$pianobar_folder/pandora.jpg"
notify_art="$pianobar_folder/notify_art"
mkdir -p $notify_art

function do_notify {
  icon_path=$1
  title=$2
  message=$3
  terminal-notifier \
    -title "$title" \
    -message "$message" \
    -contentImage "$icon_path" \
    -group pianobar -remove \
    > /dev/null
}

# don't overwrite $1...
while read L; do
  k="`echo "$L" | cut -d '=' -f 1`"
  v="`echo "$L" | cut -d '=' -f 2`"
  export "$k=$v"
done < <(grep -e '^\(title\|artist\|album\|stationName\|songStationName\|pRet\|pRetStr\|wRet\|wRetStr\|songDuration\|songPlayed\|rating\|coverArt\|stationCount\|station[0-9]\+\)=' /dev/stdin)

newline=$'\n'

[[ "$rating" == 1 ]] && like="(like)"
icon=`echo "$artist - $album.jpg" | sed 's/\//_/g'`

if [[ -z $songStationName ]]; then
  album_station="Album: ${album}${newline}Station: ${stationName}"
else
  album_station="Album: ${album}${newline}Station: ${stationName} - ${songStationName}"
fi

# Edit this to customize the format songs are displayed in (e.g. "$title - $artist" instead of
# "$artist - $title") Possible variables you can use are $artist, $title, and $album.
song_name="$artist - $title $like"

case "$1" in
  songstart|songplay)
    icon_file="$blank_icon"

	  if [[ ! -e "$icon" ]]; then
		  if [[ -n "$coverArt" ]]; then
        pushd "$notify_art" > /dev/null
  			  wget -q -O "$icon" "$coverArt"
        popd > /dev/null
        icon_file="$notify_art/$icon"
		  fi
    else
      icon_file="$notify_art/$icon"
	  fi

    do_notify "$icon_file" "$song_name" "$album_station"
  ;;

  songexplain)
	  # cp "$ds" "$dse"
	  # tail -1 "$logf" \
    # | grep --text "(i) We're" \
    # | sed 's/.*(i).*features/*/' \
    # | sed 's/,/\n*/g' \
    # | sed 's/and \([^,]*\)\./\n* \1/' \
    # | sed 's/\* many other similarities.*/* and more./' >> "$dse"
    # do_notify "$icon_file" "`cat $np`" "`cat $dse`"
  ;;

  songlove)
    do_notify "$icon_file" "Song Liked" "$song_name"
  ;;

  songban)
    do_notify "$icon_file" "Song Banned" "$song_name"
  ;;

  songshelf)
    do_notify "$icon_file" "Sonf Put Away" "$song_name"
  ;;

  stationfetchplaylist)
	  # echo "1" > "$su"
  ;;

  usergetstations)
	  # if [[ $stationCount -gt 0 ]]; then
		#   rm -f "$stl"
		#   for stnum in $(seq 0 $(($stationCount-1))); do
		# 	  echo "$stnum) "$(eval "echo \$station$stnum") >> "$stl"
		#   done
	  # fi
    # if [[ ! `cat "$st" | grep "auto" | cut -d "=" -f 2 | wc -m` -gt 2 ]]; then
	  #   echo "$($zenity --entry --title="Switch Station" --text="$(cat "$stl")")" > "$ctlf"
    # fi
  ;;

  userlogin)
	  if [ "$pRet" -ne 1 ]; then
      do_notify "$blank_icon" "Login ERROR 1" "$pRetStr"
	  elif [ "$wRet" -ne 1 ]; then
      do_notify "$blank_icon" "Login ERROR 2" "$wRetStr"
	  else
      do_notify "$blank_icon" "Login Successful" "Fetching Stations..."
	  fi
	;;

  songfinish)
	  exit
  ;;

  *)
	  if [ "$pRet" -ne 1 ]; then
	    do_notify "$blank_icon" "Pianobar - ERROR" "$1 failed: $pRetStr"
	  elif [ "$wRet" -ne 1 ]; then
	    do_notify "$blank_icon" "Pianobar - ERROR" "$1 failed: $wRetStr"
	  else
	    do_notify "$blank_icon" "$1" "fill $2"
	  fi
  ;;
esac
