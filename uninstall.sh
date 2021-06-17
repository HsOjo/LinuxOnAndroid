#!/system/bin/sh
cd "$(dirname "$0")" || exit
. "./env.sh"

./halt.sh
rm -fr "$ROOT"
