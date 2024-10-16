#!/system/bin/sh
cd "$(dirname "$0")" || exit
. "./env.sh"

PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
$chroot "$ROOT" "$@"
