# Vault CLI - Encrypted File Storage with Git Integration

A secure and lightweight solution for encrypted file storage with automated Git versioning using gocryptfs.

## Quick Start

```bash
# 1. Install dependencies and setup
sudo apt install gocryptfs
./vault install

# 2. Initialize encrypted vault
mkdir -p ~/Vault.encrypted ~/Vault
gocryptfs -init ~/Vault.encrypted

# 3. Start using your vault
vault toggle                    # Mount/unmount vault
vault status                    # Check mount status
vault sync "Initial commit"     # Sync changes to Git
vault help                      # Show all available commands
```

---

## Vault CLI

### Installation

Install the unified vault CLI system-wide:

```bash
./vault install
```

or alternatively:

```bash
sudo ./scripts/vault-install
```

This creates a single `vault` command with subcommands:

```bash
vault help        # Show all commands
vault toggle      # Mount/unmount the vault
vault sync        # Commit & push changes
vault status      # Check mount status
vault recover     # Master key backup and recovery
vault uninstall   # Remove installation
```

The installation also includes **bash completion** for tab completion:

```bash
vault <TAB><TAB>    # Shows available subcommands
vault sync <TAB>    # Shows commit message templates
```

Verify installation:

```bash
vault help
```

### Usage

#### Mount/Unmount Operations

```bash
vault toggle      # Mount if unmounted, unmount if mounted
vault status      # Check current mount status
```

#### Git Synchronization

```bash
vault sync "Update notes"    # Commit with custom message
vault sync                   # Auto-generated timestamp message
```

### Local Development

For development, you can run scripts directly:

```bash
./vault help                # Use local wrapper
./scripts/vault-toggle      # Direct script execution
```

Enable tab completion for local development:

```bash
source completions/vault.bash    # Load completion in current shell
```

#### Optional: Systemd Integration

To mount automatically on login:

```bash
mkdir -p ~/.config/systemd/user/
cp config/vault.mount.service.example ~/.config/systemd/user/vault.mount.service
systemctl --user enable vault.mount.service
systemctl --user start vault.mount.service
```

---

## Git Integration

Initialize Git repository for your encrypted vault:

```bash
cd ~/Vault.encrypted
git init
git remote add origin <your-repository-url>
```

Sync changes safely (only encrypted data is committed):

```bash
# Work on decrypted files
vault toggle
cd ~/Vault
echo "# Notes" > notes.md
vault toggle

# Commit encrypted data automatically
vault sync "Add notes"
```

> Git tracks **only encrypted data**. No plaintext ever leaves your system.

---

## Environment Variables

The vault system supports customization via environment variables:

* `VAULT_DIR` - Path to mount point (default: `~/Vault`)
* `ENCRYPTED_DIR` - Path to encrypted data (default: `~/Vault.encrypted`)
* `GIT_REMOTE_URL` - Git remote URL for sync operations
* `GIT_USER_NAME`, `GIT_USER_EMAIL` - Git identity
* `GIT_SIGN=true` - Enable GPG signing for commits

Example:

```bash
export ENCRYPTED_DIR="$HOME/MyDocs.encrypted"
export VAULT_DIR="$HOME/MyDocs"
vault toggle
vault sync "Update documentation"
```

---

## Project Structure

### Repository Structure

| Path | Description |
|------|-------------|
| `vault` | Main CLI wrapper |
| `scripts/` | Subcommand implementations |
| `config/` | Configuration files |
| `completions/` | Shell completion scripts |

### Runtime Directories

| Purpose        | Default Path          | Description                      |
| -------------- | --------------------- | -------------------------------- |
| Encrypted data | `~/Vault.encrypted/`  | Git repository (safe to version) |
| Decrypted view | `~/Vault/`            | Temporary working directory      |
| Installation   | `/usr/local/share/vault` | Installed CLI bundle location |

---

## Master Key Recovery

The vault system provides comprehensive master key recovery capabilities to protect against password loss and ensure long-term data accessibility.

### Overview

Your gocryptfs vault uses a master key stored in the `gocryptfs.conf` file, encrypted with your password. If you lose your password, you lose access to your data permanently. The recovery system helps prevent this by providing secure backup and restoration mechanisms.

#### Understanding the Master Key

The master key is the ultimate decryption secret for your vault - a 256-bit AES key represented as 64 hexadecimal characters. Understanding the components helps with recovery:

| Component | Purpose | Recoverable |
|-----------|---------|-------------|
| `gocryptfs.conf` | Contains master key encrypted with your password | ✅ Can be recreated from master key |
| Master Key | 64 hex chars (256-bit AES) - the true decryption secret | ❌ Must be backed up separately |
| `gocryptfs.diriv` | Per-directory initialization vectors | ✅ Regenerated automatically |

The master key allows **complete access to all encrypted data** without password verification, making it both your ultimate backup solution and your most sensitive security asset.

### Recovery Operations

```bash
vault recover backup                    # Create master key backup
vault recover backup ~/secure/backup   # Custom backup location
vault recover restore ~/backup/file    # Restore from backup
vault recover change-password          # Change vault password
vault recover verify                   # Verify vault integrity
```

#### Creating Master Key Backups

```bash
# Quick backup with timestamp
vault recover backup

# Custom backup location
vault recover backup ~/secure-storage/vault-key-$(date +%Y%m%d).backup

# The backup contains your encrypted master key
# Store it separately from your vault data
```

**Important:** Master key backups are encrypted with your **current password**. If you change your password, create new backups.

