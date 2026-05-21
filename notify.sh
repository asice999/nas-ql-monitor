#!/bin/sh
set -eu

# 通用通知：优先 Bark，其次 Telegram，最后打印到 stdout
notify() {
  title="$1"
  body="$2"

  if [ -n "${BARK_URL:-}" ]; then
    curl -fsS -G --data-urlencode "title=$title" --data-urlencode "body=$body" "$BARK_URL" >/dev/null && return 0
  fi

  if [ -n "${TG_BOT_TOKEN:-}" ] && [ -n "${TG_CHAT_ID:-}" ]; then
    api="https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage"
    curl -fsS -X POST "$api" \
      -d chat_id="$TG_CHAT_ID" \
      -d text="${title}%0A${body}" >/dev/null && return 0
  fi

  printf '%s\n%s\n' "$title" "$body"
}
