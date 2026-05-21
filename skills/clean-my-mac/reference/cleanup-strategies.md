# Cleanup Strategies — Per-Tool Command Reference

Exact commands for each cleanup category. All scripts support `--dry-run`.

---

## Caches & Logs

```bash
# Size check
du -sh ~/Library/Caches /Library/Caches ~/Library/Logs ~/Library/Saved\ Application\ State ~/.Trash

# User caches (per-app, loop to show each)
for dir in ~/Library/Caches/*/; do echo "$(du -sh "$dir" 2>/dev/null | cut -f1)  $dir"; done | sort -rh

# Delete user caches
rm -rf ~/Library/Caches/*

# Delete saved app state (window restore positions)
rm -rf ~/Library/Saved\ Application\ State/*

# Delete crash reports
rm -rf ~/Library/Application\ Support/CrashReporter/*

# Empty Trash via AppleScript (cleaner than rm)
osascript -e 'tell application "Finder" to empty trash'
```

---

## Homebrew

```bash
# Check cache size
du -sh ~/Library/Caches/Homebrew 2>/dev/null

# Dry-run (shows what would be removed)
brew cleanup --dry-run

# Full cleanup — removes all cached downloads older than any version
brew cleanup --prune=all

# Also remove old versions of installed formulae
brew autoremove
```

---

## Xcode

```bash
# Size overview
du -sh \
  ~/Library/Developer/Xcode/DerivedData \
  ~/Library/Developer/Xcode/Archives \
  ~/Library/Developer/CoreSimulator/Devices \
  ~/Library/Caches/com.apple.dt.Xcode \
  ~/Library/Application\ Support/MobileSync/Backup \
  2>/dev/null

# DerivedData — LOW risk, always safe
rm -rf ~/Library/Developer/Xcode/DerivedData

# Xcode caches — LOW risk
rm -rf ~/Library/Caches/com.apple.dt.Xcode

# Simulators — MEDIUM risk, prefer xcrun over rm -rf
xcrun simctl delete unavailable          # removes unusable sims only
# OR: Xcode > Settings > Platforms for manual control

# Archives — HIGH risk, double confirm required
# Never auto-delete. Show size and warn:
# "These are your compiled app archives. Only delete if you have copies or don't ship apps."
```

---

## Node.js Ecosystem

```bash
# npm cache (auto-regenerated on install)
npm cache verify       # check integrity first
npm cache clean --force

# pnpm store (prune unreferenced packages only — safe)
pnpm store prune

# yarn cache
yarn cache clean

# Find all node_modules (list only — never auto-delete)
find ~ -name "node_modules" -type d \
  -not -path "*/\.*" \
  -not -path "*/node_modules/*/node_modules" \
  2>/dev/null | while read dir; do
    echo "$(du -sh "$dir" 2>/dev/null | cut -f1)  $dir"
  done | sort -rh

# Delete a specific node_modules (after user confirms)
rm -rf "/path/to/project/node_modules"
# Restore: cd /path/to/project && npm install
```

---

## Python

```bash
# pip cache
pip3 cache info
pip3 cache purge

# pyenv versions (list only)
pyenv versions

# Virtual environments (list — never auto-delete)
find ~ -name "pyvenv.cfg" -not -path "*/\.*" 2>/dev/null | xargs dirname | while read venv; do
  echo "$(du -sh "$venv" 2>/dev/null | cut -f1)  $venv"
done | sort -rh
```

---

## Flutter / Dart

```bash
# pub-cache size
du -sh ~/.pub-cache 2>/dev/null

# Clean pub cache (keeps downloaded packages — just clears temp)
dart pub cache repair

# Clean a specific project (removes build artifacts)
# cd /path/to/project && flutter clean
```

---

## Docker

```bash
# Show Docker disk usage (always run this first)
docker system df

# Level 1 — Safe: stopped containers + dangling images + unused networks
docker system prune -f

# Level 2 — Aggressive: ALL unused images (including pulled but not running)
# Warning: re-pull required when you next use those images
docker system prune -a -f

# Level 3 — Nuclear: all of above + Docker volumes
# WARNING: can delete database data stored in volumes
docker system prune -a --volumes -f

# Individual cleanup (more surgical)
docker container prune -f     # stopped containers only
docker image prune -f         # dangling images only
docker image prune -a -f      # all unused images
docker volume prune -f        # unused volumes (DATA LOSS POSSIBLE)
docker network prune -f       # unused networks
```

---

## Go

