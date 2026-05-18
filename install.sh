#!/usr/bin/env bash
set -euo pipefail

SKILL="clean-my-mac"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_SRC="$SCRIPT_DIR/skills/$SKILL"
REPO_ROOT="$SCRIPT_DIR"

install_skill_to() {
  local dest="${1}/$SKILL"
  mkdir -p "$dest"
  cp -r "$SKILL_SRC/." "$dest/"
  chmod +x "$dest/scripts/"*.sh 2>/dev/null || true
  echo "  ✓ $dest"
}

install_rules_to() {
  local dest="$1"
  local src="$2"
  mkdir -p "$dest"
  cp "$src" "$dest/"
  echo "  ✓ $dest/$(basename "$src")"
}

echo "Installing $SKILL skill..."
install_skill_to "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills"
install_skill_to "$HOME/.agents/skills"
install_skill_to "${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills"
install_skill_to "$HOME/.gemini/antigravity/skills"
install_skill_to "$HOME/.openclaw/workspace/skills"

echo ""
echo "Installing agent rule files..."
install_rules_to "$HOME/.cursor/rules"     "$REPO_ROOT/.cursor/rules/clean-my-mac.mdc"
install_rules_to "$HOME/.windsurf/rules"   "$REPO_ROOT/.windsurf/rules/clean-my-mac.md"
install_rules_to "$HOME/.clinerules"       "$REPO_ROOT/.clinerules/clean-my-mac.md"

echo ""
echo "Done. Invoke with: /$SKILL"
echo "Reinstall anytime: bash install.sh"
