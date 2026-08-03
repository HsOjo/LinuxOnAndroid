#!/system/bin/sh
[ "$(id -u 2>/dev/null || echo 1)" = 0 ] || exit 1
MODID=${MODID:-linuxonandroid-selinux}
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
{
  echo "id=$MODID"
  echo 'name=LinuxOnAndroid SELinux'
  echo 'version=1.0'
  echo 'versionCode=1'
  echo 'author=HsOjo'
  echo 'description=Set SELinux to permissive at boot for LinuxOnAndroid.'
} > "$MODDIR/module.prop" || exit 1
{
  echo '#!/system/bin/sh'
  echo 'setenforce 0'
} > "$MODDIR/service.sh" || exit 1
chmod 0755 "$MODDIR" "$MODDIR/service.sh" 2>/dev/null || true
chmod 0644 "$MODDIR/module.prop" 2>/dev/null || true
restorecon -R "$MODDIR" 2>/dev/null || true
echo "$MODDIR"
exit 0
