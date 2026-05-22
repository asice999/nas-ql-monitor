#!/bin/sh
set -eu
DIR=$(cd "$(dirname "$0")" && pwd)
. "$DIR/notify.sh"
. "$DIR/state.sh"

HOST_STATUS_DIR=${HOST_STATUS_DIR:-/ql/data/monitor-status}
STATUS_FILE=${STATUS_FILE:-$HOST_STATUS_DIR/docker_status.json}
TITLE_ALERT=${TITLE_ALERT:-宿主机 Docker 异常}
TITLE_OK=${TITLE_OK:-宿主机 Docker 恢复}
STATE_KEY=${STATE_KEY:-host_docker}

if [ ! -f "$STATUS_FILE" ]; then
  notify_on_change "$STATE_KEY" alert "$TITLE_ALERT" "状态文件不存在：$STATUS_FILE" "$TITLE_OK" "状态文件已恢复：$STATUS_FILE"
  exit 1
fi

summary=$(python3 -c '
import json,sys
m={"running":"运行中","missing":"未找到","exited":"已退出","restarting":"重启中","paused":"已暂停","created":"已创建","dead":"不可用"}
d=json.load(open(sys.argv[1], encoding="utf-8"))
print(d.get("time",""))
parts=[]
for item in d.get("items", []):
    name=item.get("name")
    status=m.get(str(item.get("status")), str(item.get("status")))
    restart=item.get("restart",0)
    parts.append(f"{name}：{status}（重启 {restart} 次）")
print("；".join(parts))
' "$STATUS_FILE")
current=$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1], encoding="utf-8")); print("alert" if not d.get("ok",False) else "ok")' "$STATUS_FILE")
time_line=$(printf '%s
' "$summary" | sed -n '1p')
summary_line=$(printf '%s
' "$summary" | sed -n '2p')
body="时间：$time_line
摘要：$summary_line
文件：$STATUS_FILE"
if [ "$current" = "ok" ]; then
  notify_on_change "$STATE_KEY" ok "$TITLE_ALERT" "$body" "$TITLE_OK" "$body"
  exit 0
fi
notify_on_change "$STATE_KEY" alert "$TITLE_ALERT" "$body" "$TITLE_OK" "$body" || exit 1
