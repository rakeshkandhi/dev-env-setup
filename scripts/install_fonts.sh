#!/usr/bin/env bash
# ==============================================================================
# install_fonts.sh — Install MesloLGS Nerd Font
# ==============================================================================
# Downloads MesloLGS NF from nerd-fonts releases and installs to the
# platform-appropriate font directory.
#   macOS : ~/Library/Fonts/
#   Linux : ~/.local/share/fonts/
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
# Source OS detection if needed
# ---------------------------------------------------------------------------
if [[ -z "${OS_TYPE:-}" ]]; then
    # shellcheck disable=SC1091
    source "${SCRIPT_DIR}/detect_os.sh"
fi

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
FONT_NAME="Meslo"
NERD_FONTS_VERSION="v3.3.0"
DOWNLOAD_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONTS_VERSION}/${FONT_NAME}.zip"

# Platform-specific font directory
case "${OS_TYPE}" in
    macos) FONT_DIR="${HOME}/Library/Fonts" ;;
    linux) FONT_DIR="${HOME}/.local/share/fonts" ;;
    *)     _err "Unsupported OS: ${OS_TYPE}"; exit 1 ;;
esac

# ---------------------------------------------------------------------------
# Check if MesloLGS Nerd Font is already installed
# ---------------------------------------------------------------------------
is_font_installed() {
    local count
    count="$(find "${FONT_DIR}" -maxdepth 1 -iname '*MesloLGS*Nerd*' 2>/dev/null | wc -l)"
    [[ "${count}" -gt 0 ]]
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
    _info "Checking for MesloLGS Nerd Font …"

    if is_font_installed; then
        _ok "MesloLGS Nerd Font already installed in ${FONT_DIR}"
        return 0
    fi

    # Ensure font directory exists
    mkdir -p "${FONT_DIR}"

    # Create a temp directory for downloading
    local tmp_dir
    tmp_dir="$(mktemp -d)"
    # shellcheck disable=SC2064
    trap "rm -rf '${tmp_dir}'" EXIT

    _info "Downloading ${FONT_NAME} Nerd Font (${NERD_FONTS_VERSION}) …"
    curl -fsSL -o "${tmp_dir}/${FONT_NAME}.zip" "${DOWNLOAD_URL}"

    _info "Extracting fonts to ${FONT_DIR} …"
    unzip -qo "${tmp_dir}/${FONT_NAME}.zip" -d "${tmp_dir}/${FONT_NAME}"

    # Copy only the .ttf files (skip the LICENSE and README)
    local font_count=0
    while IFS= read -r -d '' font_file; do
        cp "${font_file}" "${FONT_DIR}/"
        ((font_count++))
    done < <(find "${tmp_dir}/${FONT_NAME}" -type f -name '*.ttf' -print0)

    _ok "Installed ${font_count} font files to ${FONT_DIR}"

    # Rebuild font cache on Linux
    if [[ "${OS_TYPE}" == "linux" ]]; then
        _info "Rebuilding font cache …"
        if command -v fc-cache &>/dev/null; then
            fc-cache -fv "${FONT_DIR}" >/dev/null 2>&1
            _ok "Font cache rebuilt"
        else
            _warn "fc-cache not found — install fontconfig to rebuild the font cache"
        fi
    fi

    _ok "MesloLGS Nerd Font installation complete"
}

main "$@"
