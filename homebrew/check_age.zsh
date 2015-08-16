if [ $(which brew) ]; then
  brew_repo=$(brew --repository)
  let head_age=`/usr/bin/stat -f "%m" $brew_repo/.git/FETCH_HEAD 2> /dev/null || echo 0`
  let repo_age=`date +"%s"`-$head_age
  let grace_period="86400" # 86400 = 24 hours
  if [ "$repo_age" -gt "$grace_period" ]; then
    echo "Homebrew out of date (older than $grace_period seconds)... updating"
    brew update
  fi
fi
