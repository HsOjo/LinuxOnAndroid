#!/system/bin/sh
case $0 in
  */scripts/*) CTDIR=${0%/scripts/*};;
  scripts/*) CTDIR=$(pwd);;
  */*) CTDIR=${0%/*};;
  *) CTDIR=$(pwd);;
esac
CTDIR=$(cd "$CTDIR" && pwd) || exit 1
ROOT=$CTDIR/rootfs
ROOTFS_IMG=${ROOTFS_IMG:-$CTDIR/rootfs.img}
LOOP_SIZE=${LOOP_SIZE:-40G}
ROOTFS_LOOP=${ROOTFS_LOOP:-}
ROOTFS_LOOP_DETACH=${ROOTFS_LOOP_DETACH:-0}
ROOTFS_SPARSE=${ROOTFS_SPARSE:-0}
ROOTFS_BACKUP=${ROOTFS_BACKUP:-1}
ROOTFS_BACKUP_KEEP=${ROOTFS_BACKUP_KEEP:-2}
BACKUP_DIR=${BACKUP_DIR:-$CTDIR/backup}
DNS_SYNC_INTERVAL=${DNS_SYNC_INTERVAL:-30}
LOG_MAX_KB=${LOG_MAX_KB:-256}
RUN=$CTDIR/run
PIDFILE=$RUN/container.pid
LOG=$RUN/container.log
LOCK=$CTDIR/.startlock
LIB=$CTDIR/lib
PATH=/product/bin:/apex/com.android.runtime/bin:/apex/com.android.art/bin:/system_ext/bin:/system/bin:/system/xbin:/odm/bin:/vendor/bin:/sbin
export PATH
BB=$CTDIR/bin/busybox
[ -x "$BB" ] || BB=$(command -v busybox 2>/dev/null || true)
[ -n "$BB" ] || BB=busybox
ct_pid_ok() {
  [ -n "${1:-}" ] && [ -d "/proc/$1" ] || return 1
  C=$("$BB" tr '\0' ' ' < "/proc/$1/cmdline" 2>/dev/null || true)
  case "$C" in
    *start-fore.sh*|*boot-inner*|*container-init*) return 0;;
  esac
  return 1
}
ctlog() {
  [ -n "${LOG:-}" ] || return 0
  "$BB" mkdir -p "${LOG%/*}" 2>/dev/null || true
  if [ -f "$LOG" ]; then
    sz=$("$BB" wc -c < "$LOG" 2>/dev/null || echo 0)
    case "$sz" in ''|*[!0-9]*) sz=0;; esac
    max=$(( ${LOG_MAX_KB:-256} * 1024 ))
    if [ "$sz" -gt "$max" ]; then
      "$BB" tail -c $((max / 2)) "$LOG" > "$LOG.tmp" 2>/dev/null \
        && "$BB" cat "$LOG.tmp" > "$LOG" 2>/dev/null
      "$BB" rm -f "$LOG.tmp" 2>/dev/null || true
    fi
  fi
  "$BB" printf '%s %s\n' "$("$BB" date '+%m-%d %H:%M:%S' 2>/dev/null || echo '-')" "$*" >>"$LOG" 2>/dev/null || true
}
