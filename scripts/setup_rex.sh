#!/usr/bin/env bash
# ==============================================================================
# setup_rex.sh — Rex Terminal Multiplexer Configuration Setup
# ==============================================================================
# Symlinks repo rex/init.lua → ~/.config/rex/init.lua
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

REX_CONFIG_DIR="${HOME}/.config/rex"
REX_CONFIG_DST="${REX_CONFIG_DIR}/init.lua"
REPO_REX_LUA="${REPO_DIR}/rex/init.lua"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

safe_symlink() {
    local src="$1"
    local dst="$2"

    if [[ ! -e "${src}" ]]; then
        _err "Source does not exist: ${src}"
        return 1
    fi

    mkdir -p "$(dirname "${dst}")"

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

main() {
    _info "Setting up Rex configuration …"

    if [[ -f "${REPO_REX_LUA}" ]]; then
        safe_symlink "${REPO_REX_LUA}" "${REX_CONFIG_DST}"
    else
        _err "Rex config not found at ${REPO_REX_LUA}"
        return 1
    fi

    if command -v rex &>/dev/null; then
        _info "Reloading Rex configuration …"
        rex config reload 2>/dev/null || true
    fi

    _ok "Rex setup complete"
}

main "$@"
