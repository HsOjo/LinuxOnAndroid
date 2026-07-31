#!/system/bin/sh
case $0 in
  */*) SD=${0%/*};;
  *) SD=.;;
esac
. "$SD/scripts/env.sh"
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
"$BB" echo "$BB"
exit 0