```bash
# Module cache size
du -sh ~/go/pkg 2>/dev/null

# Clean module cache (re-downloaded on next build)
go clean -modcache

# Clean build + test cache
go clean -cache -testcache
```

---

## Stale Toolchains

```bash
# Check if Rust is actually used (binary in PATH?)
command -v rustc &>/dev/null || echo "rustc not found — ~/.rustup may be stale"
du -sh ~/.rustup ~/.cargo 2>/dev/null

# Check if Flutter/Dart is actually used
command -v flutter &>/dev/null || command -v dart &>/dev/null || echo "Flutter/Dart not found — ~/.pub-cache may be stale"
du -sh ~/.pub-cache 2>/dev/null

# Remove stale toolchains (only if binary not in PATH)
rm -rf ~/.rustup ~/.cargo    # Rust
rm -rf ~/.pub-cache           # Flutter/Dart
```

---

## VS Code

```bash
# Find duplicate extensions (multiple versions installed)
ls -1 ~/.vscode/extensions/ | sed 's/-[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*.*//' | sort | uniq -d

# Cached extension downloads (safe to delete)
du -sh ~/Library/Application\ Support/Code/CachedExtensionVSIXs 2>/dev/null
rm -rf ~/Library/Application\ Support/Code/CachedExtensionVSIXs

# WebStorage cache
du -sh ~/Library/Application\ Support/Code/WebStorage 2>/dev/null
rm -rf ~/Library/Application\ Support/Code/WebStorage
```

---

## Large Log Files

```bash
# Find log files >50MB anywhere in home
find ~ -type f -name "*.log" -size +50M -exec du -sh {} \; 2>/dev/null | sort -rh

# Find large files >500MB (catches runaway logs, dumps, etc.)
find ~ -type f -size +500M -exec du -sh {} \; 2>/dev/null | sort -rh | head -20
```

---

## Application Support Deep Scan

```bash
# Top consumers in Application Support (often the biggest folder on Mac)
du -sh ~/Library/Application\ Support/* 2>/dev/null | sort -rh | head -15

# Common large items:
# - CloudDocs (iCloud) — managed by macOS, don't delete
# - Google/Chrome — browser data, user decides
# - Claude/vm_bundles — VM bundles, re-downloaded on launch
# - Code (VS Code) — extensions + cached data
```

---

## AI Models

```bash
# Find large model files (> 100MB)
find ~ -type f \( \
  -name "*.gguf" -o \
  -name "*.safetensors" -o \
  -name "*.bin" -o \
  -name "*.onnx" -o \
  -name "*.pt" -o \
  -name "*.pth" \
  \) -size +100M 2>/dev/null | xargs du -sh 2>/dev/null | sort -rh

# Ollama models
ollama list                              # list with sizes
ollama rm <model-name>                   # delete specific model
du -sh ~/.ollama/models 2>/dev/null

# LM Studio
du -sh ~/Library/Application\ Support/LM\ Studio 2>/dev/null

# Hugging Face cache
du -sh ~/.cache/huggingface 2>/dev/null
# List models: ls ~/.cache/huggingface/hub/
```

---

## Time Machine Local Snapshots

```bash
# List snapshots (often 10–50 of them)
tmutil listlocalsnapshots /

# Estimate total snapshot space
tmutil listlocalsnapshotdates | wc -l

# Show disk usage breakdown (macOS 12+)
du -sh /.MobileBackups 2>/dev/null || echo "Cannot measure directly (APFS)"

# Delete ALL local snapshots (requires sudo, requires backup confirmation first)
sudo tmutil deletelocalsnapshots /

# Delete one specific snapshot
sudo tmutil deletelocalsnapshots <YYYY-MM-DD-HHMMSS>

# Create a new snapshot (before risky cleanup)
tmutil snapshot
```

---

## Large File Scan

```bash
# Top 30 large files in home (excluding hidden dirs and Developer)
find ~ \
  -not -path "*/\.*" \
  -not -path "*/Library/Developer/*" \
  -not -path "*/node_modules/*" \
  -size +200M \
  -exec du -sh {} \; 2>/dev/null | sort -rh | head -30

# Old DMG/PKG installers
find ~ -name "*.dmg" -o -name "*.pkg" 2>/dev/null | xargs du -sh 2>/dev/null | sort -rh

# Large zip archives
find ~/Downloads ~/Desktop -name "*.zip" -size +100M -exec du -sh {} \; 2>/dev/null | sort -rh
```
