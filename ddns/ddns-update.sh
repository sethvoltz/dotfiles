#!/bin/bash

# Fix PATH for local context
export PATH="/usr/local/bin:$PATH"

if [[ -a ~/.localrc ]]; then
  source ~/.localrc
fi

# If DDNS_INTERFACE is not set, get default interface
if [ -z "$DDNS_INTERFACE" ]; then
  DDNS_INTERFACE=$(echo show State:/Network/Global/IPv4 | scutil | awk -F" " "/PrimaryInterface/{print \$NF}" | sed 's/\.$//')
fi

# If DDNS_INTERFACE has no IPv4 address, exit
ip_address=$(ifconfig ${DDNS_INTERFACE} | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
if [ -z "$ip_address" ]; then
  exit 0;
fi

# Run the script
export AWS_DEFAULT_PROFILE=personal
~/.dotfiles/ddns/ddns-route53.sh --ip "${ip_address}"
