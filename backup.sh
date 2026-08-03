#!/system/bin/sh
case $0 in
  */*) SD=${0%/*};;
  *) SD=.;;
esac
. "$SD/scripts/env.sh"
say() { "$BB" printf '%s\n' "$*"; }
mounted_by_us=0
if ! "$BB" grep -q " $ROOT " /proc/self/mounts 2>/dev/null; then
  if [ -n "$ROOTFS_IMG" ] && [ -f "$ROOTFS_IMG" ]; then
    . "$SD/scripts/rootfs-loop.sh" || exit 1
    rootfs_loop_mount || { say "backup: mount image failed"; exit 1; }
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
[ -x "$ROOT/bin/sh" ] || { say "backup: $ROOT has no rootfs"; exit 1; }
"$BB" mkdir -p "$BACKUP_DIR" 2>/dev/null || { say "backup: mkdir $BACKUP_DIR failed"; exit 1; }
sz=$("$BB" du -sm "$ROOT" 2>/dev/null | "$BB" cut -f1)
free=$("$BB" df -m "$BACKUP_DIR" 2>/dev/null | "$BB" awk 'NF>=6{print $(NF-2)}' | "$BB" tail -1)
case "$sz" in ''|*[!0-9]*) sz=0;; esac
case "$free" in ''|*[!0-9]*) free=0;; esac
need=$((sz + 128))
if [ "$free" -lt "$need" ]; then
  say "backup: not enough space, free ${free}M < need ${need}M"
  exit 1
fi
ts=$("$BB" date +%s 2>/dev/null || echo $$)
dst=$BACKUP_DIR/rootfs.$ts.tar.gz
ctlog "backup: packing $ROOT -> $dst (${sz}M)"
say "backup: packing ${sz}M -> $dst"
if "$BB" tar -cf - --exclude='./.hostdev' --exclude='./.oldroot' -C "$ROOT" . 2>/dev/null | "$BB" gzip > "$dst" && [ -s "$dst" ]; then
  n=0
  for f in $("$BB" ls -1r "$BACKUP_DIR" 2>/dev/null | "$BB" grep '^rootfs\.[0-9].*\.tar\.gz$'); do
    n=$((n+1))
    [ "$n" -gt "${ROOTFS_BACKUP_KEEP:-2}" ] && { "$BB" rm -f "$BACKUP_DIR/$f"; ctlog "backup: rotate out $f"; }
  done
  ctlog "backup: done"
  say "backup: done"
else
  ctlog "backup: pack failed"
  "$BB" rm -f "$dst" 2>/dev/null || true
  say "backup: pack failed"
  exit 1
fi
exit 0
