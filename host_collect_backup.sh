#!/bin/sh
set -eu

MONITOR_STATUS_DIR=${MONITOR_STATUS_DIR:-./data/monitor-status}
HOST_BACKUP_TARGETS=${HOST_BACKUP_TARGETS:-"/tmp|24|1"}
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$MONITOR_STATUS_DIR"
out="$MONITOR_STATUS_DIR/backup_status.json"

tmp=$(mktemp)
now_h=$(date '+%Y-%m-%d %H:%M:%S')
now=$(date +%s)
ok=true
summary=""

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
  printf '%s\t%s\t%s\t%s\t%s\n' "$path" "$status" "$exists" "$age_hours" "$size" >> "$tmp"
done

python3 "$SCRIPT_DIR/host_write_status.py" backup "$tmp" "$out" "$now_h" "$ok" "$summary"
rm -f "$tmp"
echo "wrote $out"
