#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 /path/to/package.deb" >&2
  exit 2
fi

input_path="$1"

if [[ ! -f "$input_path" ]]; then
  echo "File not found: $input_path" >&2
  exit 1
fi

if [[ "${input_path##*.}" != "deb" ]]; then
  echo "Expected a .deb file: $input_path" >&2
  exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
  echo "sudo is required but not found." >&2
  exit 1
fi

abs_path="$(readlink -f "$input_path")"
file_name="$(basename "$abs_path")"
tmp_path="/tmp/$file_name"

echo "Copying $abs_path to $tmp_path"
cp "$abs_path" "$tmp_path"
chmod 644 "$tmp_path"

echo "Installing $tmp_path"
sudo apt-get update
sudo apt-get install -y "$tmp_path"

echo "Install complete."
