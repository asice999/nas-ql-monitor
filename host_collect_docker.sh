#!/bin/sh
set -eu

MONITOR_STATUS_DIR=${MONITOR_STATUS_DIR:-./data/monitor-status}
HOST_CONTAINERS=${HOST_CONTAINERS:-"qinglong postgres-main sub2api moviepilot-v2 jellyfin emby qbittorrent navidrome"}
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$MONITOR_STATUS_DIR"
out="$MONITOR_STATUS_DIR/docker_status.json"

python3 "$SCRIPT_DIR/host_collect_docker.py" "$out" $HOST_CONTAINERS

echo "wrote $out"
