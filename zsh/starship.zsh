# Collapses long paths in a way similar to the Fish shell
fishy_collapsed_wd() {
  echo $(pwd | perl -pe "s|^$HOME|~|g; s|/([^/])[^/]*(?=/)|/\$1|g")
}

# Called by Starship to set window/tab title
function set_win_title() {
  echo -ne "\033]0;$(fishy_collapsed_wd) $USER@${HOST%*.*}\007"
}
precmd_functions+=(set_win_title)

# See starship.toml.config for prompt definition
eval "$(starship init zsh)"
