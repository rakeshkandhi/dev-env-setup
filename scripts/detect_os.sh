#!/usr/bin/env bash
# ==============================================================================
# detect_os.sh — OS Detection Helper
# ==============================================================================
# Source this file to set:
#   OS_TYPE       — "macos" | "linux"
#   LINUX_DISTRO  — "ubuntu" | "debian" | "fedora" | "arch" | "unknown" (linux only)
#   PKG_MANAGER   — "brew" | "apt" | "dnf" | "pacman"
#
# Ubuntu-based (Mint, Pop!_OS, Elementary, Zorin, …) is detected via ID or
# ID_LIKE and reported as LINUX_DISTRO=ubuntu. Debian-based (not Ubuntu)
# is reported as debian. Both use apt.
# ==============================================================================

# Guard: allow sourcing without blowing up the caller
# shellcheck disable=SC2148
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -euo pipefail
fi

# ---------------------------------------------------------------------------
# Color helpers (only define if not already defined by the caller)
# ---------------------------------------------------------------------------
if ! declare -f _info &>/dev/null; then
    _info()  { printf '\033[1;34m[INFO]\033[0m  %s\n' "$*"; }
    _ok()    { printf '\033[1;32m[ OK ]\033[0m  %s\n' "$*"; }
    _warn()  { printf '\033[1;33m[WARN]\033[0m  %s\n' "$*"; }
    _err()   { printf '\033[1;31m[ ERR]\033[0m  %s\n' "$*"; }
fi

# True if space-separated list $2 contains word $1
_id_like_has() {
    local needle="$1"
    local haystack=" $2 "
    [[ "${haystack}" == *" ${needle} "* ]]
}

# ---------------------------------------------------------------------------
# Detect OS
# ---------------------------------------------------------------------------
detect_os() {
    local kernel
    kernel="$(uname -s)"

    case "${kernel}" in
        Darwin)
            OS_TYPE="macos"
            PKG_MANAGER="brew"
            LINUX_DISTRO=""
            ;;
        Linux)
            OS_TYPE="linux"
            LINUX_DISTRO="unknown"
            PKG_MANAGER="unknown"

            if [[ -f /etc/os-release ]]; then
                # shellcheck disable=SC1091
                source /etc/os-release
                local distro_id="${ID:-}"
                local distro_like="${ID_LIKE:-}"

                case "${distro_id}" in
                    ubuntu|pop|linuxmint|elementary|zorin|neon|kubuntu|xubuntu|lubuntu)
                        LINUX_DISTRO="ubuntu"
                        PKG_MANAGER="apt"
                        ;;
                    debian|raspbian)
                        LINUX_DISTRO="debian"
                        PKG_MANAGER="apt"
                        ;;
                    fedora)
                        LINUX_DISTRO="fedora"
                        PKG_MANAGER="dnf"
                        ;;
                    arch|manjaro|endeavouros)
                        LINUX_DISTRO="arch"
                        PKG_MANAGER="pacman"
                        ;;
                    *)
                        # Derivatives: prefer ubuntu over debian when both appear
                        # (Pop!_OS, Mint, etc. set ID_LIKE="ubuntu debian")
                        if _id_like_has "ubuntu" "${distro_like}"; then
                            LINUX_DISTRO="ubuntu"
                            PKG_MANAGER="apt"
                        elif _id_like_has "debian" "${distro_like}"; then
                            LINUX_DISTRO="debian"
                            PKG_MANAGER="apt"
                        elif _id_like_has "fedora" "${distro_like}"; then
                            LINUX_DISTRO="fedora"
                            PKG_MANAGER="dnf"
                        elif _id_like_has "arch" "${distro_like}"; then
                            LINUX_DISTRO="arch"
                            PKG_MANAGER="pacman"
                        fi
                        ;;
                esac
            fi

            if [[ "${PKG_MANAGER}" == "unknown" ]]; then
                if command -v apt &>/dev/null; then
                    PKG_MANAGER="apt"
                elif command -v dnf &>/dev/null; then
                    PKG_MANAGER="dnf"
                elif command -v pacman &>/dev/null; then
                    PKG_MANAGER="pacman"
                fi
            fi
            ;;
        *)
            _err "Unsupported operating system: ${kernel}"
            return 1
            ;;
    esac

    export OS_TYPE LINUX_DISTRO PKG_MANAGER
}

# Run detection automatically when sourced / executed
detect_os

_ok "OS detected — OS_TYPE=${OS_TYPE}  LINUX_DISTRO=${LINUX_DISTRO:-n/a}  PKG_MANAGER=${PKG_MANAGER}"
