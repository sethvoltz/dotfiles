update_tab_chpwd() {
  # Ensure tab-color file exists
  if [ -f ".tab-color" ]; then
    # Ensure contents contain the hex code
    color=`cat .tab-color| egrep '#[0-9a-f]{6}'`
    if [ -n "$color" ]; then
      # Extract just the color code
      color=${(MS)color##\#[0-9a-zA-Z][0-9a-zA-Z][0-9a-zA-Z][0-9a-zA-Z][0-9a-zA-Z][0-9a-zA-Z]}

      # Set the tab color
      echo -ne "\033]6;1;bg;red;brightness;$((0x$color[2,3]))\a"
      echo -ne "\033]6;1;bg;green;brightness;$((0x$color[4,5]))\a"
      echo -ne "\033]6;1;bg;blue;brightness;$((0x$color[6,7]))\a"
    fi
  fi
}

# Register the function so it is called whenever the working
# directory changes.
autoload zsh/add-zsh-hook
add-zsh-hook chpwd update_tab_chpwd
# chpwd_functions=( ${chpwd_functions} update_tab_chpwd )

# Tell the terminal about the initial directory.
update_tab_chpwd
