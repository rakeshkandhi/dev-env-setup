#!/usr/bin/env bash
# ==============================================================================
# setup_shell.sh — Shell Environment & Aliases Setup
# ==============================================================================
# Configures environment variables and shell aliases in ~/.zshrc or ~/.bashrc
#
# Added configuration:
#   • export EDITOR="nvim"
#   • export VISUAL="nvim"
#   • alias v="nvim"
#   • alias t="tmux"
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
# Configuration Block
# ---------------------------------------------------------------------------
BLOCK_START="# >>> dev-env-setup >>>"
BLOCK_END="# <<< dev-env-setup <<<"

CONFIG_BLOCK=$(cat << 'EOF'
# >>> dev-env-setup >>>
export EDITOR="nvim"
export VISUAL="nvim"
alias v="nvim"
alias t="tmux"
# <<< dev-env-setup <<<
EOF
)

# Detect user shell config file
detect_shell_rc() {
    local user_shell
    user_shell="$(basename "${SHELL:-bash}")"

    if [[ "${user_shell}" == "zsh" ]] || [[ -f "${HOME}/.zshrc" ]]; then
        echo "${HOME}/.zshrc"
    elif [[ "${user_shell}" == "bash" ]] || [[ -f "${HOME}/.bashrc" ]]; then
        echo "${HOME}/.bashrc"
    else
        echo "${HOME}/.profile"
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
    if [[ "${SKIP_SHELL:-false}" == true ]]; then
        _info "Skipping Shell setup (--no-shell specified)"
        return 0
    fi

    _info "Setting up shell environment and aliases …"

    local rc_file
    rc_file="$(detect_shell_rc)"
    touch "${rc_file}"

    _info "Target shell configuration file: ${rc_file}"

    # If block already exists, replace it cleanly
    if grep -qF "${BLOCK_START}" "${rc_file}"; then
        _info "Updating existing dev-env-setup configuration in ${rc_file} …"
        # Temporary file for atomic write
        local tmp_rc
        tmp_rc="$(mktemp)"
        awk -v start="${BLOCK_START}" -v end="${BLOCK_END}" -v block="${CONFIG_BLOCK}" '
            $0 ~ start { printing=0; print block; next }
            $0 ~ end { printing=1; next }
            printing { print }
        ' printing=1 "${rc_file}" > "${tmp_rc}"
        mv "${tmp_rc}" "${rc_file}"
        _ok "Updated shell configuration in ${rc_file}"
    else
        _info "Appending dev-env-setup configuration to ${rc_file} …"
        echo "" >> "${rc_file}"
        echo "${CONFIG_BLOCK}" >> "${rc_file}"
        _ok "Appended shell configuration to ${rc_file}"
    fi

    _ok "Shell environment setup complete"
}

main "$@"
