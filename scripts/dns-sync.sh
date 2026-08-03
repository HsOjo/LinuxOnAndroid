#!/system/bin/sh
case $0 in
  */*) SD=${0%/*};;
  *) SD=.;;
esac
if [ -f "$SD/scripts/env.sh" ]; then
  . "$SD/scripts/env.sh"
else
  . "$SD/env.sh"
fi
OUT=$ROOT/etc/resolv.conf
TMP=$ROOT/etc/.resolv.conf.$$
collect() {
  primary=$1
  dumpsys connectivity 2>/dev/null | while IFS= read -r line; do
    case "$line" in *DnsAddresses:*) :;; *) continue;; esac
    if [ "$primary" = 1 ]; then
      case "$line" in *TRANSPORT_PRIMARY*) :;; *) continue;; esac
    fi
    addrs=${line#*DnsAddresses: }
    addrs=${addrs#*/}
    addrs=${addrs%% ]*}
    oldifs=$IFS
    IFS=','
    for a in $addrs; do
      a=${a# }
      a=${a#/}
      case "$a" in *.*|*:*) echo "nameserver $a";; esac
    done
    IFS=$oldifs
  done
}
mkdir -p "$ROOT/etc" || exit 0
collect 1 > "$TMP" 2>/dev/null || true
[ -s "$TMP" ] || collect 0 > "$TMP" 2>/dev/null || true
if [ -s "$TMP" ]; then
  if [ -f "$OUT" ] && "$BB" cmp -s "$TMP" "$OUT" 2>/dev/null; then
    rm -f "$TMP"
  else
    chmod 0644 "$TMP" 2>/dev/null || true
    mv "$TMP" "$OUT" 2>/dev/null || rm -f "$TMP"
  fi
else
  rm -f "$TMP"
  [ -f "$OUT" ] || echo 'nameserver 223.5.5.5' > "$OUT"
fi
exit 0
