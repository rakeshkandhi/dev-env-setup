#!/usr/bin/env bash
# ==============================================================================
# setup_alacritty.sh — Alacritty Configuration Setup
# ==============================================================================
# Symlinks the repo's alacritty config directory → ~/.config/alacritty/
#
# Repo layout expected:
#   alacritty/
#     alacritty.toml
#     themes/
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
ALACRITTY_CONFIG_DIR="${HOME}/.config/alacritty"
REPO_ALACRITTY_DIR="${REPO_DIR}/alacritty"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Safely create a symlink, backing up any existing target
safe_symlink() {
    local src="$1"
    local dst="$2"

    if [[ ! -e "${src}" ]]; then
        _err "Source does not exist: ${src}"
        return 1
    fi

    if [[ -L "${dst}" ]]; then
        local current_target
        current_target="$(readlink "${dst}")"
        if [[ "${current_target}" == "${src}" ]]; then
            _ok "Symlink already correct: ${dst} → ${src}"
            return 0
        fi
        _warn "Removing stale symlink: ${dst} → ${current_target}"
        rm "${dst}"
    elif [[ -e "${dst}" ]]; then
        local backup="${dst}.backup.${TIMESTAMP}"
        _warn "Backing up existing ${dst} → ${backup}"
        mv "${dst}" "${backup}"
    fi

    ln -s "${src}" "${dst}"
    _ok "Symlinked ${dst} → ${src}"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
    _info "Setting up Alacritty configuration …"

    # Verify source config exists
    if [[ ! -d "${REPO_ALACRITTY_DIR}" ]]; then
        _warn "Alacritty config directory not found at ${REPO_ALACRITTY_DIR}"
        _warn "Create your alacritty/ directory in the repo first — skipping"
        return 0
    fi

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
