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
#
# After a successful clone/pull, bootstraps the config headlessly so its
# vim.pack plugins (and the treesitter parsers / fzf-native build that
# vim.pack can't run for you) are ready before the user's first launch.
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
NVIM_REPO_SSH="git@github.com:rakeshkandhi/nvim.git"
NVIM_REPO_HTTPS="https://github.com/rakeshkandhi/nvim.git"
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

# Normalise git URLs for comparison (strip protocol prefix, .git suffix, lowercase)
normalise_url() {
    local url="$1"
    url="${url%.git}"
    url="${url#git@github.com:}"
    url="${url#https://github.com/}"
    url="${url#http://github.com/}"
    echo "${url}" | tr '[:upper:]' '[:lower:]'
}

# Create a timestamped backup of a directory
backup_dir() {
    local src="$1"
    local backup="${src}.backup.${TIMESTAMP}"
    _warn "Backing up ${src} → ${backup}"
    mv "${src}" "${backup}"
}

# Headlessly install vim.pack plugins + build steps vim.pack doesn't run itself
bootstrap_plugins() {
    if ! command -v nvim &>/dev/null; then
        _warn "nvim not on PATH — skipping plugin bootstrap (run nvim once manually)"
        return 0
    fi

    _info "Bootstrapping plugins (vim.pack.add, treesitter parsers) …"
    if ! nvim --headless "+qa" 2>/tmp/nvim_bootstrap.log; then
        _warn "Headless plugin bootstrap reported an issue — see /tmp/nvim_bootstrap.log"
    fi
    nvim --headless -c "TSUpdate" -c "qa" 2>>/tmp/nvim_bootstrap.log || true

    local fzf_native_dir="${NVIM_CONFIG_DIR}/pack/core/opt/telescope-fzf-native.nvim"
    [[ -d "${fzf_native_dir}" ]] || fzf_native_dir="$(find "${HOME}/.local/share/nvim/site/pack" -maxdepth 4 -type d -name 'telescope-fzf-native.nvim' 2>/dev/null | head -1)"
    if [[ -n "${fzf_native_dir}" && -d "${fzf_native_dir}" ]]; then
        _info "Building telescope-fzf-native …"
        (cd "${fzf_native_dir}" && make) &>/tmp/nvim_bootstrap.log || _warn "telescope-fzf-native build failed — see /tmp/nvim_bootstrap.log"
    fi

    _ok "Plugin bootstrap complete"
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

            if [[ "$(normalise_url "${current_remote}")" == "$(normalise_url "${NVIM_REPO_SSH}")" ]]; then
                _info "Existing nvim config points to the correct repo — pulling latest …"
                # --autostash: the tree can be dirty (e.g. local plugin-state edits),
                # so stash around the rebase and reapply.
                if git -C "${NVIM_CONFIG_DIR}" pull --rebase --autostash --quiet; then
                    _ok "Neovim config updated (git pull)"
                    bootstrap_plugins
                    return 0
                fi
                _err "git pull failed in ${NVIM_CONFIG_DIR} — resolve it manually (git -C ${NVIM_CONFIG_DIR} status)"
                return 1
            else
                _warn "Existing nvim config points to a different remote: ${current_remote}"
                backup_dir "${NVIM_CONFIG_DIR}"
            fi
        else
            _warn "~/.config/nvim exists but is not a git repo"
            backup_dir "${NVIM_CONFIG_DIR}"
        fi
    fi

    _info "Cloning Neovim configuration → ${NVIM_CONFIG_DIR} …"
    if git clone "${NVIM_REPO_SSH}" "${NVIM_CONFIG_DIR}" 2>/dev/null; then
        _ok "Neovim configuration installed (via SSH)"
    else
        _warn "SSH clone failed (git@github.com:rakeshkandhi/nvim.git). Falling back to HTTPS …"
        if git clone "${NVIM_REPO_HTTPS}" "${NVIM_CONFIG_DIR}"; then
            _ok "Neovim configuration installed (via HTTPS fallback)"
        else
            _err "Failed to clone Neovim repository via SSH or HTTPS"
            return 1
        fi
    fi

    bootstrap_plugins
}

main "$@"
