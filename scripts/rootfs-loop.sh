#!/system/bin/sh
rootfs_loop_backing() {
  f=/sys/block/loop${1##*loop}/loop/backing_file
  [ -f "$f" ] && "$BB" cat "$f" 2>/dev/null
}
rootfs_loop_nodes() {
  for d in /dev/block/loop* /dev/loop*; do
    [ -b "$d" ] && return 0
  done
  [ -e /dev/loop-control ] || "$BB" mknod /dev/loop-control c 10 237 2>/dev/null || true
  i=0
  while [ "$i" -lt 8 ]; do
    [ -e "/dev/loop$i" ] || "$BB" mknod "/dev/loop$i" b 7 "$i" 2>/dev/null || true
    i=$((i+1))
  done
}
rootfs_loop_devs() {
  found=0
  for d in /dev/block/loop*; do
    [ -b "$d" ] || continue
    found=1
    echo "$d"
  done
  [ "$found" = 1 ] && return 0
  for d in /dev/loop*; do
    [ -b "$d" ] || continue
    echo "$d"
  done
}
rootfs_loop_find() {
  [ -n "${ROOTFS_LOOP:-}" ] && { echo "$ROOTFS_LOOP"; return 0; }
  rootfs_loop_nodes
  for d in $(rootfs_loop_devs); do
    [ -z "$(rootfs_loop_backing "$d")" ] && { echo "$d"; return 0; }
  done
  d=$("$BB" losetup -f 2>/dev/null || true)
  [ -n "$d" ] || return 1
  [ -b "$d" ] || "$BB" mknod "$d" b 7 "${d##*loop}" 2>/dev/null || true
  [ -b "$d" ] || return 1
  echo "$d"
}
rootfs_loop_find_by_backing() {
  rootfs_loop_nodes
  for d in $(rootfs_loop_devs); do
    [ "$(rootfs_loop_backing "$d")" = "$ROOTFS_IMG" ] && { echo "$d"; return 0; }
  done
  return 1
}
rootfs_loop_prepare() {
  [ -n "$ROOTFS_IMG" ] || return 0
  ROOTFS_LOOP_CREATED=0
  if [ ! -f "$ROOTFS_IMG" ]; then
    ctlog "loop: create image $ROOTFS_IMG ($LOOP_SIZE)"
    "$BB" mkdir -p "${ROOTFS_IMG%/*}" || { ctlog "loop: mkdir image dir failed"; return 1; }
    "$BB" fallocate -l "$LOOP_SIZE" "$ROOTFS_IMG" || { ctlog "loop: fallocate failed"; return 1; }
    ROOTFS_LOOP_CREATED=1
  fi
  ROOTFS_LOOP_DEV=$(rootfs_loop_find_by_backing 2>/dev/null || true)
  if [ -z "$ROOTFS_LOOP_DEV" ]; then
    ROOTFS_LOOP_DEV=$(rootfs_loop_find) || { ctlog "loop: no free loop device"; return 1; }
    b=$(rootfs_loop_backing "$ROOTFS_LOOP_DEV")
    if [ -z "$b" ]; then
      "$BB" losetup "$ROOTFS_LOOP_DEV" "$ROOTFS_IMG" || { ctlog "loop: losetup $ROOTFS_LOOP_DEV failed"; return 1; }
      b=$(rootfs_loop_backing "$ROOTFS_LOOP_DEV")
    fi
    [ "$b" = "$ROOTFS_IMG" ] || { ctlog "loop: backing mismatch on $ROOTFS_LOOP_DEV ($b)"; return 1; }
  fi
  ctlog "loop: using $ROOTFS_LOOP_DEV (created=$ROOTFS_LOOP_CREATED)"
  if [ "$ROOTFS_LOOP_CREATED" = 1 ]; then
    "$BB" mke2fs -F -b 4096 "$ROOTFS_LOOP_DEV" || { ctlog "loop: mke2fs failed"; return 1; }
  elif "$BB" e2fsck -V >/dev/null 2>&1; then
    "$BB" e2fsck -p "$ROOTFS_LOOP_DEV" >/dev/null 2>&1
    rc=$?
    [ "$rc" -le 1 ] || ctlog "loop: e2fsck rc=$rc on $ROOTFS_LOOP_DEV"
  fi
  export ROOTFS_LOOP_DEV ROOTFS_LOOP_CREATED
}
rootfs_loop_mounted() {
  "$BB" grep -q " $1 " /proc/self/mounts 2>/dev/null
}
rootfs_loop_mount_at() {
  [ -n "$ROOTFS_IMG" ] || return 0
  rootfs_loop_mounted "$1" && return 0
  [ -n "${ROOTFS_LOOP_DEV:-}" ] || rootfs_loop_prepare || return 1
  "$BB" mkdir -p "$1" || { ctlog "loop: mkdir mountpoint $1 failed"; return 1; }
  "$BB" mount -t ext4 -o rw,relatime "$ROOTFS_LOOP_DEV" "$1" || { ctlog "loop: mount $ROOTFS_LOOP_DEV -> $1 failed"; return 1; }
  ctlog "loop: mounted $ROOTFS_LOOP_DEV at $1"
}
rootfs_loop_mount() {
  [ -n "$ROOTFS_IMG" ] || return 0
  rootfs_loop_mount_at "$ROOT"
}
rootfs_loop_umount() {
  [ -n "$ROOTFS_IMG" ] || return 0
  [ -n "${ROOTFS_LOOP_DEV:-}" ] || ROOTFS_LOOP_DEV=$(rootfs_loop_find_by_backing 2>/dev/null || true)
  while rootfs_loop_mounted "$ROOT"; do
    "$BB" umount "$ROOT" 2>/dev/null || "$BB" umount -l "$ROOT" 2>/dev/null || break
  done
  if [ "${ROOTFS_LOOP_DETACH:-0}" = 1 ]; then
    for d in $(rootfs_loop_devs); do
      [ "$(rootfs_loop_backing "$d")" = "$ROOTFS_IMG" ] || continue
      "$BB" losetup -d "$d" 2>/dev/null || true
    done
  fi
}
