#!/usr/bin/env bash
# clean-my-mac: cleanup_xcode.sh
# Phase 2 — Xcode artifacts cleanup with per-category confirmation.
# Usage: bash cleanup_xcode.sh [--dry-run]

set -euo pipefail

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

BOLD='\033[1m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; RESET='\033[0m'
LOG_FILE=~/clean-my-mac-log-$(date +%Y-%m-%d).txt

log() { echo "$1" | tee -a "$LOG_FILE"; }
size_of() { [[ -e "$1" ]] && du -sh "$1" 2>/dev/null | cut -f1 || echo "0B"; }

if [[ ! -d /Applications/Xcode.app ]]; then
  echo "ℹ️  Xcode not installed. Skipping."
  exit 0
fi

echo ""
echo -e "${BOLD}Xcode Storage Analysis:${RESET}"
echo "  DerivedData:    $(size_of ~/Library/Developer/Xcode/DerivedData)"
echo "  Archives:       $(size_of ~/Library/Developer/Xcode/Archives)"
echo "  iOS Simulators: $(size_of ~/Library/Developer/CoreSimulator/Devices)"
echo "  iOS Backups:    $(size_of ~/Library/Application\ Support/MobileSync/Backup)"
echo "  Xcode Caches:   $(size_of ~/Library/Caches/com.apple.dt.Xcode)"
echo ""

# ── 1. DerivedData — LOW risk ──────────────────────────────────────────────
echo -e "${GREEN}[LOW RISK]${RESET} DerivedData — Xcode rebuilds this automatically."
if [[ "$DRY_RUN" == "true" ]]; then
  echo "  [DRY-RUN] Would delete: ~/Library/Developer/Xcode/DerivedData"
else
  rm -rf ~/Library/Developer/Xcode/DerivedData 2>/dev/null && \
    log "✅ Deleted DerivedData" || log "⚠️ Failed to delete DerivedData"
fi

# ── 2. Xcode Cache — LOW risk ──────────────────────────────────────────────
echo -e "${GREEN}[LOW RISK]${RESET} Xcode build cache — safe to clear."
if [[ "$DRY_RUN" == "true" ]]; then
  echo "  [DRY-RUN] Would delete: ~/Library/Caches/com.apple.dt.Xcode"
else
  rm -rf ~/Library/Caches/com.apple.dt.Xcode 2>/dev/null && \
    log "✅ Deleted Xcode caches" || log "⚠️ Failed"
fi

# ── 3. iOS Simulators — MEDIUM risk ───────────────────────────────────────
SIM_SIZE=$(size_of ~/Library/Developer/CoreSimulator/Devices)
echo ""
echo -e "${YELLOW}[MEDIUM RISK]${RESET} iOS Simulators: $SIM_SIZE"
echo "  These can be re-downloaded from Xcode, but it takes time and bandwidth."
echo "  Tip: In Xcode > Settings > Platforms, you can manage simulators individually."
if [[ "$DRY_RUN" == "false" ]]; then
  read -p "  Delete all iOS Simulators? (y/N) " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    # Prefer xcrun simctl for cleaner removal
    if command -v xcrun &>/dev/null; then
      xcrun simctl delete unavailable 2>/dev/null && log "✅ Deleted unavailable simulators via xcrun"
      echo "  ℹ️  Tip: To delete ALL simulators, use Xcode > Settings > Platforms"
    else
      rm -rf ~/Library/Developer/CoreSimulator/Devices 2>/dev/null && \
        log "✅ Deleted all iOS Simulators"
    fi
  else
    echo "  Skipped."
  fi
else
  echo "  [DRY-RUN] Would offer to delete simulators ($SIM_SIZE)"
fi

# ── 4. Archives — HIGH risk ────────────────────────────────────────────────
ARCH_SIZE=$(size_of ~/Library/Developer/Xcode/Archives)
echo ""
echo -e "${RED}[HIGH RISK]${RESET} Xcode Archives: $ARCH_SIZE"
echo "  ⚠️  These are your compiled app archives. If you submit apps to the App Store"
echo "      or distribute builds, these may be the ONLY copy of past releases."
echo "      Only delete if you have copies elsewhere or never ship apps."
if [[ "$DRY_RUN" == "false" ]]; then
  read -p "  Delete Xcode Archives? This cannot be undone. (y/N) " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    read -p "  Are you SURE? Type 'yes' to confirm: " confirm2
    if [[ "$confirm2" == "yes" ]]; then
      rm -rf ~/Library/Developer/Xcode/Archives 2>/dev/null && \
        log "✅ Deleted Xcode Archives"
    else
      echo "  Skipped (good call)."
    fi
  else
    echo "  Skipped."
  fi
else
  echo "  [DRY-RUN] Would warn about Archives ($ARCH_SIZE) and require double confirmation"
fi

# ── 5. iOS Device Backups — HIGH risk ─────────────────────────────────────
BACKUP_SIZE=$(size_of ~/Library/Application\ Support/MobileSync/Backup)
echo ""
echo -e "${RED}[HIGH RISK]${RESET} iOS Device Backups: $BACKUP_SIZE"
echo "  ⚠️  These are your iPhone/iPad backups. If you don't have iCloud Backup enabled,"
echo "      deleting these means you CANNOT restore your devices from this Mac."
echo "      Manage these in: Finder > [Your Device] > Manage Backups"
echo "  Skipping automatically — manage via Finder for safety."
log "iOS Backups skipped (user must manage via Finder)"

echo ""
echo -e "${GREEN}${BOLD}Xcode cleanup complete.${RESET}"
