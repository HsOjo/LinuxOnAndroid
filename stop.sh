#!/system/bin/sh
case $0 in
  */*) SD=${0%/*};;
  *) SD=.;;
esac
. "$SD/scripts/env.sh"
say() { "$BB" printf '%s\n' "$*"; }
[ -f "$PIDFILE" ] || exit 0
P=$("$BB" cat "$PIDFILE" 2>/dev/null || true)
ct_pid_ok "$P" || { "$BB" rm -f "$PIDFILE"; exit 0; }
if [ -n "$P" ] && [ -d "/proc/$P" ]; then
  MNT=$("$BB" readlink "/proc/$P/ns/mnt" 2>/dev/null || true)
  UTS=$("$BB" readlink "/proc/$P/ns/uts" 2>/dev/null || true)
  HAVE_NS=0
  [ -n "$MNT$UTS" ] && HAVE_NS=1
  ns_pids() {
    for d in /proc/[0-9]*; do
      p=${d#/proc/}
      [ "$p" = "$$" ] && continue
      if [ -n "$MNT" ] && [ "$("$BB" readlink "$d/ns/mnt" 2>/dev/null || true)" != "$MNT" ]; then continue; fi
      if [ -n "$UTS" ] && [ "$("$BB" readlink "$d/ns/uts" 2>/dev/null || true)" != "$UTS" ]; then continue; fi
      echo "$p"
    done
  }
  say "stop: target pid $P"
  [ "${STOP_VERBOSE:-0}" = 1 ] && say "stop: ns mnt=${MNT:-none} uts=${UTS:-none}"
  if [ "$HAVE_NS" = 1 ]; then
    pids=$(ns_pids)
    set -- $pids
    say "stop: TERM $# -> $*"
    for p do "$BB" kill -TERM "$p" 2>/dev/null || true; done
  else
    say "stop: TERM pgid $P"
    "$BB" kill -TERM -"$P" 2>/dev/null || "$BB" kill -TERM "$P" 2>/dev/null || true
  fi
  i=0
  while [ -d "/proc/$P" ] && [ "$i" -lt 10 ]; do
    say "stop: wait $((i+1))/10"
    "$BB" sleep 1
    i=$((i+1))
  done
  if [ "$HAVE_NS" = 1 ]; then
    left=$(ns_pids)
    set -- $left
    if [ "$#" -gt 0 ]; then
      say "stop: KILL $# -> $*"
      for p do [ -d "/proc/$p" ] && "$BB" kill -KILL "$p" 2>/dev/null || true; done
    else
      say "stop: done"
    fi
  else
    if [ -d "/proc/$P" ]; then
      say "stop: KILL pgid $P"
      "$BB" kill -KILL -"$P" 2>/dev/null || true
    else
      say "stop: done"
    fi
  fi
fi
"$BB" rm -f "$ROOT/sbin/boot-inner" "$ROOT/sbin/setup-dev" "$ROOT/sbin/container-init" "$ROOT/sbin/guest-init-alpine" "$ROOT/sbin/guest-init-debian"
for mp in "$ROOT/.hostdev" "$ROOT/.oldroot" "$ROOT/dev/pts" "$ROOT/dev" "$ROOT/sys" "$ROOT/proc"; do
  while "$BB" grep -q " $mp " /proc/self/mounts 2>/dev/null; do "$BB" umount -l "$mp" 2>/dev/null || break; done
done
"$BB" rm -f "$PIDFILE"
exit 0
