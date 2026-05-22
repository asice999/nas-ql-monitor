#!/bin/sh
set -eu

MONITOR_STATUS_DIR=${MONITOR_STATUS_DIR:-./data/monitor-status}
HOST_BACKUP_TARGETS=${HOST_BACKUP_TARGETS:-"/tmp|24|1"}
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

python3 - "$tmp" "$out" "$now_h" "$ok" "$summary" <<'PY'
import json, sys
src, out, now_h, ok_str, summary = sys.argv[1:6]
ok = ok_str.lower() == 'true'
items = []
with open(src, 'r', encoding='utf-8') as f:
    for line in f:
        line = line.rstrip('\n')
        if not line:
            continue
        path, status, exists, age_hours, size = line.split('\t')
        items.append({
            "path": path,
            "status": status,
            "exists": exists.lower() == 'true',
            "age_hours": int(age_hours),
            "size": int(size),
        })
obj = {"kind": "backup", "ok": ok, "time": now_h, "summary": summary, "items": items}
with open(out, 'w', encoding='utf-8') as f:
    json.dump(obj, f, ensure_ascii=False)
PY
rm -f "$tmp"
echo "wrote $out"
