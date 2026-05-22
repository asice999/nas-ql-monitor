#!/bin/sh
set -eu

STATE_DIR_DEFAULT=$(cd "$(dirname "$0")" && pwd)/.state
STATE_DIR=${STATE_DIR:-$STATE_DIR_DEFAULT}
mkdir -p "$STATE_DIR"
EVENT_LOG="$STATE_DIR/alert_events.log"

state_file_for() {
  key="$1"
  safe=$(printf '%s' "$key" | tr '/ :|' '____' | tr -cd 'A-Za-z0-9._-')
  printf '%s/%s.state' "$STATE_DIR" "$safe"
}

state_get() {
  key="$1"
  file=$(state_file_for "$key")
  [ -f "$file" ] && cat "$file" || true
}

state_set() {
  key="$1"
  value="$2"
  file=$(state_file_for "$key")
  printf '%s' "$value" > "$file"
}

log_event() {
  key="$1"
  status="$2"
  title="$3"
  body="$4"
  ts=$(date '+%Y-%m-%d %H:%M:%S')
  one_line=$(printf '%s' "$body" | tr '\n' ' ' | sed 's/  */ /g' | cut -c1-240)
  printf '%s | %s | %s | %s | %s\n' "$ts" "$key" "$status" "$title" "$one_line" >> "$EVENT_LOG"
  tail -n 200 "$EVENT_LOG" > "$EVENT_LOG.tmp" && mv "$EVENT_LOG.tmp" "$EVENT_LOG"
}

notify_on_change() {
  key="$1"
  current="$2"
  alert_title="$3"
  alert_body="$4"
  ok_title="$5"
  ok_body="$6"

  previous=$(state_get "$key")

  if [ "$current" = "alert" ]; then
    if [ "$previous" != "alert" ]; then
      notify "$alert_title" "$alert_body"
      log_event "$key" alert "$alert_title" "$alert_body"
    fi
    state_set "$key" alert
    return 1
  fi

  if [ "$previous" = "alert" ]; then
    notify "$ok_title" "$ok_body"
    log_event "$key" ok "$ok_title" "$ok_body"
  fi
  state_set "$key" ok
  return 0
}
