#!/bin/sh
set -eu
DIR=$(cd "$(dirname "$0")" && pwd)
. "$DIR/notify.sh"
. "$DIR/state.sh"

API_TARGETS=${API_TARGETS:-"https://example.com/health|示例接口|200|ok"}
TIMEOUT=${TIMEOUT:-10}
FAIL=0
MSG=""
TMP_ITEMS=$(mktemp)
printf '%s' "$API_TARGETS" | awk 'BEGIN{RS=";;"} {gsub(/^[\r\n]+|[\r\n]+$/, "", $0); if (length($0) > 0) print $0}' > "$TMP_ITEMS"

while IFS= read -r item; do
  [ -n "$item" ] || continue
  url=$(printf '%s' "$item" | awk -F '|' '{print $1}')
  name=$(printf '%s' "$item" | awk -F '|' '{print $2}')
  expect=$(printf '%s' "$item" | awk -F '|' '{print $3}')
  keyword=$(printf '%s' "$item" | awk -F '|' '{print $4}')

  tmp=$(mktemp)
  code=$(curl -k -sS -m "$TIMEOUT" -o "$tmp" -w '%{http_code}' "$url" || true)
  body=$(cat "$tmp" 2>/dev/null || true)
  rm -f "$tmp"

  if [ "$code" != "$expect" ]; then
    FAIL=1
    MSG="$MSG❌ $name 状态码异常: $code != $expect\n"
    continue
  fi

  if [ -n "$keyword" ] && ! printf '%s' "$body" | grep -F "$keyword" >/dev/null 2>&1; then
    FAIL=1
    MSG="$MSG❌ $name 缺少关键字: $keyword\n"
    continue
  fi

  MSG="$MSG✅ $name 正常 ($code)\n"
done < "$TMP_ITEMS"
rm -f "$TMP_ITEMS"

if [ "$FAIL" -eq 0 ]; then
  notify_on_change api_health ok "NAS API 健康检查异常" "$(printf '%b' "$MSG")" "NAS API 健康检查恢复" "$(printf '%b' "$MSG")"
  exit 0
fi
notify_on_change api_health alert "NAS API 健康检查异常" "$(printf '%b' "$MSG")" "NAS API 健康检查恢复" "$(printf '%b' "$MSG")" || exit 1
