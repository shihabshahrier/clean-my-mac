---
name: clean-my-mac
description: >
  Safely analyze and recover disk space on macOS. Use this skill whenever the user says
  "clean my Mac", "free up disk space", "my Mac is full", "storage is full", "Mac is slow",
  "clear caches", "remove junk", "Xcode taking up space", "Docker cleanup", "npm cache",
  "node_modules cleanup", "homebrew cleanup", "Time Machine snapshots", "AI models taking space",
  "clean up my drive", "how much space do I have", or any variation of wanting to recover
  storage on macOS. Designed for M1/M2/M3 Macs with 256 GB SSDs, works on any Mac.
  ALWAYS profile the user first. ALWAYS analyze before deleting. ALWAYS confirm before
  each phase. NEVER touches system files, SIP-protected paths, keychains, or user documents.
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - Write
---

# Clean My Mac — Skill

Safe, staged, explainable disk cleanup for macOS.
Recovers real space from real culprits without touching anything the user actually needs.

Read `reference/safe-paths.md` and `reference/dangerous-paths.md` before any deletion.
Use `reference/cleanup-strategies.md` for exact per-tool commands.
Use `reference/macos-storage-guide.md` to explain storage categories to the user.

---

## Locating Scripts

Claude Code injects this skill's base directory as:
```
Base directory for this skill: /path/to/skill
```

Extract that path as `SKILL_DIR`. All scripts: `bash "$SKILL_DIR/scripts/<name>.sh"`.

Fallback if not injected:
```bash
SKILL_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
```

---

## Workflow Overview

```
Phase -1  →  Profile user (who are you, what do you use daily?)
Phase  0  →  Analyze disk (no deletions — build the picture)
           →  Present findings + proposed cleanup plan
           →  Ask for permission to proceed, phase by phase
Phase  1  →  Safe caches & logs          [LOW risk]
Phase  2  →  Developer tools             [LOW–MEDIUM, skip if not relevant]
Phase  3  →  Docker                      [MEDIUM]
Phase  4  →  AI model files              [HIGH — list only]
Phase  5  →  Time Machine snapshots      [MEDIUM — requires backup confirmed]
Phase  6  →  Large file review           [USER-DECIDES]
Phase  7  →  iCloud optimization         [guidance only]
           →  Final report
```

**Never skip Phase -1 and Phase 0. Never jump to deletions without explicit per-phase approval.**

---

## Phase -1 — User Profile (ALWAYS FIRST)

Before running any script, ask these questions conversationally — not as a form.
One message. Friendly. Goal: understand what to protect.

**Ask:**
> "Before I touch anything, I want to make sure I don't delete something you're actively using.
> A few quick questions:
>
> 1. Are you a developer? If so, what do you use most — Node.js, Python, Xcode, Docker, Flutter, something else?
> 2. Which of those do you use **daily or on active projects right now**?
> 3. Do you have an external Time Machine drive or iCloud Backup turned on?
> 4. Anything specific you're worried about or want to leave untouched?"

**Build a USER_PROFILE from their answers:**

```
USER_PROFILE
  type:         developer | designer | student | casual
  active_tools: [list of tools used daily or on active projects]
  has_backup:   yes | no | unknown
  protect:      [anything user explicitly said to leave alone]
```

**How profile affects each phase:**

| If user says... | Then... |
|----------------|---------|
| "I use npm daily" | Warn before clearing npm cache: "This will slow your next `npm install`" |
| "Active Xcode project right now" | Keep DerivedData — skip or warn strongly |
| "Haven't opened Docker in months" | Safe to suggest aggressive Docker cleanup |
| "I'm not a developer" | Skip Phase 2 entirely unless tools detected |
| "No backup / unsure" | Block Phase 5 (snapshots) — require backup confirmation first |
| "Don't touch my Downloads" | Skip Phase 6 for Downloads |
| "I use Ollama daily" | List AI models but warn: "These are active models you use regularly" |

**Never delete from a tool the user said they use daily without an extra explicit warning.**
Not just a confirmation — a warning that explains the real-world consequence:
> "Clearing the npm cache means your next `npm install` will re-download all packages from the internet. On a slow connection this can take 5–10 minutes. Still want to proceed?"

