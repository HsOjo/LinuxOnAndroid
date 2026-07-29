#!/system/bin/sh
case $0 in
  */*) SD=${0%/*};;
  *) SD=.;;
esac
. "$SD/scripts/env.sh"
[ -f "$PIDFILE" ] || exit 0
P=$(cat "$PIDFILE" 2>/dev/null || true)
if [ -n "$P" ] && [ -d "/proc/$P" ]; then
  kill -TERM -"$P" 2>/dev/null || kill -TERM "$P" 2>/dev/null || true
  i=0
  while [ -d "/proc/$P" ] && [ "$i" -lt 10 ]; do sleep 1; i=$((i+1)); done
  [ -d "/proc/$P" ] && kill -KILL -"$P" 2>/dev/null || true
fi
rm -f "$ROOT/sbin/boot-inner" "$ROOT/sbin/setup-dev" "$ROOT/sbin/container-init" "$ROOT/sbin/guest-init-alpine" "$ROOT/sbin/guest-init-debian"
for mp in "$ROOT/.hostdev" "$ROOT/.oldroot" "$ROOT/dev/pts" "$ROOT/dev" "$ROOT/sys" "$ROOT/proc"; do
  while "$BB" grep -q " $mp " /proc/self/mounts 2>/dev/null; do "$BB" umount -l "$mp" 2>/dev/null || break; done
done
rm -f "$PIDFILE"
exit 0
