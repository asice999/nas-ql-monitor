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
    MSG="$MSG✅ $c：运行中（重启 $restarts 次）\n"
  else
    FAIL=1
    cn_status=$status
    [ "$status" = "missing" ] && cn_status="未找到"
    [ "$status" = "exited" ] && cn_status="已退出"
    [ "$status" = "restarting" ] && cn_status="重启中"
    [ "$status" = "paused" ] && cn_status="已暂停"
    MSG="$MSG❌ $c：$cn_status（重启 $restarts 次）\n"
  fi
done

if [ "$FAIL" -eq 0 ]; then
  notify_on_change docker ok "NAS 容器异常" "$(printf '%b' "$MSG")" "NAS 容器恢复" "$(printf '%b' "$MSG")"
  exit 0
fi
notify_on_change docker alert "NAS 容器异常" "$(printf '%b' "$MSG")" "NAS 容器恢复" "$(printf '%b' "$MSG")" || exit 1
