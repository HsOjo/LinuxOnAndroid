#!/system/bin/sh
case $0 in
  */*) SD=${0%/*};;
  *) SD=.;;
esac
. "$SD/scripts/env.sh"
[ "$(id -u 2>/dev/null || echo 1)" = 0 ] || exit 1
MODID=${MODID:-linuxonandroid}
MODDIR=${MODDIR:-/data/adb/modules/$MODID}
case "${1:-install}" in
  remove|uninstall)
    [ -d "$MODDIR" ] || exit 0
    : > "$MODDIR/remove" || exit 1
    echo "$MODDIR/remove"
    exit 0
    ;;
  disable)
    [ -d "$MODDIR" ] || exit 1
    : > "$MODDIR/disable" || exit 1
    echo "$MODDIR/disable"
    exit 0
    ;;
  enable)
    rm -f "$MODDIR/disable"
    echo "$MODDIR"
    exit 0
    ;;
esac
mkdir -p "$MODDIR" || exit 1
rm -f /data/adb/service.d/99-linuxonandroid.sh 2>/dev/null || true
{
  echo "id=$MODID"
  echo 'name=LinuxOnAndroid'
  echo 'version=1.0'
  echo 'versionCode=1'
  echo 'author=HsOjo'
  echo 'description=Run a Linux rootfs on Android with the host kernel.'
} > "$MODDIR/module.prop" || exit 1
printf '%s\n' "$CTDIR" > "$MODDIR/ctdir" || exit 1
{
  echo '#!/system/bin/sh'
  echo 'MODDIR=${0%/*}'
  echo 'CTDIR=$(cat "$MODDIR/ctdir" 2>/dev/null || true)'
  echo '[ -n "$CTDIR" ] || exit 0'
  echo 'LOG=$CTDIR/run/magisk-service.log'
  echo 'mkdir -p "$CTDIR/run" 2>/dev/null || true'
  echo '[ -x "$CTDIR/start.sh" ] || exit 0'
  echo '"$CTDIR/start.sh" >>"$LOG" 2>&1'
} > "$MODDIR/service.sh" || exit 1
chmod 0755 "$MODDIR" "$MODDIR/service.sh" 2>/dev/null || true
chmod 0644 "$MODDIR/module.prop" "$MODDIR/ctdir" 2>/dev/null || true
restorecon -R "$MODDIR" 2>/dev/null || true
echo "$MODDIR"
exit 0
