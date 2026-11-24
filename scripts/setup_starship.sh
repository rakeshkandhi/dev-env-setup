#!/usr/bin/env bash
# ==============================================================================
# setup_starship.sh — Starship prompt (Linux only)
# ==============================================================================
# • Installs the starship binary if missing
# • Symlinks repo starship/starship.toml → ~/.config/starship.toml
#
# macOS is a no-op — Starship is only configured on Linux.
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
# Source OS detection if variables are missing
# ---------------------------------------------------------------------------
if [[ -z "${OS_TYPE:-}" ]]; then
    # shellcheck disable=SC1091
    source "${SCRIPT_DIR}/detect_os.sh"
fi

STARSHIP_CONFIG_DST="${HOME}/.config/starship.toml"
REPO_STARSHIP_TOML="${REPO_DIR}/starship/starship.toml"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

is_starship_installed() {
    command -v starship &>/dev/null || [[ -x "${HOME}/.local/bin/starship" ]]
}

install_starship_binary() {
    if is_starship_installed; then
        _ok "starship already installed ($(command -v starship 2>/dev/null || echo "${HOME}/.local/bin/starship"))"
        return 0
    fi

    _info "Installing starship …"

    case "${PKG_MANAGER:-}" in
        apt)
            if apt-cache show starship 2>/dev/null | grep -q '^Package: starship'; then
                if sudo apt install -y starship; then
                    _ok "starship installed via apt"
                    return 0
                fi
            fi
            ;;
        dnf)
            if sudo dnf install -y starship; then
                _ok "starship installed via dnf"
                return 0
            fi
            ;;
        pacman)
            if sudo pacman -S --noconfirm starship; then
                _ok "starship installed via pacman"
                return 0
            fi
            ;;
    esac

    _info "Installing starship via official installer → ~/.local/bin …"
    mkdir -p "${HOME}/.local/bin"
    if curl -sS https://starship.rs/install.sh | sh -s -- -b "${HOME}/.local/bin" -y; then
        _ok "starship installed to ${HOME}/.local/bin/starship"
    else
        _err "Failed to install starship"
        return 1
    fi
}

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
    if [[ "${OS_TYPE}" != "linux" ]]; then
        _info "Skipping Starship setup (Linux only; OS_TYPE=${OS_TYPE})"
        return 0
    fi

    _info "Setting up Starship prompt (LINUX_DISTRO=${LINUX_DISTRO:-unknown}) …"

    install_starship_binary

    if [[ -f "${REPO_STARSHIP_TOML}" ]]; then
        safe_symlink "${REPO_STARSHIP_TOML}" "${STARSHIP_CONFIG_DST}"
    else
        _err "Starship config not found at ${REPO_STARSHIP_TOML}"
        return 1
    fi

    _ok "Starship setup complete"
    _info "Prompt is activated by setup_shell.sh via: eval \"\$(starship init bash)\""
}

main "$@"
