#!/bin/sh
addgroup -g 3001 aid_net_bt_admin
addgroup -g 3002 aid_net_bt
addgroup -g 3003 aid_inet
addgroup -g 3004 aid_inet_raw
addgroup -g 3005 aid_inet_admin

addgroup root aid_net_bt_admin
addgroup root aid_net_bt
addgroup root aid_inet
addgroup root aid_inet_raw
addgroup root aid_inet_admin

DNS_FILE="/etc/resolv.conf"
rm -f "$DNS_FILE"
echo "nameserver 223.5.5.5" >"$DNS_FILE"
