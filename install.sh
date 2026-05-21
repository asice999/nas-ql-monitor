#!/bin/sh
set -eu

BASE_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_DIR_NAME=$(basename "$BASE_DIR")
QL_REPO_DIR=${QL_REPO_DIR:-"/ql/data/repo/$REPO_DIR_NAME"}

find_task_id() {
  name="$1"
  if ql cron find "$name" >/tmp/qlcron.$$ 2>/dev/null; then
    sed -n 's/.*ID=\([0-9][0-9]*\).*/\1/p' /tmp/qlcron.$$ | head -1
  fi
  rm -f /tmp/qlcron.$$ 2>/dev/null || true
}

add_or_update() {
  schedule="$1"
  command="$2"
  name="$3"
  id=$(find_task_id "$name" || true)
  if [ -n "${id:-}" ]; then
    ql cron disable "$id" >/dev/null 2>&1 || true
    ql cron del "$id" >/dev/null 2>&1 || true
  fi
  ql cron add "$schedule" "$command" "$name"
}

if ! command -v ql >/dev/null 2>&1; then
  echo '未找到 ql 命令，请在青龙容器内执行本脚本。'
  exit 1
fi

add_or_update '*/30 * * * *' "task $QL_REPO_DIR/ql_check_ddns_ip.js" 'NAS DDNS / IP 监控'
add_or_update '*/15 * * * *' "task $QL_REPO_DIR/ql_check_api_health.js" 'NAS API 健康检查'

echo '安装完成。可在青龙任务列表中查看：NAS DDNS / IP 监控 / NAS API 健康检查'
