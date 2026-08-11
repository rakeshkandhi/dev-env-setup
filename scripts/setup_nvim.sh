#!/usr/bin/env bash
# ==============================================================================
# setup_nvim.sh — Neovim Configuration Setup
# ==============================================================================
# Clones git@github.com:rakeshkandhi/nvim.git → ~/.config/nvim
#
# Handles existing directories:
#   • Same remote  → git pull
#   • Different    → timestamped backup + fresh clone
#   • Not a repo   → timestamped backup + fresh clone
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
NVIM_REPO="git@github.com:rakeshkandhi/nvim.git"
NVIM_CONFIG_DIR="${HOME}/.config/nvim"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Get the origin remote URL of a git repo
get_remote_url() {
    local dir="$1"
    git -C "${dir}" remote get-url origin 2>/dev/null || echo ""
}

# Normalise git URLs for comparison (strip .git suffix, lowercase)
normalise_url() {
    local url="$1"
    url="${url%.git}"
    echo "${url}" | tr '[:upper:]' '[:lower:]'
}

# Create a timestamped backup of a directory
backup_dir() {
    local src="$1"
    local backup="${src}.backup.${TIMESTAMP}"
    _warn "Backing up ${src} → ${backup}"
    mv "${src}" "${backup}"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
    _info "Setting up Neovim configuration …"

    # Ensure ~/.config exists
    mkdir -p "${HOME}/.config"

    if [[ -d "${NVIM_CONFIG_DIR}" ]]; then
        if [[ -d "${NVIM_CONFIG_DIR}/.git" ]]; then
            local current_remote
            current_remote="$(get_remote_url "${NVIM_CONFIG_DIR}")"

            if [[ "$(normalise_url "${current_remote}")" == "$(normalise_url "${NVIM_REPO}")" ]]; then
                _info "Existing nvim config points to the correct repo — pulling latest …"
                git -C "${NVIM_CONFIG_DIR}" pull --rebase --quiet
                _ok "Neovim config updated (git pull)"
                return 0
            else
                _warn "Existing nvim config points to a different remote: ${current_remote}"
                backup_dir "${NVIM_CONFIG_DIR}"
            fi
        else
            _warn "~/.config/nvim exists but is not a git repo"
            backup_dir "${NVIM_CONFIG_DIR}"
        fi
    fi

    _info "Cloning ${NVIM_REPO} → ${NVIM_CONFIG_DIR} …"
    git clone "${NVIM_REPO}" "${NVIM_CONFIG_DIR}"
    _ok "Neovim configuration installed"
}

main "$@"
