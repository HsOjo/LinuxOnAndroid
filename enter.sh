#!/system/bin/sh
case $0 in
  */*) SD=${0%/*};;
  *) SD=.;;
esac
. "$SD/scripts/env.sh"
[ -f "$PIDFILE" ] || exit 1
P=$("$BB" cat "$PIDFILE" 2>/dev/null || true)
[ -n "$P" ] && [ -d "/proc/$P" ] || exit 1
if [ "$#" -gt 0 ]; then
  exec "$BB" nsenter -t "$P" -m -u -- /bin/sh -c 'PATH=/bin:/sbin:/usr/bin:/usr/sbin; export PATH; "$@"' enter "$@"
else
  exec "$BB" nsenter -t "$P" -m -u -- /bin/sh -c 'PATH=/bin:/sbin:/usr/bin:/usr/sbin; export PATH; exec /bin/sh'
fi
