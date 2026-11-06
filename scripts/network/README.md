# Network Setup

Network hardening and configuration scripts for fresh VPS instances.

## Overview

This module configures the network security baseline:
- **UFW** - Uncomplicated Firewall with default-deny policy
- **SSH Hardening** - Key-only auth, non-standard port, rate limiting
- **fail2ban** - Intrusion prevention for SSH and web services
- **Automatic Updates** - Unattended security upgrades

## Quick Start

```bash
# Run as root or with sudo
sudo ./setup.sh

# Verify firewall status
sudo ufw status verbose

# Check SSH config
sudo sshd -T | grep -E 'port|permitrootlogin|passwordauthentication|maxauthtries'

# View fail2ban status
sudo fail2ban-client status
```

## Configuration

### UFW Rules Applied

| Rule | Action | Description |
|------|--------|-------------|
| Default | Deny (incoming) | Block all incoming by default |
| Default | Allow (outgoing) | Allow all outgoing |
| SSH | Allow | TCP port 22 (or custom port) |
| HTTP | Allow | TCP port 80 |
| HTTPS | Allow | TCP port 443 |
| Custom | Allow | Additional ports via `UFW_ALLOW_PORTS` env var |

### SSH Hardening Settings

| Setting | Value | Description |
|---------|-------|-------------|
| `Port` | 2222 | Non-standard port (configurable via `SSH_PORT`) |
| `PermitRootLogin` | no | Disable root login |
| `PasswordAuthentication` | no | Key-only authentication |
| `PubkeyAuthentication` | yes | Enable public key auth |
| `MaxAuthTries` | 3 | Limit auth attempts |
| `ClientAliveInterval` | 300 | Keep-alive interval (5 min) |
| `ClientAliveCountMax` | 2 | Max missed keep-alives |
| `LoginGraceTime` | 30 | Time to complete login |
| `AllowUsers` | $SUDO_USER | Restrict to sudo user only |

### fail2ban Jails Enabled

| Jail | Port | Max Retries | Ban Time | Find Time |
|------|------|-------------|----------|-----------|
| `sshd` | SSH port | 3 | 1 hour | 10 min |
| `nginx-http-auth` | 80,443 | 3 | 1 hour | 10 min |
| `nginx-limit-req` | 80,443 | 5 | 1 hour | 10 min |

## Customization

### Environment Variables

```bash
# Custom SSH port (default: 2222)
export SSH_PORT=2222

# Additional UFW allow ports (space-separated)
export UFW_ALLOW_PORTS="8080 9000"

# Skip SSH port change (keep port 22)
export KEEP_SSH_PORT=1

# Skip fail2ban installation
export SKIP_FAIL2BAN=1
```

### Running with Custom Values

```bash
SSH_PORT=2222 UFW_ALLOW_PORTS="8080 3000" sudo -E ./setup.sh
```

## File Structure

```
scripts/network/
├── setup.sh              # Main entry point
├── lib/
│   ├── ufw.sh            # Firewall configuration
│   ├── ssh.sh            # SSH hardening
│   ├── fail2ban.sh       # Intrusion prevention
│   └── updates.sh        # Automatic security updates
├── config/
│   ├── sshd_config.hardened  # SSH config template
│   └── fail2ban/
│       ├── jail.local        # fail2ban overrides
│       └── filter.d/         # Custom filters
└── README.md             # This file
```

## Verification Checklist

After running `setup.sh`, verify:

- [ ] `sudo ufw status` shows "Status: active" with SSH/HTTP/HTTPS allowed
- [ ] `sudo sshd -T | grep port` shows custom port (e.g., 2222)
- [ ] `sudo sshd -T | grep passwordauthentication` shows "no"
- [ ] `sudo fail2ban-client status sshd` shows "Jail list: sshd"
- [ ] `sudo systemctl status unattended-upgrades` shows "active"
- [ ] Can SSH in on new port with key: `ssh -p 2222 user@host`

## Rollback

If locked out:

1. Access via VPS console (provider dashboard)
2. Reset firewall: `sudo ufw --force reset`
3. Restore SSH: `sudo cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config && sudo systemctl restart ssh`
4. Re-run with `KEEP_SSH_PORT=1`

## Related Documentation

- [[README.md]] - Project overview
- [[AGENT.md]] - Agent cross-references
- [[scripts/zsh/README.md]] - Shell environment setup
- [[scripts/tools/README.md]] - Tools installation

## Security Notes

- **Test SSH access** before closing current session
- **Keep a console session open** while running for the first time
- **Backup original configs** automatically created at `/etc/ssh/sshd_config.backup`
- **fail2ban bans** are persistent across reboots (stored in SQLite)
- **UFW rules** persist via `ufw enable` (systemd service)