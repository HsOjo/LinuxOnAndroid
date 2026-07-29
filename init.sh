#!/system/bin/sh
case $0 in
  */*) SD=${0%/*};;
  *) SD=.;;
esac
. "$SD/scripts/env.sh"
BBD=$CTDIR/bin
BB=$BBD/busybox
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
    wget -O "$BB" "$BUSYBOX_URL" || exit 1
  else
    exit 3
  fi
fi
chmod 0755 "$BB" 2>/dev/null || true
[ -x "$BB" ] || exit 4
"$BB" true 2>/dev/null || exit 5
if [ ! -x "$ROOT/bin/sh" ] && [ -n "${ROOTFS_URL:-}" ]; then
  command -v wget >/dev/null 2>&1 || exit 6
  mkdir -p "$ROOT" "$CTDIR/run" || exit 1
  tmp=$CTDIR/run/.rootfs.$$
  wget -O "$tmp" "$ROOTFS_URL" || exit 1
  case "$ROOTFS_URL" in
    *.tar.xz|*.txz) top=-xJf;;
    *.tar.bz2|*.tbz2) top=-xjf;;
    *.tar.gz|*.tgz) top=-xzf;;
    *) top=-xf;;
  esac
  "$BB" tar "$top" "$tmp" -C "$ROOT" || exit 7
  rm -f "$tmp"
  if [ ! -x "$ROOT/bin/sh" ]; then
    for d in "$ROOT"/*; do
      [ -d "$d" ] || continue
      [ -x "$d/bin/sh" ] || continue
      mv "$d"/* "$ROOT"/ 2>/dev/null || true
      mv "$d"/.[!.]* "$ROOT"/ 2>/dev/null || true
      mv "$d"/..?* "$ROOT"/ 2>/dev/null || true
      rmdir "$d" 2>/dev/null || true
      break
    done
  fi
fi
echo "$BB"
exit 0
