#!/bin/sh
set -eu
DIR=$(cd "$(dirname "$0")" && pwd)
. "$DIR/notify.sh"

THRESHOLD=${THRESHOLD:-85}
TARGETS=${TARGETS:-"/ /volume1 /var/lib/docker"}
FAIL=0
MSG=""

for p in $TARGETS; do
  line=$(df -P "$p" 2>/dev/null | awk 'NR==2{print $5" "$4" "$2" "$6}') || true
  [ -n "$line" ] || continue
  used=$(printf '%s' "$line" | awk '{gsub(/%/,"",$1); print $1}')
  avail=$(printf '%s' "$line" | awk '{print $2}')
  total=$(printf '%s' "$line" | awk '{print $3}')
  mount=$(printf '%s' "$line" | awk '{print $4}')
  if [ "$used" -ge "$THRESHOLD" ]; then
    FAIL=1
    MSG="$MSG❌ $mount $used% used, free $avail / total $total\n"
  else
    MSG="$MSG✅ $mount $used% used\n"
  fi
done

[ "$FAIL" -eq 0 ] && exit 0
notify "NAS 磁盘空间告警" "$(printf '%b' "$MSG")"
exit 1
