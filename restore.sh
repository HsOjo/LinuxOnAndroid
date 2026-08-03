#!/system/bin/sh
case $0 in
  */*) SD=${0%/*};;
  *) SD=.;;
esac
. "$SD/scripts/env.sh"
say() { "$BB" printf '%s\n' "$*"; }
if [ -f "$PIDFILE" ]; then
  P=$("$BB" cat "$PIDFILE" 2>/dev/null || true)
  if ct_pid_ok "$P"; then
    say "restore: container running (pid $P), run stop.sh first"
    exit 1
  fi
fi
src=${1:-}
if [ -z "$src" ]; then
  f=$("$BB" ls -1r "$BACKUP_DIR" 2>/dev/null | "$BB" grep '^rootfs\.[0-9].*\.tar\.gz$' | "$BB" head -1)
  [ -n "$f" ] && src=$BACKUP_DIR/$f
fi
[ -n "$src" ] && [ -f "$src" ] || { say "restore: no backup file found (usage: restore.sh [file])"; exit 1; }
mounted_by_us=0
if [ -n "$ROOTFS_IMG" ]; then
  . "$SD/scripts/rootfs-loop.sh" || exit 1
  if ! "$BB" grep -q " $ROOT " /proc/self/mounts 2>/dev/null; then
    rootfs_loop_mount || { say "restore: mount image failed"; exit 1; }
    mounted_by_us=1
  fi
fi
cleanup() {
  if [ "$mounted_by_us" = 1 ]; then
    "$BB" sync
    "$BB" umount "$ROOT" 2>/dev/null || "$BB" umount -l "$ROOT" 2>/dev/null || true
  fi
}
trap cleanup EXIT
"$BB" mkdir -p "$ROOT" || exit 1
ctlog "restore: wipe $ROOT, extract <- $src"
say "restore: wipe $ROOT"
"$BB" rm -rf "$ROOT"/* "$ROOT"/.[!.]* "$ROOT"/..?* 2>/dev/null || true
say "restore: extract $src"
case "$src" in
  *.gz) "$BB" gzip -dc "$src" | "$BB" tar -xf - -C "$ROOT" 2>/dev/null;;
  *) "$BB" tar -xf "$src" -C "$ROOT" 2>/dev/null;;
esac
if [ -L "$ROOT/bin/sh" ] || [ -x "$ROOT/bin/sh" ]; then
  "$BB" sync
  ctlog "restore: done"
  say "restore: done"
  exit 0
fi
ctlog "restore: failed, $ROOT/bin/sh missing"
say "restore: failed, rootfs looks broken"
exit 1
