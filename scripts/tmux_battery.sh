#!/usr/bin/env bash
# ==============================================================================
# tmux_battery.sh — Battery indicator for the tmux status bar
# ==============================================================================
# Prints a Nerd Font battery icon, the charge percentage, and a trailing
# separator, e.g.
#
#     54% │       (discharging, half full)
#     54% │       (charging — bolt icon)
#
# Prints nothing at all when no battery is present (desktops, VMs). The
# separator is part of this script's output rather than the theme so that it
# disappears together with the reading — otherwise battery-less machines render
# an orphan "│  │" in the status bar.
#
# Colour always tracks the charge level, so a low battery still warns while
# plugged in. The bolt icon is what signals "charging".
#
# Reports the first battery present. Multi-battery machines (some ThinkPads)
# will show BAT0 only, not a combined charge.
#
# Supports Linux (/sys/class/power_supply) and macOS (pmset).
#
# Usage from tmux.conf / a theme file:
#     #(~/.local/bin/tmux-battery)
# ==============================================================================
set -uo pipefail

# Catppuccin Mocha — kept in sync with tmux/themes/catppuccin.conf
readonly C_GREEN='#A6E3A1'    # charging, healthy level
readonly C_PEACH='#FAB387'    # low
readonly C_RED='#F38BA8'      # critical
readonly C_TEXT='#CDD6F4'     # normal
readonly C_SEP='#585B70'      # separator

# ---------------------------------------------------------------------------
# Read battery state
# ---------------------------------------------------------------------------
# Sets two globals:
#   percent   integer 0–100
#   charging  true / false
# Returns non-zero when there is no battery to report.
read_battery() {
    if [[ "$(uname)" == "Darwin" ]]; then
        local output line
        output="$(pmset -g batt 2>/dev/null)" || return 1

        # Isolate the internal battery's line first — an attached UPS also
        # reports a percentage and would otherwise win the parse.
        line="$(printf '%s\n' "${output}" | grep 'InternalBattery' | head -1)"
        [[ -n "${line}" ]] || return 1

        percent="$(printf '%s' "${line}" | grep -o '[0-9]\{1,3\}%' | head -1 | tr -d '%')"
        [[ "${percent}" =~ ^[0-9]+$ ]] || return 1

        # "AC Power" also covers a fully-charged machine still plugged in
        case "${line}" in
            *discharging*) charging=false ;;
            *)             charging=true  ;;
        esac
        return 0
    fi

    # Linux — first present battery (BAT0, BAT1, …)
    local bat status
    for bat in /sys/class/power_supply/BAT*; do
        [[ -r "${bat}/capacity" ]] || continue

        # An empty bay can leave its sysfs node behind, reading a bogus 0%
        [[ -r "${bat}/present" && "$(< "${bat}/present")" == "0" ]] && continue

        # Guard against an empty or non-numeric read: bash treats a null value
        # as 0 in arithmetic, which would raise a false critical warning
        percent="$(< "${bat}/capacity")"
        [[ "${percent}" =~ ^[0-9]+$ ]] || continue

        status=""
        [[ -r "${bat}/status" ]] && status="$(< "${bat}/status")"

        # Only an explicit plugged-in state counts as charging. Drivers report
        # "Unknown" after resume, and defaulting that to charging would both
        # show a false bolt and mask a low-battery warning.
        case "${status}" in
            Charging|Full|"Not charging") charging=true  ;;
            *)                            charging=false ;;
        esac
        return 0
    done

    return 1
}

# ---------------------------------------------------------------------------
# Icon — the bolt is what signals "plugged in"
# ---------------------------------------------------------------------------
battery_icon() {
    if [[ "${charging}" == true ]]; then
        printf ''          # bolt — plugged in
    elif (( percent >= 88 )); then
        printf ''          # full
    elif (( percent >= 63 )); then
        printf ''          # three quarters
    elif (( percent >= 38 )); then
        printf ''          # half
    elif (( percent >= 13 )); then
        printf ''          # quarter
    else
        printf ''          # empty
    fi
}

# ---------------------------------------------------------------------------
# Colour — level first, so a low battery still warns while charging
# ---------------------------------------------------------------------------
battery_color() {
    if (( percent <= 15 )); then
        printf '%s' "${C_RED}"
    elif (( percent <= 35 )); then
        printf '%s' "${C_PEACH}"
    elif [[ "${charging}" == true ]]; then
        printf '%s' "${C_GREEN}"
    else
        printf '%s' "${C_TEXT}"
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
    local percent charging
    read_battery || exit 0   # no battery — print nothing, separator included

    printf '#[fg=%s]%s %s%% #[fg=%s]│ ' \
        "$(battery_color)" "$(battery_icon)" "${percent}" "${C_SEP}"
}

main "$@"
