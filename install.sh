#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./install.sh [--force]

Installs the bundled G615JPR ASUS Aura support files with sudo, backs up the
current target files, and restarts asusd.

Options:
  --force   allow install on boards other than G615JPR
  --help    show this help
EOF
}

force=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      force=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
files_dir="$script_dir/files"
support_src="$files_dir/aura_support.ron"
config_src="$files_dir/aura_19b6.ron"

support_dst="/usr/share/asusd/aura_support.ron"
config_dst="/etc/asusd/aura_19b6.ron"

board_name="$(cat /sys/devices/virtual/dmi/id/board_name 2>/dev/null || true)"
product_name="$(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || true)"

if [[ ! -f "$support_src" || ! -f "$config_src" ]]; then
  echo "Missing bundled files in $files_dir" >&2
  exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
  echo "sudo is required" >&2
  exit 1
fi

if ! command -v systemctl >/dev/null 2>&1; then
  echo "systemctl is required" >&2
  exit 1
fi

if [[ "$board_name" != "G615JPR" && "$force" -ne 1 ]]; then
  echo "Refusing to install on board '$board_name' ($product_name)." >&2
  echo "This bundle is intended for G615JPR. Re-run with --force if you want to override." >&2
  exit 1
fi

timestamp="$(date +%Y%m%d-%H%M%S)"
backup_dir="/var/tmp/g615-lightbar-backup-$timestamp"

echo "Board: ${board_name:-unknown}"
echo "Product: ${product_name:-unknown}"
echo "Backup dir: $backup_dir"

sudo mkdir -p "$backup_dir"
sudo cp "$support_dst" "$backup_dir/aura_support.ron"

if [[ -f "$config_dst" ]]; then
  sudo cp "$config_dst" "$backup_dir/aura_19b6.ron"
fi

sudo install -m 0644 "$support_src" "$support_dst"
sudo install -m 0644 "$config_src" "$config_dst"
sudo systemctl restart asusd

echo
echo "Installed files:"
sha256sum "$support_src" "$config_src"

echo
echo "Latest asusd log tail:"
sudo journalctl -b -u asusd --no-pager | tail -n 40

echo
echo "Done. If you need to roll back, restore the files from:"
echo "  $backup_dir"
