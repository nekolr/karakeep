#!/usr/bin/env bash

set -Eeuo pipefail

DISPLAY="${DISPLAY:-:99}"
DESKTOP_SIZE="${CHROME_DESKTOP_SIZE:-1440x900x24}"
CHROME_WINDOW_SIZE="${CHROME_WINDOW_SIZE:-1440,900}"
CHROME_REMOTE_DEBUGGING_PORT="${CHROME_REMOTE_DEBUGGING_PORT:-9222}"
CHROME_INTERNAL_DEBUGGING_PORT="${CHROME_INTERNAL_DEBUGGING_PORT:-9223}"
CHROME_PROFILE_DIR="${CHROME_PROFILE_DIR:-/tmp/chrome-profile}"
CHROME_START_URL="${CHROME_START_URL:-about:blank}"
CHROME_VNC_PORT="${CHROME_VNC_PORT:-5900}"
CHROME_NOVNC_PORT="${CHROME_NOVNC_PORT:-6080}"
CHROME_PROXY_SERVER="${CHROME_PROXY_SERVER:-}"
CHROME_PROXY_BYPASS_LIST="${CHROME_PROXY_BYPASS_LIST:-}"
CHROME_PROXY_PAC_URL="${CHROME_PROXY_PAC_URL:-}"
CHROME_DISABLE_SANDBOX="${CHROME_DISABLE_SANDBOX:-false}"
ENABLE_VNC="${ENABLE_VNC:-true}"
ENABLE_NOVNC="${ENABLE_NOVNC:-true}"
NOVNC_WEB_ROOT="${NOVNC_WEB_ROOT:-/usr/share/novnc}"
DISPLAY_NUMBER="${DISPLAY#:}"
DISPLAY_SOCKET="/tmp/.X11-unix/X${DISPLAY_NUMBER}"
DISPLAY_LOCK="/tmp/.X${DISPLAY_NUMBER}-lock"

declare -a BACKGROUND_PIDS=()

cleanup() {
  for pid in "${BACKGROUND_PIDS[@]:-}"; do
    if kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
    fi
  done
}

wait_for_x_display() {
  local retries=50

  for ((i=0; i<retries; i++)); do
    if [[ -S "$DISPLAY_SOCKET" ]]; then
      return 0
    fi

    if ! kill -0 "$XVFB_PID" 2>/dev/null; then
      echo "Xvfb exited before display ${DISPLAY} became ready" >&2
      return 1
    fi

    sleep 0.2
  done

  echo "Timed out waiting for X display ${DISPLAY}" >&2
  return 1
}

trap cleanup EXIT INT TERM

mkdir -p "$CHROME_PROFILE_DIR" /tmp/runtime-chrome /tmp/.X11-unix
chmod 700 /tmp/runtime-chrome
chmod 1777 /tmp/.X11-unix
rm -f "$DISPLAY_LOCK" "$DISPLAY_SOCKET"
export XDG_RUNTIME_DIR=/tmp/runtime-chrome
export DISPLAY

Xvfb "$DISPLAY" -screen 0 "$DESKTOP_SIZE" -ac -nolisten tcp +extension RANDR &
XVFB_PID="$!"
BACKGROUND_PIDS+=("$XVFB_PID")

wait_for_x_display

openbox-session &
BACKGROUND_PIDS+=("$!")

if [[ "$ENABLE_VNC" == "true" ]]; then
  x11vnc \
    -display "$DISPLAY" \
    -forever \
    -shared \
    -nopw \
    -rfbport "$CHROME_VNC_PORT" \
    -listen 0.0.0.0 \
    -xkb &
  BACKGROUND_PIDS+=("$!")

  if [[ "$ENABLE_NOVNC" == "true" ]]; then
    websockify --web="$NOVNC_WEB_ROOT" "$CHROME_NOVNC_PORT" "127.0.0.1:$CHROME_VNC_PORT" &
    BACKGROUND_PIDS+=("$!")
  fi
fi

socat TCP-LISTEN:"$CHROME_REMOTE_DEBUGGING_PORT",fork,reuseaddr,bind=0.0.0.0 TCP:127.0.0.1:"$CHROME_INTERNAL_DEBUGGING_PORT" &
BACKGROUND_PIDS+=("$!")

declare -a CHROME_ARGS=(
  "--disable-dev-shm-usage"
  "--disable-gpu"
  "--disable-software-rasterizer"
  "--hide-scrollbars"
  "--no-default-browser-check"
  "--no-first-run"
  "--password-store=basic"
  "--remote-debugging-address=127.0.0.1"
  "--remote-debugging-port=${CHROME_INTERNAL_DEBUGGING_PORT}"
  "--user-data-dir=${CHROME_PROFILE_DIR}"
  "--window-size=${CHROME_WINDOW_SIZE}"
)

if [[ "$CHROME_DISABLE_SANDBOX" == "true" ]]; then
  CHROME_ARGS+=("--no-sandbox")
fi

if [[ -n "$CHROME_PROXY_SERVER" ]]; then
  CHROME_ARGS+=("--proxy-server=${CHROME_PROXY_SERVER}")
fi

if [[ -n "$CHROME_PROXY_BYPASS_LIST" ]]; then
  CHROME_ARGS+=("--proxy-bypass-list=${CHROME_PROXY_BYPASS_LIST}")
fi

if [[ -n "$CHROME_PROXY_PAC_URL" ]]; then
  CHROME_ARGS+=("--proxy-pac-url=${CHROME_PROXY_PAC_URL}")
fi

if [[ -n "${CHROME_EXTRA_ARGS:-}" ]]; then
  # shellcheck disable=SC2206
  EXTRA_ARGS=( ${CHROME_EXTRA_ARGS} )
  CHROME_ARGS+=("${EXTRA_ARGS[@]}")
fi

google-chrome-stable "${CHROME_ARGS[@]}" "$CHROME_START_URL" &
CHROME_PID="$!"
wait "$CHROME_PID"