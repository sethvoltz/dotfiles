autoload -U colors && colors
autoload zsh/terminfo
####################################################################################################
# https://github.com/ehrenmurdick/config/blob/master/zsh/prompt.zsh
# https://github.com/holman/dotfiles/blob/master/zsh/prompt.zsh

scm_prompt(){
  # vcprompt -f '(%n:%b%m%u) '

  # https://joshdick.net/2017/06/08/my_git_prompt_for_zsh_revisited.html
  # https://jonasjacek.github.io/colors/
  # Exit if not inside a Git repository
  ! git rev-parse --is-inside-work-tree > /dev/null 2>&1 && return

  # Git branch/tag, or name-rev if on detached head
  local GIT_LOCATION=${$(git symbolic-ref -q HEAD || git name-rev --name-only --no-undefined --always HEAD)#(refs/heads/|tags/)}

  local AHEAD="%{$fg[red]%}⇡NUM%{$reset_color%}"
  local BEHIND="%{$fg[cyan]%}⇣NUM%{$reset_color%}"
  local MERGING="%{$fg[magenta]%}⚡︎%{$reset_color%}"
  local UNTRACKED="%{$fg[red]%}●%{$reset_color%}"
  local MODIFIED="%{$fg[yellow]%}●%{$reset_color%}"
  local STAGED="%{$fg[green]%}●%{$reset_color%}"

  local -a DIVERGENCES
  local -a FLAGS

  local NUM_AHEAD="$(git log --oneline @{u}.. 2> /dev/null | wc -l | tr -d ' ')"
  if [ "$NUM_AHEAD" -gt 0 ]; then
    DIVERGENCES+=( "${AHEAD//NUM/$NUM_AHEAD}" )
  fi

  local NUM_BEHIND="$(git log --oneline ..@{u} 2> /dev/null | wc -l | tr -d ' ')"
  if [ "$NUM_BEHIND" -gt 0 ]; then
    DIVERGENCES+=( "${BEHIND//NUM/$NUM_BEHIND}" )
  fi

  local GIT_DIR="$(git rev-parse --git-dir 2> /dev/null)"
  if [ -n $GIT_DIR ] && test -r $GIT_DIR/MERGE_HEAD; then
    FLAGS+=( "$MERGING" )
  fi

  if [[ -n $(git ls-files --other --exclude-standard 2> /dev/null) ]]; then
    FLAGS+=( "$UNTRACKED" )
  fi

  if ! git diff --quiet 2> /dev/null; then
    FLAGS+=( "$MODIFIED" )
  fi

  if ! git diff --cached --quiet 2> /dev/null; then
    FLAGS+=( "$STAGED" )
  fi

  local -a GIT_INFO
  GIT_INFO+=( "%{\033[38;5;208m%}⎇" )
  [ -n "$GIT_STATUS" ] && GIT_INFO+=( "$GIT_STATUS" )
  [[ ${#DIVERGENCES[@]} -ne 0 ]] && GIT_INFO+=( "${(j::)DIVERGENCES}" )
  [[ ${#FLAGS[@]} -ne 0 ]] && GIT_INFO+=( "${(j::)FLAGS}" )
  GIT_INFO+=( "%{\033[38;5;223m%}$GIT_LOCATION%{$reset_color%}" )

  echo "${(j: :)GIT_INFO} "
}

fishy_collapsed_wd(){
  echo $(pwd | perl -pe "s|^$HOME|~|g; s|/([^/])[^/]*(?=/)|/\$1|g")
}

####################################################################################################
# Adapted from http://aperiodic.net/phil/prompt/

function precmd {
  local TERMWIDTH
  (( TERMWIDTH = ${COLUMNS} - 1 ))

  ###
  # Truncate the path if it's too long.

  PR_FILLBAR=""
  PR_PWDLEN=""

  # promptsize defines the size of the left-portion of the first line of the prompt.
  # Be sure to put in placeholders for all styling characters as well as dynamic attributes.
  # Template: ${#${(%):-____()}} where ____ is replaced with the contents.

  local promptsize=${#${(%):-[%n@%m]......%~}}
  local rightsize=0

  if [[ "$promptsize + $rightsize" -gt $TERMWIDTH ]]; then
    ((PR_PWDLEN=$TERMWIDTH - $promptsize))
  else
    PR_FILLBAR="\${(l.(($TERMWIDTH - ($promptsize + $rightsize))).. .)}"
  fi
}

setprompt () {
  ###
  # Need this so the prompt will work.
  setopt prompt_subst

  for color in RED GREEN YELLOW BLUE MAGENTA CYAN WHITE BLACK; do
    eval PR_$color='%{$fg_no_bold[${(L)color}]%}'
    eval PR_LIGHT_$color='%{$fg_bold[${(L)color}]%}'
    eval PR_BG_$color='%{$bg[${(L)color}]%}'
    (( count = $count + 1 ))
  done

  PR_NO_COLOUR="%{$terminfo[sgr0]%}"

  ###
  # Decide if we need to set titlebar text.

  case $TERM in
    xterm*)
      # PR_TITLEBAR=$'%{\e]0;%(!.[ROOT] .)%n@%m:%~\a%}'
      PR_TITLEBAR=$'%{\e]0;%(!.[ROOT] .) $(fishy_collapsed_wd) %n@%m\a%}'
      ;;
    screen)
      PR_TITLEBAR=$'%{\e_screen \005 (\005t) | %(!.[ROOT] .)%n@%m:%~\e\\%}'
      ;;
    *)
      PR_TITLEBAR=''
      ;;
  esac

  ###
  # Decide whether to set a screen title
  if [[ "$TERM" == "screen" ]]; then
    PR_STITLE=$'%{\ekzsh\e\\%}'
  else
    PR_STITLE=''
  fi

  ###
  # Finally, the prompt.
  # A and B colors define the first line's colors and the gradient transition

  BASE_NUM=$(( $(hostname | od | tr ' ' '\n' | awk '{total = total + $1}END{print total}') % 6 ))
  COLOR_LIST=(
    "214" "%K{208} %K{203} %K{198} %K{199} %K{164} "
    "198" "%K{199} %K{164} %K{129} %K{093} %K{063} "
    "129" "%K{093} %K{063} %K{033} %K{039} %K{044} "
    "033" "%K{039} %K{044} %K{049} %K{048} %K{083} "
    "049" "%K{048} %K{083} %K{118} %K{154} %K{184} "
    "154" "%K{148} %K{184} %K{214} %K{208} %K{203} "
  )
  START_COLOR=$COLOR_LIST[$(( (BASE_NUM * 2) + 1 ))]
  GRADIENT=$COLOR_LIST[$(( (BASE_NUM * 2) + 2 ))]

  PROMPT='$PR_STITLE${(e)PR_TITLEBAR}\
%F{black}%K{$START_COLOR}[%n@%m] \
$GRADIENT\
%$PR_PWDLEN<...<%~%<<${(e)PR_FILLBAR}\
%{$reset_color%}\

%F{$START_COLOR}╙─%(?.$PR_GREEN.$PR_RED🔥 %?) \
$(scm_prompt)\
%(?.%F{022}»%F{034}»%F{046}».%F{052}»%F{124}»%F{196}»)\
%{$reset_color%}%f%k '

  RPROMPT=' $PR_LIGHT_BLUE($PR_YELLOW%D{%a, %b %d} %D{%H:%M}$PR_LIGHT_BLUE)$PR_NO_COLOUR'

  PS2='$PR_GREEN($PR_LIGHT_GREEN%_$PR_GREEN)$PR_NO_COLOUR '
}

setprompt
