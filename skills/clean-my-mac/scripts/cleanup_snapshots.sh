#!/usr/bin/env bash
# clean-my-mac: cleanup_snapshots.sh
# Removes Time Machine local snapshots — often the biggest hidden space consumer.
# Usage: bash cleanup_snapshots.sh [--dry-run]

set -euo pipefail
DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

BOLD='\033[1m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; GREEN='\033[0;32m'; RESET='\033[0m'
LOG_FILE=~/clean-my-mac-log-$(date +%Y-%m-%d).txt
log() { echo "$1" | tee -a "$LOG_FILE"; }

echo ""
echo -e "${BOLD}Time Machine Local Snapshots${RESET}"
echo ""

SNAPS=$(tmutil listlocalsnapshots / 2>/dev/null)
SNAP_COUNT=$(echo "$SNAPS" | grep -c "com.apple.TimeMachine" 2>/dev/null || echo "0")

if [[ "$SNAP_COUNT" -eq 0 ]]; then
  echo "  No local snapshots found. Nothing to do."
  exit 0
fi

echo "Found $SNAP_COUNT local snapshots:"
echo "$SNAPS"
echo ""
echo -e "${YELLOW}${BOLD}⚠️  Important:${RESET}"
echo "  Local snapshots are what macOS uses for 'Time Machine' restores"
echo "  when your external backup drive isn't connected."
echo ""
echo "  Only proceed if you have:"
echo "    ✅ An external Time Machine backup drive (recently backed up), OR"
echo "    ✅ iCloud Backup enabled for your important files"
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
  echo "  [DRY-RUN] Would delete all $SNAP_COUNT local snapshots."
  echo "  Command: sudo tmutil deletelocalsnapshots /"
  echo "  Note: macOS will re-create snapshots during the next Time Machine backup."
else
  read -p "  Do you have an external TM backup or iCloud Backup? (y/N) " has_backup
  if [[ ! "$has_backup" =~ ^[Yy]$ ]]; then
    echo -e "${RED}  Aborting. Please ensure you have a backup before clearing snapshots.${RESET}"
    exit 0
  fi

  read -p "  Delete all $SNAP_COUNT local Time Machine snapshots? (y/N) " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    echo "  Deleting snapshots..."
    sudo tmutil deletelocalsnapshots / 2>/dev/null && \
      echo -e "  ${GREEN}✅ All local snapshots deleted.${RESET}" && \
      log "✅ Deleted $SNAP_COUNT Time Machine local snapshots"
    echo "  ℹ️  macOS will create new snapshots during the next scheduled backup."
  else
    echo "  Skipped."
  fi
fi
