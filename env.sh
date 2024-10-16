#!/system/bin/sh
PATH="/system/xbin:$PATH"
ROOT="/data/.linux"
TMP_SIZE="512m"
SHELL="/bin/sh"
TMPDIR="/tmp"

chroot="busybox chroot"
mount="busybox mount"
umount="busybox umount"
