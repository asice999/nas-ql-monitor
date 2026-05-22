#!/bin/sh
set -eu
DIR=$(cd "$(dirname "$0")" && pwd)
. "$DIR/notify.sh"
. "$DIR/state.sh"

STATE_DIR=${STATE_DIR:-"$DIR/.state"}
IP_API_URL=${IP_API_URL:-"https://icanhazip.com"}
IP_API_URLS=${IP_API_URLS:-"https://icanhazip.com https://ifconfig.me/ip https://ip.sb https://api.ipify.org"}
DDNS_DOMAINS=${DDNS_DOMAINS:-""}
IP_FAMILY=${IP_FAMILY:-"ipv4"}
mkdir -p "$STATE_DIR"
state_file="$STATE_DIR/public_ip_${IP_FAMILY}.txt"

current_ip=""
used_api=""
for api in $IP_API_URL $IP_API_URLS; do
  [ -n "$api" ] || continue
  ip=$(curl -fsS --max-time 10 "$api" 2>/dev/null | tr -d '\r\n ' || true)
  case "$ip" in
    *.*.*.*|*:*:*) current_ip="$ip"; used_api="$api"; break ;;
    *) ;;
  esac
done

if [ -z "$current_ip" ]; then
  notify_on_change ddns_ip alert "NAS 公网 IP 监控异常" "无法从任何公网 IP 接口获取当前公网 IP。已尝试：$IP_API_URL $IP_API_URLS" "NAS 公网 IP 监控恢复" "已恢复获取公网 IP"
  exit 1
fi

old_ip=""
[ -f "$state_file" ] && old_ip=$(cat "$state_file" 2>/dev/null || true)
printf '%s' "$current_ip" > "$state_file"

FAIL=0
MSG="当前公网 IP：$current_ip\n接口来源：$used_api\n"

if [ -n "$old_ip" ] && [ "$old_ip" != "$current_ip" ]; then
  MSG="$MSG⚠️ 公网 IP 发生变化：$old_ip → $current_ip\n"
  FAIL=1
fi

for domain in $DDNS_DOMAINS; do
  resolved=$(nslookup "$domain" 2>/dev/null | awk '/^Address: /{print $2}' | tail -1)
  if [ -z "$resolved" ]; then
    MSG="$MSG❌ $domain：解析失败\n"
    FAIL=1
    continue
  fi
  if [ "$resolved" = "$current_ip" ]; then
    MSG="$MSG✅ $domain：解析正常（$resolved）\n"
  else
    MSG="$MSG❌ $domain：当前解析 $resolved，与公网 IP 不一致\n"
    FAIL=1
  fi
done

if [ "$FAIL" -eq 0 ]; then
  notify_on_change ddns_ip ok "NAS DDNS / IP 告警" "$(printf '%b' "$MSG")" "NAS DDNS / IP 恢复" "$(printf '%b' "$MSG")"
  exit 0
fi
notify_on_change ddns_ip alert "NAS DDNS / IP 告警" "$(printf '%b' "$MSG")" "NAS DDNS / IP 恢复" "$(printf '%b' "$MSG")" || exit 1
