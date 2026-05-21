#!/bin/sh
set -eu
DIR=$(cd "$(dirname "$0")" && pwd)
. "$DIR/notify.sh"

REPORT_SERVICES=${REPORT_SERVICES:-""}
REPORT_CONTAINERS=${REPORT_CONTAINERS:-""}
REPORT_TARGETS=${REPORT_TARGETS:-"/"}
REPORT_CERT_HOSTS=${REPORT_CERT_HOSTS:-""}
REPORT_BACKUP_TARGETS=${REPORT_BACKUP_TARGETS:-""}
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
    [ "$code" = "200" ] && MSG="$MSG- $name: OK\n" || MSG="$MSG- $name: FAIL($code)\n"
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
  MSG="$MSG\n[磁盘空间]\n"
  for p in $REPORT_TARGETS; do
    line=$(df -P "$p" 2>/dev/null | awk 'NR==2{print $5" "$4" "$6}') || true
    [ -n "$line" ] || continue
    used=$(printf '%s' "$line" | awk '{print $1}')
    avail=$(printf '%s' "$line" | awk '{print $2}')
    mount=$(printf '%s' "$line" | awk '{print $3}')
    MSG="$MSG- $mount: used $used, free $avail\n"
  done
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

notify "NAS 每日报告" "$(printf '%b' "$MSG")"
exit 0
