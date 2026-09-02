#!/usr/bin/env bash
# ==============================================================================
# setup_shell.sh — Shell Environment & Aliases Setup
# ==============================================================================
# Configures environment variables, aliases, and fzf in the OS default shell:
#   macOS  → zsh  (~/.zshrc)     eval "$(fzf --zsh)"
#   Linux  → bash (~/.bashrc)    fzf key-bindings + starship init
#
# The other rc file is never touched (macOS does not write ~/.bashrc;
# Linux does not write ~/.zshrc).
#
# Added configuration:
#   • export EDITOR="nvim" / VISUAL="nvim"
#   • alias v="nvim" / t="tmux"
#   • fzf eval / sourced key-bindings (Ctrl-T, Ctrl-R, Alt-C, ** completion)
#   • vf   — fuzzy-find file(s) with preview, open in nvim
#   • fcd  — fuzzy cd into a directory
#   • fkill — fuzzy-select and kill process(es)
#   • Linux: ~/.local/bin on PATH, starship init bash
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# Source OS detection if variables are missing
# ---------------------------------------------------------------------------
if [[ -z "${OS_TYPE:-}" ]]; then
    # shellcheck disable=SC1091
    source "${SCRIPT_DIR}/detect_os.sh"
fi

# ---------------------------------------------------------------------------
# Color helpers
# ---------------------------------------------------------------------------
_info()  { printf '\033[1;34m[INFO]\033[0m  %s\n' "$*"; }
_ok()    { printf '\033[1;32m[ OK ]\033[0m  %s\n' "$*"; }
_warn()  { printf '\033[1;33m[WARN]\033[0m  %s\n' "$*"; }
_err()   { printf '\033[1;31m[ ERR]\033[0m  %s\n' "$*"; }

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
FZF_CONFIG_DIR="${HOME}/.config/fzf"
FZF_CACHE_DIR="${HOME}/.cache/fzf"
BLOCK_START="# >>> dev-env-setup >>>"
BLOCK_END="# <<< dev-env-setup <<<"

# Distro-packaged fzf shell scripts (Ubuntu/Debian first)
FZF_SHELL_SEARCH_PATHS=(
    /usr/share/doc/fzf/examples
    /usr/share/fzf/shell
    /usr/share/fzf
    "${HOME}/.fzf/shell"
)

# ---------------------------------------------------------------------------
# OS → default shell + rc file
#   macOS  → zsh  / ~/.zshrc   (only)
#   Linux  → bash / ~/.bashrc  (only — Ubuntu, Debian, Fedora, Arch, …)
# ---------------------------------------------------------------------------
detect_target_shell() {
    case "${OS_TYPE}" in
        macos)
            TARGET_SHELL="zsh"
            TARGET_RC="${HOME}/.zshrc"
            ;;
        linux)
            TARGET_SHELL="bash"
            TARGET_RC="${HOME}/.bashrc"
            ;;
        *)
            _err "Unsupported OS_TYPE: ${OS_TYPE:-unset}"
            exit 1
            ;;
    esac
}

# Copy distro files, or fetch from GitHub matching the installed fzf version.
# Writes:
#   ~/.config/fzf/key-bindings.<shell>
#   ~/.config/fzf/completion.<shell>
#   ~/.cache/fzf/   (history dir)
install_fzf_user_files() {
    local sh="$1"
    mkdir -p "${FZF_CONFIG_DIR}" "${FZF_CACHE_DIR}"

    if ! command -v fzf >/dev/null 2>&1; then
        _warn "fzf not found — skipping key-bindings install"
        return 0
    fi

    local name dest src dir ver url
    for name in "key-bindings.${sh}" "completion.${sh}"; do
        dest="${FZF_CONFIG_DIR}/${name}"
        src=""

        for dir in "${FZF_SHELL_SEARCH_PATHS[@]}"; do
            if [[ -f "${dir}/${name}" ]]; then
                src="${dir}/${name}"
                break
            fi
        done

        if command -v brew >/dev/null 2>&1; then
            local brew_fzf
            brew_fzf="$(brew --prefix 2>/dev/null)/opt/fzf/shell"
            if [[ -z "${src}" && -f "${brew_fzf}/${name}" ]]; then
                src="${brew_fzf}/${name}"
            fi
        fi

        if [[ -n "${src}" ]]; then
            cp "${src}" "${dest}"
            _ok "Installed ${dest} ← ${src}"
            continue
        fi

        ver="$(fzf --version 2>/dev/null | awk '{print $1}')"
        url="https://raw.githubusercontent.com/junegunn/fzf/v${ver}/shell/${name}"
        if curl -fsSL "${url}" -o "${dest}"; then
            _ok "Fetched ${dest} (fzf v${ver})"
            continue
        fi

        if curl -fsSL "https://raw.githubusercontent.com/junegunn/fzf/master/shell/${name}" -o "${dest}"; then
            _ok "Fetched ${dest} (fzf master)"
            continue
        fi

        _warn "Could not install ${name} — fzf shortcuts may be unavailable"
        rm -f "${dest}"
    done
}

