# Set the terminal tab and background colors per-directory.
#
#   .tab-color         sets the tab color
#   .background-color  sets the session background color
#
# Each file should contain a hex color code including the preceeding hash (#).
# The nearest file walking up from the working directory wins; when there is
# none anywhere in the tree the terminal is reset to its profile default.

# Write an escape sequence to the terminal, wrapping it in a DCS passthrough
# when we are inside tmux so the outer terminal still sees it. Requires
# `set -g allow-passthrough on` in tmux.conf; without it tmux drops the
# sequence, which is harmless.
emit_terminal_osc() {
  if [ -n "$TMUX" ]; then
    printf '\033Ptmux;\033%b\033\\' "$1"
  else
    printf '%b' "$1"
  fi
}

# Walk up from the working directory looking for the color file named in $1.
# Echoes the hex color it contains, and returns non-zero when no such file
# exists anywhere in the tree -- a file we can't read a color out of is not
# the same thing as no file at all, so the caller can tell them apart.
find_dir_color() {
  local dir color
  dir=$(pwd -P 2>/dev/null || command pwd)
  while [ ! -e "$dir/$1" ]; do
    dir=${dir%/*}
    if [ "$dir" = "" ]; then return 1; fi
  done

  # Ensure contents contain the hex code, then extract just the color code
  color=`cat $dir/$1 | grep -E '#[0-9a-fA-F]{6}'`
  echo ${(MS)color##\#[0-9a-zA-Z][0-9a-zA-Z][0-9a-zA-Z][0-9a-zA-Z][0-9a-zA-Z][0-9a-zA-Z]}
}

update_term_colors_chpwd() {
  local color

  if color=$(find_dir_color .tab-color); then
    if [ -n "$color" ]; then
      # Set the tab color
      emit_terminal_osc "\033]6;1;bg;red;brightness;$((0x$color[2,3]))\a"
      emit_terminal_osc "\033]6;1;bg;green;brightness;$((0x$color[4,5]))\a"
      emit_terminal_osc "\033]6;1;bg;blue;brightness;$((0x$color[6,7]))\a"
    fi
  else
    # No color file exists, reset the tab to default
    emit_terminal_osc "\033]6;1;bg;*;default\a"
  fi

  # iTerm2 has its own escape for the session background; everything else
  # (Ghostty, kitty, WezTerm, ...) speaks OSC 11 to set and OSC 111 to reset.
  if color=$(find_dir_color .background-color); then
    if [ -n "$color" ]; then
      if [ "$TERM_PROGRAM" = "iTerm.app" ]; then
        emit_terminal_osc "\033]1337;SetColors=bg=${color[2,7]}\a"
      else
        emit_terminal_osc "\033]11;${color}\a"
      fi
    fi
  else
    # Reset the background. Sending SetColors=bg=default alone did not reset
    # iTerm2 3.6.11, so follow it with the standard OSC 111 -- whichever the
    # terminal understands wins, and OSC 111 goes last so the well-defined
    # one has the final say.
    if [ "$TERM_PROGRAM" = "iTerm.app" ]; then
      emit_terminal_osc "\033]1337;SetColors=bg=default\a"
    fi
    emit_terminal_osc "\033]111\a"
  fi
}

# Register the function so it is called whenever the working
# directory changes.
autoload -Uz add-zsh-hook
add-zsh-hook chpwd update_term_colors_chpwd

# Tell the terminal about the initial directory.
update_term_colors_chpwd
