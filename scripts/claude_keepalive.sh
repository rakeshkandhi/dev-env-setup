#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# DO NOT USE — kept for the record only. See the closed PR on this branch.
#
# Automating this ping violates Anthropic's Consumer Terms §3(7): "Except when
# you are accessing our Services via an Anthropic API Key or where we otherwise
# explicitly permit it, to access the Services through automated or non-human
# means, whether through a bot, script, or otherwise."
#
# It also does not work. The five-hour window is anchored to your first message
# and runs five hours from that instant — it is not a bucket that can be filled
# ahead of time. A ping at 09:00 followed by real work at 09:40 leaves 4h20m of
# window, where simply starting at 09:40 would have given the full five hours.
# Pre-opening windows banks nothing and forfeits the unused head of each one.
# ------------------------------------------------------------------------------
# ==============================================================================
# claude_keepalive.sh — Open a Claude usage window on a schedule
# ==============================================================================
# Sends the cheapest possible message to Claude ("hi") so that a five-hour
# usage window opens at a predictable clock time instead of whenever you happen
# to type your first prompt.
#
# Why this helps
# --------------
# On a Claude subscription the five-hour window starts with your *first*
# message and expires five hours later. Left alone, the window boundary drifts
# with your habits: start at 09:40 one day and 11:15 the next, and you can sit
# down mid-afternoon to find a window that resets in twelve minutes. Pinging on
# fixed anchors pins the boundaries to the clock, so "when does this reset" has
# the same answer every day.
#
# What this does NOT do: it does not create extra quota. The weekly cap is
# unaffected, and a window opened while another is still running is simply
# wasted. This buys predictability, not capacity.
#
# The ping itself is deliberately tiny — Haiku, no tools, no MCP servers, no
# CLAUDE.md, no session on disk. Measured cost is ~3.5k input / ~110 output
# tokens, which is noise against a five-hour window.
#
# Usage:
#     claude_keepalive.sh            # send the ping
#     claude_keepalive.sh --dry-run  # print what would run, send nothing
#
# Environment overrides:
#     CLAUDE_KEEPALIVE_MODEL   model alias for the ping   (default: haiku)
#     CLAUDE_KEEPALIVE_LOG     log file                   (default: ~/.local/state/claude-keepalive.log)
#     CLAUDE_KEEPALIVE_PROMPT  prompt text                (default: hi)
# ==============================================================================
set -uo pipefail

# cron hands us a near-empty PATH; claude lives in ~/.local/bin
export PATH="${HOME}/.local/bin:/usr/local/bin:/usr/bin:/bin"

readonly MODEL="${CLAUDE_KEEPALIVE_MODEL:-haiku}"
readonly PROMPT="${CLAUDE_KEEPALIVE_PROMPT:-hi}"
readonly LOG_FILE="${CLAUDE_KEEPALIVE_LOG:-${HOME}/.local/state/claude-keepalive.log}"
readonly LOCK_FILE="${TMPDIR:-/tmp}/claude-keepalive.lock"

readonly MAX_ATTEMPTS=2      # one retry covers a laptop that just woke up
readonly RETRY_DELAY=60      # seconds
readonly LOG_MAX_BYTES=$((256 * 1024))

log() {
    printf '%s  %s\n' "$(date '+%Y-%m-%d %H:%M:%S %z')" "$*" >> "${LOG_FILE}"
}

# Keep the log from growing without bound — halve it rather than truncating, so
# a failure that happened an hour ago is still readable after a rotation.
rotate_log() {
    local size
    size="$(stat -c %s "${LOG_FILE}" 2>/dev/null || stat -f %z "${LOG_FILE}" 2>/dev/null || echo 0)"
    (( size > LOG_MAX_BYTES )) || return 0
    local keep
    keep="$(tail -n 200 "${LOG_FILE}")"
    printf '%s\n' "${keep}" > "${LOG_FILE}"
}

# ---------------------------------------------------------------------------
# The ping
# ---------------------------------------------------------------------------
# --safe-mode is what keeps this cheap and inert: it drops CLAUDE.md, skills,
# plugins, hooks, MCP servers and custom agents while leaving auth working.
# (--bare would be leaner still, but it refuses OAuth and demands an API key.)
# Run from $HOME so no project directory is implicitly trusted.
ping_claude() {
    cd "${HOME}" || return 1
    claude \
        --safe-mode \
        --print "${PROMPT}" \
        --model "${MODEL}" \
        --tools "" \
        --no-session-persistence \
        --output-format json \
        2>&1
}

main() {
    mkdir -p "$(dirname "${LOG_FILE}")"

    if [[ "${1:-}" == "--dry-run" ]]; then
        printf 'would run: claude --safe-mode --print %q --model %s --tools "" --no-session-persistence --output-format json\n' \
            "${PROMPT}" "${MODEL}"
        printf 'logging to: %s\n' "${LOG_FILE}"
        return 0
    fi

    command -v claude >/dev/null 2>&1 || { log "SKIP  claude not on PATH"; return 1; }

    rotate_log

    local attempt output
    for (( attempt = 1; attempt <= MAX_ATTEMPTS; attempt++ )); do
        output="$(ping_claude)"

        # --output-format json always reports its own outcome; trust that over
        # the exit code, which is also non-zero for plain network failures.
        if grep -q '"is_error":false' <<< "${output}"; then
            local in_tok out_tok
            in_tok="$(grep -o '"input_tokens":[0-9]*' <<< "${output}" | head -1 | cut -d: -f2)"
            out_tok="$(grep -o '"output_tokens":[0-9]*' <<< "${output}" | head -1 | cut -d: -f2)"
            log "OK    window opened (model=${MODEL} in=${in_tok:-?} out=${out_tok:-?} attempt=${attempt})"
            return 0
        fi

        if (( attempt < MAX_ATTEMPTS )); then
            log "WARN  ping failed (attempt ${attempt}), retrying in ${RETRY_DELAY}s"
            sleep "${RETRY_DELAY}"
        fi
    done

    log "FAIL  ping failed after ${MAX_ATTEMPTS} attempts: $(tr '\n' ' ' <<< "${output}" | cut -c1-300)"
    return 1
}

# Overlap is possible when a retry is still sleeping as the next anchor fires;
# a second window would be wasted quota, so the later run just leaves.
if command -v flock >/dev/null 2>&1; then
    exec 9>"${LOCK_FILE}"
    flock -n 9 || exit 0
fi

main "$@"
