#!/bin/sh
# Upgrade the deployment at /data/adb/LinuxOnAndroid from this repo.
# Run on the host (macOS/Linux) with adb connected and root (su) available.
# Only syncs repo files; runtime data (rootfs.img, rootfs/, run/, bin/, backup/)
# on the device is left untouched.
set -e

SD=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DST=${DST:-/data/adb/LinuxOnAndroid}
ADB=${ADB:-adb}

die() { printf '%s\n' "upgrade: $*" >&2; exit 1; }

adbcmd=${ADB:-adb}
command -v "${adbcmd%% *}" >/dev/null 2>&1 || die "adb not found, install Android platform-tools first"

if [ "${ADB:-adb}" = "adb" ]; then
  devs=$(adb devices | awk 'NR>1 && $2=="device" {print $1}')
  n=$(printf '%s\n' "$devs" | sed '/^$/d' | wc -l | tr -d ' ')
  if [ "$n" -gt 1 ]; then
    printf '%s\n' "upgrade: multiple devices, pick one with ADB=\"adb -s <serial>\":" >&2
    printf '  %s\n' $devs >&2
    exit 1
  fi
fi

"$ADB" get-state >/dev/null 2>&1 || die "no adb device"
"$ADB" shell "su -c 'test -d $DST'" >/dev/null 2>&1 || die "$DST not found (or no root)"

FILES="
LICENSE
README.md
README.zh.md
backup.sh
enter.sh
init.sh
restore.sh
setup_magisk_module.sh
setup_selinux_magisk_module.sh
start.sh
stop.sh
lib/boot-inner
lib/container-init
lib/guest-init-alpine
lib/guest-init-debian
lib/setup-dev
scripts/dns-sync.sh
scripts/env.sh
scripts/rootfs-loop.sh
scripts/start-fore.sh
"

changed=0
for f in $FILES; do
  [ -f "$SD/$f" ] || { printf 'skip (missing locally): %s\n' "$f"; continue; }
  lsum=$(md5 -q "$SD/$f" 2>/dev/null || md5sum "$SD/$f" | awk '{print $1}')
  rsum=$("$ADB" shell "su -c 'md5sum $DST/$f 2>/dev/null'" | tr -d '\r' | awk '{print $1}')
  if [ "$lsum" = "$rsum" ]; then
    printf 'same:    %s\n' "$f"
  else
    "$ADB" push "$SD/$f" "/data/local/tmp/loa-upgrade.tmp" >/dev/null
    case $f in
      */*) dir=$DST/${f%/*};;
      *) dir=$DST;;
    esac
    "$ADB" shell "su -c 'mkdir -p $dir; cp /data/local/tmp/loa-upgrade.tmp $DST/$f; chmod 755 $DST/$f; rm -f /data/local/tmp/loa-upgrade.tmp'" >/dev/null
    printf 'updated: %s\n' "$f"
    changed=1
  fi
done

# Clean macOS junk left by earlier copies.
"$ADB" shell "su -c 'find $DST -name \".DS_Store\" -o -name \"._*\" | while read -r j; do rm -f \"\$j\"; done'" >/dev/null

[ "$changed" = 1 ] || printf '%s\n' 'upgrade: already up to date'
printf '%s\n' 'upgrade: done'
