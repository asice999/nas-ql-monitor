#!/bin/sh
set -eu
DIR=$(cd "$(dirname "$0")" && pwd)
. "$DIR/notify.sh"
. "$DIR/state.sh"

SERVICES=${SERVICES:-"https://127.0.0.1:5700|青龙 https://127.0.0.1:8096|Jellyfin"}
TIMEOUT=${TIMEOUT:-8}
FAIL=0
MSG=""

for item in $SERVICES; do
  url=${item%%|*}
  name=${item#*|}
  code=$(curl -k -sS -m "$TIMEOUT" -o /dev/null -w '%{http_code}' "$url" || true)
  if [ "$code" = "200" ]; then
    MSG="$MSG✅ $name OK ($code)\n"
  else
    FAIL=1
    MSG="$MSG❌ $name FAIL ($code)\n"
  fi
done

if [ "$FAIL" -eq 0 ]; then
  notify_on_change services ok "NAS 服务异常" "$(printf '%b' "$MSG")" "NAS 服务恢复" "$(printf '%b' "$MSG")"
  exit 0
fi
notify_on_change services alert "NAS 服务异常" "$(printf '%b' "$MSG")" "NAS 服务恢复" "$(printf '%b' "$MSG")" || exit 1
