#!/system/bin/sh
case $0 in
  */*) SD=${0%/*};;
  *) SD=.;;
esac
if [ -f "$SD/scripts/env.sh" ]; then
  . "$SD/scripts/env.sh"
else
  . "$SD/env.sh"
fi
[ "${CT_FORE:-0}" = 1 ] || exit 2
OLD=.oldroot
HOSTDEV=$ROOT/.hostdev
inject() {
  f=$1
  src=$LIB/$f
  dst=$ROOT/sbin/$f
  [ -f "$src" ] || return 1
  "$BB" mkdir -p "${dst%/*}" 2>/dev/null || true
  [ -e "$dst" ] || : > "$dst"
  "$BB" mount --bind "$src" "$dst" 2>/dev/null || return 1
  "$BB" chmod 0755 "$dst" 2>/dev/null || true
}
"$BB" mount --make-rprivate / || exit 12
"$BB" mount --bind "$ROOT" "$ROOT" || exit 13
"$BB" mount --make-private "$ROOT" 2>/dev/null || true
inject boot-inner || exit 16
inject setup-dev || exit 17
inject container-init || exit 18
inject guest-init-alpine || exit 19
inject guest-init-debian || exit 20
"$CTDIR/scripts/dns-sync.sh" 2>/dev/null || true
"$BB" mkdir -p "$HOSTDEV" "$ROOT/$OLD" "$ROOT/dev" "$ROOT/proc" "$ROOT/sys" "$ROOT/run" "$ROOT/var/log"
"$BB" mount --bind /dev "$HOSTDEV" || exit 15
"$BB" mount --make-private "$HOSTDEV" 2>/dev/null || true
cd "$ROOT" || exit 14
if ! "$BB" pivot_root . "$OLD"; then
  exec chroot "$ROOT" /sbin/container-init
fi
export PATH=/bin:/sbin:/usr/bin:/usr/sbin
exec /bin/sh /sbin/boot-inner
