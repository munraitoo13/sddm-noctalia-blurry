#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACTION="install"
AVATAR_PATH=""
PREVIEW=0

usage() {
    cat <<'EOF'
Usage: ./install.sh [OPTIONS]

Install, preview, or uninstall sddm-noctalia-blurry.

Options:
  --install          Install theme, sync CLI, systemd units, and SDDM drop-in (default)
  --preview          Sync assets locally and launch sddm-greeter-qt6 --test-mode
  --avatar <image>   Crop/mask <image> into avatar.png during install or preview
  --uninstall        Remove installed system files and disable user timer
  -h, --help         Show this help message
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --install)   ACTION="install" ;;
        --uninstall) ACTION="uninstall" ;;
        --preview)   PREVIEW=1 ;;
        --avatar)
            shift
            [ "$#" -gt 0 ] || { echo "Error: --avatar requires a path" >&2; exit 2; }
            AVATAR_PATH="$1"
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

run_as_root() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    elif command -v pkexec >/dev/null 2>&1; then
        pkexec "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        echo "Error: root privileges (pkexec or sudo) are required." >&2
        exit 1
    fi
}

if [ "$PREVIEW" -eq 1 ]; then
    command -v sddm-greeter-qt6 >/dev/null 2>&1 || { echo "Error: sddm-greeter-qt6 not found." >&2; exit 1; }
    sync_args=(--preview "$ROOT_DIR/theme" --force)
    if [ -n "$AVATAR_PATH" ]; then
        sync_args+=(--avatar "$AVATAR_PATH")
    fi
    "$ROOT_DIR/scripts/noctalia-sddm-sync" "${sync_args[@]}"
    exec sddm-greeter-qt6 --test-mode --theme "$ROOT_DIR/theme"
fi

if [ "$ACTION" = "uninstall" ]; then
    systemctl --user disable --now noctalia-sddm-sync.timer 2>/dev/null || true
    run_as_root bash -c "
        set -euo pipefail
        make -C '$ROOT_DIR' PREFIX=/usr uninstall
        rm -f /etc/sddm.conf.d/10-noctalia-blurry.conf
    "
    echo "Uninstalled sddm-noctalia-blurry. (/var/lib/noctalia-sddm was preserved; remove manually if desired.)"
    exit 0
fi

for cmd in make magick python3 sddm-greeter-qt6; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "Error: missing required command '$cmd'." >&2; exit 1; }
done

TARGET_USER="${SUDO_USER:-$USER}"
run_as_root bash -c "
    set -euo pipefail
    make -C '$ROOT_DIR' PREFIX=/usr install
    systemd-sysusers || true
    systemd-tmpfiles --create || true
    if id '$TARGET_USER' >/dev/null 2>&1; then
        usermod -aG noctalia-sddm '$TARGET_USER' 2>/dev/null || true
        chown -R '$TARGET_USER':noctalia-sddm /var/lib/noctalia-sddm 2>/dev/null || true
    fi
    chmod 2775 /var/lib/noctalia-sddm
    install -Dm644 '$ROOT_DIR/packaging/sddm.conf.d/10-noctalia-blurry.conf' /etc/sddm.conf.d/10-noctalia-blurry.conf
"

sync_args=(--force)
if [ -n "$AVATAR_PATH" ]; then
    sync_args+=(--avatar "$AVATAR_PATH")
fi
/usr/bin/noctalia-sddm-sync "${sync_args[@]}"

systemctl --user daemon-reload || true
systemctl --user enable --now noctalia-sddm-sync.timer || true

echo "Installed sddm-noctalia-blurry! Test with: sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/noctalia-blurry"
