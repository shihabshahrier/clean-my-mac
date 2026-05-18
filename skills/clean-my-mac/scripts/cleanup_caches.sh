#!/usr/bin/env bash
# clean-my-mac: cleanup_caches.sh
# Phase 1 — Safe caches, logs, and temp files. Zero risk.
# Usage: bash cleanup_caches.sh [--dry-run]

set -euo pipefail

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

BOLD='\033[1m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RESET='\033[0m'
LOG_FILE=~/clean-my-mac-log-$(date +%Y-%m-%d).txt
FREED=0

# Load protected paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROTECTED="$SCRIPT_DIR/../config/protected_paths.txt"

log() { echo "$1" | tee -a "$LOG_FILE"; }
size_kb() { [[ -e "$1" ]] && du -sk "$1" 2>/dev/null | cut -f1 || echo "0"; }

is_protected() {
  local path="$1"
  [[ -f "$PROTECTED" ]] || return 1
  while IFS= read -r pp; do
    [[ "$pp" =~ ^[[:space:]]*# || -z "${pp// }" ]] && continue
    local expanded="${pp/#\~/$HOME}"
    [[ "$path" == "$expanded" || "$path" == "${expanded}/"* ]] && return 0
  done < "$PROTECTED"
  return 1
}

delete_path() {
  local path="$1"
  local label="$2"
  local kb
  kb=$(size_kb "$path")

  if is_protected "$path"; then
    log "  SKIPPED (protected): $path"
    return
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    log "  [DRY-RUN] Would delete: $path (~$(echo "$kb/1024" | bc) MB)"
  else
    if [[ -e "$path" ]]; then
      if rm -rf "$path" 2>/dev/null; then
        log "  ✅ Deleted: $label (~$(echo "$kb/1024" | bc) MB)"
        FREED=$((FREED + kb))
      else
        log "  ⚠️  Failed: $path"
      fi
    fi
  fi
}

echo ""
if [[ "$DRY_RUN" == "true" ]]; then
  echo -e "${YELLOW}${BOLD}[DRY-RUN MODE] — No files will be deleted${RESET}"
else
  echo -e "${BOLD}Phase 1: Cleaning caches, logs, and temp files...${RESET}"
fi
log "=== Phase 1: Caches & Logs — $(date) ==="

# User caches (Homebrew excluded — Phase 2 handles it via `brew cleanup`)
echo -e "\n${BOLD}User Caches (~/Library/Caches):${RESET}"
for dir in ~/Library/Caches/*/; do
  [[ "$(basename "$dir")" == "Homebrew" ]] && continue
  delete_path "$dir" "$(basename "$dir") cache"
done

# System caches
echo -e "\n${BOLD}System Caches (/Library/Caches) — requires sudo:${RESET}"
if sudo -n true 2>/dev/null; then
  for dir in /Library/Caches/*/; do
    delete_path "$dir" "system/$(basename "$dir")"
  done
else
  echo "  ℹ️  Run with sudo for system cache access: sudo bash cleanup_caches.sh"
fi

# User logs
echo -e "\n${BOLD}User Logs (~/Library/Logs):${RESET}"
delete_path ~/Library/Logs "User logs"

# System logs
echo -e "\n${BOLD}System Logs (/Library/Logs):${RESET}"
[[ $(id -u) -eq 0 ]] && delete_path /Library/Logs "System logs" || \
  echo "  ℹ️  Requires sudo for /Library/Logs"

# Saved application state
echo -e "\n${BOLD}Saved Application State:${RESET}"
delete_path ~/Library/Saved\ Application\ State "Saved app state"

# Crash reports
echo -e "\n${BOLD}Crash Reports:${RESET}"
delete_path ~/Library/Application\ Support/CrashReporter "Crash reports"

# Temp files
echo -e "\n${BOLD}Temp files (/private/tmp):${RESET}"
if [[ $(id -u) -eq 0 ]]; then
  delete_path /private/tmp "System temp files"
else
  echo "  ℹ️  Requires sudo for /private/tmp"
fi

# Empty Trash
echo -e "\n${BOLD}Trash:${RESET}"
TRASH_SIZE=$(size_kb ~/.Trash)
if [[ "$DRY_RUN" == "true" ]]; then
  echo "  [DRY-RUN] Would empty Trash (~$(echo "$TRASH_SIZE/1024" | bc) MB)"
else
  osascript -e 'tell application "Finder" to empty trash' 2>/dev/null && \
    echo "  ✅ Trash emptied (~$(echo "$TRASH_SIZE/1024" | bc) MB)" || \
    echo "  ⚠️  Could not empty Trash via Finder"
  FREED=$((FREED + TRASH_SIZE))
fi

echo ""
if [[ "$DRY_RUN" == "true" ]]; then
  echo -e "${YELLOW}Dry-run complete. Run without --dry-run to execute.${RESET}"
else
  echo -e "${GREEN}${BOLD}Phase 1 complete. Freed: ~$(echo "$FREED/1024/1024" | bc) GB${RESET}"
fi
log "Phase 1 complete. Freed: ~$(echo "$FREED/1024" | bc) MB"
