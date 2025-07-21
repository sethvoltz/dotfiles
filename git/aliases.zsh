# Pull & push
alias gl='git up --prune'
alias glr='git reup --prune'
alias gp='git push origin HEAD'
alias gpu='git push --set-upstream origin $(git rev-parse --abbrev-ref HEAD)'
alias gpfl='gp --force-with-lease'

# Log & diff
alias glog="git log --graph --pretty=format:'%Cred%h%Creset %an: %s - %Creset %C(yellow)%d%Creset %Cgreen(%cr)%Creset' --abbrev-commit --date=relative"
#alias gd='git diff-fancy'
alias gd='git diff' # when using git-delta or diff-so-fancy

# Repo & branch lifecycle
alias gco='git checkout'
# alias gb='git branch'
alias gw='git switch'
alias gwd='gw `default-branch`' # See zsh/functions/default-branch
alias gn='gw -c'
# alias gs='git status -sb' # upgrade your git if -sb breaks for you. it's fun.
alias gs='git st' # See bin/git-st
alias grm="git status | grep deleted | awk '{print \$3}' | xargs git rm"
# alias ga='git add'
alias gaa='ga .'
alias gc='git commit'
alias gca='git commit -a'
