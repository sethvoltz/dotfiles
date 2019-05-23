alias reload!='. ~/.zshrc'

alias ls="exa -a"
alias ll="exa -algh"
alias ducks='du -cksh * | sort -rn | head -11' # Lists the size of all the folders and files
alias top='top -o cpu'
alias cd..="cd .."
alias ..="cd .."
alias ...='cd ../..'
alias ....='cd ../../..'
alias cwd='pwd | pbcopy'    # Copy the current directory to the pastebin
alias gowd='cd "`pbpaste`"' # Change into the directory in the pastebin

# profileme: history 1 # Magic to show all history items.
alias profileme="history 1 | awk '{print \$2}' | awk 'BEGIN{FS=\"|\"}{print \$1}' | sort | uniq -c | sort -n | tail -n 20 | sort -nr"
alias path='echo -e ${PATH//:/\\n}' # Each part on its own line
alias grep='grep --color'
# alias unpushed='unpushed=`git unpushed` && echo -n $unpushed | wc -l | tr -d " "'
alias netprocs="lsof -P -i -n +c0 | iconv -c -f utf-8 -t ascii | awk '{printf \"%-5s %s\\n\", \$2, \$1}' | uniq"
alias recent="find . -type f -print0 -o \( -type d -path './.*' -prune -o -path './tmp' -prune -o -path './log' -prune \) | xargs -0 ls -lrt | tail -n 20"
alias fuck='sudo $(fc -ln -1)'

alias help=run-help

# Flush Directory Service cache
alias flush="dscacheutil -flushcache"

# View HTTP traffic
alias sniff="sudo ngrep -d 'en1' -t '^(GET|POST) ' 'tcp and port 80'"
alias httpdump="sudo tcpdump -i en1 -n -s 0 -w - | grep -a -o -E \"Host\: .*|GET \/.*\""

# Clear Apple System Logs for faster shell startup
alias clearasl="sudo rm -rfv /private/var/log/asl/*.asl"

# One of @janmoesen’s ProTip™s
for method in GET HEAD POST PUT DELETE TRACE OPTIONS; do
	alias "$method"="lwp-request -m '$method'"
done
