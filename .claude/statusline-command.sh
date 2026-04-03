#!/usr/bin/env bash
# Claude Code status line — base shell segments + Claude signals

input=$(cat)
field() { echo "$input" | jq -r "$1 // empty"; }

# ── shell segments ───────────────────────────────────────────────
user=$(whoami)
cwd=$(field '.workspace.current_dir')
short_cwd="${cwd/#$HOME/~}"
branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
venv=$(basename "${VIRTUAL_ENV:-}" 2>/dev/null)

# hostname only on remote (SSH)
host_seg=""
[ -n "${SSH_CONNECTION:-}" ] && host_seg="@$(hostname -s) "

# ── claude segments ──────────────────────────────────────────────
model=$(field '.model.display_name')
ctx=$(field '.context_window.used_percentage')
r5h=$(field '.rate_limits.five_hour.used_percentage')
r7d=$(field '.rate_limits.seven_day.used_percentage')
cost=$(field '.cost.total_cost_usd')
lines_add=$(field '.cost.total_lines_added')
lines_rem=$(field '.cost.total_lines_removed')
dur_ms=$(field '.cost.total_duration_ms')
style=$(field '.output_style.name')

# ── colors ───────────────────────────────────────────────────────
R=$'\033[0m'
DIM=$'\033[2m'
BLUE=$'\033[0;34m'
CYAN=$'\033[0;36m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
RED=$'\033[0;31m'
MAGENTA=$'\033[0;35m'

pct() { printf '%.0f' "$1" 2>/dev/null; }

# Color by threshold: green → yellow → red as usage increases
color_pct() {
  local val=$(pct "$1") warn="${2:-50}" crit="${3:-75}"
  local color=$GREEN
  [ "$val" -ge "$warn" ] && color=$YELLOW
  [ "$val" -ge "$crit" ] && color=$RED
  printf "${color}%s${R}" "${val}%"
}

# Output style: concise=green (cheap), default=yellow, verbose/markdown=red (expensive)
style_color() {
  case "$1" in
    concise)  printf "${GREEN}%s${R}" "$1" ;;
    default)  printf "${YELLOW}%s${R}" "$1" ;;
    *)        printf "${RED}%s${R}" "$1" ;;
  esac
}

# Cost: green <$10, yellow <$50, red >=$50
color_cost() {
  local val=$(printf '%.0f' "$1" 2>/dev/null)
  local color=$GREEN
  [ "$val" -ge 10 ] && color=$YELLOW
  [ "$val" -ge 50 ] && color=$RED
  printf "${color}\$%.2f${R}" "$1"
}

fmt_lines() {
  printf "${CYAN}+%s/-%s${R}" "$1" "$2"
}

fmt_dur() {
  local min="$1"
  if [ "$min" -ge 60 ]; then
    printf "${CYAN}%sh%sm${R}" "$(( min / 60 ))" "$(( min % 60 ))"
  else
    printf "${CYAN}%sm${R}" "$min"
  fi
}

# ── build shell part ─────────────────────────────────────────────
out="${BLUE}${user}${host_seg}${R} ${CYAN}${short_cwd}${R}"
[ -n "$branch" ] && out="${out} ${MAGENTA}${branch}${R}"
[ -n "$venv" ] && out="${out} ${DIM}(${venv})${R}"

# ── build claude part ────────────────────────────────────────────
parts=()
[ -n "$model" ] && parts+=("${GREEN}${model}${R}")
[ -n "$style" ] && parts+=("$(style_color "$style")")
[ -n "$ctx" ] && parts+=("ctx:$(color_pct "$ctx" 50 75)")
[ -n "$r5h" ] && parts+=("5h:$(color_pct "$r5h" 50 80)")
[ -n "$r7d" ] && parts+=("7d:$(color_pct "$r7d" 50 80)")
[ -n "$cost" ] && parts+=("$(color_cost "$cost")")
if [ -n "$lines_add" ] && [ -n "$lines_rem" ]; then
  parts+=("$(fmt_lines "$lines_add" "$lines_rem")")
fi
if [ -n "$dur_ms" ]; then
  dur_min=$(( ${dur_ms%.*} / 60000 ))
  parts+=("$(fmt_dur "$dur_min")")
fi

if [ ${#parts[@]} -gt 0 ]; then
  out="${out} | ${parts[*]}"
fi

printf '%s' "$out"
