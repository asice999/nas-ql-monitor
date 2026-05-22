#!/bin/sh
set -eu
DIR=$(cd "$(dirname "$0")" && pwd)
. "$DIR/notify.sh"
. "$DIR/state.sh"

HOST_STATUS_DIR=${HOST_STATUS_DIR:-/ql/data/monitor-status}
STATUS_FILE=${STATUS_FILE:-$HOST_STATUS_DIR/backup_status.json}
TITLE_ALERT=${TITLE_ALERT:-宿主机备份异常}
TITLE_OK=${TITLE_OK:-宿主机备份恢复}
STATE_KEY=${STATE_KEY:-host_backup}

if [ ! -f "$STATUS_FILE" ]; then
  notify_on_change "$STATE_KEY" alert "$TITLE_ALERT" "状态文件不存在：$STATUS_FILE" "$TITLE_OK" "状态文件已恢复：$STATUS_FILE"
  exit 1
fi

summary=$(python3 -c '
import json,sys
m={"missing":"缺失","small":"文件过小","stale":"过期","ok":"正常"}
d=json.load(open(sys.argv[1], encoding="utf-8"))
print(d.get("time",""))
parts=[]
for item in d.get("items", []):
    path=item.get("path")
    status=m.get(str(item.get("status")), str(item.get("status")))
    parts.append(f"{path}：{status}")
print("；".join(parts))
print("alert" if not d.get("ok",False) else "ok")
' "$STATUS_FILE")
time_line=$(printf '%s
' "$summary" | sed -n '1p')
summary_line=$(printf '%s
' "$summary" | sed -n '2p')
current=$(printf '%s
' "$summary" | sed -n '3p')
body="时间：$time_line
摘要：$summary_line
文件：$STATUS_FILE"
if [ "$current" = "ok" ]; then
  notify_on_change "$STATE_KEY" ok "$TITLE_ALERT" "$body" "$TITLE_OK" "$body"
  exit 0
fi
notify_on_change "$STATE_KEY" alert "$TITLE_ALERT" "$body" "$TITLE_OK" "$body" || exit 1
