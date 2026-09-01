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
# setup_claude_keepalive.sh — Schedule the Claude usage-window ping
# ==============================================================================
# • Symlinks claude_keepalive.sh → ~/.local/bin/claude-keepalive
# • Installs a cron entry that pings Claude on five fixed daily anchors
#
# Anchors are derived from your workday start hour: START, +5h, +10h, +15h,
# +20h. Five anchors is the most a 24-hour day allows, so exactly one gap is
# four hours rather than five — deriving the anchors from START puts that short
# gap in the four hours before you start, where it costs nothing.
#
# With --start-hour 9 the anchors are 00, 05, 09, 14, 19 and the short gap
# falls between 05:00 and 09:00.
#
# cron is used rather than a systemd user timer because this account has
# lingering disabled, so user timers would only fire while you are logged in.
#
# Usage:
#     setup_claude_keepalive.sh                  # install, anchored on 09:00
#     setup_claude_keepalive.sh --start-hour 7   # install, anchored on 07:00
#     setup_claude_keepalive.sh --status         # show schedule and recent log
#     setup_claude_keepalive.sh --uninstall      # remove the cron entry
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
readonly SOURCE_SCRIPT="${REPO_DIR}/scripts/claude_keepalive.sh"
readonly BIN_DIR="${HOME}/.local/bin"
readonly BIN_LINK="${BIN_DIR}/claude-keepalive"
readonly LOG_FILE="${HOME}/.local/state/claude-keepalive.log"

# Fenced block so the entry can be rewritten or removed without touching any
# other cron job you have.
readonly MARK_BEGIN='# >>> claude-keepalive (dev-env-setup) >>>'
readonly MARK_END='# <<< claude-keepalive (dev-env-setup) <<<'

START_HOUR=9
ACTION=install

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while (( $# )); do
    case "$1" in
        --start-hour) START_HOUR="${2:-}"; shift 2 ;;
        --uninstall)  ACTION=uninstall; shift ;;
        --status)     ACTION=status; shift ;;
        -h|--help)    sed -n '2,30p' "${BASH_SOURCE[0]}"; exit 0 ;;
        *)            _err "unknown option: $1"; exit 1 ;;
    esac
done

if ! [[ "${START_HOUR}" =~ ^[0-9]{1,2}$ ]] || (( START_HOUR > 23 )); then
    _err "--start-hour must be an integer 0-23 (got: ${START_HOUR})"
    exit 1
fi

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
# START, +5, +10, +15, +20 (mod 24), sorted — cron wants ascending hours.
anchor_hours() {
    local offset hours=()
    for offset in 0 5 10 15 20; do
        hours+=( $(( (START_HOUR + offset) % 24 )) )
    done
    printf '%s\n' "${hours[@]}" | sort -n | paste -sd,
}

read_crontab() { crontab -l 2>/dev/null || true; }

# Everything outside the fence, with the fence itself dropped.
crontab_without_block() {
    read_crontab | awk -v b="${MARK_BEGIN}" -v e="${MARK_END}" '
        $0 == b { skip = 1; next }
        $0 == e { skip = 0; next }
        !skip
    '
}

# ---------------------------------------------------------------------------
# Actions
# ---------------------------------------------------------------------------
do_status() {
    _info "cron entry:"
    if read_crontab | grep -qF "${MARK_BEGIN}"; then
        read_crontab | sed -n "/${MARK_BEGIN}/,/${MARK_END}/p" | sed 's/^/    /'
    else
        _warn "    not installed"
    fi

    _info "recent pings (${LOG_FILE}):"
    if [[ -f "${LOG_FILE}" ]]; then
        tail -n 10 "${LOG_FILE}" | sed 's/^/    /'
    else
        _warn "    no log yet"
    fi
}

do_uninstall() {
    if ! read_crontab | grep -qF "${MARK_BEGIN}"; then
        _warn "cron entry not present — nothing to remove"
    else
        crontab_without_block | crontab -
        _ok "removed cron entry"
    fi
    [[ -L "${BIN_LINK}" ]] && rm -f "${BIN_LINK}" && _ok "removed ${BIN_LINK}"
    _info "log kept at ${LOG_FILE}"
}

do_install() {
    [[ -f "${SOURCE_SCRIPT}" ]] || { _err "missing ${SOURCE_SCRIPT}"; exit 1; }
    command -v crontab >/dev/null 2>&1 || { _err "crontab not found"; exit 1; }
    command -v claude  >/dev/null 2>&1 || _warn "claude not on PATH right now — the ping will log a SKIP until it is"

    mkdir -p "${BIN_DIR}" "$(dirname "${LOG_FILE}")"
    chmod +x "${SOURCE_SCRIPT}"
    ln -sfn "${SOURCE_SCRIPT}" "${BIN_LINK}"
    _ok "linked ${BIN_LINK} → ${SOURCE_SCRIPT}"

    local hours
    hours="$(anchor_hours)"

    # Absolute path, not $HOME — cron's shell is minimal and the symlink target
    # must resolve without any profile being sourced.
    {
        crontab_without_block
        printf '%s\n' "${MARK_BEGIN}"
        printf '0 %s * * * %s >/dev/null 2>&1\n' "${hours}" "${BIN_LINK}"
        printf '%s\n' "${MARK_END}"
    } | crontab -

    _ok "cron entry installed: hourly anchors ${hours//,/, }:00 (local time)"
    _info "workday start assumed ${START_HOUR}:00 — the 4-hour gap sits just before it"
    _info "log: ${LOG_FILE}"
    _info "verify now with: ${BIN_LINK} && tail -n 3 ${LOG_FILE}"
}

case "${ACTION}" in
    install)   do_install ;;
    uninstall) do_uninstall ;;
    status)    do_status ;;
esac
