# clean-my-mac — Contributor Guide

## What this repo is
A multi-agent skill for safe, staged macOS disk cleanup. Works in Claude Code, Cursor, Windsurf, Codex, Gemini CLI, and any agent that supports the Agent Skills open standard.

## Source of truth
Edit only `skills/clean-my-mac/`. Never edit agent-specific files directly:
- `.cursor/rules/` — synced from SKILL.md phases
- `.windsurf/rules/` — synced from SKILL.md phases
- `.clinerules/` — synced from SKILL.md phases
- `.github/copilot-instructions.md` — synced from SKILL.md phases
- `AGENTS.md`, `GEMINI.md` — reference SKILL.md via `@` include

## Key constraints
- All scripts must support `--dry-run` flag
- Scripts must use `set -euo pipefail`
- Check `skills/clean-my-mac/config/protected_paths.txt` before any deletion
- Never add `sudo rm -rf` on unknown paths
- New cleanup targets need: SKILL.md phase entry + script + risk level + dry-run support
- `set -o pipefail` sensitive commands must use `|| true` or subshell `(cmd; true)` pattern

## Making changes
1. Edit `skills/clean-my-mac/SKILL.md` or scripts
2. Test: `bash skills/clean-my-mac/scripts/analyze_storage.sh`
3. If phases changed, sync agent rule files (.cursor, .windsurf, .clinerules, copilot-instructions)
4. Reinstall for Claude Code:
   ```bash
   claude plugin uninstall clean-my-mac
   claude plugin marketplace remove clean-my-mac
   claude plugin marketplace add .
   claude plugin install clean-my-mac
   ```
5. For other agents: `bash install.sh`
