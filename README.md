# Vault CLI - gocryptfs Integration with Git Versioning

Professional CLI wrapper for gocryptfs with automated Git synchronization and comprehensive recovery capabilities.

## Quick Start

```bash
# Prerequisites and installation
sudo apt install gocryptfs
./vault install

# Vault initialization
mkdir -p ~/Vault.encrypted ~/Vault
gocryptfs -init ~/Vault.encrypted

# Operations
vault toggle                    # Mount/unmount (work ONLY in $VAULT_DIR)
vault sync "message"            # Commit and synchronize changes
vault recover backup            # Create master key backup
```

> ⚠️ **Critical:** Always edit files in the **mounted plaintext directory** (`$VAULT_DIR`, default `~/Vault`).
> Do **not** put plaintext files directly into `$ENCRYPTED_DIR` (default `~/Vault.encrypted`).

---

## Installation & CLI Interface

### System Installation

```bash
./vault install                 # Install system-wide
# or: sudo ./scripts/vault-install
```

### Command Reference

| Command | Function |
|---------|----------|
| `vault toggle` | Mount/unmount operations |
| `vault sync [message]` | Commit and push encrypted changes |
| `vault status` | Display mount status |
| `vault recover <action>` | Master key backup/recovery operations |
| `vault help` | Display command reference |

**Features:** Bash completion, automated Git integration, comprehensive error handling.

### Development & Automation

**Local Development:** Execute scripts directly via `./vault` or `./scripts/vault-*`
**Shell Completion:** `source completions/vault.bash`
**Systemd Integration:** Copy `config/vault.mount.service.example` to `~/.config/systemd/user/`

---

## Git Integration

**Repository Setup:**

```bash
cd ~/Vault.encrypted && git init && git remote add origin <repository-url>
```

**Workflow:** All Git operations target encrypted data exclusively. Plaintext never leaves the local system.

```bash
vault toggle        # Mount for editing
# ... edit files in ~/Vault ...
vault toggle        # Unmount (use: 'fusermount -u ~/Vault' or 'fusermount3 -u ~/Vault')
vault sync "msg"    # Commit encrypted changes
```

---

## Automated Synchronization

**⚠️ Important:** Automated sync only works when vault is **unmounted**. Never run `vault sync` on mounted vaults.

### Auto-Sync Script

Create `/usr/local/bin/vault-auto-sync.sh`:

```bash
#!/bin/bash
# Automated vault synchronization with safety checks

VAULT_DIR="${VAULT_DIR:-$HOME/Vault}"
ENCRYPTED_DIR="${ENCRYPTED_DIR:-$HOME/Vault.encrypted}"

# Exit if vault is mounted (safety check)
if mountpoint -q "$VAULT_DIR" 2>/dev/null; then
    echo "$(date): Vault is mounted - skipping auto-sync for safety"
    exit 0
fi

# Exit if no changes detected
cd "$ENCRYPTED_DIR" || exit 1
if git diff --quiet && git diff --cached --quiet; then
    echo "$(date): No changes detected - skipping sync"
    exit 0
fi

# Perform sync with timestamp
echo "$(date): Starting auto-sync..."
if /usr/local/bin/vault sync "Auto-sync $(date +%Y-%m-%d %H:%M)"; then
    echo "$(date): Auto-sync completed successfully"
else
    echo "$(date): Auto-sync failed - check manually" >&2
    exit 1
fi
```

Make script executable:

```bash
sudo chmod +x /usr/local/bin/vault-auto-sync.sh
```

### Crontab Setup

```bash
# Create log directory
mkdir -p ~/logs/vault

# Add to crontab (crontab -e):

# Smart sync with change detection and logging
*/30 * * * * /usr/local/bin/vault-auto-sync.sh >> ~/logs/vault/sync.log 2>&1

# Weekly cleanup of old logs
0 1 * * 0 find ~/logs/vault -name "*.log" -mtime +30 -delete
```

---

## Configuration

| Variable | Default | Purpose |
|----------|---------|---------|
| `VAULT_DIR` | `~/Vault` | Mount point path |
| `ENCRYPTED_DIR` | `~/Vault.encrypted` | Encrypted data path |
| `GIT_REMOTE_URL` | - | Remote repository URL |
| `GIT_USER_NAME`, `GIT_USER_EMAIL` | - | Git identity |
| `GIT_SIGN` | `false` | Enable GPG commit signing |

---

## Architecture