---

## Phase 0 — Disk Analysis (no deletions)

After profiling, run the analysis script:

```bash
bash "$SKILL_DIR/scripts/analyze_storage.sh"
```

Present the full output table to the user.

Then generate a **Personalized Cleanup Plan** based on USER_PROFILE + analysis results:

```
Based on your profile and what I found, here's my recommended plan:

✅ SAFE TO CLEAN (no impact on your workflow):
   • User & system caches       ~X GB   [regenerated automatically]
   • Logs & crash reports       ~X GB   [regenerated automatically]
   • Homebrew cache             ~X GB   [brew re-downloads when needed]
   • [other tools NOT in active_tools]

⚠️  REVIEW FIRST (may affect your active work):
   • npm cache                  ~X GB   [you said you use this daily — see warning above]
   • Xcode DerivedData          ~X GB   [you have an active Xcode project]
   • Docker images              ~X GB   [confirm which images you still need]

🔴 HIGH RISK — YOUR DECISION:
   • AI model files             ~X GB   [will list them — you choose]
   • Time Machine snapshots     ~X GB   [backup confirmed? YES/NO]
   • Xcode Archives             ~X GB   [only delete if you have copies]

⏭️  SKIPPING (based on your profile):
   • [phases not relevant to user type]

Estimated recoverable: ~XX GB

Shall I proceed? I'll ask for your approval before each phase.
```

Only proceed after the user says yes.

---

## Phase 1 — Safe Caches & Logs (Risk: LOW)

These are always safe — regenerated by macOS automatically.

**Before running:** Confirm once for all of Phase 1 combined.
> "Phase 1 will clear system and app caches, logs, crash reports, and empty Trash.
> Everything here is automatically rebuilt by macOS. Estimated: ~X GB.
> Proceed? (yes/no)"

```bash
bash "$SKILL_DIR/scripts/cleanup_caches.sh" --dry-run
# Show dry-run output. Then ask: "Looks good? Run it for real?"
bash "$SKILL_DIR/scripts/cleanup_caches.sh"
```

**Active tool protection:** If any app in `active_tools` has a large cache entry in the
dry-run output (>500MB), call it out specifically before proceeding.

---

## Phase 2 — Developer Tools (Risk: LOW–MEDIUM)

**Skip entire phase if:** user type is `casual` or `designer` AND no dev tools detected.

**For each tool below — only run if tool was detected in Phase 0.**
**Skip a tool's cache cleanup if it's in `active_tools` AND user is on an active project,
unless the user explicitly confirms after seeing the consequence warning.**

### Homebrew

```bash
bash "$SKILL_DIR/scripts/cleanup_homebrew.sh" --dry-run
bash "$SKILL_DIR/scripts/cleanup_homebrew.sh"
```
Safe. `brew` re-downloads bottles on next install. No consequence warning needed.

### Xcode

```bash
bash "$SKILL_DIR/scripts/cleanup_xcode.sh" --dry-run
bash "$SKILL_DIR/scripts/cleanup_xcode.sh"
```

Confirm each target separately:

| Target | Risk | Active project warning |
|--------|------|----------------------|
| DerivedData | 🟢 LOW | "Next build will take longer while Xcode recompiles." |
| Xcode caches | 🟢 LOW | None needed |
| iOS Simulators | 🟡 MEDIUM | "Re-downloading takes 2–10 GB bandwidth + time." |
| Xcode Archives | 🔴 HIGH | "These may be your only App Store release builds. Confirm you have copies." |
| iOS Backups | 🔴 HIGH | Guide to Finder only. Never script this. |

### Node.js Ecosystem

```bash
bash "$SKILL_DIR/scripts/cleanup_node.sh" --dry-run
bash "$SKILL_DIR/scripts/cleanup_node.sh"
```

**If npm/pnpm/yarn in `active_tools`**, show this warning before cache cleanup:
> "You use npm/pnpm daily. Clearing the cache means your next install re-downloads
> all packages. On a slow connection: 5–15 min for large projects. Still proceed?"

`node_modules` directories: list only, never auto-delete. User picks which projects to clean.
> "These are project dependencies. Deleting means you run `npm install` again per project.
> Which ones do you want to remove?"

