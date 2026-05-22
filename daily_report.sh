#!/bin/sh
set -eu
DIR=$(cd "$(dirname "$0")" && pwd)
. "$DIR/notify.sh"
. "$DIR/state.sh"

REPORT_SERVICES=${REPORT_SERVICES:-""}
REPORT_CONTAINERS=${REPORT_CONTAINERS:-""}
REPORT_TARGETS=${REPORT_TARGETS:-"/"}
REPORT_DISK_WARN=${REPORT_DISK_WARN:-85}
REPORT_CERT_HOSTS=${REPORT_CERT_HOSTS:-""}
REPORT_BACKUP_TARGETS=${REPORT_BACKUP_TARGETS:-""}
REPORT_EVENT_LINES=${REPORT_EVENT_LINES:-10}
HOST_STATUS_DIR=${HOST_STATUS_DIR:-/ql/data/monitor-status}
REPORT_HOST_DOCKER=${REPORT_HOST_DOCKER:-true}
REPORT_HOST_DISK=${REPORT_HOST_DISK:-true}
TIMEOUT=${TIMEOUT:-8}
CERT_WARN_DAYS=${CERT_WARN_DAYS:-30}
NOW=$(date +%s)
MSG="【NAS 每日报告】\n"

if [ -n "$REPORT_SERVICES" ]; then
  MSG="$MSG\n[服务在线]\n"
  for item in $REPORT_SERVICES; do
    url=${item%%|*}
    name=${item#*|}
    code=$(curl -k -sS -m "$TIMEOUT" -o /dev/null -w '%{http_code}' "$url" || true)
    [ "$code" = "200" ] && MSG="$MSG- $name：正常\n" || MSG="$MSG- $name：异常($code) ⚠️\n"
  done
fi

if [ -n "$REPORT_CONTAINERS" ]; then
  MSG="$MSG\n[容器状态]\n"
  for c in $REPORT_CONTAINERS; do
    status=$(docker inspect -f '{{.State.Status}}' "$c" 2>/dev/null || echo missing)
    MSG="$MSG- $c: $status\n"
  done
fi

if [ -n "$REPORT_TARGETS" ]; then
  MSG="$MSG\n[容器内磁盘空间]\n"
  for p in $REPORT_TARGETS; do
    line=$(df -P "$p" 2>/dev/null | awk 'NR==2{print $5" "$4" "$2" "$6}') || true
    [ -n "$line" ] || continue
    used=$(printf '%s' "$line" | awk '{print $1}')
    used_num=$(printf '%s' "$used" | tr -d '%')
    avail=$(printf '%s' "$line" | awk '{print $2}')
    total=$(printf '%s' "$line" | awk '{print $3}')
    mount=$(printf '%s' "$line" | awk '{print $4}')
    human=$(python3 -c '
import sys
v = float(sys.argv[1])
if v >= 1024*1024*1024:
    print(f"{v/1024/1024/1024:.2f} T")
elif v >= 1024*1024:
    print(f"{v/1024/1024:.2f} G")
elif v >= 1024:
    print(f"{v/1024:.2f} M")
else:
    print(f"{v:.2f} K")
' "$avail")
    human_total=$(python3 -c '
import sys
v = float(sys.argv[1])
if v >= 1024*1024*1024:
    print(f"{v/1024/1024/1024:.2f} T")
elif v >= 1024*1024:
    print(f"{v/1024/1024:.2f} G")
elif v >= 1024:
    print(f"{v/1024:.2f} M")
else:
    print(f"{v:.2f} K")
' "$total")
    MSG="$MSG- $mount：已用 $used，剩余 $human，总容量 $human_total"
    [ "$used_num" -ge "$REPORT_DISK_WARN" ] && MSG="$MSG ⚠️"
    MSG="$MSG\n"
  done
fi

if [ "$REPORT_HOST_DISK" = "true" ] && [ -f "$HOST_STATUS_DIR/disk_status.json" ]; then
  MSG="$MSG\n[宿主机磁盘状态]\n"
  python3 -c '
import json, sys
p = sys.argv[1]
warn = int(sys.argv[2])
d = json.load(open(p, encoding="utf-8"))
def human(kb):
    kb = float(kb)
    if kb >= 1024 * 1024 * 1024:
        return f"{kb/1024/1024/1024:.2f} TB"
    if kb >= 1024 * 1024:
        return f"{kb/1024/1024:.2f} GB"
    if kb >= 1024:
        return f"{kb/1024:.2f} MB"
    return f"{kb:.2f} KB"
for item in d.get("items", []):
    mount = item.get("mount")
    used = int(item.get("used", 0))
    free_kb = float(item.get("free", 0))
    total_kb = float(item.get("total", 0))
    mark = " ⚠️" if used >= warn else ""
    print("- {}：已用 {}%，剩余 {}，总容量 {}{}".format(mount, used, human(free_kb), human(total_kb), mark))
' "$HOST_STATUS_DIR/disk_status.json" "$REPORT_DISK_WARN" > "$DIR/.state/.host_disk_daily.tmp"
  MSG="$MSG$(cat "$DIR/.state/.host_disk_daily.tmp")\n"
  rm -f "$DIR/.state/.host_disk_daily.tmp"
fi

if [ "$REPORT_HOST_DOCKER" = "true" ] && [ -f "$HOST_STATUS_DIR/docker_status.json" ]; then
  MSG="$MSG\n[宿主机 Docker 状态]\n"
  python3 -c '
import json, sys
p = sys.argv[1]
d = json.load(open(p, encoding="utf-8"))
for item in d.get("items", []):
    name = item.get("name")
    status = item.get("status")
    restart = item.get("restart", 0)
    mark = " ⚠️" if status != "running" else ""
    cn = "运行中" if status == "running" else ("未找到" if status == "missing" else str(status))
    print("- {}：{}，重启 {} 次{}".format(name, cn, restart, mark))
' "$HOST_STATUS_DIR/docker_status.json" > "$DIR/.state/.host_docker_daily.tmp"
  MSG="$MSG$(cat "$DIR/.state/.host_docker_daily.tmp")\n"
  rm -f "$DIR/.state/.host_docker_daily.tmp"
fi

if [ -n "$REPORT_CERT_HOSTS" ]; then
  MSG="$MSG\n[证书]\n"
  for host in $REPORT_CERT_HOSTS; do
    line=$(echo | openssl s_client -servername "$host" -connect "$host:443" 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null || true)
    end=${line#notAfter=}
    end_ts=$(date -d "$end" +%s 2>/dev/null || true)
    if [ -z "$end" ] || [ -z "$end_ts" ]; then
      MSG="$MSG- $host: 获取失败\n"
    else
      days=$(( (end_ts - NOW) / 86400 ))
      MSG="$MSG- $host: 剩余 ${days} 天"
      [ "$days" -le "$CERT_WARN_DAYS" ] && MSG="$MSG ⚠️"
      MSG="$MSG\n"
    fi
  done
fi

if [ -n "$REPORT_BACKUP_TARGETS" ]; then
  MSG="$MSG\n[备份]\n"
  for item in $REPORT_BACKUP_TARGETS; do
    path=${item%%|*}
    rest=${item#*|}
    max_hours=${rest%%|*}
    min_size=${rest#*|}
    if [ ! -e "$path" ]; then
      MSG="$MSG- $path: 缺失\n"
      continue
    fi
    mtime=$(stat -c %Y "$path" 2>/dev/null || true)
    size=$(stat -c %s "$path" 2>/dev/null || echo 0)
    age_hours=$(( (NOW - mtime) / 3600 ))
    MSG="$MSG- $path: ${age_hours}h, ${size}B"
    [ "$size" -lt "$min_size" ] && MSG="$MSG ⚠️"
    [ "$age_hours" -gt "$max_hours" ] && MSG="$MSG ⚠️"
    MSG="$MSG\n"
  done
fi

if [ -f "$EVENT_LOG" ]; then
  MSG="$MSG\n[最近异常摘要]\n"
  tail -n "$REPORT_EVENT_LINES" "$EVENT_LOG" | while IFS= read -r line; do
    printf '%s\n' "- $line"
  done > "$DIR/.state/.daily_event_snip.tmp"
  if [ -s "$DIR/.state/.daily_event_snip.tmp" ]; then
    MSG="$MSG$(cat "$DIR/.state/.daily_event_snip.tmp")\n"
  else
    MSG="$MSG- 无\n"
  fi
  rm -f "$DIR/.state/.daily_event_snip.tmp"
else
  MSG="$MSG\n[最近异常摘要]\n- 暂无记录\n"
fi

notify "NAS 每日报告" "$(printf '%b' "$MSG")"
exit 0
