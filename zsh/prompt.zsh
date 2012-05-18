autoload -U colors && colors
autoload zsh/terminfo
####################################################################################################
# https://github.com/ehrenmurdick/config/blob/master/zsh/prompt.zsh
# https://github.com/holman/dotfiles/blob/master/zsh/prompt.zsh

unpushed () {
	/usr/bin/env git cherry -v @{upstream} 2>/dev/null
}

need_push () {
	if [[ $(unpushed) == "" ]]
	then
		echo ""
	else
		echo "with %{$fg_bold[magenta]%}unpushed%{$reset_color%} "
	fi
}

rb_prompt(){
	if $(which rbenv &> /dev/null)
	then
		echo "%{$fg_no_bold[green]%}‹$(rbenv version | awk '{print $1}')›%{$reset_color%} "
	else
		echo ""
	fi
}

scm_prompt(){
	echo "%{$fg[green]%}$(vcprompt -f '(%n:%b%m%u) ')%{$reset_color%}"
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
	local promptsize=${#${(%):-.%! [%n@%m......]()}}
	local pwdsize=${#${(%):-%~}}
    
	if [[ "$promptsize + $pwdsize" -gt $TERMWIDTH ]]; then
		((PR_PWDLEN=$TERMWIDTH - $promptsize))
	else
		PR_FILLBAR="\${(l.(($TERMWIDTH - ($promptsize + $pwdsize))).. .)}"
	fi
}

setopt extended_glob
preexec () {
	if [[ "$TERM" == "screen" ]]; then
		local CMD=${1[(wr)^(*=*|sudo|-*)]}
		echo -n "\ek$CMD\e\\"
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
			PR_TITLEBAR=$'%{\e]0;%(!.[ROOT] .)%n@%m:%~\a%}'
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

	PROMPT='$PR_STITLE${(e)PR_TITLEBAR}\
%{$fg[black]$bg[yellow]%}\
𐄦%! [%n@%m]\
%{$fg[cyan] ░▒$fg[yellow]$bg[cyan]▒░ %}\
${PR_BLACK}${(e)PR_FILLBAR}\
(%$PR_PWDLEN<...<%~%<<)\
%{$reset_color%}\

%(?.$PR_GREEN●.$PR_LIGHT_RED◖%?◗) \
$(rb_prompt)$(scm_prompt)\
%(?.$PR_LIGHT_BLACK»$PR_GREEN»$PR_LIGHT_GREEN».$PR_LIGHT_BLACK»$PR_RED»$PR_LIGHT_RED»)\
%{$reset_color%} '

	RPROMPT=' $PR_LIGHT_BLUE($PR_YELLOW%D{%a, %b %d} %D{%H:%M}$PR_LIGHT_BLUE)$PR_NO_COLOUR'

	PS2='$PR_GREEN($PR_LIGHT_GREEN%_$PR_GREEN)$PR_NO_COLOUR '
}

setprompt
