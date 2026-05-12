#!/usr/bin/env bash
# clean-my-mac: cleanup_docker.sh
# Cleans Docker images, containers, volumes with risk tiering.
# Usage: bash cleanup_docker.sh [--dry-run] [--level=safe|aggressive|volumes]

set -euo pipefail
DRY_RUN=false
LEVEL="safe"
for arg in "$@"; do
  [[ "$arg" == "--dry-run" ]] && DRY_RUN=true
  [[ "$arg" =~ ^--level=(.+)$ ]] && LEVEL="${BASH_REMATCH[1]}"
done

BOLD='\033[1m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; RESET='\033[0m'
LOG_FILE=~/clean-my-mac-log-$(date +%Y-%m-%d).txt
log() { echo "$1" | tee -a "$LOG_FILE"; }

if ! command -v docker &>/dev/null; then
  echo "ℹ️  Docker not installed. Skipping."
  exit 0
fi

if ! docker info &>/dev/null 2>&1; then
  echo "ℹ️  Docker is not running. Start Docker Desktop first."
  exit 0
fi

echo ""
echo -e "${BOLD}Docker Storage Status:${RESET}"
docker system df

echo ""
echo -e "${BOLD}Cleanup Level: ${LEVEL}${RESET}"

case "$LEVEL" in
  safe)
    echo -e "${GREEN}Safe mode:${RESET} Removes stopped containers, dangling images, unused networks."
    echo "  Does NOT remove images you might need to re-pull."
    if [[ "$DRY_RUN" == "true" ]]; then
      echo "  [DRY-RUN] Would run: docker system prune -f"
    else
      # Create TM snapshot first
      echo "  Creating Time Machine snapshot before cleanup..."
      tmutil snapshot 2>/dev/null && echo "  ✅ Snapshot created" || echo "  ⚠️  Snapshot failed (continuing)"
      docker system prune -f && log "✅ Docker safe prune complete"
    fi
    ;;
  aggressive)
    echo -e "${YELLOW}Aggressive mode:${RESET} Removes ALL unused images (including pulled ones you haven't run recently)."
    echo -e "  ${YELLOW}⚠️  You'll need to re-pull images next time you use them.${RESET}"
    if [[ "$DRY_RUN" == "true" ]]; then
      echo "  [DRY-RUN] Would run: docker system prune -a -f"
      docker system prune -a --dry-run 2>/dev/null || echo "  (dry-run not supported by this Docker version)"
    else
      read -p "  Confirm aggressive Docker cleanup? (y/N) " confirm
      if [[ "$confirm" =~ ^[Yy]$ ]]; then
        tmutil snapshot 2>/dev/null
        docker system prune -a -f && log "✅ Docker aggressive prune complete"
      else
        echo "  Cancelled."
      fi
    fi
    ;;
  volumes)
    echo -e "${RED}Volume mode:${RESET} Removes ALL unused images AND volumes."
    echo -e "  ${RED}❗ WARNING: This can delete database data stored in Docker volumes.${RESET}"
    echo -e "  ${RED}   Only use if you have no persistent data in Docker volumes.${RESET}"
    if [[ "$DRY_RUN" == "true" ]]; then
      echo "  [DRY-RUN] Would run: docker system prune -a --volumes -f"
    else
      read -p "  This may DELETE DATABASE DATA. Type 'yes I understand' to confirm: " confirm
      if [[ "$confirm" == "yes I understand" ]]; then
        tmutil snapshot 2>/dev/null
        docker system prune -a --volumes -f && log "✅ Docker full prune with volumes complete"
      else
        echo "  Cancelled (good call)."
      fi
    fi
    ;;
esac

echo ""
echo -e "${BOLD}Docker storage after cleanup:${RESET}"
docker system df
