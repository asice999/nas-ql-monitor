#!/bin/sh
set -eu

MONITOR_STATUS_DIR=${MONITOR_STATUS_DIR:-./data/monitor-status}
HOST_CONTAINERS=${HOST_CONTAINERS:-"qinglong postgres-main sub2api moviepilot-v2 jellyfin emby qbittorrent navidrome"}
mkdir -p "$MONITOR_STATUS_DIR"
out="$MONITOR_STATUS_DIR/docker_status.json"

tmp=$(mktemp)
now=$(date '+%Y-%m-%d %H:%M:%S')
ok=true
summary=""

for c in $HOST_CONTAINERS; do
  status=$(docker inspect -f '{{.State.Status}}' "$c" 2>/dev/null || echo missing)
  restart=$(docker inspect -f '{{.RestartCount}}' "$c" 2>/dev/null || echo 0)
  [ "$status" = "running" ] || ok=false
  line="$c:$status(restart=$restart)"
  [ -z "$summary" ] && summary="$line" || summary="$summary; $line"
  printf '%s\t%s\t%s\n' "$c" "$status" "$restart" >> "$tmp"
done

python3 - "$tmp" "$out" "$now" "$ok" "$summary" <<'PY'
import json, sys
src, out, now, ok_str, summary = sys.argv[1:6]
ok = ok_str.lower() == 'true'
items = []
with open(src, 'r', encoding='utf-8') as f:
    for line in f:
        line = line.rstrip('\n')
        if not line:
            continue
        name, status, restart = line.split('\t')
        items.append({"name": name, "status": status, "restart": int(restart)})
obj = {"kind": "docker", "ok": ok, "time": now, "summary": summary, "items": items}
with open(out, 'w', encoding='utf-8') as f:
    json.dump(obj, f, ensure_ascii=False)
PY
rm -f "$tmp"
echo "wrote $out"
