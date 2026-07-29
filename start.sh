#!/system/bin/sh
case $0 in
  */*) SD=${0%/*};;
  *) SD=.;;
esac
. "$SD/scripts/env.sh"
[ -x "$ROOT/bin/sh" ] || exit 1
[ -x "$CTDIR/lib/boot-inner" ] || exit 1
[ -x "$CTDIR/lib/setup-dev" ] || exit 1
[ -x "$CTDIR/lib/container-init" ] || exit 1
[ -x "$CTDIR/lib/guest-init-alpine" ] || exit 1
[ -x "$CTDIR/lib/guest-init-debian" ] || exit 1
[ -x "$CTDIR/scripts/start-fore.sh" ] || exit 1
[ -x "$BB" ] || exit 1
if [ -f "$PIDFILE" ]; then
  P=$(cat "$PIDFILE" 2>/dev/null || true)
  [ -n "$P" ] && [ -d "/proc/$P" ] && exit 0
fi
mkdir "$LOCK" 2>/dev/null || exit 0
trap 'rmdir "$LOCK" 2>/dev/null' EXIT
mkdir -p "$RUN"
CT_FORE=1 "$BB" setsid "$BB" unshare -m -u /system/bin/sh "$CTDIR/scripts/start-fore.sh" >>"$LOG" 2>&1 &
P=$!
echo "$P" > "$PIDFILE"
sleep 1
[ -d "/proc/$P" ] || exit 4
exit 0
