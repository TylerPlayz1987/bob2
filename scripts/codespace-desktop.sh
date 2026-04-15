#!/usr/bin/env bash
set -euo pipefail

PORT="${DESKTOP_PORT:-6080}"

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

port_is_listening() {
  if has_cmd ss; then
    ss -ltn | awk '{print $4}' | grep -Eq "[:.]${PORT}$"
    return
  fi

  if has_cmd netstat; then
    netstat -ltn 2>/dev/null | awk '{print $4}' | grep -Eq "[:.]${PORT}$"
    return
  fi

  return 1
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

print_status() {
  if port_is_listening; then
    echo "Desktop noVNC is listening on port ${PORT}."
    echo "Desktop URL: $(desktop_url)"
  else
    echo "Desktop noVNC is not currently listening on port ${PORT}."
    echo "Run: ./scripts/codespace-desktop.sh start"
  fi
}

start_and_wait() {
  if port_is_listening; then
    echo "Desktop noVNC is already running on port ${PORT}."
    echo "Desktop URL: $(desktop_url)"
    return 0
  fi

  echo "Attempting to start desktop services..."
  try_start_desktop || true

  local i
  for i in $(seq 1 20); do
    if port_is_listening; then
      echo "Desktop noVNC is now available on port ${PORT}."
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
