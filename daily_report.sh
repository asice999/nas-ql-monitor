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
REPORT_EVENT_LINES=${REPORT_EVENT_LINES:-3}
HOST_STATUS_DIR=${HOST_STATUS_DIR:-/ql/data/monitor-status}
REPORT_HOST_DOCKER=${REPORT_HOST_DOCKER:-true}
REPORT_HOST_DISK=${REPORT_HOST_DISK:-true}
REPORT_FULL_DOCKER=${REPORT_FULL_DOCKER:-false}
TIMEOUT=${TIMEOUT:-8}
CERT_WARN_DAYS=${CERT_WARN_DAYS:-30}
NOW=$(date +%s)
MSG="【NAS 每日报告】\n"
HAS_WARN=0

human_kb() {
  python3 -c '
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
' "$1"
}

if [ -n "$REPORT_SERVICES" ]; then
  block=""
  for item in $REPORT_SERVICES; do
    url=${item%%|*}
    name=${item#*|}
    code=$(curl -k -sS -m "$TIMEOUT" -o /dev/null -w '%{http_code}' "$url" || true)
    if [ "$code" = "200" ]; then
      :
    elif [ "$code" = "301" ] || [ "$code" = "302" ]; then
      block="$block- $name：跳转($code) ⚠️\n"
      HAS_WARN=1
    else
      block="$block- $name：异常($code) ⚠️\n"
      HAS_WARN=1
    fi
  done
  [ -n "$block" ] && MSG="$MSG\n[服务异常]\n$(printf '%b' "$block")"
fi

if [ "$REPORT_HOST_DISK" = "true" ] && [ -f "$HOST_STATUS_DIR/disk_status.json" ]; then
  MSG="$MSG\n[宿主机磁盘]\n"
  python3 -c '
import json, sys
p = sys.argv[1]
warn = int(sys.argv[2])
d = json.load(open(p, encoding="utf-8"))
def human(kb):
    kb = float(kb)
    if kb >= 1024 * 1024 * 1024:
        return f"{kb/1024/1024/1024:.2f} TB"
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
    print("- {}：{} 已用，剩余 {} / 总 {}{}".format(mount, str(used)+"%", human(free_kb), human(total_kb), mark))
' "$HOST_STATUS_DIR/disk_status.json" "$REPORT_DISK_WARN" > "$DIR/.state/.host_disk_daily.tmp"
  MSG="$MSG$(cat "$DIR/.state/.host_disk_daily.tmp")\n"
  rm -f "$DIR/.state/.host_disk_daily.tmp"
fi

if [ "$REPORT_HOST_DOCKER" = "true" ] && [ -f "$HOST_STATUS_DIR/docker_status.json" ]; then
  python3 -c '
import json, sys
p = sys.argv[1]
full = sys.argv[2].lower() == "true"
d = json.load(open(p, encoding="utf-8"))
lines=[]
for item in d.get("items", []):
    name = item.get("name")
    status = item.get("status")
    restart = item.get("restart", 0)
    cn = "运行中" if status == "running" else ("未找到" if status == "missing" else str(status))
    mark = " ⚠️" if status != "running" else ""
    line = "- {}：{}，重启 {} 次{}".format(name, cn, restart, mark)
    if full or status != "running":
        lines.append(line)
print("\n".join(lines))
' "$HOST_STATUS_DIR/docker_status.json" "$REPORT_FULL_DOCKER" > "$DIR/.state/.host_docker_daily.tmp"
  if [ -s "$DIR/.state/.host_docker_daily.tmp" ]; then
    MSG="$MSG\n[宿主机 Docker]\n$(cat "$DIR/.state/.host_docker_daily.tmp")\n"
  fi
  rm -f "$DIR/.state/.host_docker_daily.tmp"
fi

if [ -n "$REPORT_CERT_HOSTS" ]; then
  block=""
  for host in $REPORT_CERT_HOSTS; do
    line=$(echo | openssl s_client -servername "$host" -connect "$host:443" 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null || true)
    end=${line#notAfter=}
    end_ts=$(date -d "$end" +%s 2>/dev/null || true)
    if [ -z "$end" ] || [ -z "$end_ts" ]; then
      block="$block- $host：获取失败 ⚠️\n"
      HAS_WARN=1
    else
      days=$(( (end_ts - NOW) / 86400 ))
      if [ "$days" -le "$CERT_WARN_DAYS" ]; then
        block="$block- $host：剩余 ${days} 天 ⚠️\n"
        HAS_WARN=1
      fi
    fi
  done
  [ -n "$block" ] && MSG="$MSG\n[证书提醒]\n$(printf '%b' "$block")"
fi

if [ -f "$EVENT_LOG" ]; then
  tail -n "$REPORT_EVENT_LINES" "$EVENT_LOG" | while IFS= read -r line; do
    printf '%s\n' "- $line"
  done > "$DIR/.state/.daily_event_snip.tmp"
  if [ -s "$DIR/.state/.daily_event_snip.tmp" ]; then
    MSG="$MSG\n[最近异常摘要]\n$(cat "$DIR/.state/.daily_event_snip.tmp")\n"
  fi
  rm -f "$DIR/.state/.daily_event_snip.tmp"
fi

[ "$HAS_WARN" -eq 0 ] && MSG="$MSG\n[状态概览]\n- 当前未发现新的服务/证书异常\n"

notify "NAS 每日报告" "$(printf '%b' "$MSG")"
exit 0
