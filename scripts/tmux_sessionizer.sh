#!/usr/bin/env bash
# ==============================================================================
# tmux_sessionizer.sh — Instant Tmux Project & Session Switcher
# ==============================================================================
# Fuzzy-finds project directories using fzf and creates or switches to a
# dedicated tmux session in zero keystrokes.
#
# Usage:
#   tmux_sessionizer.sh            # Interactively select directory via fzf
#   tmux_sessionizer.sh <path>     # Directly open/switch session for <path>
# ==============================================================================
set -euo pipefail

# 1. Determine target directory
if [[ $# -eq 1 ]]; then
    selected="$1"
else
    search_dirs=()
    for d in "${HOME}/code" "${HOME}/personal" "${HOME}/projects" "${HOME}/work" "${HOME}/.config" "${HOME}/src"; do
        [[ -d "${d}" ]] && search_dirs+=("${d}")
    done

    if [[ ${#search_dirs[@]} -eq 0 ]]; then
        search_dirs=("${HOME}")
    fi

    if command -v fd >/dev/null 2>&1; then
        selected="$(fd . "${search_dirs[@]}" --min-depth 1 --max-depth 2 --type d --hidden --exclude .git 2>/dev/null | fzf --prompt="Select Project > " --preview 'ls -la {}' --preview-window=right:50%:wrap)"
    elif command -v fdfind >/dev/null 2>&1; then
        selected="$(fdfind . "${search_dirs[@]}" --min-depth 1 --max-depth 2 --type d --hidden --exclude .git 2>/dev/null | fzf --prompt="Select Project > " --preview 'ls -la {}' --preview-window=right:50%:wrap)"
    else
        selected="$(find "${search_dirs[@]}" -mindepth 1 -maxdepth 2 -type d 2>/dev/null | fzf --prompt="Select Project > " --preview 'ls -la {}' --preview-window=right:50%:wrap)"
    fi
fi

if [[ -z "${selected:-}" ]]; then
    exit 0
fi

# 2. Sanitize name for tmux session ID
selected_name="$(basename "${selected}" | tr '.:' '__')"

# 3. Create session if it doesn't exist
if ! tmux has-session -t="${selected_name}" 2>/dev/null; then
    tmux new-session -ds "${selected_name}" -c "${selected}"
fi

# 4. Switch or attach depending on whether we are currently inside tmux
if [[ -z "${TMUX:-}" ]]; then
    tmux attach-session -t "${selected_name}"
else
    tmux switch-client -t "${selected_name}"
fi
