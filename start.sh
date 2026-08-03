#!/system/bin/sh
case $0 in
  */*) SD=${0%/*};;
  *) SD=.;;
esac
. "$SD/scripts/env.sh"
ctlog "start: begin (pid $$)"
if [ -n "$ROOTFS_IMG" ] && [ -f "$ROOTFS_IMG" ]; then
  . "$SD/scripts/rootfs-loop.sh" || { ctlog "start: load rootfs-loop.sh failed"; exit 1; }
  rootfs_loop_mount || { ctlog "start: rootfs mount failed"; exit 1; }
fi
[ -L "$ROOT/bin/sh" ] || [ -x "$ROOT/bin/sh" ] || { ctlog "start: $ROOT/bin/sh missing"; exit 1; }
[ -x "$CTDIR/lib/boot-inner" ] || { ctlog "start: lib/boot-inner missing"; exit 1; }
[ -x "$CTDIR/lib/setup-dev" ] || { ctlog "start: lib/setup-dev missing"; exit 1; }
[ -x "$CTDIR/lib/container-init" ] || { ctlog "start: lib/container-init missing"; exit 1; }
[ -x "$CTDIR/lib/guest-init-alpine" ] || { ctlog "start: lib/guest-init-alpine missing"; exit 1; }
[ -x "$CTDIR/lib/guest-init-debian" ] || { ctlog "start: lib/guest-init-debian missing"; exit 1; }
[ -x "$CTDIR/scripts/start-fore.sh" ] || { ctlog "start: scripts/start-fore.sh missing"; exit 1; }
[ -x "$BB" ] || { ctlog "start: busybox missing"; exit 1; }
if [ -f "$PIDFILE" ]; then
  P=$("$BB" cat "$PIDFILE" 2>/dev/null || true)
  if ct_pid_ok "$P"; then
    ctlog "start: already running (pid $P)"
    exit 0
  fi
  ctlog "start: stale pidfile (pid ${P:-?})"
  "$BB" rm -f "$PIDFILE"
fi
"$BB" mkdir "$LOCK" 2>/dev/null || { ctlog "start: another start in progress"; exit 0; }
trap '"$BB" rmdir "$LOCK" 2>/dev/null' EXIT
"$BB" mkdir -p "$RUN"
CT_FORE=1 "$BB" setsid "$BB" unshare -m -u /system/bin/sh "$CTDIR/scripts/start-fore.sh" >>"$LOG" 2>&1 &
P=$!
"$BB" printf '%s\n' "$P" > "$PIDFILE"
"$BB" sleep 1
[ -d "/proc/$P" ] || { ctlog "start: foreground died early (pid $P)"; exit 4; }
ctlog "start: launched (pid $P)"
exit 0
