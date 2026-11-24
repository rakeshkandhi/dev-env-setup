#!/usr/bin/env bash
# ==============================================================================
# tmux_copy.sh — copy stdin to the system clipboard, wherever tmux is running
# ==============================================================================
# Reads text on stdin and puts it on the clipboard by every route available:
#
#   1. tmux paste buffer + OSC 52 escape sequence (`tmux load-buffer -w`).
#      OSC 52 hands the text to the terminal emulator itself, so it reaches the
#      clipboard of the machine you are sitting at — including over SSH, where
#      there is no local X display for xclip to talk to.
#   2. A native clipboard tool (pbcopy / wl-copy / xclip / xsel), used only when
#      a display is actually reachable.
#
# Always exits 0. A missing or failing clipboard tool must never make a tmux
# key binding report an error — the text still lands in the tmux paste buffer.
# ==============================================================================
set -uo pipefail

payload="$(cat)"
[[ -n "${payload}" ]] || exit 0

# 1. tmux paste buffer + OSC 52 to the terminal
printf '%s' "${payload}" | tmux load-buffer -w - 2>/dev/null || true

# 2. Native clipboard tool, only when there is a display to talk to
if [[ "$(uname)" == "Darwin" ]]; then
    if command -v pbcopy >/dev/null 2>&1; then
        printf '%s' "${payload}" | pbcopy 2>/dev/null || true
    fi
elif [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "${payload}" | wl-copy 2>/dev/null || true
elif [[ -n "${DISPLAY:-}" ]]; then
    if command -v xclip >/dev/null 2>&1; then
        printf '%s' "${payload}" | xclip -in -selection clipboard 2>/dev/null || true
    elif command -v xsel >/dev/null 2>&1; then
        printf '%s' "${payload}" | xsel -i --clipboard 2>/dev/null || true
    fi
fi

exit 0
