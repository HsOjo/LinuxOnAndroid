#!/system/bin/sh
case $0 in
  */*) SD=${0%/*};;
  *) SD=.;;
esac
. "$SD/scripts/env.sh"
[ -f "$PIDFILE" ] || exit 1
P=$("$BB" cat "$PIDFILE" 2>/dev/null || true)
ct_pid_ok "$P" || exit 1
if [ "$#" -gt 0 ]; then
  exec "$BB" nsenter -t "$P" -m -u -- /usr/bin/env -i PATH=/bin:/sbin:/usr/bin:/usr/sbin HOME=/root TMPDIR=/tmp "$@"
fi
exec "$BB" nsenter -t "$P" -m -u -- /usr/bin/env -i PATH=/bin:/sbin:/usr/bin:/usr/sbin HOME=/root TMPDIR=/tmp /bin/sh
