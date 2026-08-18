#!/usr/bin/env bash
# ==============================================================================
# install.sh — Dev Environment Bootstrap
# ==============================================================================
# Master installer that orchestrates all setup scripts.
#
# Usage:
#   ./install.sh                 # Run everything
#   ./install.sh update          # Self-update repo, then re-run all steps
#   ./install.sh update --only nvim  # Self-update, then run only nvim
#   ./install.sh --only nvim     # Run only the nvim setup
#   ./install.sh --no-deps       # Skip dependency installation
#   ./install.sh --dry-run       # Show what would be done
#   ./install.sh --help          # Show usage
#
# Execution order:
#   1. Detect OS
#   2. Install dependencies
#   3. Install fonts
#   4. Setup Neovim
#   5. Setup tmux
#   6. Setup Alacritty
#   7. Setup Starship Prompt (Linux only)
#   8. Setup Shell Environment & Aliases
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS="${SCRIPT_DIR}/scripts"

# ---------------------------------------------------------------------------
# Color helpers
# ---------------------------------------------------------------------------
BOLD='\033[1m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
BLUE='\033[1;34m'
DIM='\033[2m'
RESET='\033[0m'

_info()  { printf "${BLUE}[INFO]${RESET}  %s\n" "$*"; }
_ok()    { printf "${GREEN}[ OK ]${RESET}  %s\n" "$*"; }
_warn()  { printf "${YELLOW}[WARN]${RESET}  %s\n" "$*"; }
_err()   { printf "${RED}[ ERR]${RESET}  %s\n" "$*"; }
_step()  { printf "\n${CYAN}${BOLD}━━━ %s ━━━${RESET}\n\n" "$*"; }

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------
print_banner() {
    printf "${CYAN}"
    if [[ "${UPDATE_MODE}" == true ]]; then
        cat << 'EOF'
    ╔══════════════════════════════════════════════════════╗
    ║                                                      ║
    ║         🔄  Dev Environment Updating  🔄             ║
    ║                                                      ║
    ║   Alacritty  •  tmux  •  Neovim                      ║
    ║   Catppuccin Mocha  •  MesloLGS Nerd Font            ║
    ║                                                      ║
    ╚══════════════════════════════════════════════════════╝
EOF
    else
        cat << 'EOF'
    ╔══════════════════════════════════════════════════════╗
    ║                                                      ║
    ║          🚀  Dev Environment Setup  🚀               ║
    ║                                                      ║
    ║   Alacritty  •  tmux  •  Neovim                      ║
    ║   Catppuccin Mocha  •  MesloLGS Nerd Font            ║
    ║                                                      ║
    ╚══════════════════════════════════════════════════════╝
EOF
    fi
    printf "${RESET}\n"
}

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]
       $(basename "$0") update [OPTIONS]

Commands:
  update             Self-update the repo (git pull), then re-run all
                     idempotent setup steps. Supports --only and --dry-run.

Options:
  --only <step>    Run only a specific step. Valid steps:
                     deps, fonts, nvim, tmux, alacritty, starship, shell
  --no-deps        Skip dependency installation
  --no-alacritty   Skip Alacritty setup & settings porting
                     (aliases: --skip-alacritty, --exclude-alacritty)
  --no-starship    Skip Starship prompt setup
                     (aliases: --skip-starship, --exclude-starship)
  --no-shell       Skip shell environment & aliases setup
                     (aliases: --skip-shell, --exclude-shell)
  --dry-run        Show what would be done without executing
  --help, -h       Show this help message

Examples:
  $(basename "$0")                  # Full install
  $(basename "$0") update           # Self-update repo, re-run all steps
  $(basename "$0") update --only nvim  # Self-update, then only Neovim
  $(basename "$0") --only nvim      # Only setup Neovim
  $(basename "$0") --only starship  # Only setup Starship prompt
  $(basename "$0") --only shell     # Only setup shell environment & aliases
  $(basename "$0") --no-deps        # Skip deps, do everything else
  $(basename "$0") --no-alacritty   # Skip Alacritty setup & config porting
  $(basename "$0") --no-starship    # Skip Starship setup
  $(basename "$0") --no-shell       # Skip shell setup
  $(basename "$0") --dry-run        # Preview what will happen
EOF
}

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
ONLY_STEP=""
SKIP_DEPS=false
SKIP_ALACRITTY=false
SKIP_STARSHIP=false
SKIP_SHELL=false
DRY_RUN=false
UPDATE_MODE=false

# Check for 'update' subcommand before parsing flags
if [[ "${1:-}" == "update" ]]; then
    UPDATE_MODE=true
    shift
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        --only)
            if [[ -z "${2:-}" ]]; then
                _err "--only requires a step name (deps|fonts|nvim|tmux|alacritty|starship|shell)"
                exit 1
            fi
            ONLY_STEP="$2"
            shift 2
            ;;
        --no-deps)
            SKIP_DEPS=true
            shift
            ;;
        --no-alacritty|--skip-alacritty|--exclude-alacritty)
            SKIP_ALACRITTY=true
            shift
            ;;
        --no-starship|--skip-starship|--exclude-starship)
            SKIP_STARSHIP=true
            shift
            ;;
        --no-shell|--skip-shell|--exclude-shell)
            SKIP_SHELL=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            _err "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

