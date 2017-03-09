#!/bin/bash

# If DDNS_INTERFACE is not set, exit
if [ -z "$DDNS_INTERFACE" ]; then
  exit 0;
fi

# If DDNS_INTERFACE has no IPv4 address, exit
ip_address=$(ifconfig ${DDNS_INTERFACE} | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
if [ -z "$ip_address" ]; then
  exit 0;
fi

# Run the script
export AWS_DEFAULT_PROFILE=personal
~/.dotfiles/ddns/ddns-route53.sh -i "${ip_address}"
