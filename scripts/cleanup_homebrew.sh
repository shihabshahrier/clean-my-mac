#!/usr/bin/env bash
# clean-my-mac: cleanup_homebrew.sh
# Usage: bash cleanup_homebrew.sh [--dry-run]

set -euo pipefail
DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

LOG_FILE=~/clean-my-mac-log-$(date +%Y-%m-%d).txt
log() { echo "$1" | tee -a "$LOG_FILE"; }

if ! command -v brew &>/dev/null; then
  echo "ℹ️  Homebrew not installed. Skipping."; exit 0
fi

echo ""
echo "Homebrew cleanup"
echo "Cache before: $(du -sh ~/Library/Caches/Homebrew 2>/dev/null | cut -f1)"

if [[ "$DRY_RUN" == "true" ]]; then
  echo "[DRY-RUN] Would run: brew cleanup --prune=all"
  brew cleanup --dry-run 2>/dev/null | head -30
else
  brew cleanup --prune=all 2>/dev/null && log "✅ Homebrew cleanup complete"
  echo "Cache after:  $(du -sh ~/Library/Caches/Homebrew 2>/dev/null | cut -f1)"
fi
