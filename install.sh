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

add_or_update '*/10 * * * *' "task $QL_REPO_DIR/ql_check_services.js" 'NAS 服务在线监控'
add_or_update '*/10 * * * *' "task $QL_REPO_DIR/ql_check_docker.js" 'NAS 容器状态监控'
add_or_update '0 */6 * * *' "task $QL_REPO_DIR/ql_check_disk.js" 'NAS 磁盘空间监控'
add_or_update '30 8 * * *' "task $QL_REPO_DIR/ql_check_cert.js" 'NAS 证书到期监控'
add_or_update '20 3 * * *' "task $QL_REPO_DIR/ql_check_backup.js" 'NAS 备份结果监控'
add_or_update '0 9 * * *' "task $QL_REPO_DIR/ql_daily_report.js" 'NAS 每日报告'
add_or_update '*/30 * * * *' "task $QL_REPO_DIR/ql_check_ddns_ip.js" 'NAS DDNS / IP 监控'
add_or_update '*/15 * * * *' "task $QL_REPO_DIR/ql_check_api_health.js" 'NAS API 健康检查'

echo '安装完成。已创建/重建全部 NAS 监控任务。'
