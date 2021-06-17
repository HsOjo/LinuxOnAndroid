#!/system/bin/sh
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
SHELL="/bin/sh"
TMPDIR="/tmp"
/system/xbin/chroot "$ROOT" "$@"
