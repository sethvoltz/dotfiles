#!/bin/sh

# Note: Please ensure the following variables are exposed in .localrc
#   DDNS_ROUTE53_ZONE_ID
#   DDNS_ROUTE53_RECORD_SET
#   DDNS_INTERFACE (optional)
# Additionally, the AWS CLI will need to be configured with a profile called 'personal'

# Expand Path
pushd $(dirname -- "$0") > /dev/null
  ddns_path=$(pwd)
popd > /dev/null

# Ensure aws cli
if [ ! $(which aws) ]; then
  source ${ddns_path}/../aws/install.sh
fi

# Generate LaunchAgent for this user
log_path=${HOME}/Library/Logs/ifup.ddns
destination_file="${HOME}/Library/LaunchAgents/ifup.ddns.plist"
mkdir -p ${log_path}

if [ ! -f $destination_file ]; then
  sed -e "s,{{DDNS_PATH}},${ddns_path},g" \
      -e "s,{{USER_LOG_PATH}},${log_path},g" \
      "${ddns_path}/ifup.ddns.plist" \
      > $destination_file

  # Start it up
  launchctl load ${HOME}/Library/LaunchAgents/ifup.ddns.plist
  launchctl start ifup.ddns
fi
