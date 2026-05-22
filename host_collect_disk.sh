#!/bin/sh
set -eu

MONITOR_STATUS_DIR=${MONITOR_STATUS_DIR:-./data/monitor-status}
HOST_TARGETS=${HOST_TARGETS:-"/ /volume1 /var/lib/docker"}
HOST_THRESHOLD=${HOST_THRESHOLD:-85}
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$MONITOR_STATUS_DIR"
out="$MONITOR_STATUS_DIR/disk_status.json"

tmp=$(mktemp)
now=$(date '+%Y-%m-%d %H:%M:%S')
ok=true
summary=""

for p in $HOST_TARGETS; do
  line=$(df -P "$p" 2>/dev/null | awk 'NR==2{print $5" "$4" "$2" "$6}') || true
  [ -n "$line" ] || continue
  used=$(printf '%s' "$line" | awk '{gsub(/%/,"",$1); print $1}')
  free=$(printf '%s' "$line" | awk '{print $2}')
  total=$(printf '%s' "$line" | awk '{print $3}')
  mount=$(printf '%s' "$line" | awk '{print $4}')
  [ "$used" -lt "$HOST_THRESHOLD" ] || ok=false
  one="$mount:${used}%"
  [ -z "$summary" ] && summary="$one" || summary="$summary; $one"
  printf '%s\t%s\t%s\t%s\n' "$mount" "$used" "$free" "$total" >> "$tmp"
done

python3 "$SCRIPT_DIR/host_write_status.py" disk "$tmp" "$out" "$now" "$ok" "$summary"
rm -f "$tmp"
echo "wrote $out"
