#!/bin/bash

# <xbar.title>tmux</xbar.title>
# <xbar.version>v1.0</xbar.version>
# <xbar.author>sethvoltz</xbar.author>
# <xbar.author.github>sethvoltz</xbar.author.github>
# <xbar.desc>Manage tmux from the menu bar</xbar.desc>
# <xbar.dependencies>bash</xbar.dependencies>

# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
# <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>

# Ensure Homebrew binaries are on PATH (for tmux)
[[ -d /opt/homebrew/bin ]] && export PATH="/opt/homebrew/bin:$PATH"

# --- Handle actions (called by SwiftBar with params) ---
if [ "$1" = 'opensession' ]; then
  session_name="$2"
  osascript -e 'tell application "iTerm2"' -e 'activate' \
    -e 'tell current session of current tab of current window' \
    -e "write text \"tmux attach -t ${session_name}\"" \
    -e 'end tell' -e 'end tell'
  exit 0

elif [ "$1" = 'newsession' ]; then
  osascript -e 'tell application "iTerm2"' -e 'activate' \
    -e 'tell current session of current tab of current window' \
    -e 'write text "tmux"' \
    -e 'end tell' -e 'end tell'
  exit 0
fi

# --- Menu rendering (normal refresh cycle) ---
sessions=$(tmux list-sessions -F '#{session_name}:#{session_attached}' 2>/dev/null) || sessions=""
number=0
if [ -n "$sessions" ]; then
  number=$(echo "$sessions" | wc -l | xargs)
fi

if [ "$number" != '0' ]; then
  echo "$number | sfimage=terminal"
  echo "---"
  echo "$number Running tmux sessions | color=white"
  echo "---"
  while IFS=: read -r name attached; do
    label="$name"
    [ "$attached" = "1" ] && label="$name (attached)"
    echo "$label | sfimage=text.and.command.macwindow bash='$0' param1=opensession param2=$name terminal=false"
  done <<< "$sessions"
  echo "---"
  echo "Start new tmux session | bash='$0' param1=newsession terminal=false"
  exit 0
fi

echo "0 | sfimage=terminal"
echo "---"
echo "Start a tmux session | bash='$0' param1=newsession terminal=false"
