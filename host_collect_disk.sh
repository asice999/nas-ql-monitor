#!/bin/sh
set -eu

MONITOR_STATUS_DIR=${MONITOR_STATUS_DIR:-./data/monitor-status}
HOST_TARGETS=${HOST_TARGETS:-"/ /volume1 /var/lib/docker"}
HOST_THRESHOLD=${HOST_THRESHOLD:-85}
mkdir -p "$MONITOR_STATUS_DIR"
out="$MONITOR_STATUS_DIR/disk_status.json"

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

now=$(date '+%Y-%m-%d %H:%M:%S')
ok=true
summary=""
items=""
first=1

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
  esc_mount=$(json_escape "$mount")
  if [ "$first" -eq 1 ]; then
    items="{\"mount\":\"$esc_mount\",\"used\":$used,\"free\":\"$free\",\"total\":\"$total\"}"
    first=0
  else
    items="$items,{\"mount\":\"$esc_mount\",\"used\":$used,\"free\":\"$free\",\"total\":\"$total\"}"
  fi
done

esc_summary=$(json_escape "$summary")
printf '{"kind":"disk","ok":%s,"time":"%s","summary":"%s","items":[%s]}\n' "$ok" "$now" "$esc_summary" "$items" > "$out"
echo "wrote $out"