| Component | Path | Function |
|-----------|------|----------|
| **CLI Wrapper** | `vault` | Main command interface |
| **Subcommands** | `scripts/` | Individual operation implementations |
| **Configuration** | `config/` | Service definitions, examples |
| **Completion** | `completions/` | Shell integration |
| **Encrypted Data** | `~/Vault.encrypted/` | Git-versioned encrypted storage |
| **Mount Point** | `~/Vault/` | Temporary plaintext access |

---

## Master Key Recovery

**Principle:** gocryptfs uses a 256-bit AES master key stored in `gocryptfs.conf`, encrypted with your password. Password loss equals permanent data loss without key backup.

### Component Architecture

| Component | Function | Recovery Method |
|-----------|----------|-----------------|
| `gocryptfs.conf` | Encrypted master key container | Can be recreated from raw master key |
| Master Key | 8×8-char hex AES-256 key (hyphen-separated) | Must be backed up separately/offline |
| `gocryptfs.diriv` | Per-directory initialization vector | **Must be preserved** with data; loss causes data loss in that directory |

### Operations

| Command | Function |
|---------|----------|
| `vault recover backup [path]` | Create encrypted master key backup |
| `vault recover restore <file>` | Restore configuration from backup |
| `vault recover change-password` | Update password, backup configuration |
| `vault recover verify` | Validate vault integrity |

**Critical:** Backups of `gocryptfs.conf` are protected by your **current password**.
After changing the password, create **new backups**. Old backups remain decryptable with the **old** password.

### Recovery Procedures

**Restoration:** `vault recover restore <backup>` + password from backup creation
**Password Change:** Automated backup, unmount, re-encryption, verification
**Verification:** Configuration integrity, mount capability, access permissions

### Direct gocryptfs Operations

**Configuration Recreation:** `gocryptfs -init -masterkey <xxxxxxxx-xxxxxxxx-xxxxxxxx-xxxxxxxx-xxxxxxxx-xxxxxxxx-xxxxxxxx-xxxxxxxx> <vault-path>`
**Vault Information:** `gocryptfs -info <vault-path>` (shows configuration details)
**Change Password:** `gocryptfs -passwd <vault-path>`
**Manual Operations:** `gocryptfs <encrypted> <mount>` / `fusermount -u <mount>` or `fusermount3 -u <mount>`

**⚠️ Security:** Master key visible in process list (`ps`). Use `echo <key> | gocryptfs -masterkey=stdin` for secure input.

### Backup Strategy

**Automation:** `crontab` with `vault recover backup` for scheduled key backups
**Distribution:** External storage, encrypted cloud, offline media, password managers
**Validation:** Regular restoration testing in isolated environments

### Common Scenarios

| Scenario | Solution | Prerequisite |
|----------|----------|--------------|
| **Forgotten Password** | `vault recover restore <backup>` | Master key backup |
| **Corrupted Config** | `vault recover restore <backup>` + `verify` | Master key backup |
| **System Migration** | `vault recover backup` → `restore` | Backup transport |
| **No Backup Available** | Data permanently inaccessible | - |

### Security Framework

**Backup Security:** Never version control backups, separate storage from vault data, additional encryption (GPG/age)
**Password Policy:** Strong passwords, password manager integration, documented recovery procedures
**Emergency Access:** Multiple backup variants, trusted contact procedures, documented locations

### Shell Completion Security Note

For convenience, shell completion auto-discovers subcommands in several local paths.
In shared or untrusted environments, ensure those paths are trusted to avoid subcommand shadowing.

### Diagnostics

| Error | Causes | Resolution |
|-------|--------|------------|
| **Backup not found** | Missing file, permissions | Verify path, check access rights |
| **Access verification failed** | Wrong password, corrupted backup | Alternative backups, password verification |
| **Config corruption** | Filesystem issues, incomplete writes | `vault recover restore <backup>` |

---

## Security Model

### Dual Backup Architecture

| Backup Type | Command | Content | Storage Policy |
|-------------|---------|---------|----------------|
| **Master Key** | `vault recover backup` | Encrypted key configuration | Offline, separate from vault |
| **Encrypted Data** | `git push` / `rsync` | All encrypted files + metadata | Git repository or external |

### Security Requirements

**Access Control:** Strong passwords, regular unmounting, session management
**Key Management:** Master key backups separate from data, no version control of keys
**Data Integrity:** Regular backup testing, verification procedures
**Safe Operations:** `gocryptfs.conf` safe for Git, plaintext never transmitted
**Configuration Security:** For high-security environments, store config file separately from encrypted data to prevent brute-force attacks
