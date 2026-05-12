#!/usr/bin/env bash
# clean-my-mac: analyze_storage.sh
# Phase 0 — Disk analysis with zero deletions.
# Usage: bash analyze_storage.sh [--json]

set -euo pipefail

DRY_RUN=false
JSON_OUTPUT=false
[[ "${1:-}" == "--json" ]] && JSON_OUTPUT=true

# ─── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

# ─── Helpers ──────────────────────────────────────────────────────────────────
size_of() {
  local path="$1"
  if [[ -e "$path" ]]; then
    local sz
    sz=$(du -sh "$path" 2>/dev/null | cut -f1 | head -1) || true
    echo "${sz:-0B}"
  else
    echo "0B"
  fi
}

size_bytes() {
  local path="$1"
  [[ -e "$path" ]] && du -sk "$path" 2>/dev/null | cut -f1 || echo "0"
}

tool_installed() {
  command -v "$1" &>/dev/null && echo "yes" || echo "no"
}

# ─── System Overview ──────────────────────────────────────────────────────────
DISK_TOTAL=$(df -h / | awk 'NR==2{print $2}')
DISK_USED=$(df -h / | awk 'NR==2{print $3}')
DISK_FREE=$(df -h / | awk 'NR==2{print $4}')
DISK_PCT=$(df -h / | awk 'NR==2{print $5}')

# ─── Category Sizes ───────────────────────────────────────────────────────────
USER_CACHES=$(size_of ~/Library/Caches)
SYS_CACHES=$(size_of /Library/Caches)
USER_LOGS=$(size_of ~/Library/Logs)
SYS_LOGS=$(size_of /Library/Logs)
TRASH=$(size_of ~/.Trash)

XCODE_DERIVED=$(size_of ~/Library/Developer/Xcode/DerivedData)
XCODE_ARCHIVES=$(size_of ~/Library/Developer/Xcode/Archives)
SIMULATORS=$(size_of ~/Library/Developer/CoreSimulator/Devices)
IOS_BACKUPS=$(size_of ~/Library/Application\ Support/MobileSync/Backup)

HOMEBREW_CACHE=$(size_of ~/Library/Caches/Homebrew)
NPM_CACHE=$(size_of ~/.npm)
PNPM_STORE=$(size_of ~/.pnpm-store)
YARN_CACHE=$(size_of ~/.yarn/cache)
PIP_CACHE=$(size_of ~/Library/Caches/pip)
GRADLE_CACHE=$(size_of ~/.gradle/caches)
PUB_CACHE=$(size_of ~/.pub-cache)

DOCKER_INSTALLED=$(tool_installed docker)
DOCKER_INFO=""
if [[ "$DOCKER_INSTALLED" == "yes" ]]; then
  DOCKER_INFO=$(docker system df 2>/dev/null | awk 'NR==2{print $4" imgs"}' || echo "unknown")
fi

# AI model files — wrap xargs in subshell so empty-input failure doesn't propagate
AI_SIZE=$( (find ~ -type f \( -name "*.gguf" -o -name "*.safetensors" \) -size +100M 2>/dev/null || true) | \
  (xargs du -sk 2>/dev/null || true) | awk '{sum+=$1} END {printf "%.1fGB", sum/1024/1024}')
OLLAMA_SIZE=$(size_of ~/.ollama/models)
LMSTUDIO_SIZE=$(size_of ~/Library/Application\ Support/LM\ Studio)
HF_CACHE=$(size_of ~/.cache/huggingface)

# node_modules scan — prune media dirs; only count top-level (not nested) node_modules
_nm_find() {
  find ~ \
    \( -path "$HOME/Desktop" -o -path "$HOME/Movies" -o -path "$HOME/Music" \
       -o -path "$HOME/Pictures" -o -path "$HOME/.*" \) -prune \
    -o -name "node_modules" -type d -print 2>/dev/null
}
NM_COUNT=$( (_nm_find; true) | grep -v '.*/node_modules/.*/node_modules$' | wc -l | tr -d ' ')
NM_SIZE=$( (_nm_find; true) | grep -v '.*/node_modules/.*/node_modules$' | \
  (xargs du -sk 2>/dev/null || true) | awk '{sum+=$1} END {printf "%.1fGB", sum/1024/1024}')

# Time Machine snapshots
TM_SNAPS=$(tmutil listlocalsnapshots / 2>/dev/null | wc -l | tr -d ' ')

# Downloads
DOWNLOADS=$(size_of ~/Downloads)

# ─── Tool Detection ───────────────────────────────────────────────────────────
HAS_XCODE=$([[ -d /Applications/Xcode.app ]] && echo "yes" || echo "no")
HAS_BREW=$(tool_installed brew)
HAS_NODE=$(tool_installed node)
HAS_NPM=$(tool_installed npm)
HAS_PNPM=$(tool_installed pnpm)
HAS_YARN=$(tool_installed yarn)
HAS_PYTHON=$(tool_installed python3)
HAS_FLUTTER=$(tool_installed flutter)
HAS_GRADLE=$(tool_installed gradle)
HAS_DOCKER=$(tool_installed docker)
HAS_OLLAMA=$(tool_installed ollama)

# ─── Output ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║           CLEAN MY MAC — DISK ANALYSIS REPORT               ║${RESET}"
echo -e "${BOLD}╠══════════════════════════════════════════════════════════════╣${RESET}"
printf "${BOLD}║${RESET} Total: %-8s  Used: %-8s (%s)  Free: %-8s       ${BOLD}║${RESET}\n" \
  "$DISK_TOTAL" "$DISK_USED" "$DISK_PCT" "$DISK_FREE"
