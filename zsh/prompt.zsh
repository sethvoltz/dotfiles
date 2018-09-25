autoload -U colors && colors
autoload zsh/terminfo
####################################################################################################
# https://github.com/ehrenmurdick/config/blob/master/zsh/prompt.zsh
# https://github.com/holman/dotfiles/blob/master/zsh/prompt.zsh

scm_prompt(){
  vcprompt -f '(%n:%b%m%u) '
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
