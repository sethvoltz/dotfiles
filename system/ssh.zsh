# OS X no longer adds keys automatically on boot
# See: https://openradar.appspot.com/27348363

ssh_add=$(ssh-add -A 2>&1)
if [ "$?" != "0" ]; then
  echo $ssh_add
fi
