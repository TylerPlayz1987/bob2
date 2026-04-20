#!/usr/bin/env bash
set -euo pipefail

DISPLAY="${DISPLAY:-:1}"
CONFIG_DIR="${HOME}/.config/codespace-desktop"
CONFIG_FILE="${CONFIG_DIR}/wallpaper.conf"
DEFAULT_COLOR="#1e1e1e"

ensure_config_dir() {
  mkdir -p "${CONFIG_DIR}"
}

set_dark_mode() {
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true
  gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' || true
  echo "Dark mode enabled."
}

set_light_mode() {
  gsettings set org.gnome.desktop.interface color-scheme 'default' || true
  gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita' || true
  echo "Light mode enabled."
}

set_solid_color() {
  local color="${1:-$DEFAULT_COLOR}"
  DISPLAY="${DISPLAY}" xsetroot -solid "${color}"

  ensure_config_dir
  {
    echo "COLOR=${color}"
  } > "${CONFIG_FILE}"

  echo "Solid background set to ${color}."
}

set_wallpaper() {
  local image_path="$1"

  if [[ ! -f "${image_path}" ]]; then
    echo "Image not found: ${image_path}" >&2
    exit 1
  fi

  if ! command -v feh >/dev/null 2>&1; then
    echo "feh is required to set image wallpapers. Install it with: sudo apt-get install -y feh" >&2
    exit 1
  fi

  DISPLAY="${DISPLAY}" feh --bg-fill "${image_path}"

  ensure_config_dir
  {
    echo "WALLPAPER=${image_path}"
  } > "${CONFIG_FILE}"

  echo "Wallpaper set to ${image_path}."
}

pick_wallpaper() {
  if ! command -v zenity >/dev/null 2>&1; then
    echo "zenity is not available. Use: $0 set-wallpaper /path/to/image" >&2
    exit 1
  fi

  local selected
  selected=$(zenity --file-selection --title="Choose Wallpaper" \
    --file-filter="Images | *.png *.jpg *.jpeg *.webp *.bmp") || exit 0

  set_wallpaper "${selected}"
}

usage() {
  cat <<'EOF'
Usage:
  desktop-appearance.sh dark
  desktop-appearance.sh light
  desktop-appearance.sh solid [#RRGGBB]
  desktop-appearance.sh pick-wallpaper
  desktop-appearance.sh set-wallpaper /absolute/path/to/image
EOF
}

main() {
  local cmd="${1:-}"

  case "${cmd}" in
    dark)
      set_dark_mode
      ;;
    light)
      set_light_mode
      ;;
    solid)
      set_solid_color "${2:-$DEFAULT_COLOR}"
      ;;
    pick-wallpaper)
      pick_wallpaper
      ;;
    set-wallpaper)
      if [[ -z "${2:-}" ]]; then
        usage
        exit 2
      fi
      set_wallpaper "${2}"
      ;;
    *)
      usage
      exit 2
      ;;
  esac
}

main "$@"