export SKIP_ALACRITTY SKIP_STARSHIP SKIP_SHELL UPDATE_MODE

# Validate --only step
if [[ -n "${ONLY_STEP}" ]]; then
    case "${ONLY_STEP}" in
        deps|fonts|nvim|tmux|alacritty|starship|shell) ;;
        *)
            _err "Invalid step: ${ONLY_STEP}"
            _err "Valid steps: deps, fonts, nvim, tmux, alacritty, starship, shell"
            exit 1
            ;;
    esac
fi

# ---------------------------------------------------------------------------
# Should-run helper (respects --only, --no-deps, --no-alacritty, --no-starship, --no-shell)
# ---------------------------------------------------------------------------
should_run() {
    local step="$1"

    if [[ -n "${ONLY_STEP}" ]]; then
        [[ "${ONLY_STEP}" == "${step}" ]]
        return
    fi

    if [[ "${step}" == "deps" && "${SKIP_DEPS}" == true ]]; then
        return 1
    fi

    if [[ "${step}" == "alacritty" && "${SKIP_ALACRITTY}" == true ]]; then
        return 1
    fi

    if [[ "${step}" == "starship" && "${SKIP_STARSHIP}" == true ]]; then
        return 1
    fi

    if [[ "${step}" == "shell" && "${SKIP_SHELL}" == true ]]; then
        return 1
    fi

    return 0
}

# ---------------------------------------------------------------------------
# Run step (respects --dry-run)
# ---------------------------------------------------------------------------
RESULTS=()

run_step() {
    local name="$1"
    local script="$2"
    local label="$3"

    if ! should_run "${name}"; then
        RESULTS+=("${DIM}SKIP${RESET}  ${label}")
        return 0
    fi

    _step "${label}"

    if [[ "${DRY_RUN}" == true ]]; then
        _info "[dry-run] Would execute: ${script}"
        RESULTS+=("${YELLOW}DRY ${RESET}  ${label}")
        return 0
    fi

    if bash "${script}"; then
        RESULTS+=("${GREEN} ✓  ${RESET}  ${label}")
    else
        RESULTS+=("${RED} ✗  ${RESET}  ${label}")
        _err "${label} — failed"
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
    print_banner

    if [[ "${DRY_RUN}" == true ]]; then
        _warn "DRY RUN — no changes will be made"
        echo ""
    fi

    # Self-update: pull latest changes when in update mode
    if [[ "${UPDATE_MODE}" == true ]]; then
        _step "Self-Updating dev-env-setup"
        if [[ "${DRY_RUN}" == true ]]; then
            _info "[dry-run] Would run: git -C ${SCRIPT_DIR} pull --rebase"
        else
            if git -C "${SCRIPT_DIR}" pull --rebase; then
                _ok "Repository updated successfully"
            else
                _warn "git pull --rebase failed — continuing with current version"
            fi
        fi
    fi

    # Step 0: Detect OS (always runs — other scripts depend on it)
    _step "Detecting Operating System"
    if [[ "${DRY_RUN}" == true ]]; then
        _info "[dry-run] Would detect OS"
    else
        # shellcheck disable=SC1091
        source "${SCRIPTS}/detect_os.sh"
        export OS_TYPE LINUX_DISTRO PKG_MANAGER
    fi

    # Steps 1–7
    run_step "deps"      "${SCRIPTS}/install_deps.sh"      "Install Dependencies"
    run_step "fonts"     "${SCRIPTS}/install_fonts.sh"      "Install MesloLGS Nerd Font"
    run_step "nvim"      "${SCRIPTS}/setup_nvim.sh"         "Setup Neovim Config"
    run_step "tmux"      "${SCRIPTS}/setup_tmux.sh"         "Setup tmux Config & TPM"
    run_step "alacritty" "${SCRIPTS}/setup_alacritty.sh"    "Setup Alacritty Config"
    run_step "starship"  "${SCRIPTS}/setup_starship.sh"     "Setup Starship Prompt (Linux only)"
    run_step "shell"     "${SCRIPTS}/setup_shell.sh"        "Setup Shell Environment & Aliases"

    # ------------------------------------------------------------------
    # Summary
    # ------------------------------------------------------------------
    echo ""
    printf "${CYAN}${BOLD}━━━ Summary ━━━${RESET}\n\n"

    for result in "${RESULTS[@]}"; do
        printf "  ${result}\n"
    done

    echo ""
    printf "${DIM}─────────────────────────────────────────────────${RESET}\n"

    if [[ "${DRY_RUN}" == false ]]; then
        if [[ "${UPDATE_MODE}" == true ]]; then
            _ok "Dev environment update complete! 🎉"
            echo ""
            _info "Next steps:"
            echo "  1. Restart your terminal (or source your shell rc)"
            echo "  2. Restart tmux to apply config changes"
            echo "  3. In Neovim, run  :Lazy sync  to update plugins"
            echo ""
        else
            _ok "Dev environment setup complete! 🎉"
            echo ""
            _info "Next steps:"
            echo "  1. Restart your terminal (or source your shell rc)"
            echo "  2. Open tmux and press  prefix + I  to install plugins"
            echo "  3. Open Neovim — plugins will auto-install on first launch"
            echo ""
        fi
    fi
}

main "$@"
