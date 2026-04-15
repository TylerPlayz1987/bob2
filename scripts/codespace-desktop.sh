#!/usr/bin/env bash
set -euo pipefail

PORT="${DESKTOP_PORT:-6080}"
VNC_PORT="${VNC_PORT:-5901}"

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

port_is_listening() {
  local port="$1"

  if has_cmd ss; then
    ss -ltn | awk '{print $4}' | grep -Eq "[:.]${port}$"
    return
  fi

  if has_cmd netstat; then
    netstat -ltn 2>/dev/null | awk '{print $4}' | grep -Eq "[:.]${port}$"
    return
  fi

  return 1
}

novnc_is_listening() {
  port_is_listening "$PORT"
}

vnc_is_listening() {
  port_is_listening "$VNC_PORT"
}

desktop_url() {
  if [[ -n "${CODESPACE_NAME:-}" && -n "${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-}" ]]; then
    printf 'https://%s-%s.%s\n' "$CODESPACE_NAME" "$PORT" "$GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN"
    return
  fi

  printf 'Open the Ports panel in Codespaces and open port %s.\n' "$PORT"
}

try_start_desktop() {
  # Try common start commands used by desktop-lite images.
  local candidates=(
    "desktop-lite start"
    "start-desktop"
    "supervisorctl start novnc"
    "supervisorctl start xvfb"
    "supervisorctl start x11vnc"
  )

  local cmd
  for cmd in "${candidates[@]}"; do
    if eval "$cmd" >/dev/null 2>&1; then
      return 0
    fi
  done

  return 1
}

try_start_vnc_backend() {
  if ! has_cmd tigervncserver; then
    return 1
  fi

  tigervncserver -kill :1 >/dev/null 2>&1 || true
  tigervncserver :1 -geometry 1440x768 -depth 16 -rfbport "$VNC_PORT" -dpi 96 -localhost -desktop fluxbox -SecurityTypes None >/dev/null 2>&1
}

print_status() {
  if novnc_is_listening && vnc_is_listening; then
    echo "Desktop noVNC is listening on port ${PORT}."
    echo "Desktop VNC backend is listening on port ${VNC_PORT}."
    echo "Desktop URL: $(desktop_url)"
  elif novnc_is_listening; then
    echo "Desktop noVNC is listening on port ${PORT}, but VNC backend is down on port ${VNC_PORT}."
    echo "Run: ./scripts/codespace-desktop.sh start"
  else
    echo "Desktop noVNC is not currently listening on port ${PORT}."
    echo "Run: ./scripts/codespace-desktop.sh start"
  fi
}

start_and_wait() {
  if novnc_is_listening && vnc_is_listening; then
    echo "Desktop noVNC is already running on port ${PORT}."
    echo "Desktop URL: $(desktop_url)"
    return 0
  fi

  echo "Attempting to start desktop services..."
  try_start_desktop || true
  vnc_is_listening || try_start_vnc_backend || true

  local i
  for i in $(seq 1 20); do
    if novnc_is_listening && vnc_is_listening; then
      echo "Desktop noVNC is now available on port ${PORT}."
      echo "Desktop VNC backend is now available on port ${VNC_PORT}."
      echo "Desktop URL: $(desktop_url)"
      return 0
    fi
    sleep 1
  done

  echo "Desktop did not come up on port ${PORT}." >&2
  echo "Check README troubleshooting in this repository." >&2
  return 1
}

case "${1:-status}" in
  status)
    print_status
    ;;
  start)
    start_and_wait
    ;;
  url)
    echo "$(desktop_url)"
    ;;
  *)
    echo "Usage: $0 [status|start|url]"
    exit 2
    ;;
esac
