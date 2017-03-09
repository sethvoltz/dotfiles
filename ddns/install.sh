#!/bin/sh

# Note: Please ensure the following variables are exposed in .localrc
#   DDNS_ROUTE53_ZONE_ID
#   DDNS_ROUTE53_RECORD_SET
#   DDNS_INTERFACE
# Additionally, the AWS CLI will need to be configured with a profile called 'personal'

# Expand Path
pushd $(dirname -- "$0") > /dev/null
  ddns_path=$(pwd)
popd > /dev/null

# Ensure aws cli
if [ ! $(which aws) ]; then
  source ${ddns_path}/../aws/install.sh
fi

# Copy networkchange.plist and ddns-update.sh to the correct places
ln -sf ${ddns_path}/ifup.ddns.plist ~/Library/LaunchAgents

mkdir -p /Users/Shared/bin
ln -sf ${ddns_path}/ddns-update.sh /Users/Shared/bin/ddns-update.sh

# Start it up
launchctl load ~/Library/LaunchAgents/ifup.ddns.plist
launchctl start ifup.ddns
