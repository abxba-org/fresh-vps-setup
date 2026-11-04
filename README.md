# Fresh VPS Setup

A complete, production-ready VPS hardening and tooling setup for Ubuntu servers. This repository contains scripts and configurations to secure a fresh VPS, install essential CLI tools, configure Zsh with modern plugins, and set up secure remote access via Cloudflare Tunnels and Tailscale.

## Repository Structure

```
.
├── AGENT.md                          # AI agent instructions and cross-references
├── README.md                         # This file
├── scripts/
│   ├── network/
│   │   ├── README.md                 # [[scripts/network/README|Network hardening docs]]
│   │   ├── restrict-ssh.sh           # [[scripts/network/restrict-ssh.sh|SSH access restriction via nftables]]
│   │   └── secure-vps.sh             # [[scripts/network/secure-vps.sh|Full VPS hardening (UFW, Fail2ban, SSH, idle timeout)]]
│   ├── system-update/
│   │   └── auto-system-update.sh     # [[scripts/system-update/auto-system-update.sh|Unattended upgrades setup]]
│   ├── tools/
│   │   ├── README.md                 # [[scripts/tools/README|CLI tools installation docs]]
│   │   ├── install-sys-tools.sh      # [[scripts/tools/install-sys-tools.sh|System tools installer]]
│   │   ├── tools.sh                  # (empty placeholder)
│   │   ├── cloudflare/
│   │   │   ├── README.md             # [[scripts/tools/cloudflare/README|Cloudflare tunnel setup]]
│   │   │   ├── CF-tunnels.md         # [[scripts/tools/cloudflare/CF-tunnels|Detailed Cloudflare tunnels guide]]
│   │   │   └── CF-setup.sh           # [[scripts/tools/cloudflare/CF-setup.sh|Cloudflared install script]]
│   │   └── tailscale/
│   │       ├── README.md             # [[scripts/tools/tailscale/README|Tailscale setup docs]]
│   │       └── tailscale-setup.sh    # [[scripts/tools/tailscale/tailscale-setup.sh|Tailscale install & join script]]
│   └── zsh/
│       ├── README.md                 # [[scripts/zsh/README|Zsh configuration docs]]
│       ├── .zshrc                    # [[scripts/zsh/.zshrc|Zsh configuration file]]
│       └── zsh_script.sh             # [[scripts/zsh/zsh_script.sh|Zsh quick install script]]
```

## Quick Start

### 1. Initial VPS Hardening (Run First)
```bash
# Run the full hardening script (interactive, requires sudo)
sudo ./scripts/network/secure-vps.sh --apply

# Or just check current state
sudo ./scripts/network/secure-vps.sh --check
```

### 2. Install System Tools
```bash
./scripts/tools/install-sys-tools.sh
```

### 3. Configure Zsh
```bash
# Quick install (interactive)
./scripts/zsh/zsh_script.sh

# Or manually:
# 1. Install zsh: sudo apt install zsh
# 2. Run oh-my-zsh installer
# 3. Copy .zshrc: cp scripts/zsh/.zshrc ~/.zshrc
# 4. Restart terminal
```

### 4. Set Up Secure Remote Access

**Cloudflare Tunnels** (for HTTPS/SSH over Cloudflare):
```bash
# Install cloudflared
./scripts/tools/cloudflare/CF-setup.sh

# Follow [[scripts/tools/cloudflare/CF-tunnels|detailed guide]] for per-service tunnels
```

**Tailscale** (for tailnet SSH/admin access):
```bash
sudo ./scripts/tools/tailscale/tailscale-setup.sh
# Then approve in admin console and disable key expiry
```

### 5. Enable Automatic Updates
```bash
./scripts/system-update/auto-system-update.sh
```

## Security Model

This setup implements a **two-path SSH access model**:

1. **Cloudflare Access SSH** — HTTPS → Cloudflare Edge → cloudflared tunnel → `ssh://localhost:22`
   - Authenticated at Cloudflare Access edge (MFA, short sessions)
   - No open inbound ports on the VPS

2. **Tailscale SSH** — Tailnet device → `tailscale0` interface → `sshd`
   - Authenticated via Tailscale ACLs (device posture, MFA)
   - Direct encrypted WireGuard connection

**Direct SSH by public IP is denied** by [[scripts/network/restrict-ssh.sh|restrict-ssh.sh]] nftables guard.

## Key Scripts Summary

| Script | Purpose | Run As |
|--------|---------|--------|
| `secure-vps.sh` | UFW, Fail2ban, SSH hardening, idle timeout | `sudo` |
| `restrict-ssh.sh` | nftables guard: only lo + tailscale0 can reach tcp/22 | `sudo` |
| `install-sys-tools.sh` | exa, fd, zoxide, bat, fzf, ripgrep, atuin, neofetch | user |
| `zsh_script.sh` | Interactive zsh + oh-my-zsh + .zshrc setup | user |
| `auto-system-update.sh` | unattended-upgrades install & enable | `sudo` |
| `CF-setup.sh` | cloudflared repo + install | `sudo` |
| `tailscale-setup.sh` | Tailscale install, join tag:hermes-vps, enable SSH | `sudo` |

## Documentation Index

- [[AGENT|Agent instructions & cross-references]]
- [[scripts/network/README|Network hardening documentation]]
- [[scripts/tools/README|CLI tools documentation]]
- [[scripts/zsh/README|Zsh configuration documentation]]
- [[scripts/tools/cloudflare/README|Cloudflare tunnel setup]]
- [[scripts/tools/cloudflare/CF-tunnels|Cloudflare tunnels deep dive]]
- [[scripts/tools/tailscale/README|Tailscale setup]]

## Requirements

- Ubuntu 22.04+ or 24.04+
- Root/sudo access
- Cloudflare account (for tunnels)
- Tailscale account (for tailnet access)
- Provider console/rescue access (break-glass)

## Known Gaps / Future Work

> **⚠️ Agent-Vault Setup Pending**
>
> Secret management for automated provisioning is not yet implemented:
> - **Cloudflare tunnel tokens** — Currently passed inline or stored in local files
> - **Tailscale auth keys** — Currently uses interactive `tailscale up` auth URL
> - **SSH keys / API tokens** — No centralized secrets store
>
> **Planned:** Integrate a secrets manager (1Password CLI, HashiCorp Vault, SOPS/age, or similar) to enable fully automated, non-interactive node provisioning and credential rotation.

## License

MIT
