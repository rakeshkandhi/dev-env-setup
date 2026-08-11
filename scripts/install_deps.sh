#!/usr/bin/env bash
# ==============================================================================
# install_deps.sh — Install Dependencies
# ==============================================================================
# Installs required packages via the appropriate package manager.
# Expects OS_TYPE & PKG_MANAGER to be set (source detect_os.sh first).
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
# Source OS detection if variables are missing
# ---------------------------------------------------------------------------
if [[ -z "${OS_TYPE:-}" || -z "${PKG_MANAGER:-}" ]]; then
    # shellcheck disable=SC1091
    source "${SCRIPT_DIR}/detect_os.sh"
fi

# ---------------------------------------------------------------------------
# Package lists
# ---------------------------------------------------------------------------
# Common packages across all platforms
COMMON_PKGS=(git curl wget tmux neovim ripgrep fzf fd lazygit)

# macOS-only (via Homebrew)
BREW_EXTRAS=(node lua luarocks)

# Linux-only extras
LINUX_EXTRAS=(build-essential unzip fontconfig)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
is_installed() {
    command -v "$1" &>/dev/null
}

install_homebrew() {
    if is_installed brew; then
        _ok "Homebrew already installed"
        return 0
    fi
    _info "Installing Homebrew …"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    _ok "Homebrew installed"
}

# ---------------------------------------------------------------------------
# Install via Homebrew (macOS)
# ---------------------------------------------------------------------------
install_with_brew() {
    install_homebrew

    _info "Updating Homebrew …"
    brew update --quiet

    local pkgs=("${COMMON_PKGS[@]}" "${BREW_EXTRAS[@]}")
    local to_install=()

    for pkg in "${pkgs[@]}"; do
        if brew list --formula "${pkg}" &>/dev/null || is_installed "${pkg}"; then
            _ok "${pkg} — already installed"
        else
            to_install+=("${pkg}")
        fi
    done

    if [[ ${#to_install[@]} -eq 0 ]]; then
        _ok "All Homebrew packages already installed"
        return 0
    fi

    _info "Installing: ${to_install[*]}"
    brew install "${to_install[@]}"
    _ok "Homebrew packages installed"
}

# ---------------------------------------------------------------------------
# Install via apt (Ubuntu / Debian)
# ---------------------------------------------------------------------------
install_with_apt() {
    _info "Updating apt cache …"
    sudo apt update -qq

    local pkgs=("${COMMON_PKGS[@]}" "${LINUX_EXTRAS[@]}" nodejs npm)
    local to_install=()

    # apt uses different names for some packages
    declare -A apt_names=(
        [neovim]="neovim"
        [ripgrep]="ripgrep"
        [fd]="fd-find"
    )

    for pkg in "${pkgs[@]}"; do
        local apt_pkg="${apt_names[${pkg}]:-${pkg}}"
        if dpkg -l "${apt_pkg}" 2>/dev/null | grep -q '^ii'; then
            _ok "${apt_pkg} — already installed"
        else
            to_install+=("${apt_pkg}")
        fi
    done

    if [[ ${#to_install[@]} -eq 0 ]]; then
        _ok "All apt packages already installed"
        return 0
    fi

    _info "Installing: ${to_install[*]}"
    sudo apt install -y "${to_install[@]}"
    _ok "apt packages installed"

    # lazygit (not in default Ubuntu repos)
    if ! is_installed lazygit; then
        _info "Installing lazygit from GitHub releases …"
        local lg_version
        lg_version="$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')"
        curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${lg_version}/lazygit_${lg_version}_Linux_x86_64.tar.gz" | sudo tar xz -C /usr/local/bin lazygit
        _ok "lazygit installed"
    fi
}

# ---------------------------------------------------------------------------
# Install via dnf (Fedora)
# ---------------------------------------------------------------------------
install_with_dnf() {
    local pkgs=("${COMMON_PKGS[@]}" "${LINUX_EXTRAS[@]}" nodejs)
    # Remove build-essential (Fedora uses @development-tools)
    pkgs=("${pkgs[@]/build-essential/}")

    local to_install=()

    declare -A dnf_names=(
        [fd]="fd-find"
    )

    for pkg in "${pkgs[@]}"; do
        [[ -z "${pkg}" ]] && continue
        local dnf_pkg="${dnf_names[${pkg}]:-${pkg}}"
        if rpm -q "${dnf_pkg}" &>/dev/null || is_installed "${pkg}"; then
            _ok "${dnf_pkg} — already installed"
        else
            to_install+=("${dnf_pkg}")
        fi
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        _info "Installing: ${to_install[*]}"
        sudo dnf install -y "${to_install[@]}"
        _ok "dnf packages installed"
    else
        _ok "All dnf packages already installed"
    fi

    # lazygit via copr
    if ! is_installed lazygit; then
        _info "Installing lazygit via COPR …"
        sudo dnf copr enable -y atim/lazygit
        sudo dnf install -y lazygit
        _ok "lazygit installed"
    fi
}

# ---------------------------------------------------------------------------
# Install via pacman (Arch)
# ---------------------------------------------------------------------------
install_with_pacman() {
    local pkgs=("${COMMON_PKGS[@]}" base-devel unzip fontconfig nodejs npm)
    # Remove build-essential (Arch uses base-devel)
    pkgs=("${pkgs[@]/build-essential/}")

    local to_install=()

    for pkg in "${pkgs[@]}"; do
        [[ -z "${pkg}" ]] && continue
        if pacman -Qi "${pkg}" &>/dev/null; then
            _ok "${pkg} — already installed"
        else
            to_install+=("${pkg}")
        fi
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        _info "Installing: ${to_install[*]}"
        sudo pacman -S --noconfirm --needed "${to_install[@]}"
        _ok "pacman packages installed"
    else
        _ok "All pacman packages already installed"
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
    _info "Installing dependencies (PKG_MANAGER=${PKG_MANAGER}) …"

    case "${PKG_MANAGER}" in
        brew)   install_with_brew   ;;
        apt)    install_with_apt    ;;
        dnf)    install_with_dnf    ;;
        pacman) install_with_pacman ;;
        *)
            _err "Unsupported package manager: ${PKG_MANAGER}"
            exit 1
            ;;
    esac

    _ok "Dependency installation complete"
}

main "$@"
