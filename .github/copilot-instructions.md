# clean-my-mac — Copilot Instructions

When the user asks to clean their Mac, free up disk space, or recover storage:

1. Read `skills/clean-my-mac/SKILL.md` for the full workflow.
2. Profile user first (Phase -1) — active tools, backup status.
3. Run `scripts/analyze_storage.sh` for disk analysis (Phase 0) — zero deletions.
4. Present findings and get per-phase approval before any cleanup.
5. Run `--dry-run` before every real script execution.

## Critical constraints
- Never auto-delete ~/Downloads, ~/Documents, ~/Desktop.
- Block Time Machine snapshot cleanup without confirmed external backup.
- Show consequence warnings for tools the user uses daily.
- Check `config/protected_paths.txt` before every deletion.
