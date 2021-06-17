#!/system/bin/sh
SRC_DIR="$(realpath "$(dirname "$0")")"
SRC="$SRC_DIR/service.sh"
DEST="/data/adb/service.d/linux.sh"

rm -f "$DEST"
sed "s/INSTALL_DIR/$(echo "$SRC_DIR" | sed 's/\//\\\//g')/g" "$SRC" >"$DEST"
chmod 777 "$DEST"
