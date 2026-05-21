#!/usr/bin/env bash
# clean-my-mac: cleanup_dev_tools.sh
# Phase 2b — Developer tool cleanup: Go cache, stale toolchains,
# old VS Code extensions, large log files, npx caches.
# Usage: bash cleanup_dev_tools.sh [--dry-run]

set -euo pipefail
DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

BOLD='\033[1m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; RESET='\033[0m'
LOG_FILE=~/clean-my-mac-log-$(date +%Y-%m-%d).txt
FREED=0

log() { echo "$1" | tee -a "$LOG_FILE"; }
size_kb() { [[ -e "$1" ]] && du -sk "$1" 2>/dev/null | cut -f1 || echo "0"; }
size_of() { [[ -e "$1" ]] && du -sh "$1" 2>/dev/null | cut -f1 || echo "0B"; }

delete_path() {
  local path="$1" label="$2"
  local kb
  kb=$(size_kb "$path")
  if [[ "$DRY_RUN" == "true" ]]; then
    log "  [DRY-RUN] Would delete: $label (~$((kb/1024)) MB)"
  else
    if [[ -e "$path" ]] && rm -rf "$path" 2>/dev/null; then
      log "  ✅ Deleted: $label (~$((kb/1024)) MB)"
      FREED=$((FREED + kb))
    else
      log "  ⚠️  Failed: $path"
    fi
  fi
}

echo ""
if [[ "$DRY_RUN" == "true" ]]; then
  echo -e "${YELLOW}${BOLD}[DRY-RUN MODE] — No files will be deleted${RESET}"
fi
echo -e "${BOLD}Developer Tools Cleanup${RESET}"
log "=== Dev Tools Cleanup — $(date) ==="

# ─── Go Module Cache ─────────────────────────────────────────────────────────
if [[ -d ~/go/pkg ]]; then
  echo -e "\n${BOLD}Go module cache:${RESET} $(size_of ~/go/pkg)"
  if command -v go &>/dev/null; then
    if [[ "$DRY_RUN" == "true" ]]; then
      log "  [DRY-RUN] Would run: go clean -modcache"
    else
      go clean -modcache 2>/dev/null && log "  ✅ Go module cache cleared" || \
        log "  ⚠️  go clean -modcache failed"
    fi
  else
    delete_path ~/go/pkg "Go module cache (no go binary)"
  fi
fi

# ─── Stale Toolchains ────────────────────────────────────────────────────────
echo -e "\n${BOLD}Stale toolchains:${RESET}"
FOUND_STALE=false

if [[ -d ~/.rustup ]] && ! command -v rustc &>/dev/null; then
  FOUND_STALE=true
  delete_path ~/.rustup "Rust toolchain (.rustup) — rustc not in PATH"
fi
if [[ -d ~/.cargo ]] && ! command -v cargo &>/dev/null; then
  FOUND_STALE=true
  delete_path ~/.cargo "Cargo (.cargo) — cargo not in PATH"
fi
if [[ -d ~/.pub-cache ]] && ! command -v flutter &>/dev/null && ! command -v dart &>/dev/null; then
  FOUND_STALE=true
  delete_path ~/.pub-cache "Flutter/Dart pub-cache — neither flutter nor dart in PATH"
fi

if [[ "$FOUND_STALE" == "false" ]]; then
  echo "  None found."
fi

# ─── Old VS Code Extensions (duplicate versions) ─────────────────────────────
if [[ -d ~/.vscode/extensions ]]; then
  echo -e "\n${BOLD}Old VS Code extensions (keeping newest version only):${RESET}"
  FOUND_OLD_EXT=false

  DUPES=$(ls -1 ~/.vscode/extensions/ 2>/dev/null | \
    sed 's/-[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*.*//' | \
    sort | uniq -d)

  if [[ -n "$DUPES" ]]; then
    while IFS= read -r ext_base; do
      # Sort versions, keep newest (last), delete rest
      VERSIONS=$(ls -1d ~/.vscode/extensions/${ext_base}-* 2>/dev/null | sort -V)
      NEWEST=$(echo "$VERSIONS" | tail -1)
      while IFS= read -r ext_dir; do
        if [[ "$ext_dir" != "$NEWEST" ]]; then
          FOUND_OLD_EXT=true
          delete_path "$ext_dir" "Old extension: $(basename "$ext_dir")"
        fi
      done <<< "$VERSIONS"
    done <<< "$DUPES"
  fi

  if [[ "$FOUND_OLD_EXT" == "false" ]]; then
    echo "  None found."
  fi
fi

# ─── npx Caches ──────────────────────────────────────────────────────────────
if [[ -d ~/.npm/_npx ]]; then
  NPX_SIZE=$(size_of ~/.npm/_npx)
  echo -e "\n${BOLD}npx one-time runner cache:${RESET} $NPX_SIZE"
  delete_path ~/.npm/_npx "npx caches"
fi

# ─── Large Log Files (>50MB) ─────────────────────────────────────────────────
echo -e "\n${BOLD}Large log files (>50MB):${RESET}"
FOUND_LOGS=false
while IFS= read -r line; do
  if [[ -n "$line" ]]; then
    FOUND_LOGS=true
    local_size=$(echo "$line" | awk '{print $1}')
    local_path=$(echo "$line" | awk '{$1=""; print substr($0,2)}')
    if [[ "$DRY_RUN" == "true" ]]; then
      log "  [DRY-RUN] Would delete: $local_path ($local_size)"
    else
      echo -e "  ${YELLOW}Found:${RESET} $local_path ($local_size)"
      echo "    → Listed for review (not auto-deleted — may be actively written to)"
    fi
  fi
done < <(find ~ -type f -name "*.log" -size +50M -exec du -sh {} \; 2>/dev/null | sort -rh | head -10)

if [[ "$FOUND_LOGS" == "false" ]]; then
  echo "  None found."
fi

# ─── Inactive nvm Node Versions ──────────────────────────────────────────────
if [[ -d ~/.nvm/versions/node ]]; then
  NODE_VERSIONS=$(ls ~/.nvm/versions/node/ 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$NODE_VERSIONS" -gt 1 ]]; then
    CURRENT_NODE=$(node -v 2>/dev/null || echo "unknown")
    echo -e "\n${BOLD}Inactive Node versions (nvm):${RESET}"
    FOUND_INACTIVE=false
    for ndir in ~/.nvm/versions/node/*/; do
      local_ver=$(basename "$ndir")
      if [[ "$local_ver" != "$CURRENT_NODE" ]]; then
        FOUND_INACTIVE=true
        local_size=$(size_of "$ndir")
        if [[ "$DRY_RUN" == "true" ]]; then
          log "  [DRY-RUN] Would remove: $local_ver ($local_size)"
        else
          echo -e "  ${YELLOW}$local_ver${RESET} ($local_size) — not active"
          echo "    → Listed for review (run: nvm uninstall $local_ver)"
        fi
      fi
    done
    if [[ "$FOUND_INACTIVE" == "false" ]]; then
      echo "  None found."
    fi
  fi
fi

# ─── Summary ─────────────────────────────────────────────────────────────────
echo ""
if [[ "$DRY_RUN" == "true" ]]; then
  echo -e "${YELLOW}Dry-run complete. Run without --dry-run to execute.${RESET}"
else
  echo -e "${GREEN}${BOLD}Dev tools cleanup complete. Freed: ~$((FREED/1024/1024)) GB ($((FREED/1024)) MB)${RESET}"
fi
log "Dev tools cleanup complete. Freed: ~$((FREED/1024)) MB"
