#!/bin/sh
set -eu

MONITOR_STATUS_DIR=${MONITOR_STATUS_DIR:-./data/monitor-status}
HOST_CONTAINERS=${HOST_CONTAINERS:-"qinglong postgres-main sub2api moviepilot-v2 jellyfin emby qbittorrent navidrome"}
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
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

python3 "$SCRIPT_DIR/host_write_status.py" docker "$tmp" "$out" "$now" "$ok" "$summary"
rm -f "$tmp"
echo "wrote $out"
