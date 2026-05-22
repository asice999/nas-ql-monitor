#!/bin/sh
set -eu
DIR=$(cd "$(dirname "$0")" && pwd)
. "$DIR/notify.sh"
. "$DIR/state.sh"

CONTAINERS=${CONTAINERS:-"qinglong postgres-main sub2api moviepilot-v2 jellyfin emby qbittorrent navidrome"}
FAIL=0
MSG=""

for c in $CONTAINERS; do
  status=$(docker inspect -f '{{.State.Status}}' "$c" 2>/dev/null || echo missing)
  restarts=$(docker inspect -f '{{.RestartCount}}' "$c" 2>/dev/null || echo 0)
  if [ "$status" = "running" ]; then
    MSG="$MSG✅ $c running (restart=$restarts)\n"
  else
    FAIL=1
    MSG="$MSG❌ $c $status (restart=$restarts)\n"
  fi
done

if [ "$FAIL" -eq 0 ]; then
  notify_on_change docker ok "NAS 容器异常" "$(printf '%b' "$MSG")" "NAS 容器恢复" "$(printf '%b' "$MSG")"
  exit 0
fi
notify_on_change docker alert "NAS 容器异常" "$(printf '%b' "$MSG")" "NAS 容器恢复" "$(printf '%b' "$MSG")" || exit 1
