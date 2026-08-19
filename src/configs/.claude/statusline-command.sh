#!/usr/bin/env bash
# Claude Code statusLine
#
# Visible segments: cwd, git branch, git worktree, GitHub repo, Azure
# subscription, Kubernetes context/namespace, GitHub CLI active user, model
# name, context remaining %.
# All optional segments are conditional on the relevant CLI/config being
# present and applicable to the current directory, and all of them avoid
# network calls entirely (local file / cached-profile reads only) to keep
# prompt rendering fast.
#
# This script also preserves the Dorothy "Dev Bar" side-effect writes
# (rate-limits.json / token-stats.json) that were present in the previous
# statusline command (~/.dorothy/statusline.sh), so the Dorothy app's Usage
# page keeps working.

set -uo pipefail

INPUT=$(cat)

# ---------------------------------------------------------------------------
# Dorothy Dev Bar integration (preserved from prior statusline.sh) ----------
# ---------------------------------------------------------------------------
RATE_LIMITS_FILE="$HOME/.dorothy/rate-limits.json"
RATE_LIMITS=$(echo "$INPUT" | jq -c '.rate_limits // empty' 2>/dev/null || true)
if [ -n "$RATE_LIMITS" ] && [ "$RATE_LIMITS" != "null" ]; then
  echo "$RATE_LIMITS" > "$RATE_LIMITS_FILE" 2>/dev/null || true
fi

TOKEN_STATS_FILE="$HOME/.dorothy/token-stats.json"
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null || true)
if [ -n "$SESSION_ID" ]; then
  T_IN=$(echo "$INPUT" | jq -r '.context_window.total_input_tokens // 0' 2>/dev/null || echo 0)
  T_OUT=$(echo "$INPUT" | jq -r '.context_window.total_output_tokens // 0' 2>/dev/null || echo 0)
  T_COST=$(echo "$INPUT" | jq -r '.cost.total_cost_usd // 0' 2>/dev/null || echo 0)
  T_MODEL=$(echo "$INPUT" | jq -r '.model.model_id // .model.display_name // "unknown"' 2>/dev/null || echo "unknown")

  PCT_5H=$(echo "$INPUT" | jq -r '.rate_limits.five_hour.used_percentage // 0' 2>/dev/null || echo 0)
  PCT_7D=$(echo "$INPUT" | jq -r '.rate_limits.seven_day.used_percentage // 0' 2>/dev/null || echo 0)
  IS_EXTRA="false"
  if [ "$(echo "$PCT_5H > 100" | bc -l 2>/dev/null || echo 0)" = "1" ] || [ "$(echo "$PCT_7D > 100" | bc -l 2>/dev/null || echo 0)" = "1" ]; then
    IS_EXTRA="true"
  fi

  LOCK_DIR="$HOME/.dorothy/token-stats.lock"
  LOCK_ACQUIRED=false
  for _i in $(seq 1 20); do
    if mkdir "$LOCK_DIR" 2>/dev/null; then
      LOCK_ACQUIRED=true
      break
    fi
    sleep 0.05
  done
  if [ "$LOCK_ACQUIRED" = "false" ] && [ -d "$LOCK_DIR" ]; then
    LOCK_AGE=$(( $(date +%s) - $(stat -f%m "$LOCK_DIR" 2>/dev/null || stat -c%Y "$LOCK_DIR" 2>/dev/null || echo 0) ))
    if [ "$LOCK_AGE" -gt 5 ]; then
      rmdir "$LOCK_DIR" 2>/dev/null || true
      mkdir "$LOCK_DIR" 2>/dev/null && LOCK_ACQUIRED=true
    fi
  fi

  if [ "$LOCK_ACQUIRED" = "true" ]; then
    trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT
    if [ -f "$TOKEN_STATS_FILE" ]; then
      EXISTING=$(cat "$TOKEN_STATS_FILE" 2>/dev/null || echo '{}')
    else
      EXISTING='{}'
    fi
    T_DATE=$(date +%Y-%m-%d)
    TMP_FILE="${TOKEN_STATS_FILE}.tmp.$$"
    echo "$EXISTING" | jq -c \
      --arg sid "$SESSION_ID" \
      --argjson tin "$T_IN" \
      --argjson tout "$T_OUT" \
      --argjson cost "$T_COST" \
      --arg model "$T_MODEL" \
      --argjson extra "$IS_EXTRA" \
      --arg date "$T_DATE" \
      '.[$sid] = {"in": $tin, "out": $tout, "cost": $cost, "model": $model, "extra": $extra, "date": $date}' \
      > "$TMP_FILE" 2>/dev/null && mv "$TMP_FILE" "$TOKEN_STATS_FILE" 2>/dev/null || rm -f "$TMP_FILE"
    rmdir "$LOCK_DIR" 2>/dev/null || true
  fi