echo -e "${BOLD}╠══════════════════════════════════════════════════════════════╣${RESET}"
echo -e "${BOLD}║  CATEGORY                    SIZE        RISK    SAFE?       ║${RESET}"
echo -e "${BOLD}║  ──────────────────────────────────────────────────────────  ║${RESET}"
printf "║  %-28s %-10s  ${GREEN}LOW${RESET}     ✅ Yes        ║\n" "User Caches" "$USER_CACHES"
printf "║  %-28s %-10s  ${GREEN}LOW${RESET}     ✅ Yes        ║\n" "System Caches" "$SYS_CACHES"
printf "║  %-28s %-10s  ${GREEN}LOW${RESET}     ✅ Yes        ║\n" "User Logs" "$USER_LOGS"
printf "║  %-28s %-10s  ${GREEN}LOW${RESET}     ✅ Yes        ║\n" "Trash" "$TRASH"

if [[ "$HAS_XCODE" == "yes" ]]; then
  printf "║  %-28s %-10s  ${GREEN}LOW${RESET}     ✅ Yes        ║\n" "Xcode DerivedData" "$XCODE_DERIVED"
  printf "║  %-28s %-10s  ${YELLOW}MED${RESET}     ⚠️  Confirm    ║\n" "Xcode Archives" "$XCODE_ARCHIVES"
  printf "║  %-28s %-10s  ${YELLOW}MED${RESET}     ⚠️  Confirm    ║\n" "iOS Simulators" "$SIMULATORS"
  printf "║  %-28s %-10s  ${RED}HIGH${RESET}    ❗ Warn hard  ║\n" "iOS Device Backups" "$IOS_BACKUPS"
fi

[[ "$HAS_BREW" == "yes" ]]   && printf "║  %-28s %-10s  ${GREEN}LOW${RESET}     ✅ Yes        ║\n" "Homebrew Cache" "$HOMEBREW_CACHE"
[[ "$HAS_NPM" == "yes" ]]    && printf "║  %-28s %-10s  ${GREEN}LOW${RESET}     ✅ Yes        ║\n" "npm Cache" "$NPM_CACHE"
[[ "$HAS_PNPM" == "yes" ]]   && printf "║  %-28s %-10s  ${GREEN}LOW${RESET}     ✅ Yes        ║\n" "pnpm Store" "$PNPM_STORE"
[[ "$HAS_YARN" == "yes" ]]   && printf "║  %-28s %-10s  ${GREEN}LOW${RESET}     ✅ Yes        ║\n" "Yarn Cache" "$YARN_CACHE"
[[ "$HAS_PYTHON" == "yes" ]] && printf "║  %-28s %-10s  ${GREEN}LOW${RESET}     ✅ Yes        ║\n" "pip Cache" "$PIP_CACHE"
[[ "$HAS_FLUTTER" == "yes" ]] && printf "║  %-28s %-10s  ${GREEN}LOW${RESET}     ✅ Yes        ║\n" "Dart pub-cache" "$PUB_CACHE"
[[ "$HAS_GRADLE" == "yes" ]]  && printf "║  %-28s %-10s  ${GREEN}LOW${RESET}     ✅ Yes        ║\n" "Gradle Cache" "$GRADLE_CACHE"

if [[ "$HAS_DOCKER" == "yes" ]]; then
  printf "║  %-28s %-10s  ${YELLOW}MED${RESET}     ⚠️  Confirm    ║\n" "Docker Images/Data" "${DOCKER_INFO:-?}"
fi

printf "║  %-28s %-10s  ${YELLOW}MED${RESET}     ⚠️  Review    ║\n" "node_modules ($NM_COUNT dirs)" "$NM_SIZE"
printf "║  %-28s %-10s  ${RED}HIGH${RESET}    ❗ List only  ║\n" "AI Model Files" "${AI_SIZE:-0B}"
printf "║  %-28s %-10s  ${YELLOW}MED${RESET}     ⚠️  Confirm    ║\n" "Time Machine Snaps ($TM_SNAPS)" "~varies"
printf "║  %-28s %-10s  ${YELLOW}MED${RESET}     ⚠️  Review    ║\n" "Downloads" "$DOWNLOADS"
echo -e "${BOLD}╠══════════════════════════════════════════════════════════════╣${RESET}"
echo -e "${BOLD}║  Detected tools:${RESET}"
echo "║  $([ "$HAS_XCODE" == "yes" ]  && echo "✅" || echo "⬜") Xcode    $([ "$HAS_BREW" == "yes" ]  && echo "✅" || echo "⬜") Homebrew  $([ "$HAS_NODE" == "yes" ]  && echo "✅" || echo "⬜") Node.js   $([ "$HAS_DOCKER" == "yes" ] && echo "✅" || echo "⬜") Docker"
echo "║  $([ "$HAS_PNPM" == "yes" ]   && echo "✅" || echo "⬜") pnpm     $([ "$HAS_YARN" == "yes" ]  && echo "✅" || echo "⬜") Yarn      $([ "$HAS_FLUTTER" == "yes" ] && echo "✅" || echo "⬜") Flutter   $([ "$HAS_OLLAMA" == "yes" ] && echo "✅" || echo "⬜") Ollama"
echo -e "${BOLD}╚══════════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "${BOLD}Top 15 largest directories in your home folder:${RESET}"
{ du -sh ~/* ~/.[^.]* 2>/dev/null || true; } | sort -rh | head -15
echo ""
