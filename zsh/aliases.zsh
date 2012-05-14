alias reload!='. ~/.zshrc'

alias ls="ls -a"
alias ll="ls -lGh"
alias ducks='du -cksh * | sort -rn | head -11' # Lists the size of all the folders and files
alias top='top -o cpu'
alias cd..="cd .."
alias ..="cd .."
alias ...='cd ../..'
alias ....='cd ../../..'
alias cwd='pwd | pbcopy'    # Copy the current directory to the pastebin
alias gowd='cd "`pbpaste`"' # Change into the directory in the pastebin
alias profileme="history | awk '{print \$2}' | awk 'BEGIN{FS=\"|\"}{print \$1}' | sort | uniq -c | sort -n | tail -n 20 | sort -nr"
alias path='echo -e ${PATH//:/\\n}' # Each part on its own line
alias grep='grep --color'
# alias unpushed='unpushed=`git unpushed` && echo -n $unpushed | wc -l | tr -d " "'
alias netprocs='lsof -P -i -n | cut -f 1 -d " " | uniq'
alias recent="find . -type f -print0 -o \( -type d -path './.*' -prune -o -path './tmp' -prune -o -path './log' -prune \) | xargs -0 ls -lrt | tail -n 20"
