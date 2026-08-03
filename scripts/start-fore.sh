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
if [ -n "$ROOTFS_IMG" ] && [ -f "$ROOTFS_IMG" ]; then
  if [ -f "$SD/scripts/rootfs-loop.sh" ]; then
    . "$SD/scripts/rootfs-loop.sh" || exit 11
  else
    . "$SD/rootfs-loop.sh" || exit 11
  fi
  rootfs_loop_mount || { ctlog "fore: rootfs mount failed"; exit 11; }
fi
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
"$BB" mount --make-rprivate / || { ctlog "fore: make-rprivate / failed"; exit 12; }
"$BB" mount --bind "$ROOT" "$ROOT" || { ctlog "fore: bind root failed"; exit 13; }
"$BB" mount --make-private "$ROOT" 2>/dev/null || true
inject boot-inner || { ctlog "fore: inject boot-inner failed"; exit 16; }
inject setup-dev || { ctlog "fore: inject setup-dev failed"; exit 17; }
inject container-init || { ctlog "fore: inject container-init failed"; exit 18; }
inject guest-init-alpine || { ctlog "fore: inject guest-init-alpine failed"; exit 19; }
inject guest-init-debian || { ctlog "fore: inject guest-init-debian failed"; exit 20; }
"$CTDIR/scripts/dns-sync.sh" 2>/dev/null || true
"$BB" mkdir -p "$HOSTDEV" "$ROOT/$OLD" "$ROOT/dev" "$ROOT/proc" "$ROOT/sys" "$ROOT/run" "$ROOT/var/log"
"$BB" mount --bind /dev "$HOSTDEV" || { ctlog "fore: bind /dev failed"; exit 15; }
"$BB" mount --make-private "$HOSTDEV" 2>/dev/null || true
cd "$ROOT" || { ctlog "fore: cd $ROOT failed"; exit 14; }
ctlog "fore: entering rootfs"
if ! "$BB" pivot_root . "$OLD"; then
  ctlog "fore: pivot_root failed, fallback to chroot"
  exec chroot "$ROOT" /sbin/container-init
fi
export PATH=/bin:/sbin:/usr/bin:/usr/sbin
exec /bin/sh /sbin/boot-inner
