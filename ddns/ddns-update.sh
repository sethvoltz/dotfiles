#!/bin/bash

echo "---"
echo "Network change at `date`"

# Fix PATH for local context
export PATH="/usr/local/bin:$PATH"

if [[ -a ~/.localrc ]]; then
  echo "  - Sourcing .localrc"
  source ~/.localrc
fi

# If DDNS_INTERFACE is not set, get default interface
if [ -z "$DDNS_INTERFACE" ]; then
  echo "  - No DDNS interface override specified, looking for current default..."
  # DDNS_INTERFACE=$(echo show State:/Network/Global/IPv4 | scutil | awk -F" " "/PrimaryInterface/{print \$NF}" | sed 's/\.$//')
  DDNS_INTERFACE=$(echo $(route get 8.8.8.8 2>&1 | grep interface | cut -d : -f 2))
fi
echo "  - Using interface '${DDNS_INTERFACE}'"

# If DDNS_INTERFACE has no IPv4 address, exit
ip_address=$(ifconfig ${DDNS_INTERFACE} | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
if [ -z "$ip_address" ] || [ "$ip_address" = "127.0.0.1" ]; then
  echo "  - Interface either has no IP or it is local loopback. Exiting."
  exit 0;
fi

# Run the script
export AWS_DEFAULT_PROFILE=personal
~/.dotfiles/ddns/ddns-route53.sh --ip "${ip_address}"

echo "Done."
