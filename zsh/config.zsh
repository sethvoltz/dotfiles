# if [[ -n $SSH_CONNECTION ]]; then
#   export PS1='%m:%3~$(git_info_for_prompt)%# '
# else
#   export PS1='%3~$(git_info_for_prompt)%# '
# fi

# Editors
export EDITOR='vim'
export LESSEDIT='vim ?lm+%lm. %f'
export CVSEDITOR=$EDITOR
export SVN_EDITOR=$EDITOR
export GIT_EDITOR=$EDITOR
export VISUAL=$EDITOR

# Other Settings
export PAGER=less
export CLICOLOR=true
export EXA_COLORS="uu=33:gu=37:sn=32:sb=32:da=36:"
export LC_CTYPE=en_US.UTF-8 # Ensure UTF-8 always, everywhere

fpath=(/usr/local/share/zsh-completions $ZSH/zsh/functions $fpath)

autoload -U $ZSH/zsh/functions/*(:t)

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

setopt NO_BG_NICE # don't nice background tasks
setopt CHECK_JOBS # A little nag that jobs exist before quiting
setopt NO_HUP # Used in combination with CHECK_JOBS
setopt NO_LIST_BEEP
setopt LOCAL_OPTIONS # allow functions to have local options
setopt LOCAL_TRAPS # allow functions to have local traps
setopt HIST_VERIFY
setopt SHARE_HISTORY # share history between sessions ???
setopt EXTENDED_HISTORY # add timestamps to history
setopt PROMPT_SUBST
setopt CORRECT
setopt COMPLETE_IN_WORD
setopt NO_ALWAYS_TO_END # Don't got to end of word on completion from middle
setopt NO_LIST_AMBIGUOUS # Show completion list immediately when ambiguous
setopt LIST_ROWS_FIRST # Order completion by row instead of column

setopt AUTO_PARAM_KEYS      # Neater prompt, deletes spaces after complete
setopt AUTO_PARAM_SLASH     # Params that are directories get a /
setopt NOAUTO_REMOVE_SLASH  # Keep a slash if I put it there

setopt APPEND_HISTORY # adds history
setopt INC_APPEND_HISTORY SHARE_HISTORY  # adds history incrementally and share it across sessions
setopt HIST_IGNORE_ALL_DUPS  # don't record dupes in history
setopt HIST_REDUCE_BLANKS

# don't expand aliases _before_ completion has finished
#   like: git comm-[tab]
# Comment out to allow autocompletion of aliased command parameters
# setopt complete_aliases

if [[ -o interactive ]]; then
  ZLE_REMOVE_SUFFIX_CHARS=$' \n\t;' # Prevent zsh from eating spaces after completion when inserting | &
fi

zle -N newtab

bindkey '^[^[[D' backward-word
bindkey '^[^[[C' forward-word
bindkey '^[[5D' beginning-of-line
bindkey '^[[5C' end-of-line
bindkey '^[[3~' delete-char
bindkey '^[^N' newtab
bindkey '^?' backward-delete-char

# Kudos: https://github.com/cehoffman/dotfiles/blob/cec090cba571074ee77b0cc46f7f821c3ecaa988/zsh/bindings#L105-L110
# Make it easy to remove directory components when deleting words
function slash-backward-kill-word() {
  local WORDCHARS="${${WORDCHARS:s#/#}:s/=/}"
  zle backward-delete-word
}
zle -N slash-backward-kill-word

bindkey '^W' slash-backward-kill-word