#### Restoring from Backup

If you forget your password or the `gocryptfs.conf` file becomes corrupted:

```bash
# First, try to recover/remember your password
# The backup is encrypted with your password

# Restore the master key configuration
vault recover restore ~/path/to/backup.backup

# Test access
vault toggle
```

#### Changing Passwords Safely

```bash
vault recover change-password
```

This operation:

1. Unmounts the vault for safety
2. Backs up your current configuration
3. Prompts for old and new passwords
4. Updates the master key encryption

**After changing passwords:**

* Create new master key backups
* Update any stored passwords
* Old backups remain valid with the old password

#### Verifying Vault Health

```bash
vault recover verify
```

Checks:

* Configuration file integrity
* Mount capability
* Encrypted directory structure
* Access permissions

### Advanced: Direct gocryptfs Recovery

For advanced users or emergency situations where the vault CLI is unavailable, you can work directly with gocryptfs commands:

#### Recreating Configuration from Master Key

If you have the raw master key (64 hexadecimal characters) but lost your `gocryptfs.conf`:

```bash
# Recreate configuration with existing master key
gocryptfs -init -masterkey <YOUR-64-CHAR-MASTER-KEY> ~/Vault.encrypted

# Example with placeholder key (64 hex characters):
gocryptfs -init -masterkey a1b2c3d4e5f67890abcdef1234567890fedcba0987654321a1b2c3d4e5f67890 ~/Vault.encrypted
```

You'll be prompted to set a new password to encrypt the master key.

#### Extracting Master Key from Existing Vault

To view or backup your current master key:

```bash
# Display master key from existing configuration
gocryptfs -info ~/Vault.encrypted
```

Output example:

```text
Decryption succeeded, master key: a1b2c3d4e5f67890abcdef1234567890fedcba0987654321...
```

**⚠️ Security Warning:** The master key grants complete access to your encrypted data. Store it securely and separately from your vault.

#### Manual Mount/Unmount

```bash
# Manual mount (alternative to vault toggle)
mkdir -p ~/Vault
gocryptfs ~/Vault.encrypted ~/Vault

# Manual unmount
fusermount -u ~/Vault
```

### Backup Strategy Recommendations

#### 1. Regular Automated Backups

```bash
# Add to crontab for weekly backups (run 'crontab -e' to edit)
0 2 * * 0 /usr/local/bin/vault recover backup ~/secure/vault-key-$(date +\%Y\%m\%d).backup
```

#### 2. Multiple Storage Locations

Store backups in different locations:

* External drive or USB stick
* Cloud storage (encrypted folder)
* Print on paper (for ultimate fallback)
* Secure password manager notes

#### 3. Test Recovery Process

Periodically test your backup:

```bash
# Verify backup file exists and is readable
ls -la ~/secure/vault-*.backup

# Test restore in a temporary location (advanced)
mkdir /tmp/test-vault
cp ~/secure/vault-key-backup.backup /tmp/test-vault/gocryptfs.conf
gocryptfs -info /tmp/test-vault  # Should show vault info
rm -rf /tmp/test-vault
```

### Recovery Scenarios

#### Scenario 1: Forgotten Password

1. **If you have a master key backup:**

   ```bash
   vault recover restore ~/secure/vault-backup.backup
   # Enter the password you used when creating the backup
   vault toggle  # Test access
   ```

2. **If you have no backup:**

   * Data is permanently inaccessible
   * This is why regular backups are critical

#### Scenario 2: Corrupted gocryptfs.conf

```bash
# Restore from backup
vault recover restore ~/secure/vault-backup.backup

# Verify restoration
vault recover verify
```

#### Scenario 3: System Migration

Moving to a new system:

```bash
# On old system: ensure you have recent backup
vault recover backup ~/migration/vault-key.backup

# On new system: after installing vault-cli
vault recover restore ~/migration/vault-key.backup
vault toggle  # Test access
```

### Security Considerations

#### Master Key Backup Security

* **Never commit backups to Git** - they contain your encrypted master key
* Store backups separate from your encrypted vault data
* Use strong, unique passwords
* Consider encrypting backup files with additional tools (GPG, age)

#### Password Management

* Use a password manager to store vault passwords
* Consider using a passphrase instead of a complex password
* Document your backup locations securely
* Share recovery information with trusted contacts if needed

#### Emergency Access Planning

For critical data, consider:

```bash
# Create multiple backups with different passwords
vault recover change-password    # Set emergency password
vault recover backup ~/emergency/vault-backup-emergency.backup
vault recover change-password    # Return to normal password
vault recover backup ~/regular/vault-backup-normal.backup
```

### Troubleshooting

#### Common Issues

##### "Backup file not found"

```bash
# Check backup file exists and is readable
ls -la ~/path/to/backup.backup
file ~/path/to/backup.backup  # Should show text file
```

##### "Cannot verify vault access"

* Password may be incorrect
* Backup file may be corrupted
* Try different backup files
* Check vault directory permissions

##### "Config file corrupted"

```bash
# Check if backup exists before restoration
vault recover verify  # Shows current status
vault recover restore ~/secure/backup.backup
```

---

## Security Guidelines

* **Critical**: Always maintain secure master key backups
* Never version or share your master key backups
* Always use a **strong, unique password**
* Backup both your encrypted data **and** the master key
* Test your recovery process regularly
* Unmount your Vault after work sessions
* The file `gocryptfs.conf` is **safe to commit** (contains only encrypted config data)
* Store master key backups separately from vault data
