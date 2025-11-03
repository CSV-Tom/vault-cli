# gocryptfs – Encrypted Vault Setup

A secure and lightweight solution for encrypted file storage with Git versioning.

## Quick Start

```bash
# 1. Install dependencies and setup
sudo apt install gocryptfs
./vault install

# 2. Initialize vault
mkdir -p ~/Vault.encrypted ~/Vault
gocryptfs -init ~/Vault.encrypted

# 3. Start using
vault toggle          # Mount vault
vault status          # Check status  
vault sync "message"  # Sync changes
vault help            # Show all commands
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

---

### Optional: Systemd Integration

To mount automatically on login:

```bash
mkdir -p ~/.config/systemd/user/
cp config/vault.mount.service.example ~/.config/systemd/user/vault.mount.service
systemctl --user enable vault.mount.service
systemctl --user start vault.mount.service
```

---

## Git Integration

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

### Environment Variables

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

| Path | Description |
|------|-------------|
| `vault` | Main CLI wrapper |
| `scripts/` | Subcommand implementations |
| `config/` | Configuration files |
| `completions/` | Shell completion scripts |

## Directory Overview

| Purpose        | Path                  | Description                      |
| -------------- | --------------------- | -------------------------------- |
| Encrypted data | `~/Vault.encrypted/`  | Git repository (safe to version) |
| Decrypted view | `~/Vault/`            | Temporary working directory      |
| CLI Command    | `vault`               | Unified vault management CLI     |
| Installation   | `/usr/local/share/vault` | Installed CLI bundle location |

---

## Security Guidelines

* Never version or share your `masterkey.txt`
* Always use a **strong, unique password**
* Backup both your encrypted data **and** the password
* Unmount your Vault after work sessions
* The file `gocryptfs.conf` is **safe to commit** (contains only encrypted config data)
