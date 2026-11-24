#!/usr/bin/env bash
# ==============================================================================
# setup_alacritty.sh — Alacritty Configuration Setup
# ==============================================================================
# Symlinks the repo's alacritty config directory → ~/.config/alacritty/
#
# Repo layout expected:
#   alacritty/
#     alacritty.toml
# Installs the Alacritty binary first if it is missing.
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ---------------------------------------------------------------------------
# Color helpers
# ---------------------------------------------------------------------------
_info()  { printf '\033[1;34m[INFO]\033[0m  %s\n' "$*"; }
_ok()    { printf '\033[1;32m[ OK ]\033[0m  %s\n' "$*"; }
_warn()  { printf '\033[1;33m[WARN]\033[0m  %s\n' "$*"; }
_err()   { printf '\033[1;31m[ ERR]\033[0m  %s\n' "$*"; }

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
ALACRITTY_CONFIG_DIR="${ALACRITTY_CONFIG_DIR:-"${HOME}/.config/alacritty"}"
REPO_ALACRITTY_DIR="${REPO_ALACRITTY_DIR:-"${REPO_DIR}/alacritty"}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

# Source OS detection if PKG_MANAGER is unset
if [[ -z "${OS_TYPE:-}" || -z "${PKG_MANAGER:-}" ]]; then
    if [[ -f "${SCRIPT_DIR}/detect_os.sh" ]]; then
        # shellcheck disable=SC1091
        source "${SCRIPT_DIR}/detect_os.sh"
    fi
fi

# ---------------------------------------------------------------------------
# Install Helpers
# ---------------------------------------------------------------------------
install_alacritty_binary() {
    if command -v alacritty &>/dev/null; then
        _ok "Alacritty binary is already installed"
        return 0
    fi

    _info "Installing Alacritty application binary …"
    case "${PKG_MANAGER:-}" in
        brew)
            brew install --cask alacritty || brew install alacritty
            ;;
        apt)
            sudo apt update -qq && sudo apt install -y alacritty
            ;;
        dnf)
            sudo dnf install -y alacritty
            ;;
        pacman)
            sudo pacman -S --noconfirm alacritty
            ;;
        *)
            _warn "Could not auto-install Alacritty binary for package manager '${PKG_MANAGER:-unknown}'. Please install manually."
            return 0
            ;;
    esac
    _ok "Alacritty binary installed"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
    if [[ "${SKIP_ALACRITTY:-false}" == true ]]; then
        _info "Skipping Alacritty setup (--no-alacritty specified)"
        return 0
    fi

    _info "Setting up Alacritty configuration …"

    if [[ ! -f "${REPO_ALACRITTY_DIR}/alacritty.toml" ]]; then
        _err "Alacritty config not found at ${REPO_ALACRITTY_DIR}/alacritty.toml"
        return 1
    fi

    install_alacritty_binary

    # Ensure parent directory exists
    mkdir -p "${HOME}/.config"

    # If the config dir is already a correct symlink, we're done
    if [[ -L "${ALACRITTY_CONFIG_DIR}" ]]; then
        local current_target
        current_target="$(readlink "${ALACRITTY_CONFIG_DIR}")"
        if [[ "${current_target}" == "${REPO_ALACRITTY_DIR}" ]]; then
            _ok "Alacritty config already symlinked correctly"
            return 0
        fi
        _warn "Removing stale symlink: ${ALACRITTY_CONFIG_DIR} → ${current_target}"
        rm "${ALACRITTY_CONFIG_DIR}"
    elif [[ -d "${ALACRITTY_CONFIG_DIR}" ]]; then
        local backup="${ALACRITTY_CONFIG_DIR}.backup.${TIMESTAMP}"
        _warn "Backing up existing config: ${ALACRITTY_CONFIG_DIR} → ${backup}"
        mv "${ALACRITTY_CONFIG_DIR}" "${backup}"
    fi

    # Symlink the entire alacritty config directory
    ln -s "${REPO_ALACRITTY_DIR}" "${ALACRITTY_CONFIG_DIR}"
    _ok "Symlinked ${ALACRITTY_CONFIG_DIR} → ${REPO_ALACRITTY_DIR}"

    _ok "Alacritty setup complete"
}

main "$@"
