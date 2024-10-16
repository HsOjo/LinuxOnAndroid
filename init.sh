#!/system/bin/sh
cd "$(dirname "$0")" || exit
. "./env.sh"

hostname "$(getprop ro.product.device)"

$mount "/proc" "$ROOT/proc"
$mount "/sys" "$ROOT/sys"
$mount "/dev" "$ROOT/dev"
$mount "/dev/pts" "$ROOT/dev/pts"

mkdir -p "$ROOT/dev/shm"
$mount -t tmpfs -o size="$TMP_SIZE" tmpfs "$ROOT/dev/shm"
mkdir -p "$ROOT/dev/shm/tmp"

$mount "$ROOT/dev/shm/tmp" "$ROOT/tmp"
chmod 777 "$ROOT/tmp"

mkdir -p "$ROOT/media/sdcard"
mkdir -p "$ROOT/media/sdext"
$mount "/sdcard" "$ROOT/media/sdcard"

./exec.sh "/bin/su" -c "/init.sh"