# fzf eval + fallback that sources ~/.config/fzf files (Ubuntu/Debian apt
# packages are too old for `fzf --bash` / `fzf --zsh`).
fzf_integration_block() {
    local sh="$1"
    sed "s/__SHELL__/${sh}/g" << 'EOF'
# Key bindings + fuzzy completion (Ctrl-T files, Ctrl-R history, Alt-C cd,
# and ** completion: cd **<Tab>, kill **<Tab>, nvim **<Tab>)
if command -v fzf >/dev/null 2>&1; then
  if fzf --help 2>&1 | grep -q -- '--__SHELL__'; then
    eval "$(fzf --__SHELL__)"
  else
    [ -f "${HOME}/.config/fzf/key-bindings.__SHELL__" ] && . "${HOME}/.config/fzf/key-bindings.__SHELL__"
    [ -f "${HOME}/.config/fzf/completion.__SHELL__" ] && . "${HOME}/.config/fzf/completion.__SHELL__"
  fi
fi
EOF
}

starship_integration_block() {
    cat << 'EOF'
# Starship prompt (Linux)
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
fi
EOF
}

# Assemble the managed rc block. Placeholders are replaced here so the
# written ~/.zshrc / ~/.bashrc actually contains fzf + starship init.
build_config_block() {
    local sh="$1"

    local fzf_block
    fzf_block="$(fzf_integration_block "${sh}")"

    local starship_block=""
    if [[ "${OS_TYPE}" == "linux" ]]; then
        starship_block="$(starship_integration_block)"
        starship_block=$'\n'"${starship_block}"$'\n'
    fi

    cat << EOF
# >>> dev-env-setup >>>
# User-local binaries (~/.local/bin)
case ":\${PATH}:" in
  *:"\${HOME}/.local/bin":*) ;;
  *) export PATH="\${HOME}/.local/bin:\${PATH}" ;;
esac

export EDITOR="nvim"
export VISUAL="nvim"
alias v="nvim"
alias t="tmux"
alias ta="tmux-sessionizer"

# Ubuntu/Debian ships the fd binary as fdfind. Resolve the real binary name
# *before* defining the alias: an \`fd\` alias makes \`command -v fd\` succeed, so
# a bare \`fd\` would end up in FZF_DEFAULT_COMMAND — and fzf runs that through
# /bin/sh, where aliases do not exist, leaving every fzf list empty.
unalias fd 2>/dev/null || true
if command -v fd >/dev/null 2>&1; then
  _DEV_ENV_FD="fd"
elif command -v fdfind >/dev/null 2>&1; then
  _DEV_ENV_FD="fdfind"
  alias fd="fdfind"
else
  _DEV_ENV_FD=""
fi

# fzf defaults — fd as the finder, cat (or bat) for previews
if [ -n "\${_DEV_ENV_FD}" ]; then
  export FZF_DEFAULT_COMMAND="\${_DEV_ENV_FD} --type f --hidden --follow --exclude .git"
  export FZF_CTRL_T_COMMAND="\${FZF_DEFAULT_COMMAND}"
  export FZF_ALT_C_COMMAND="\${_DEV_ENV_FD} --type d --hidden --follow --exclude .git"
fi

# Preview must be a standalone command — fzf runs it in a subshell
_FZF_FILE_PREVIEW='if command -v bat >/dev/null 2>&1; then bat --style=numbers --color=always --line-range :200 {}; else cat {}; fi'

export FZF_DEFAULT_OPTS="\\
  --height 50% --layout=reverse --border --info=inline \\
  --history=\${HOME}/.cache/fzf/history \\
  --bind ctrl-u:preview-page-up,ctrl-d:preview-page-down \\
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \\
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \\
  --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \\
  --color=selected-bg:#45475a"
export FZF_CTRL_T_OPTS="--preview '\${_FZF_FILE_PREVIEW}' --preview-window=right:60%:wrap"
export FZF_ALT_C_OPTS="--preview 'ls -la {}' --preview-window=right:50%:wrap"

