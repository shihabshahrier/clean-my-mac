#!/bin/bash
set -e

SKILL="clean-my-mac"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_SRC="$SCRIPT_DIR/skills/$SKILL"

install_to() {
  local dest="${1}/$SKILL"
  mkdir -p "$dest"
  cp -r "$SKILL_SRC/." "$dest/"
  chmod +x "$dest/scripts/"*.sh 2>/dev/null || true
  echo "  ✓ $dest"
}

echo "Installing $SKILL skill..."
install_to "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills"
install_to "$HOME/.agents/skills"
install_to "${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills"
install_to "$HOME/.gemini/antigravity/skills"
install_to "$HOME/.openclaw/workspace/skills"

echo ""
echo "Done. Invoke with: /$SKILL"
echo "Reinstall anytime: bash install.sh"
