if [ $ZSH ]; then
  let head_age=`/usr/bin/stat -f "%m" $ZSH/.git/FETCH_HEAD 2> /dev/null || echo 0`
  let repo_age=`date +"%s"`-$head_age
  let grace_period="86400" # 86400 = 24 hours
  if [ "$repo_age" -gt "$grace_period" ]; then
    echo "ZSH repo is out of date (older than $grace_period seconds)... updating"
    $ZSH/script/update -f
    echo "Some updates not run, run \`\$ZSH/script/update\` for a full update."
  fi
fi
