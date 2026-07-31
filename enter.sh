#!/system/bin/sh
case $0 in
  */*) SD=${0%/*};;
  *) SD=.;;
esac
. "$SD/scripts/env.sh"
[ -f "$PIDFILE" ] || exit 1
P=$("$BB" cat "$PIDFILE" 2>/dev/null || true)
ct_pid_ok "$P" || exit 1
HAVE_CAPSH=0
"$BB" nsenter -t "$P" -m -u -- /bin/sh -c '[ -x /usr/sbin/capsh ]' 2>/dev/null && HAVE_CAPSH=1
if [ "$#" -gt 0 ]; then
  if [ "$HAVE_CAPSH" = 1 ]; then
    exec "$BB" nsenter -t "$P" -m -u -- /usr/sbin/capsh --user=root --drop=cap_sys_ptrace --shell=/bin/sh -- -c 'PATH=/bin:/sbin:/usr/bin:/usr/sbin; export PATH; "$@"' enter "$@"
  fi
  exec "$BB" nsenter -t "$P" -m -u -- /bin/sh -c 'PATH=/bin:/sbin:/usr/bin:/usr/sbin; export PATH; "$@"' enter "$@"
else
  if [ "$HAVE_CAPSH" = 1 ]; then
    exec "$BB" nsenter -t "$P" -m -u -- /usr/sbin/capsh --user=root --drop=cap_sys_ptrace --shell=/bin/sh -- -c 'PATH=/bin:/sbin:/usr/bin:/usr/sbin; export PATH; exec /bin/sh'
  fi
  exec "$BB" nsenter -t "$P" -m -u -- /bin/sh -c 'PATH=/bin:/sbin:/usr/bin:/usr/sbin; export PATH; exec /bin/sh'
fi
