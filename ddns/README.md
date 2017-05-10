# Notes

Another way of getting the default interface is through `osquery`. This gives you the IP at the same time without a need to call `ifconfig`:

```
osqueryi --json "select destination, id.interface, routes.type from interface_details as id, interface_addresses as ia, routes where id.interface = ia.interface and routes.destination = ia.address and routes.type = 'static';" | jq -r ".[]"
```

Other methods are:

- `echo show State:/Network/Global/IPv4 | scutil | awk -F" " "/PrimaryInterface/{print \$NF}" | sed 's/\.$//'`
- `echo $(route get 8.8.8.8 2>&1 | grep interface | cut -d : -f 2)`
