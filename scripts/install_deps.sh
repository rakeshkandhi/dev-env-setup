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
# Neovim is intentionally excluded — it's installed separately by install_neovim()
# so we always get a current release instead of whatever an OS repo has cached.
COMMON_PKGS=(git curl wget tmux ripgrep fzf fd lazygit)

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

    local pkgs=("${COMMON_PKGS[@]}" "${BREW_EXTRAS[@]}")
    local to_install=()

    for pkg in "${pkgs[@]}"; do
        if is_installed "${pkg}" || brew list --formula "${pkg}" &>/dev/null; then
            _ok "${pkg} — already installed"
        else
            to_install+=("${pkg}")
        fi
    done

    if [[ ${#to_install[@]} -eq 0 ]]; then
        _ok "All Homebrew packages already installed"
        return 0
    fi

    _info "Updating Homebrew …"
    brew update --quiet

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
# Install a single-binary GitHub release asset (zip) into ~/.local/bin
# ---------------------------------------------------------------------------
# $1 = binary name (also used for the is_installed check)
# $2 = GitHub "owner/repo"
# $3 = asset filename (exact, as published on the release)
install_binary_from_zip_release() {
    local bin_name="$1" repo="$2" asset="$3"

    if is_installed "${bin_name}"; then
        _ok "${bin_name} — already installed"
        return 0
    fi

    _info "Installing ${bin_name} from ${repo} releases …"
    mkdir -p "${HOME}/.local/bin"

    local tmpdir
    tmpdir="$(mktemp -d)"
    if ! curl -fsSL "https://github.com/${repo}/releases/latest/download/${asset}" -o "${tmpdir}/${asset}"; then
        _warn "Could not download ${asset} for ${bin_name} — skipping (install manually)"
        rm -rf "${tmpdir}"
        return 1
    fi

    (cd "${tmpdir}" && unzip -oq "${asset}")
    if [[ ! -f "${tmpdir}/${bin_name}" ]]; then
        _warn "${bin_name} binary not found inside ${asset} — skipping"
        rm -rf "${tmpdir}"
        return 1
    fi

    mv "${tmpdir}/${bin_name}" "${HOME}/.local/bin/${bin_name}"
    chmod +x "${HOME}/.local/bin/${bin_name}"
    rm -rf "${tmpdir}"
    _ok "${bin_name} installed → ${HOME}/.local/bin/${bin_name}"
}

# ---------------------------------------------------------------------------
# Remove the OS-packaged neovim (apt/dnf/pacman) now that ~/.local/bin/nvim
# takes priority on PATH — leaving both around just wastes disk and can
# confuse `which`/package-manager audits.
# ---------------------------------------------------------------------------
remove_os_neovim_package() {
    case "${PKG_MANAGER}" in
        apt)
            if dpkg -l neovim 2>/dev/null | grep -q '^ii'; then
                _info "Removing OS-packaged neovim (apt) — using ~/.local/bin/nvim instead …"
                sudo apt remove -y neovim neovim-runtime && _ok "apt neovim package removed" \
                    || _warn "Failed to remove apt neovim package — remove manually with: sudo apt remove neovim neovim-runtime"
            fi
            ;;
        dnf)
            if rpm -q neovim &>/dev/null; then
                _info "Removing OS-packaged neovim (dnf) — using ~/.local/bin/nvim instead …"
                sudo dnf remove -y neovim && _ok "dnf neovim package removed" \
                    || _warn "Failed to remove dnf neovim package — remove manually with: sudo dnf remove neovim"
            fi
            ;;
        pacman)
            if pacman -Qi neovim &>/dev/null; then
                _info "Removing OS-packaged neovim (pacman) — using ~/.local/bin/nvim instead …"
                sudo pacman -Rns --noconfirm neovim && _ok "pacman neovim package removed" \
                    || _warn "Failed to remove pacman neovim package — remove manually with: sudo pacman -Rns neovim"
            fi
            ;;
    esac
}

