# Contributing to clean-my-mac

Read `CLAUDE.md` first — it covers repo structure and constraints.

## How to contribute

1. Fork the repo
2. `git checkout -b feat/your-feature`
3. Edit only `skills/clean-my-mac/` — SKILL.md and/or scripts
4. Test: open your agent, run `/clean-my-mac` in a new session
5. Submit a PR

## Adding a new cleanup target

1. Add phase entry to `skills/clean-my-mac/SKILL.md` with risk level
2. Add `skills/clean-my-mac/scripts/cleanup_<name>.sh` with `--dry-run` support
3. Add script to `analyze_storage.sh` size scan if applicable
4. Update agent rule files if phase list changed

## Adding a new protected path

Add to `skills/clean-my-mac/config/protected_paths.txt` with a comment explaining why.

## Reporting issues

Use GitHub Issues. Include: macOS version, Mac model, Claude Code version, agent used, and paste `~/clean-my-mac-log-<date>.txt` if available.

## Security

If you find a path that could be accidentally deleted, open an issue marked `[SECURITY]` — don't wait for a full PR.
