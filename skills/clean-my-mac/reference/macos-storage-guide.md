# macOS Storage Guide — What Each Category Means

Reference for interpreting macOS storage reports and `du` output.

---

## macOS Storage Categories (System Settings → General → Storage)

| Category | What it includes | Notes |
|----------|-----------------|-------|
| **System** | macOS itself, signed system volume | Cannot be reduced manually |
| **System Data** | Local Time Machine snapshots, caches, support files | Often the biggest surprise — snapshots hide here |
| **Apps** | Installed applications | Remove via Launchpad or Finder |
| **Documents** | Files in Documents, Downloads, Desktop, iCloud Drive | Review manually |
| **iCloud Drive** | Locally-stored iCloud files | Enable "Optimize Mac Storage" to offload |
| **Photos** | Photos.app library | Enable "Optimize Mac Storage" in Photos prefs |
| **Mail** | Mail.app database, attachments | Enable "Only store recent messages" in Mail |
| **Trash** | Items pending permanent deletion | Empty Trash |

---

## Why "System Data" Is Often Huge

On M1/M2 Macs, **local Time Machine snapshots** accumulate silently and are counted as "System Data." This is the single biggest surprise for people who think they have less free space than they do.

- macOS creates a local snapshot **every hour** when on battery
- Snapshots are deleted automatically when you need space — but only up to a point
- `tmutil listlocalsnapshots /` shows them
- They can occupy 20–60 GB on a developer machine

**Fix:** Run `sudo tmutil deletelocalsnapshots /` after confirming you have an external backup.

---

## Developer Tool Space Breakdown (Typical M1 256 GB)

| Tool | Typical Size | Grows because... |
|------|-------------|-----------------|
| Xcode DerivedData | 10–40 GB | Every project build adds artifacts |
| iOS Simulators | 10–30 GB | Each platform version downloaded separately |
| Docker images | 5–30 GB | Each `docker pull` adds layers |
| npm/pnpm caches | 2–10 GB | Every `npm install` caches packages |
| node_modules (all projects) | 5–20 GB | Each project reinstalls all deps |
| Homebrew cache | 1–5 GB | Downloaded bottles never auto-pruned |
| AI models (.gguf, etc.) | 2–70 GB | Each model file is 2–70 GB |
| pip cache | 0.5–3 GB | Every `pip install` adds to cache |

---

## APFS Concepts Relevant to Cleanup

**Snapshots** — Point-in-time copies of the volume. Created by Time Machine, iOS device backups, and macOS updates. They share data with the live filesystem (copy-on-write) so their "size" is the changed data since the snapshot was taken.

**Clones** — Files that share blocks with other files. `cp` on APFS creates clones instantly. `du` reports the full size of each clone even though they share disk space. This is why `du ~` may show more used space than `df` reports.

**Purgeables** — Space that macOS considers "purgeable" — it can reclaim it automatically if needed (iCloud-offloaded files, caches). Shows as free space in some contexts, used in others. This is why Finder and `df` sometimes disagree.

---

## Disk Usage Commands Cheat Sheet

```bash
# Overall disk usage (what Finder shows)
df -h /

# macOS-native storage report (most accurate — includes purgeable)
diskutil info / | grep -E "Free Space|Used Space|Total Space"

# Size of a directory
du -sh ~/Library/Caches

# Top 20 items in a directory
du -sh ~/Library/Caches/* 2>/dev/null | sort -rh | head -20

# Total size of all node_modules
find ~ -name "node_modules" -type d -not -path "*/\.*" 2>/dev/null | \
  xargs du -sk 2>/dev/null | awk '{sum+=$1} END {printf "%.1f GB\n", sum/1024/1024}'

# Time Machine snapshot count
tmutil listlocalsnapshots / | wc -l
```

---

## When to Run Cleanup

| Situation | Priority cleanups |
|-----------|------------------|
| < 20 GB free | TM snapshots → caches → Xcode DerivedData |
| Xcode builds failing | DerivedData → Xcode caches |
| Docker pulling fails "no space" | `docker system prune -a` |
| npm/yarn install fails | Clear respective caches |
| General slowness | Caches → logs → Trash → TM snapshots |
| Monthly maintenance | All LOW-risk categories |
