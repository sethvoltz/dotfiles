#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name // "unknown"')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
PCT_INT=${PCT%.*}
IN=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
OUT=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
RATE=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // ""')

# ANSI colors
RST=$'\e[0m'
BOLD=$'\e[1m'
DIM=$'\e[2m'

# Context bar colors based on usage
if [ "$PCT_INT" -ge 90 ]; then
  BAR_COLOR=$'\e[91m'
elif [ "$PCT_INT" -ge 70 ]; then
  BAR_COLOR=$'\e[93m'
else
  BAR_COLOR=$'\e[92m'
fi

# Build progress bar with literal block chars
BAR_WIDTH=15
FILLED=$(( PCT_INT * BAR_WIDTH / 100 ))
REMAINING=$(( BAR_WIDTH - FILLED ))

BAR=""
for (( i=0; i<FILLED; i++ )); do BAR+="█"; done
for (( i=0; i<REMAINING; i++ )); do BAR+="░"; done

fmt_tokens() {
  local n=$1
  if [ "$n" -ge 1000000 ]; then
    printf "%.1fM" "$(echo "$n / 1000000" | bc -l)"
  elif [ "$n" -ge 1000 ]; then
    printf "%.0fk" "$(echo "$n / 1000" | bc -l)"
  else
    echo "$n"
  fi
}

IN_FMT=$(fmt_tokens "$IN")
OUT_FMT=$(fmt_tokens "$OUT")

# Rate limit section (only if available)
RATE_SEC=""
if [ -n "$RATE" ]; then
  RATE_INT=${RATE%.*}
  if [ "$RATE_INT" -ge 80 ]; then
    RATE_CLR=$'\e[91m'
  elif [ "$RATE_INT" -ge 50 ]; then
    RATE_CLR=$'\e[93m'
  else
    RATE_CLR=$'\e[92m'
  fi
  RATE_SEC=" ${DIM}│${RST} ${RATE_CLR}${RATE_INT}%${RST} rate"
fi

echo "${BOLD}${MODEL}${RST} ${DIM}│${RST} ${BAR_COLOR}${BAR} ${PCT_INT}%${RST} ${DIM}│${RST} ${DIM}↓${RST}${IN_FMT} ${DIM}↑${RST}${OUT_FMT}${RATE_SEC}"
