#!/system/bin/sh
case $0 in
  */*) SD=${0%/*};;
  *) SD=.;;
esac
. "$SD/scripts/env.sh"
setenforce 0 2>/dev/null || true
BBD=$CTDIR/bin
BB=$BBD/busybox
WGET_UA=${WGET_UA:-Wget/1.36.1.1}
mkdir -p "$BBD" || exit 1
if [ ! -x "$BB" ]; then
  for c in /data/adb/magisk/busybox /sbin/busybox /system/bin/busybox /system/xbin/busybox; do
    [ -x "$c" ] && cp "$c" "$BB" && break
  done
fi
if [ ! -x "$BB" ]; then
  c=$(command -v busybox 2>/dev/null || true)
  [ -n "$c" ] && cp "$c" "$BB" 2>/dev/null || true
fi
if [ ! -x "$BB" ] && [ -n "${BUSYBOX_URL:-}" ]; then
  if command -v wget >/dev/null 2>&1; then
    wget -U "$WGET_UA" -O "$BB" "$BUSYBOX_URL" || exit 1
  else
    exit 3
  fi
fi
chmod 0755 "$BB" 2>/dev/null || true
[ -x "$BB" ] || exit 4
"$BB" true 2>/dev/null || exit 5
if [ -n "$ROOTFS_IMG" ]; then
  . "$SD/scripts/rootfs-loop.sh" || exit 1
  if [ ! -f "$ROOTFS_IMG" ] && [ -x "$ROOT/bin/sh" ] && ! "$BB" grep -q " $ROOT " /proc/self/mounts 2>/dev/null; then
    rootfs_loop_prepare || exit 8
    tmpmnt=$RUN/.rootfs-mnt.$$
    "$BB" mkdir -p "$RUN" "$tmpmnt" || exit 1
    rootfs_loop_mount_at "$tmpmnt" || exit 8
    "$BB" cp -a "$ROOT"/. "$tmpmnt"/ || { "$BB" umount -l "$tmpmnt" 2>/dev/null || true; exit 9; }
    "$BB" umount "$tmpmnt" 2>/dev/null || "$BB" umount -l "$tmpmnt" 2>/dev/null || exit 10
    "$BB" rmdir "$tmpmnt" 2>/dev/null || true
    if [ "${ROOTFS_BACKUP:-1}" = 1 ]; then
      ts=$("$BB" date +%s 2>/dev/null || echo $$)
      "$BB" mv "$ROOT" "$ROOT.bak.$ts" || exit 11
    else
      "$BB" rm -rf "$ROOT" || exit 11
    fi
    "$BB" mkdir -p "$ROOT" || exit 1
    rootfs_loop_mount_at "$ROOT" || exit 12
  else
    rootfs_loop_mount || exit 8
  fi
fi
if [ ! -x "$ROOT/bin/sh" ] && [ -n "${ROOTFS_URL:-}" ]; then
  "$BB" mkdir -p "$ROOT" "$CTDIR/run" || exit 1
  tmp=$CTDIR/run/.rootfs.$$
  "$BB" wget -U "$WGET_UA" -O "$tmp" "$ROOTFS_URL" || exit 6
  case "$ROOTFS_URL" in
    *.tar.xz|*.txz) top=-xJf;;
    *.tar.bz2|*.tbz2) top=-xjf;;
    *.tar.gz|*.tgz) top=-xzf;;
    *) top=-xf;;
  esac
  "$BB" tar "$top" "$tmp" -C "$ROOT" || exit 7
  "$BB" rm -f "$tmp"
  if [ ! -x "$ROOT/bin/sh" ]; then
    for d in "$ROOT"/*; do
      [ -d "$d" ] || continue
      [ -x "$d/bin/sh" ] || continue
      "$BB" mv "$d"/* "$ROOT"/ 2>/dev/null || true
      "$BB" mv "$d"/.[!.]* "$ROOT"/ 2>/dev/null || true
      "$BB" mv "$d"/..?* "$ROOT"/ 2>/dev/null || true
      "$BB" rmdir "$d" 2>/dev/null || true
      break
    done
  fi
fi
hn=$(getprop ro.product.device 2>/dev/null || true)
if [ -n "$hn" ] && [ -d "$ROOT/etc" ]; then
  "$BB" printf '%s\n' "$hn" > "$ROOT/etc/hostname" 2>/dev/null || true
fi
"$BB" echo "$BB"
exit 0
