#!/system/bin/sh
cd "$(dirname "$0")" || exit
. "./env.sh"

./exec.sh "/bin/su" -c "/halt.sh"

$umount "$ROOT/proc"
$umount "$ROOT/sys"
$umount "$ROOT/tmp"
$umount "$ROOT/dev/pts"
$umount "$ROOT/dev/shm"
$umount "$ROOT/dev"

$umount "$ROOT/media/sdcard"
