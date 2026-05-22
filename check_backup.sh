#!/bin/sh
set -eu
DIR=$(cd "$(dirname "$0")" && pwd)
. "$DIR/notify.sh"
. "$DIR/state.sh"

BACKUP_TARGETS=${BACKUP_TARGETS:-"/tmp|24|1"}
NOW=$(date +%s)
FAIL=0
MSG=""

for item in $BACKUP_TARGETS; do
  path=${item%%|*}
  rest=${item#*|}
  max_hours=${rest%%|*}
  min_size=${rest#*|}

  if [ ! -e "$path" ]; then
    FAIL=1
    MSG="$MSG❌ $path 不存在\n"
    continue
  fi

  mtime=$(stat -c %Y "$path" 2>/dev/null || true)
  size=$(stat -c %s "$path" 2>/dev/null || echo 0)
  [ -n "$mtime" ] || mtime=0
  age_hours=$(( (NOW - mtime) / 3600 ))

  if [ "$size" -lt "$min_size" ]; then
    FAIL=1
    MSG="$MSG❌ $path 大小异常: ${size}B < ${min_size}B\n"
    continue
  fi

  if [ "$age_hours" -gt "$max_hours" ]; then
    FAIL=1
    MSG="$MSG❌ $path 距今 ${age_hours} 小时，超过 ${max_hours} 小时\n"
  else
    MSG="$MSG✅ $path 正常，${age_hours} 小时前更新\n"
  fi
done

if [ "$FAIL" -eq 0 ]; then
  notify_on_change backup ok "NAS 备份结果告警" "$(printf '%b' "$MSG")" "NAS 备份恢复正常" "$(printf '%b' "$MSG")"
  exit 0
fi
notify_on_change backup alert "NAS 备份结果告警" "$(printf '%b' "$MSG")" "NAS 备份恢复正常" "$(printf '%b' "$MSG")" || exit 1
