#!/bin/sh
set -eu

# 通用通知：优先走青龙自带 sendNotify.js，其次兼容常见青龙通知变量，最后打印到 stdout
notify() {
  title="$1"
  body="$2"

  # 1) 青龙自带 sendNotify.js
  if command -v node >/dev/null 2>&1; then
    for f in \
      /ql/data/scripts/sendNotify.js \
      /ql/data/config/sendNotify.js \
      /ql/scripts/sendNotify.js \
      /ql/config/sendNotify.js
    do
      if [ -f "$f" ]; then
        if NOTIFY_TITLE="$title" NOTIFY_BODY="$body" NOTIFY_FILE="$f" node -e '
const mod = require(process.env.NOTIFY_FILE);
(async () => {
  try {
    if (typeof mod.sendNotify === "function") {
      await mod.sendNotify(process.env.NOTIFY_TITLE, process.env.NOTIFY_BODY);
    } else if (typeof mod === "function") {
      await mod(process.env.NOTIFY_TITLE, process.env.NOTIFY_BODY);
    } else {
      process.exit(2);
    }
  } catch (e) {
    process.exit(3);
  }
})();
' >/dev/null 2>&1; then
          return 0
        fi
      fi
    done
  fi

  # 2) Bark（兼容青龙 BARK_PUSH / BARK_URL，也兼容旧的 BARK_URL）
  bark_base="${BARK_URL:-}"
  if [ -z "$bark_base" ] && [ -n "${BARK_PUSH:-}" ]; then
    case "$BARK_PUSH" in
      http://*|https://*) bark_base="$BARK_PUSH" ;;
      *) bark_base="https://api.day.app/$BARK_PUSH" ;;
    esac
  fi
  if [ -n "$bark_base" ]; then
    curl -fsS -G \
      --data-urlencode "title=$title" \
      --data-urlencode "body=$body" \
      "$bark_base" >/dev/null 2>&1 && return 0
  fi

  # 3) Telegram（兼容青龙 TG_USER_ID，也兼容旧的 TG_CHAT_ID）
  tg_chat_id="${TG_CHAT_ID:-${TG_USER_ID:-}}"
  if [ -n "${TG_BOT_TOKEN:-}" ] && [ -n "$tg_chat_id" ]; then
    api="https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage"
    curl -fsS -X POST "$api" \
      --data-urlencode "chat_id=$tg_chat_id" \
      --data-urlencode "text=$title
$body" >/dev/null 2>&1 && return 0
  fi

  # 4) PushPlus
  if [ -n "${PUSH_PLUS_TOKEN:-}" ]; then
    title_json=$(printf '%s' "$title" | sed 's/\\/\\\\/g; s/"/\\"/g')
    content_json=$(printf '%s\n%s' "$title" "$body" | sed ':a;N;$!ba;s/\n/<br>/g' | sed 's/\\/\\\\/g; s/"/\\"/g')
    curl -fsS -X POST 'http://www.pushplus.plus/send' \
      -H 'Content-Type: application/json' \
      -d "{\"token\":\"${PUSH_PLUS_TOKEN}\",\"title\":\"${title_json}\",\"content\":\"${content_json}\",\"template\":\"html\"}" >/dev/null 2>&1 && return 0
  fi

  # 5) 企业微信机器人
  if [ -n "${QYWX_KEY:-}" ]; then
    text_json=$(printf '%s\n%s' "$title" "$body" | sed 's/\\/\\\\/g; s/"/\\"/g')
    curl -fsS -X POST "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=${QYWX_KEY}" \
      -H 'Content-Type: application/json' \
      -d "{\"msgtype\":\"text\",\"text\":{\"content\":\"${text_json}\"}}" >/dev/null 2>&1 && return 0
  fi

  # 6) 钉钉机器人
  if [ -n "${DD_BOT_TOKEN:-}" ]; then
    text_json=$(printf '%s\n%s' "$title" "$body" | sed 's/\\/\\\\/g; s/"/\\"/g')
    url="https://oapi.dingtalk.com/robot/send?access_token=${DD_BOT_TOKEN}"
    curl -fsS -X POST "$url" \
      -H 'Content-Type: application/json' \
      -d "{\"msgtype\":\"text\",\"text\":{\"content\":\"${text_json}\"}}" >/dev/null 2>&1 && return 0
  fi

  printf '%s\n%s\n' "$title" "$body"
}