# ---------------------------------------------------------------------------
# Install Neovim (always latest upstream release, not the OS-packaged one)
# ---------------------------------------------------------------------------
install_neovim() {
    local latest
    latest="$(curl -fsSL https://api.github.com/repos/neovim/neovim/releases/latest | grep '"tag_name"' | sed -E 's/.*"(v[^"]+)".*/\1/')"

    if [[ -z "${latest}" ]]; then
        _warn "Could not determine latest Neovim release — leaving existing install as-is"
        return 0
    fi

    if [[ "${OS_TYPE}" == "macos" ]]; then
        install_homebrew
        if is_installed nvim && [[ "v$(nvim --version | head -1 | awk '{print $2}' | sed 's/^v//')" == "${latest}" ]]; then
            _ok "neovim already up to date"
            return 0
        fi
        if brew list --formula neovim &>/dev/null; then
            _info "Upgrading neovim via Homebrew …"
            brew upgrade neovim || _ok "neovim already at brew's latest formula version"
        else
            _info "Installing neovim via Homebrew …"
            brew install neovim
        fi
        _ok "neovim installed via Homebrew"
        return 0
    fi

    # Linux: install the official prebuilt release — no sudo needed, and it
    # takes priority on PATH since ~/.local/bin is prepended in setup_shell.sh.
    # Always run the cleanup below, even if ~/.local/bin/nvim is already
    # current, so a leftover OS package from before this script existed
    # still gets removed on a re-run.
    if [[ -f "${HOME}/.local/bin/nvim" ]] && "${HOME}/.local/bin/nvim" --version 2>/dev/null | head -1 | grep -q "${latest#v}"; then
        _ok "neovim ${latest} — already up to date"
        remove_os_neovim_package
        return 0
    fi

    local arch tarball
    arch="$(uname -m)"
    case "${arch}" in
        x86_64)          tarball="nvim-linux-x86_64.tar.gz" ;;
        aarch64|arm64)   tarball="nvim-linux-arm64.tar.gz"   ;;
        *)
            _err "Unsupported architecture for prebuilt neovim: ${arch}"
            return 1
            ;;
    esac

    local install_root="${HOME}/.local/opt/nvim-${latest}"
    _info "Installing neovim ${latest} → ${install_root} …"
    mkdir -p "${HOME}/.local/opt" "${HOME}/.local/bin"

    local tmpdir
    tmpdir="$(mktemp -d)"
    curl -fsSL "https://github.com/neovim/neovim/releases/download/${latest}/${tarball}" -o "${tmpdir}/${tarball}"
    tar xzf "${tmpdir}/${tarball}" -C "${tmpdir}"
    rm -rf "${install_root}"
    mv "${tmpdir}/${tarball%.tar.gz}" "${install_root}"
    rm -rf "${tmpdir}"

    ln -sf "${install_root}/bin/nvim" "${HOME}/.local/bin/nvim"
    _ok "neovim ${latest} installed → ${HOME}/.local/bin/nvim"

    remove_os_neovim_package
}

# ---------------------------------------------------------------------------
# Install lua-language-server from upstream releases (full dir, not a zip)
# ---------------------------------------------------------------------------
install_lua_language_server() {
    if is_installed lua-language-server; then
        _ok "lua-language-server — already installed"
        return 0
    fi

    local latest
    latest="$(curl -fsSL https://api.github.com/repos/LuaLS/lua-language-server/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')"
    if [[ -z "${latest}" ]]; then
        _warn "Could not determine latest lua-language-server release — skipping"
        return 1
    fi

    local os_part arch tarball
    arch="$(uname -m)"
    case "${OS_TYPE}" in
        macos) os_part="darwin" ;;
        linux) os_part="linux"  ;;
    esac
    case "${arch}" in
        x86_64|amd64)  arch="x64"   ;;
        aarch64|arm64) arch="arm64" ;;
    esac
    tarball="lua-language-server-${latest}-${os_part}-${arch}.tar.gz"

    _info "Installing lua-language-server ${latest} …"
    local install_root="${HOME}/.local/opt/lua-language-server"
    mkdir -p "${HOME}/.local/opt" "${HOME}/.local/bin"
    rm -rf "${install_root}"
    mkdir -p "${install_root}"

    if ! curl -fsSL "https://github.com/LuaLS/lua-language-server/releases/download/${latest}/${tarball}" -o "/tmp/${tarball}"; then
        _warn "Could not download ${tarball} — skipping lua-language-server (install manually)"
        return 1
    fi
    tar xzf "/tmp/${tarball}" -C "${install_root}"
    rm -f "/tmp/${tarball}"

    ln -sf "${install_root}/bin/lua-language-server" "${HOME}/.local/bin/lua-language-server"
    _ok "lua-language-server installed → ${HOME}/.local/bin/lua-language-server"
}