### Python
```bash
pip3 cache info && pip3 cache purge 2>/dev/null
```
Low consequence — pip re-downloads on next `pip install`.

### Flutter / Dart
```bash
du -sh ~/.pub-cache 2>/dev/null
dart pub cache repair   # clears temp only, keeps downloaded packages
```

### Gradle / Android Studio
```bash
du -sh ~/.gradle/caches 2>/dev/null
# After confirmation: rm -rf ~/.gradle/caches/*
```
**Warning if active Android project:** "Next Gradle build will re-download dependencies."

### CocoaPods
```bash
pod cache clean --all 2>/dev/null
```

---

## Phase 3 — Docker Cleanup (Risk: MEDIUM)

**Skip if Docker not installed or not running.**
**Run `tmutil snapshot` before this phase.**

```bash
bash "$SKILL_DIR/scripts/cleanup_docker.sh" --dry-run
```

Show `docker system df` output. Then ask which level:

| Option | Flag | Consequence warning |
|--------|------|---------------------|
| Safe | `--level=safe` | Stopped containers + dangling images. Minimal impact. |
| Aggressive | `--level=aggressive` | ALL unused images removed. Re-pull required. Warn: "Which images do you still need?" |
| Nuclear | `--level=volumes` | ⚠️ Database data in volumes may be deleted. Double confirm required. |

**If Docker in `active_tools`:** Default to Safe only. Require explicit request for Aggressive.

```bash
bash "$SKILL_DIR/scripts/cleanup_docker.sh" --level=safe
```

---

## Phase 4 — AI Model Files (Risk: HIGH — list only)

AI models are 2–70 GB each. Find and list. **Never auto-delete.**

```bash
find ~ -type f \( \
  -name "*.gguf" -o -name "*.safetensors" -o \
  -name "*.bin" -o -name "*.onnx" -o \
  -name "*.pt" -o -name "*.pth" \
  \) -size +100M 2>/dev/null | xargs du -sh 2>/dev/null | sort -rh

du -sh ~/.ollama/models 2>/dev/null
ollama list 2>/dev/null
du -sh ~/Library/Application\ Support/LM\ Studio 2>/dev/null
du -sh ~/.cache/huggingface 2>/dev/null
```

Present as numbered list. User says which to remove. Delete only what they name explicitly.

**If Ollama/LM Studio in `active_tools`:** Add note per model:
> "You said you use Ollama regularly. Which of these models do you actually still use?
> I'd suggest keeping your most-used ones and removing anything you haven't run in months."

---

## Phase 5 — Time Machine Snapshots (Risk: MEDIUM)

**Often the single biggest win** — accumulates 20–60 GB silently, shows as "System Data."

**HARD BLOCK: Do not proceed if `has_backup = no` or `has_backup = unknown`.**
If backup status unknown, ask first:
> "Before clearing Time Machine snapshots, I need to confirm: do you have an external
> Time Machine drive that's been recently backed up, or iCloud Backup enabled?
> If you have neither, I'll skip this phase — local snapshots may be your only recovery option."

Only after backup confirmed:
```bash
bash "$SKILL_DIR/scripts/cleanup_snapshots.sh" --dry-run
# Show snapshot list and estimated space
bash "$SKILL_DIR/scripts/cleanup_snapshots.sh"
```

---

## Phase 6 — Large File & Downloads Review (Risk: USER-DECIDES)

**Never auto-delete anything here.** Present findings, user chooses.

```bash
# Large files (>200MB), excluding hidden + Developer + node_modules
find ~ -not -path "*/\.*" \
  -not -path "*/Library/Developer/*" \
  -not -path "*/node_modules/*" \
  -size +200M \
  -exec du -sh {} \; 2>/dev/null | sort -rh | head -30

# Old installers
find ~ \( -name "*.dmg" -o -name "*.pkg" \) 2>/dev/null | \
  xargs du -sh 2>/dev/null | sort -rh

# Large archives
find ~/Downloads ~/Desktop -name "*.zip" -size +100M \
  -exec du -sh {} \; 2>/dev/null | sort -rh
```

