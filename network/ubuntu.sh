#!/bin/sh
groupadd -g 3001 aid_net_bt_admin
groupadd -g 3002 aid_net_bt
groupadd -g 3003 aid_inet
groupadd -g 3004 aid_inet_raw
groupadd -g 3005 aid_inet_admin

gpasswd -a root aid_net_bt_admin
gpasswd -a root aid_net_bt
gpasswd -a root aid_inet
gpasswd -a root aid_inet_raw
gpasswd -a root aid_inet_admin

DNS_FILE="/etc/resolv.conf"
rm -f "$DNS_FILE"
echo "nameserver 223.5.5.5" >"$DNS_FILE"