# ---------------------------------------------------------------------------
# Install LSP servers, linters & formatters (replaces Mason)
# ---------------------------------------------------------------------------
install_lsp_tools() {
    _info "Installing LSP servers, linters & formatters …"

    if is_installed npm; then
        # Default global prefixes (e.g. /usr/local on Debian/Ubuntu) are
        # root-owned, so `npm install -g` fails with EACCES. Point npm at
        # ~/.local instead — already on PATH via setup_shell.sh, no sudo needed.
        local npm_prefix
        npm_prefix="$(npm config get prefix)"
        if [[ ! -w "${npm_prefix}" ]]; then
            _info "npm global prefix (${npm_prefix}) isn't user-writable — switching to ${HOME}/.local"
            mkdir -p "${HOME}/.local"
            npm config set prefix "${HOME}/.local"
        fi

        local npm_pkgs=(
            pyright
            typescript typescript-language-server
            vscode-langservers-extracted
            "@tailwindcss/language-server"
            yaml-language-server
            bash-language-server
            cspell cspell-lsp
            prettier
            eslint_d
        )
        _info "Installing npm globals: ${npm_pkgs[*]}"
        npm install -g "${npm_pkgs[@]}" --silent || _warn "Some npm global installs failed — check output above"
    else
        _warn "npm not found — skipping JS/TS/web LSP tools"
    fi

    install_lua_language_server

    case "${PKG_MANAGER}" in
        brew)
            is_installed clangd || brew install llvm || _warn "clangd not installed — Xcode Command Line Tools usually provide it (xcode-select --install)"
            is_installed stylua || brew install stylua || _warn "stylua install failed"
            is_installed ruff   || brew install ruff   || _warn "ruff install failed"
            ;;
        apt)
            is_installed clangd || sudo apt install -y clangd || _warn "clangd not available in apt — install manually"
            ;;
        dnf)
            is_installed clangd || sudo dnf install -y clang-tools-extra || _warn "clangd not available in dnf — install manually"
            ;;
        pacman)
            is_installed clangd || sudo pacman -S --noconfirm --needed clang || _warn "clangd not available in pacman — install manually"
            ;;
    esac

    # stylua/ruff: no reliable apt/dnf/pacman package on most distros —
    # fall back to upstream release binaries.
    if ! is_installed stylua; then
        local arch stylua_asset
        arch="$(uname -m)"
        case "${OS_TYPE}-${arch}" in
            linux-x86_64)        stylua_asset="stylua-linux-x86_64.zip"  ;;
            linux-aarch64|linux-arm64) stylua_asset="stylua-linux-aarch64.zip" ;;
            macos-x86_64)        stylua_asset="stylua-macos-x86_64.zip"  ;;
            macos-arm64|macos-aarch64) stylua_asset="stylua-macos-aarch64.zip" ;;
        esac
        [[ -n "${stylua_asset:-}" ]] && install_binary_from_zip_release stylua JohnnyMorganz/StyLua "${stylua_asset}"
    fi

    if ! is_installed ruff; then
        _info "Installing ruff via the official installer …"
        RUFF_NO_MODIFY_PATH=1 sh -c "$(curl -LsSf https://astral.sh/ruff/install.sh)" || _warn "ruff install failed — install manually"
    fi

    _ok "LSP tool installation attempted (see warnings above for anything skipped)"
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

    install_neovim
    install_lsp_tools

    _ok "Dependency installation complete"
}

main "$@"
