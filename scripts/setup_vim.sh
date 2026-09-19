#!/usr/bin/env bash
# ==============================================================================
# setup_vim.sh — Vim Configuration Setup
# ==============================================================================
# Symlinks repo vim/vimrc → ~/.vimrc
#
# Handles an existing ~/.vimrc:
#   • Already the correct symlink → no-op
#   • Stale symlink               → replace
#   • Regular file / directory    → timestamped backup, then symlink
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
VIM_RC_DST="${HOME}/.vimrc"
REPO_VIMRC="${REPO_DIR}/vim/vimrc"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

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
    _info "Setting up Vim configuration …"

    if [[ ! -f "${REPO_VIMRC}" ]]; then
        _err "Vim config not found at ${REPO_VIMRC}"
        return 1
    fi

    safe_symlink "${REPO_VIMRC}" "${VIM_RC_DST}"

    _ok "Vim setup complete"
}

main "$@"
