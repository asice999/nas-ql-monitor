#!/bin/sh
set -eu
DIR=$(cd "$(dirname "$0")" && pwd)
. "$DIR/notify.sh"
. "$DIR/state.sh"

CERT_HOSTS=${CERT_HOSTS:-"example.com"}
CERT_WARN_DAYS=${CERT_WARN_DAYS:-30}
FAIL=0
MSG=""
NOW=$(date +%s)

for host in $CERT_HOSTS; do
  line=$(echo | openssl s_client -servername "$host" -connect "$host:443" 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null || true)
  end=${line#notAfter=}
  if [ -z "$end" ] || [ "$end" = "$line" ]; then
    FAIL=1
    MSG="$MSG❌ $host 证书获取失败\n"
    continue
  fi
  end_ts=$(date -d "$end" +%s 2>/dev/null || true)
  if [ -z "$end_ts" ]; then
    FAIL=1
    MSG="$MSG❌ $host 证书日期解析失败: $end\n"
    continue
  fi
  days=$(( (end_ts - NOW) / 86400 ))
  if [ "$days" -le "$CERT_WARN_DAYS" ]; then
    FAIL=1
    MSG="$MSG❌ $host 证书剩余 ${days} 天\n"
  else
    MSG="$MSG✅ $host 证书剩余 ${days} 天\n"
  fi
done

if [ "$FAIL" -eq 0 ]; then
  notify_on_change cert ok "NAS 证书到期告警" "$(printf '%b' "$MSG")" "NAS 证书恢复正常" "$(printf '%b' "$MSG")"
  exit 0
fi
notify_on_change cert alert "NAS 证书到期告警" "$(printf '%b' "$MSG")" "NAS 证书恢复正常" "$(printf '%b' "$MSG")" || exit 1
