#!/bin/sh
set -eu
DIR=$(cd "$(dirname "$0")" && pwd)
. "$DIR/notify.sh"
. "$DIR/state.sh"

HOST_STATUS_DIR=${HOST_STATUS_DIR:-/ql/data/monitor-status}
STATUS_FILE=${STATUS_FILE:-$HOST_STATUS_DIR/disk_status.json}
TITLE_ALERT=${TITLE_ALERT:-宿主机磁盘异常}
TITLE_OK=${TITLE_OK:-宿主机磁盘恢复}
STATE_KEY=${STATE_KEY:-host_disk}

if [ ! -f "$STATUS_FILE" ]; then
  notify_on_change "$STATE_KEY" alert "$TITLE_ALERT" "状态文件不存在: $STATUS_FILE" "$TITLE_OK" "状态文件已恢复: $STATUS_FILE"
  exit 1
fi

tmp=$(mktemp)
python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print("alert" if not d.get("ok",False) else "ok"); print(d.get("time","")); print(d.get("summary",""))' "$STATUS_FILE" > "$tmp"
current=$(sed -n '1p' "$tmp")
time_line=$(sed -n '2p' "$tmp")
summary=$(sed -n '3p' "$tmp")
rm -f "$tmp"
body="时间: $time_line\n摘要: $summary\n文件: $STATUS_FILE"
if [ "$current" = "ok" ]; then
  notify_on_change "$STATE_KEY" ok "$TITLE_ALERT" "$body" "$TITLE_OK" "$body"
  exit 0
fi
notify_on_change "$STATE_KEY" alert "$TITLE_ALERT" "$body" "$TITLE_OK" "$body" || exit 1