${fzf_block}
${starship_block}
# vf — fuzzy-find file(s) with preview and open in nvim
#   vf            search from cwd
#   vf <query>    start fzf with a query
vf() {
  local selected
  selected="\$(fzf -m --query="\${1:-}" --preview "\${_FZF_FILE_PREVIEW}" --preview-window=right:60%:wrap)" || return
  [ -z "\${selected}" ] && return
  local files=()
  while IFS= read -r line; do
    files+=("\${line}")
  done <<< "\${selected}"
  nvim "\${files[@]}"
}

# fcd — fuzzy cd into a directory (preview shows listing)
#   fcd           search from cwd
#   fcd <path>    search under <path>
fcd() {
  local start="\${1:-.}"
  local dir
  if [ -n "\${_DEV_ENV_FD}" ]; then
    dir="\$("\${_DEV_ENV_FD}" --type d --hidden --follow --exclude .git . "\${start}" | fzf --preview 'ls -la {}' --preview-window=right:50%:wrap)"
  else
    dir="\$(find "\${start}" -type d 2>/dev/null | fzf --preview 'ls -la {}' --preview-window=right:50%:wrap)"
  fi || return
  [ -n "\${dir}" ] && cd "\${dir}"
}

# fkill — fuzzy-select process(es) and kill them
#   fkill         SIGKILL (9)
#   fkill 15      SIGTERM
#   Tab           multi-select
fkill() {
  local signal="\${1:-9}"
  local pids
  pids="\$(ps -ef | sed 1d | fzf -m \\
    --header="Tab: multi-select   Enter: kill -\${signal}" \\
    --preview 'echo {}' --preview-window=down:3:wrap \\
    | awk '{print \$2}')" || return
  [ -z "\${pids}" ] && return
  echo "\${pids}" | xargs kill -"\${signal}"
  echo "Killed: \$(echo "\${pids}" | tr '\\n' ' ')"
}
# <<< dev-env-setup <<<
EOF
}

# Replace or append the managed block in the target rc file.
upsert_rc_block() {
    local rc_file="$1"
    local config="$2"

    touch "${rc_file}"

    local tmp_rc tmp_block
    tmp_rc="$(mktemp)"
    tmp_block="$(mktemp)"
    printf '%s\n' "${config}" > "${tmp_block}"

    if grep -qF "${BLOCK_START}" "${rc_file}"; then
        _info "Updating existing dev-env-setup configuration in ${rc_file} …"
        awk -v start="${BLOCK_START}" -v end="${BLOCK_END}" -v blockfile="${tmp_block}" '
            index($0, start) {
                printing=0
                while ((getline line < blockfile) > 0) print line
                close(blockfile)
                next
            }
            index($0, end) { printing=1; next }
            printing { print }
        ' printing=1 "${rc_file}" > "${tmp_rc}"
        mv "${tmp_rc}" "${rc_file}"
        _ok "Updated shell configuration in ${rc_file}"
    else
        _info "Appending dev-env-setup configuration to ${rc_file} …"
        printf '\n%s\n' "${config}" >> "${rc_file}"
        rm -f "${tmp_rc}"
        _ok "Appended shell configuration to ${rc_file}"
    fi

    rm -f "${tmp_block}"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
    if [[ "${SKIP_SHELL:-false}" == true ]]; then
        _info "Skipping Shell setup (--no-shell specified)"
        return 0
    fi

    detect_target_shell

    _info "Setting up shell environment and aliases …"
    _info "OS=${OS_TYPE}${LINUX_DISTRO:+ (${LINUX_DISTRO})} → ${TARGET_SHELL} (${TARGET_RC})"

    if [[ "${OS_TYPE}" == "macos" ]]; then
        _info "macOS: writing ~/.zshrc only (not ~/.bashrc)"
    else
        _info "Linux: writing ~/.bashrc only (not ~/.zshrc)"
    fi

    # Linux (Ubuntu/Debian especially): persist fzf key-bindings + completion
    # into ~/.config/fzf and keep history in ~/.cache/fzf.
    mkdir -p "${FZF_CACHE_DIR}"
    if [[ "${OS_TYPE}" == "linux" ]]; then
        _info "Installing fzf key-bindings/completion into ${FZF_CONFIG_DIR} …"
        install_fzf_user_files "${TARGET_SHELL}"
    fi

    local config
    config="$(build_config_block "${TARGET_SHELL}")"

    upsert_rc_block "${TARGET_RC}" "${config}"

    _ok "Shell environment setup complete"
}

main "$@"
