#!/usr/bin/env bash
# ==============================================================================
# setup_alacritty.sh — Alacritty Configuration Setup
# ==============================================================================
# Symlinks the repo's alacritty config directory → ~/.config/alacritty/
#
# Repo layout expected:
#   alacritty/
#     alacritty.toml
#     themes/
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
ALACRITTY_CONFIG_DIR="${ALACRITTY_CONFIG_DIR:-"${HOME}/.config/alacritty"}"
REPO_ALACRITTY_DIR="${REPO_ALACRITTY_DIR:-"${REPO_DIR}/alacritty"}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

# Source OS detection if PKG_MANAGER is unset
if [[ -z "${OS_TYPE:-}" || -z "${PKG_MANAGER:-}" ]]; then
    if [[ -f "${SCRIPT_DIR}/detect_os.sh" ]]; then
        # shellcheck disable=SC1091
        source "${SCRIPT_DIR}/detect_os.sh"
    fi
fi

# ---------------------------------------------------------------------------
# Generator & Install Helpers
# ---------------------------------------------------------------------------

create_default_config() {
    local target_dir="$1"
    mkdir -p "${target_dir}"
    cat << 'EOF' > "${target_dir}/alacritty.toml"
[general]
working_directory = "~"

[window]
padding = { x = 2, y = 2 }
dimensions = { columns = 120, lines = 35 }
opacity = 0.9
blur = true
dynamic_title = true
option_as_alt = "Both"

[scrolling]
multiplier = 1

[selection]
save_to_clipboard = true

# Default colors (Catppuccin Mocha)
[colors.primary]
background = '#1E1E2E'
foreground = '#CDD6F4'
dim_foreground = '#CDD6F4'
bright_foreground = '#CDD6F4'

[colors.cursor]
text = '#1E1E2E'
cursor = '#F5E0DC'

[colors.vi_mode_cursor]
text = '#1E1E2E'
cursor = '#B4BEFE'

[colors.search.matches]
foreground = '#1E1E2E'
background = '#A6ADC8'

[colors.search.focused_match]
foreground = '#1E1E2E'
background = '#A6E3A1'

[colors.footer_bar]
foreground = '#1E1E2E'
background = '#A6ADC8'

[colors.hints.start]
foreground = '#1E1E2E'
background = '#F9E2AF'

[colors.hints.end]
foreground = '#1E1E2E'
background = '#A6ADC8'

[colors.selection]
text = '#1E1E2E'
background = '#F5E0DC'

[colors.normal]
black   = '#45475A'
red     = '#F38BA8'
green   = '#A6E3A1'
yellow  = '#F9E2AF'
blue    = '#89B4FA'
magenta = '#F5C2E7'
cyan    = '#94E2D5'
white   = '#BAC2DE'

[colors.bright]
black   = '#585B70'
red     = '#F38BA8'
green   = '#A6E3A1'
yellow  = '#F9E2AF'
blue    = '#89B4FA'
magenta = '#F5C2E7'
cyan    = '#94E2D5'
white   = '#A6ADC8'

[colors.dim]
black   = '#45475A'
red     = '#F38BA8'
green   = '#A6E3A1'
yellow  = '#F9E2AF'
blue    = '#89B4FA'
magenta = '#F5C2E7'
cyan    = '#94E2D5'
white   = '#BAC2DE'

[font]
size = 11

[font.normal]
family = "MesloLGS Nerd Font"
style = "Regular"

[font.bold]
family = "MesloLGS Nerd Font"
style = "Bold"

[font.italic]
family = "MesloLGS Nerd Font"
style = "Italic"

[font.bold_italic]
family = "MesloLGS Nerd Font"
style = "Bold Italic"

[keyboard]

[[keyboard.bindings]]
key = "D"
mods = "Command"
chars = "\u0004"
EOF
    _ok "Created default Alacritty config at ${target_dir}/alacritty.toml"
}

install_alacritty_binary() {
    if command -v alacritty &>/dev/null; then
        _ok "Alacritty binary is already installed"
        return 0
    fi

    _info "Installing Alacritty application binary …"
    case "${PKG_MANAGER:-}" in
        brew)
            brew install --cask alacritty || brew install alacritty
            ;;
        apt)
            sudo apt update -qq && sudo apt install -y alacritty
            ;;
        dnf)
            sudo dnf install -y alacritty
            ;;
        pacman)
            sudo pacman -S --noconfirm alacritty
            ;;
        *)
            _warn "Could not auto-install Alacritty binary for package manager '${PKG_MANAGER:-unknown}'. Please install manually."
            return 0
            ;;
    esac
    _ok "Alacritty binary installed"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
    if [[ "${SKIP_ALACRITTY:-false}" == true ]]; then
        _info "Skipping Alacritty setup (--no-alacritty specified)"
        return 0
    fi

    _info "Setting up Alacritty configuration …"

    # Check if Alacritty config directory and alacritty.toml exist
    if [[ ! -d "${REPO_ALACRITTY_DIR}" || ! -f "${REPO_ALACRITTY_DIR}/alacritty.toml" ]]; then
        _warn "Alacritty config not found at ${REPO_ALACRITTY_DIR}"

        # If interactive session, prompt user whether to skip or install
        if [[ -t 0 ]] || [[ -c /dev/tty ]]; then
            local choice=""
            while true; do
                printf "\033[1;33mAlacritty config is not present. Do you want to (s)kip or (i)nstall Alacritty? [s/i]: \033[0m"
                read -r choice < /dev/tty || choice="s"
                case "${choice}" in
                    [sS]* )
                        _info "Skipping Alacritty setup per user selection"
                        return 0
                        ;;
                    [iI]* )
                        _info "Installing & initializing Alacritty configuration …"
                        create_default_config "${REPO_ALACRITTY_DIR}"
                        if ! command -v alacritty &>/dev/null; then
                            install_alacritty_binary
                        fi
                        break
                        ;;
                    * )
                        echo "Please enter 's' to skip or 'i' to install."
                        ;;
                esac
            done
        else
            _warn "Non-interactive environment and Alacritty config not present — skipping Alacritty setup"
            return 0
        fi
    fi

    # Ensure parent directory exists
    mkdir -p "${HOME}/.config"

    # If the config dir is already a correct symlink, we're done
    if [[ -L "${ALACRITTY_CONFIG_DIR}" ]]; then
        local current_target
        current_target="$(readlink "${ALACRITTY_CONFIG_DIR}")"
        if [[ "${current_target}" == "${REPO_ALACRITTY_DIR}" ]]; then
            _ok "Alacritty config already symlinked correctly"
            return 0
        fi
        _warn "Removing stale symlink: ${ALACRITTY_CONFIG_DIR} → ${current_target}"
        rm "${ALACRITTY_CONFIG_DIR}"
    elif [[ -d "${ALACRITTY_CONFIG_DIR}" ]]; then
        local backup="${ALACRITTY_CONFIG_DIR}.backup.${TIMESTAMP}"
        _warn "Backing up existing config: ${ALACRITTY_CONFIG_DIR} → ${backup}"
        mv "${ALACRITTY_CONFIG_DIR}" "${backup}"
    fi

    # Symlink the entire alacritty config directory
    ln -s "${REPO_ALACRITTY_DIR}" "${ALACRITTY_CONFIG_DIR}"
    _ok "Symlinked ${ALACRITTY_CONFIG_DIR} → ${REPO_ALACRITTY_DIR}"

    _ok "Alacritty setup complete"
}

main "$@"
