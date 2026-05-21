#!/usr/bin/env bash
# clean-my-mac: cleanup_node.sh
# Cleans npm, pnpm, yarn caches + lists node_modules for review.
# Usage: bash cleanup_node.sh [--dry-run]

set -euo pipefail
DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

BOLD='\033[1m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RESET='\033[0m'
LOG_FILE=~/clean-my-mac-log-$(date +%Y-%m-%d).txt
log() { echo "$1" | tee -a "$LOG_FILE"; }
size_of() { [[ -e "$1" ]] && du -sh "$1" 2>/dev/null | cut -f1 || echo "0B"; }

echo ""
echo -e "${BOLD}Node.js Ecosystem Cleanup${RESET}"

# npm cache
if command -v npm &>/dev/null; then
  echo -e "\n${GREEN}npm cache:${RESET} $(size_of ~/.npm)"
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "  [DRY-RUN] Would run: npm cache clean --force"
  else
    if npm cache clean --force 2>/dev/null; then
      log "✅ npm cache cleared"
    else
      echo "  ⚠️  npm cache clean failed (likely root-owned files). Removing ~/.npm directly..."
      rm -rf ~/.npm 2>/dev/null && log "✅ npm cache removed (rm -rf ~/.npm)" || \
        log "  ❌ Failed to remove ~/.npm — run: sudo chown -R \$(id -u):\$(id -g) ~/.npm"
    fi
  fi
fi

# pnpm store
if command -v pnpm &>/dev/null; then
  PNPM_STORE=$(pnpm store path 2>/dev/null || echo ~/.pnpm-store)
  echo -e "\n${GREEN}pnpm store:${RESET} $(size_of "$PNPM_STORE")"
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "  [DRY-RUN] Would run: pnpm store prune"
  else
    pnpm store prune 2>/dev/null && log "✅ pnpm store pruned"
  fi
fi

# yarn cache
if command -v yarn &>/dev/null; then
  YARN_CACHE=$(yarn cache dir 2>/dev/null || echo ~/.yarn/cache)
  echo -e "\n${GREEN}Yarn cache:${RESET} $(size_of "$YARN_CACHE")"
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "  [DRY-RUN] Would run: yarn cache clean"
  else
    yarn cache clean 2>/dev/null && log "✅ yarn cache cleaned"
  fi
fi

# node_modules finder — LIST ONLY, never auto-delete
echo ""
echo -e "${YELLOW}${BOLD}node_modules directories found in your home folder:${RESET}"
echo "(These are NOT auto-deleted — review and delete manually if desired)"
echo ""
_nm_find() {
  find ~ -name "node_modules" -type d \
    -not -path "*/\.*" \
    -not -path "*/node_modules/*/node_modules" \
    2>/dev/null || true
}
if command -v timeout &>/dev/null; then
  NM_LIST=$(timeout 15 bash -c "$(declare -f _nm_find); _nm_find")
else
  NM_LIST=$(_nm_find)
fi

if [[ -z "$NM_LIST" ]]; then
  echo "  No node_modules found."
else
  i=1
  while IFS= read -r dir; do
    size=$(du -sh "$dir" 2>/dev/null | cut -f1)
    printf "  %2d. %-60s %s\n" "$i" "$dir" "$size"
    i=$((i+1))
  done <<< "$NM_LIST"
  echo ""
  echo "  💡 To delete one: rm -rf \"<path>\""
  echo "  💡 To reinstall: cd <project> && npm install"
fi
