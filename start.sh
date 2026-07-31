#!/system/bin/sh
case $0 in
  */*) SD=${0%/*};;
  *) SD=.;;
esac
. "$SD/scripts/env.sh"
if [ -n "$ROOTFS_IMG" ] && [ -f "$ROOTFS_IMG" ]; then
  . "$SD/scripts/rootfs-loop.sh" || exit 1
  rootfs_loop_mount || exit 1
fi
[ -L "$ROOT/bin/sh" ] || [ -x "$ROOT/bin/sh" ] || exit 1
[ -x "$CTDIR/lib/boot-inner" ] || exit 1
[ -x "$CTDIR/lib/setup-dev" ] || exit 1
[ -x "$CTDIR/lib/container-init" ] || exit 1
[ -x "$CTDIR/lib/guest-init-alpine" ] || exit 1
[ -x "$CTDIR/lib/guest-init-debian" ] || exit 1
[ -x "$CTDIR/scripts/start-fore.sh" ] || exit 1
[ -x "$BB" ] || exit 1
if [ -f "$PIDFILE" ]; then
  P=$("$BB" cat "$PIDFILE" 2>/dev/null || true)
  if ct_pid_ok "$P"; then
    exit 0
  fi
  "$BB" rm -f "$PIDFILE"
fi
"$BB" mkdir "$LOCK" 2>/dev/null || exit 0
trap '"$BB" rmdir "$LOCK" 2>/dev/null' EXIT
"$BB" mkdir -p "$RUN"
CT_FORE=1 "$BB" setsid "$BB" unshare -m -u /system/bin/sh "$CTDIR/scripts/start-fore.sh" >>"$LOG" 2>&1 &
P=$!
"$BB" printf '%s\n' "$P" > "$PIDFILE"
"$BB" sleep 1
[ -d "/proc/$P" ] || exit 4
exit 0
