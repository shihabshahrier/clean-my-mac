# Dangerous Paths — NEVER Delete

These paths must never be touched by any cleanup operation. Deletion causes data loss,
system instability, security compromise, or unrecoverable damage.

## System Integrity (SIP-protected — deletion impossible anyway)

| Path | Why off-limits |
|------|---------------|
| `/System/*` | Core macOS system files. SIP prevents deletion. |
| `/usr/*` | UNIX system binaries and libraries. |
| `/bin/*` | Essential shell commands (`ls`, `cp`, `rm`, etc.). |
| `/sbin/*` | System administration binaries. |
| `/private/var/db/*` | System databases (user accounts, permissions, etc.). |
| `/Library/Security/*` | Security certificates and trust stores. |
| `/Library/Keychains/*` | System keychain. |

## User Security — Credentials and Keys

| Path | Why off-limits |
|------|---------------|
| `~/.ssh/*` | SSH private keys. Loss = permanent lockout from servers. |
| `~/Library/Keychains/*` | Passwords, certificates, API keys stored by apps. |
| `~/.gnupg/*` | GPG encryption keys. |
| `~/.aws/*` | AWS credentials and config. |
| `~/.kube/*` | Kubernetes cluster credentials. |
| `~/.docker/config.json` | Docker registry credentials. |
| `~/.netrc` | FTP/HTTP authentication credentials. |
| `~/.npmrc` | npm auth token (private registry access). |
| `~/.pypirc` | PyPI upload credentials. |
| `~/.gitcredentials` | Git credential store. |
| `~/.config/*` | App configuration (may contain tokens, settings). |

## Irreplaceable User Data

| Path | Why off-limits |
|------|---------------|
| `~/Library/Mail/*` | Local email database and attachments. |
| `~/Pictures/Photos Library.photoslibrary` | Entire Photos library. Possibly the only copy. |
| `~/Library/Application Support/MobileSync/Backup/*` | iPhone/iPad backups. Never auto-delete — guide to Finder. |
| `~/Documents/*` | User documents. Never auto-touch. |
| `~/Desktop/*` | User files. Never auto-touch. |
| `~/Downloads/*` | User downloads. List only — never auto-delete. |

## Developer Data That Cannot Be Auto-Regenerated

| Path | Why off-limits |
|------|---------------|
| `~/Library/Developer/Xcode/Archives/*` | App Store release builds. May be only copy. HIGH risk — double confirm. |
| Any Git repository working tree | Uncommitted changes would be lost. |
| Database files (`*.sqlite`, `*.db`) outside known safe locations | May be app data. |

## Rule for Uncertain Paths

> If the path is not on the safe list in `reference/safe-paths.md`, skip it and report it.
> Never guess. Never delete based on filename pattern alone.
