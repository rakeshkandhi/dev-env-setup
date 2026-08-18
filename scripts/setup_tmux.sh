#!/usr/bin/env bash
# ==============================================================================
# setup_tmux.sh — tmux Configuration & TPM Setup
# ==============================================================================
# • Symlinks repo tmux.conf     → ~/.config/tmux/tmux.conf
# • Symlinks repo themes/       → ~/.config/tmux/themes
# • Creates legacy symlink       → ~/.tmux.conf → ~/.config/tmux/tmux.conf
# • Installs TPM (Tmux Plugin Manager)
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
TMUX_CONFIG_DIR="${HOME}/.config/tmux"
TMUX_LEGACY="${HOME}/.tmux.conf"
TPM_DIR="${HOME}/.tmux/plugins/tpm"
TPM_REPO="https://github.com/tmux-plugins/tpm"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

# Source files in the repo
REPO_TMUX_CONF="${REPO_DIR}/tmux/tmux.conf"
REPO_TMUX_THEMES="${REPO_DIR}/tmux/themes"

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
    _info "Setting up tmux configuration …"

    # Ensure the tmux config directory exists
    mkdir -p "${TMUX_CONFIG_DIR}"

    # 1. Symlink tmux.conf
    if [[ -f "${REPO_TMUX_CONF}" ]]; then
        safe_symlink "${REPO_TMUX_CONF}" "${TMUX_CONFIG_DIR}/tmux.conf"
    else
        _warn "tmux.conf not found at ${REPO_TMUX_CONF} — skipping"
    fi

    # 2. Symlink themes directory
    if [[ -d "${REPO_TMUX_THEMES}" ]]; then
        safe_symlink "${REPO_TMUX_THEMES}" "${TMUX_CONFIG_DIR}/themes"
    else
        _warn "tmux themes directory not found at ${REPO_TMUX_THEMES} — skipping"
    fi

    # 3. Legacy ~/.tmux.conf symlink (points to the XDG config)
    safe_symlink "${TMUX_CONFIG_DIR}/tmux.conf" "${TMUX_LEGACY}"

    # 4. Install tmux-sessionizer helper to ~/.local/bin
    mkdir -p "${HOME}/.local/bin"
    if [[ -f "${SCRIPT_DIR}/tmux_sessionizer.sh" ]]; then
        chmod +x "${SCRIPT_DIR}/tmux_sessionizer.sh"
        safe_symlink "${SCRIPT_DIR}/tmux_sessionizer.sh" "${HOME}/.local/bin/tmux-sessionizer"
    fi

    # 4. Install TPM
    if [[ -d "${TPM_DIR}/.git" ]]; then
        _ok "TPM already installed at ${TPM_DIR}"
        _info "Updating TPM …"
        git -C "${TPM_DIR}" pull --rebase --quiet
        _ok "TPM updated"
        if [[ "${UPDATE_MODE:-false}" == true && -f "${TPM_DIR}/bin/update_plugins" ]]; then
            _info "Updating tmux plugins via TPM …"
            "${TPM_DIR}/bin/update_plugins" all || true
            _ok "tmux plugins updated"
        fi
    else
        if [[ -d "${TPM_DIR}" ]]; then
            _warn "TPM directory exists but is not a git repo — backing up"
            mv "${TPM_DIR}" "${TPM_DIR}.backup.${TIMESTAMP}"
        fi
        _info "Cloning TPM → ${TPM_DIR} …"
        mkdir -p "$(dirname "${TPM_DIR}")"
        git clone "${TPM_REPO}" "${TPM_DIR}" --quiet
        _ok "TPM installed"
    fi

    # 5. Auto-install plugins non-interactively via TPM
    if [[ -f "${TPM_DIR}/bin/install_plugins" ]]; then
        _info "Installing tmux plugins non-interactively via TPM …"
        "${TPM_DIR}/bin/install_plugins" || true
        _ok "tmux plugins installed"
    fi

    _ok "tmux setup complete"
}

main "$@"