fi

# ---------------------------------------------------------------------------
# Colors (the footer already renders dimmed, so plain ANSI colors are used)
# ---------------------------------------------------------------------------
RESET=$'\033[0m'
DIM=$'\033[2m'
CYAN=$'\033[36m'
YELLOW=$'\033[33m'
MAGENTA=$'\033[35m'
GREEN=$'\033[32m'
BLUE=$'\033[34m'
WHITE=$'\033[37m'
RED=$'\033[31m'

SEP="${DIM} │ ${RESET}"

segments=()

# ---------------------------------------------------------------------------
# Current directory
# ---------------------------------------------------------------------------
CWD=$(echo "$INPUT" | jq -r '.workspace.current_dir // .cwd // empty')
if [ -n "$CWD" ]; then
  DIR_DISPLAY="${CWD/#$HOME/~}"
  segments+=("${CYAN}${DIR_DISPLAY}${RESET}")
fi

# ---------------------------------------------------------------------------
# Git branch, worktree, GitHub repo (fast, local-only git calls)
# ---------------------------------------------------------------------------
if [ -n "$CWD" ] && git -C "$CWD" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  BRANCH=$(git -C "$CWD" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
  if [ -z "$BRANCH" ]; then
    BRANCH=$(git -C "$CWD" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  fi
  [ -n "$BRANCH" ] && segments+=("${MAGENTA} ${BRANCH}${RESET}")

  GIT_DIR=$(git -C "$CWD" --no-optional-locks rev-parse --git-dir 2>/dev/null)
  COMMON_DIR=$(git -C "$CWD" --no-optional-locks rev-parse --git-common-dir 2>/dev/null)
  if [ -n "$GIT_DIR" ] && [ -n "$COMMON_DIR" ]; then
    [[ "$GIT_DIR" == /* ]] || GIT_DIR="$CWD/$GIT_DIR"
    [[ "$COMMON_DIR" == /* ]] || COMMON_DIR="$CWD/$COMMON_DIR"
    GIT_DIR_ABS=$(cd "$GIT_DIR" 2>/dev/null && pwd -P)
    COMMON_DIR_ABS=$(cd "$COMMON_DIR" 2>/dev/null && pwd -P)
    if [ -n "$GIT_DIR_ABS" ] && [ -n "$COMMON_DIR_ABS" ] && [ "$GIT_DIR_ABS" != "$COMMON_DIR_ABS" ]; then
      WT_ROOT=$(git -C "$CWD" --no-optional-locks rev-parse --show-toplevel 2>/dev/null)
      WT_NAME=$(basename "${WT_ROOT:-$CWD}")
      segments+=("${RED}wt:${WT_NAME}${RESET}")
    fi
  fi

  ORIGIN_URL=$(git -C "$CWD" --no-optional-locks remote get-url origin 2>/dev/null)
  if [ -n "$ORIGIN_URL" ] && [[ "$ORIGIN_URL" == *github.com* ]]; then
    GH_REPO=$(echo "$ORIGIN_URL" | sed -E 's#.*github\.com[:/]##; s#\.git$##')
    [ -n "$GH_REPO" ] && segments+=("${WHITE}${GH_REPO}${RESET}")
  fi
fi

# ---------------------------------------------------------------------------
# Azure CLI current subscription (cached local profile, no network call)
# ---------------------------------------------------------------------------
if command -v az >/dev/null 2>&1; then
  AZ_CONFIG_DIR="${AZURE_CONFIG_DIR:-$HOME/.azure}"
  AZ_PROFILE="$AZ_CONFIG_DIR/azureProfile.json"
  if [ -f "$AZ_PROFILE" ]; then
    AZ_SUB=$(jq -r '.subscriptions[]? | select(.isDefault==true) | .name' "$AZ_PROFILE" 2>/dev/null | head -n1)
    if [ -n "$AZ_SUB" ] && [ "$AZ_SUB" != "null" ]; then
      segments+=("${BLUE}az:${AZ_SUB}${RESET}")
    fi
  fi
fi

# ---------------------------------------------------------------------------
# Kubernetes current context/namespace (local kubeconfig read only, no API calls)
# ---------------------------------------------------------------------------
if command -v kubectl >/dev/null 2>&1; then
  K8S_CTX=$(kubectl config current-context 2>/dev/null)
  if [ -n "$K8S_CTX" ]; then
    K8S_NS=$(kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null)
    [ -z "$K8S_NS" ] && K8S_NS="default"
    segments+=("${BLUE}k8s:${K8S_CTX}/${K8S_NS}${RESET}")
  fi
fi

# ---------------------------------------------------------------------------
# GitHub CLI active user — read directly from the local hosts.yml (no `gh`
# invocation, no network call, no cache needed). Only the `user:` login
# field nested directly under the `github.com:` host entry is read; token
# values in that file are never touched or displayed.
# ---------------------------------------------------------------------------
GH_HOSTS_FILE="$HOME/.config/gh/hosts.yml"
if [ -f "$GH_HOSTS_FILE" ]; then
  GH_ACTIVE_USER=$(awk '
    /^[^[:space:]]/ { in_host = ($0 ~ /^github\.com:/) ? 1 : 0; next }
    in_host && /^[[:space:]]+user:/ {
      sub(/^[[:space:]]+user:[[:space:]]*/, "")
      gsub(/^"|"$/, "")
      print
      exit
    }
  ' "$GH_HOSTS_FILE" 2>/dev/null)
  [ -n "$GH_ACTIVE_USER" ] && segments+=("${GREEN}gh:${GH_ACTIVE_USER}${RESET}")
fi

# ---------------------------------------------------------------------------
# Model name + context remaining %
# ---------------------------------------------------------------------------
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // empty')
[ -n "$MODEL" ] && segments+=("${WHITE}${MODEL}${RESET}")

CTX_REMAINING=$(echo "$INPUT" | jq -r '.context_window.remaining_percentage // empty')
if [ -n "$CTX_REMAINING" ] && [ "$CTX_REMAINING" != "null" ]; then
  CTX_INT=$(awk -v p="$CTX_REMAINING" 'BEGIN { printf "%d", p }')
  if [ "$CTX_INT" -ge 50 ]; then
    CTX_COLOR="$GREEN"
  elif [ "$CTX_INT" -ge 20 ]; then
    CTX_COLOR="$YELLOW"
  else
    CTX_COLOR="$RED"
  fi
  segments+=("${CTX_COLOR}ctx:${CTX_INT}%${RESET}")
fi

# ---------------------------------------------------------------------------
# Join and print
# ---------------------------------------------------------------------------
OUT=""
for s in "${segments[@]}"; do
  if [ -z "$OUT" ]; then
    OUT="$s"
  else
    OUT="${OUT}${SEP}${s}"
  fi
done

printf "%s\n" "$OUT"
