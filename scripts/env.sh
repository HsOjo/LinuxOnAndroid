#!/system/bin/sh
case $0 in
  */scripts/*) CTDIR=${0%/scripts/*};;
  scripts/*) CTDIR=$(pwd);;
  */*) CTDIR=${0%/*};;
  *) CTDIR=$(pwd);;
esac
CTDIR=$(cd "$CTDIR" && pwd) || exit 1
ROOT=$CTDIR/rootfs
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