If user said "don't touch Downloads" in profiling — skip Downloads scan.

---

## Phase 7 — iCloud Optimization (Guidance only — no shell commands)

Walk user through macOS Storage UI:

1. Apple Menu → System Settings → General → Storage
2. **Store in iCloud** — offloads Desktop/Documents (files stay accessible on demand)
3. **Optimize Storage** — removes watched videos, keeps only recent email attachments
4. **Empty Trash Automatically** — auto-deletes after 30 days
5. **Applications** — review unused apps (free space + memory)
6. **Documents → Downloads** — review large forgotten files

---

## Hard Rules — Never Violate

1. **Profile first.** No analysis, no cleanup without knowing what the user actively uses.
2. **Analyze before deleting.** Run all scans before touching anything.
3. **Per-phase permission.** Ask before each phase. Approval for Phase 1 does not imply Phase 2.
4. **Dry-run before real run.** Show what will be deleted, get confirmation, then execute.
5. **No `sudo rm -rf` on unknown paths.** Only paths in `reference/safe-paths.md`.
6. **Active tool protection.** If a tool is in `active_tools`, show consequence warning — not just a confirm prompt.
7. **Snapshot before Phase 3+.** Run `tmutil snapshot` before any medium/high-risk phase.
8. **Backup required for snapshots.** Block Phase 5 until user confirms external backup or iCloud.
9. **Never auto-delete Downloads, Documents, Desktop.** List only — user decides.
10. **Log everything.** Write to `~/clean-my-mac-log-$(date +%Y-%m-%d).txt`.
11. **Skip and report uncertain paths.** Never guess.
12. **Check `config/protected_paths.txt`** before every deletion. See `reference/dangerous-paths.md`.

---

## Risk Scoring

| Level | Meaning | Confirmation required |
|-------|---------|----------------------|
| 🟢 LOW | Auto-regenerated | Single "yes" for whole phase |
| 🟡 MEDIUM | Recoverable but takes effort | Per-category confirmation |
| 🔴 HIGH | Potentially irreplaceable | Explicit warning + double confirm |
| 🔒 ACTIVE | In user's `active_tools` | Consequence warning + confirm (even for LOW-risk targets) |

---

## Final Cleanup Report

Save to `~/clean-my-mac-report-$(date +%Y-%m-%d).md`:

```
╔══════════════════════════════════════════════════════════════╗
║              CLEAN MY MAC — COMPLETE                         ║
╠══════════════════════════════════════════════════════════════╣
║ Storage Before:  XXX GB used (XX%)                          ║
║ Storage After:   XXX GB used (XX%)                          ║
║ Total Reclaimed: XX GB                                       ║
╠══════════════════════════════════════════════════════════════╣
║ Phase 1: Caches & Logs          X GB freed   ✅              ║
║ Phase 2: Developer tools        X GB freed   ✅              ║
║ Phase 3: Docker                 X GB freed   ✅              ║
║ Phase 4: AI Models              X GB freed   ✅              ║
║ Phase 5: TM Snapshots           X GB freed   ✅              ║
║ Phase 6: Large files            X GB freed   ✅              ║
║ Phase 7: iCloud guidance        —            ✅ guided       ║
╠══════════════════════════════════════════════════════════════╣
║ Protected (active tools):  npm cache, Xcode DerivedData     ║
║ Skipped (user request):    ~/Downloads                      ║
║ Full log: ~/clean-my-mac-log-<date>.txt                     ║
╚══════════════════════════════════════════════════════════════╝

Maintenance tips:
• Run this skill monthly
• Enable "Empty Trash Automatically" in Storage settings
• Run `brew cleanup` weekly if using Homebrew heavily
• Keep ~/Downloads < 2 GB — archive or delete regularly
• Use `ollama rm <model>` to remove unused AI models
```

---

## Out of Scope

This skill does NOT:
- Uninstall applications (human judgment required)
- Touch `/System`, `/usr`, `/bin`, `/sbin`, or SIP-protected paths
- Delete `~/.ssh`, Keychains, or cloud credentials
- Auto-delete Downloads, Documents, or Desktop
- Run package installs or system configuration changes
- Access network resources
- Use tools beyond the `allowed-tools` list above
