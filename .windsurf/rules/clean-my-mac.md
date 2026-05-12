# clean-my-mac

Invoke: `/clean-my-mac` or say "clean my Mac", "free up space", "my Mac is full"

## Phases (in order — never skip)
- Phase -1: Profile user — active tools, backup status, what to protect
- Phase 0: Analyze disk — `scripts/analyze_storage.sh`, zero deletions
- Phase 1: Safe caches & logs (LOW)
- Phase 2: Developer tools — Homebrew, Xcode, Node, Python, Flutter (LOW–MED)
- Phase 3: Docker cleanup (MEDIUM)
- Phase 4: AI model files — list only, never auto-delete (HIGH)
- Phase 5: Time Machine snapshots — confirmed backup required (MEDIUM)
- Phase 6: Large file review — user decides
- Phase 7: iCloud guidance only

## Rules
- Profile first. Analyze before deleting. Per-phase confirmation required.
- Consequence warnings (not just confirms) for tools user uses daily.
- Never auto-delete ~/Downloads, ~/Documents, ~/Desktop.
- Block Phase 5 without confirmed backup.
- Check `config/protected_paths.txt` before every deletion.
- Dry-run before real run on every script.
