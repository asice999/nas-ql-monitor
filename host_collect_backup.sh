#!/bin/sh
set -eu

MONITOR_STATUS_DIR=${MONITOR_STATUS_DIR:-./data/monitor-status}
HOST_BACKUP_TARGETS=${HOST_BACKUP_TARGETS:-"/tmp|24|1"}
mkdir -p "$MONITOR_STATUS_DIR"
out="$MONITOR_STATUS_DIR/backup_status.json"

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

now_h=$(date '+%Y-%m-%d %H:%M:%S')
now=$(date +%s)
ok=true
summary=""
items=""
first=1

for item in $HOST_BACKUP_TARGETS; do
  path=${item%%|*}
  rest=${item#*|}
  max_hours=${rest%%|*}
  min_size=${rest#*|}
  exists=true
  age_hours=-1
  size=0
  status=ok

  if [ ! -e "$path" ]; then
    exists=false
    status=missing
    ok=false
  else
    mtime=$(stat -c %Y "$path" 2>/dev/null || echo 0)
    size=$(stat -c %s "$path" 2>/dev/null || echo 0)
    age_hours=$(( (now - mtime) / 3600 ))
    if [ "$size" -lt "$min_size" ]; then
      status=small
      ok=false
    elif [ "$age_hours" -gt "$max_hours" ]; then
      status=stale
      ok=false
    fi
  fi

  one="$path:$status"
  [ -z "$summary" ] && summary="$one" || summary="$summary; $one"
  esc_path=$(json_escape "$path")
  esc_status=$(json_escape "$status")
  if [ "$first" -eq 1 ]; then
    items="{\"path\":\"$esc_path\",\"status\":\"$esc_status\",\"exists\":$exists,\"age_hours\":$age_hours,\"size\":$size}"
    first=0
  else
    items="$items,{\"path\":\"$esc_path\",\"status\":\"$esc_status\",\"exists\":$exists,\"age_hours\":$age_hours,\"size\":$size}"
  fi
done

esc_summary=$(json_escape "$summary")
printf '{"kind":"backup","ok":%s,"time":"%s","summary":"%s","items":[%s]}\n' "$ok" "$now_h" "$esc_summary" "$items" > "$out"
echo "wrote $out"
