#!/bin/sh
set -eu

MONITOR_STATUS_DIR=${MONITOR_STATUS_DIR:-./data/monitor-status}
HOST_CONTAINERS=${HOST_CONTAINERS:-"qinglong postgres-main sub2api moviepilot-v2 jellyfin emby qbittorrent navidrome"}
mkdir -p "$MONITOR_STATUS_DIR"
out="$MONITOR_STATUS_DIR/docker_status.json"

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

now=$(date '+%Y-%m-%d %H:%M:%S')
ok=true
summary=""
items=""
first=1

for c in $HOST_CONTAINERS; do
  status=$(docker inspect -f '{{.State.Status}}' "$c" 2>/dev/null || echo missing)
  restart=$(docker inspect -f '{{.RestartCount}}' "$c" 2>/dev/null || echo 0)
  [ "$status" = "running" ] || ok=false
  line="$c:$status(restart=$restart)"
  [ -z "$summary" ] && summary="$line" || summary="$summary; $line"
  esc_name=$(json_escape "$c")
  esc_status=$(json_escape "$status")
  if [ "$first" -eq 1 ]; then
    items="{\"name\":\"$esc_name\",\"status\":\"$esc_status\",\"restart\":$restart}"
    first=0
  else
    items="$items,{\"name\":\"$esc_name\",\"status\":\"$esc_status\",\"restart\":$restart}"
  fi
done

esc_summary=$(json_escape "$summary")
printf '{"kind":"docker","ok":%s,"time":"%s","summary":"%s","items":[%s]}\n' "$ok" "$now" "$esc_summary" "$items" > "$out"
echo "wrote $out"
