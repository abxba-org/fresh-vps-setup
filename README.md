# Fresh VPS Setup

A comprehensive, modular toolkit for provisioning and configuring fresh VPS instances. This repository contains scripts, templates, and documentation for automating server setup, tooling installation, and service configuration.

## Overview

```
fresh-VPS-setup/
├── scripts/              # Executable setup scripts
│   ├── network/          # Network configuration (firewall, DNS, SSH hardening)
│   ├── zsh/              # Zsh shell setup with plugins & themes
│   └── tools/            # Development & infrastructure tools
│       ├── cloudflare/   # Cloudflare Tunnel (cloudflared) setup
│       └── tailscale/    # Tailscale VPN mesh networking
├── templates/            # Reusable script templates
└── docs/                 # Additional documentation (this README + AGENT.md, CHANGELOG.md)
```

## Quick Start

### Automated Provisioning (Recommended)

```bash
# Clone the repository
git clone <repo-url> fresh-VPS-setup
cd fresh-VPS-setup

# Phase 1: Fully automatic (unattended-upgrades, terminal tools, cloudflared)
sudo ./auto-install.sh --phase=1

# Phase 2: Interactive (UFW, SSH hardening, nftables guard, Tailscale, Zsh)
sudo ./auto-install.sh --phase=2
```

Or run both phases with prompts:
```bash
sudo ./auto-install.sh
```

### Manual Step-by-Step

```bash
# Clone the repository
git clone <repo-url> fresh-VPS-setup
cd fresh-VPS-setup

# Run network hardening (firewall, SSH config, fail2ban)
sudo ./scripts/network/secure-vps.sh --apply --harden-ssh

# Apply nftables SSH guard (run FROM Cloudflare Access/Tailscale SSH)
sudo ./scripts/network/restrict-ssh.sh apply
# Test, then confirm:
sudo ./scripts/network/restrict-ssh.sh confirm

# Install terminal tools in parallel (exa, fd, zoxide, bat, fzf, rg, Atuin, starship, fnm, etc.)
sudo ./scripts/tools/parallel-tools-installer.sh

# Install and configure Zsh with Oh My Zsh, plugins, and theme
# (See scripts/zsh/README.md for manual steps)

# Set up Cloudflare Tunnels for secure service exposure
./scripts/tools/cloudflare/CF-setup.sh
cloudflared tunnel login  # Manual auth

# Set up Tailscale for private network access
sudo ./scripts/tools/tailscale/tailscale-setup.sh
# Complete admin console approval + disable key expiry
```

## Prerequisites

- Fresh Ubuntu 22.04+ / Debian 12+ VPS
- Root or sudo access
- Internet connectivity
- Domain name (for Cloudflare Tunnels)

## Automated Provisioning

### `auto-install.sh` — Two-Phase Orchestrator

Orchestrates the full VPS setup in two phases:

**Phase 1 (Autonomous)** — runs non-interactively:
1. `scripts/system-update/auto-system-update.sh` — unattended-upgrades (preseeded)
2. `scripts/tools/install-sys-tools.sh` — terminal tools + Atuin
3. `scripts/tools/cloudflare/CF-setup.sh` — cloudflared package

**Phase 2 (Interactive)** — requires manual confirmation:
4. `scripts/network/secure-vps.sh --apply --harden-ssh` — UFW, SSH hardening, fail2ban
5. `scripts/network/restrict-ssh.sh apply` — nftables SSH guard (loopback + Tailscale only)
6. `scripts/tools/tailscale/tailscale-setup.sh` — Tailscale join with tags
7. Zsh setup instructions

```bash
# Run both phases (prompts before Phase 2)
sudo ./auto-install.sh

# Phase 1 only
sudo ./auto-install.sh --phase=1

# Phase 2 only (after Phase 1 completes)
sudo ./auto-install.sh --phase=2

# Skip interactive entirely
sudo ./auto-install.sh --skip-interactive
```

> **Important:** For Phase 2 step 5 (restrict-ssh.sh), you MUST be connected via Cloudflare Access SSH or Tailscale SSH. Direct-IP sessions will be terminated. Keep provider console/rescue access ready.

### `scripts/tools/parallel-tools-installer.sh` — Parallel Tool Installer

Based on [tools-installer-template.md](templates/tools-installer-template.md), installs 17 tools in parallel with failure detection and verification.

```bash
# Install all tools (APT packages, GitHub releases, install scripts)
sudo ./scripts/tools/parallel-tools-installer.sh

# Custom timeout (default 300s)
TIMEOUT=600 sudo ./scripts/tools/parallel-tools-installer.sh

# Skip shell modifications for specific tools
NO_SHELL_MODIFY="atuin starship" sudo ./scripts/tools/parallel-tools-installer.sh

# Verify only (no installation)
./scripts/tools/parallel-tools-installer.sh --verify-only

# List configured tools
./scripts/tools/parallel-tools-installer.sh --list
```

**Tools installed:**
- **APT**: exa, fd, zoxide, bat, fzf, ripgrep, curl, jq, htop, ncdu, cloudflared
- **GitHub releases**: eza, btop, duf, dust
- **Install scripts**: atuin, starship, fnm

> **Note:** `cloudflared` via APT requires Cloudflare repo pre-configured (run `CF-setup.sh` first).

## Scripts

### Network Setup (`scripts/network/`)
Hardens the VPS network stack:
- UFW firewall configuration (default deny, allow SSH/HTTP/HTTPS)
- SSH hardening (key-only auth, non-standard port, rate limiting)
- fail2ban for intrusion prevention
- Automatic security updates

### Zsh Setup (`scripts/zsh/`)
Installs and configures Zsh with:
- Oh My Zsh framework
- Powerlevel10k theme
- Plugins: zsh-autosuggestions, zsh-syntax-highlighting, zsh-completions
- fzf integration
- zoxide for smart directory jumping
- Custom aliases and functions

### Tools Setup (`scripts/tools/`)
Installs essential development and infrastructure tools:
- **Container**: Docker, Docker Compose, containerd
- **Kubernetes**: kubectl, helm, kind, k9s
- **Infrastructure**: Terraform, Packer, Ansible
- **Cloud CLIs**: AWS CLI, gcloud, Azure CLI
- **Utilities**: jq, yq, bat, eza, ripgrep, fd, htop, btop
- **Version managers**: asdf, fnm, pyenv

### Cloudflare Tunnels (`scripts/tools/cloudflare/`)
Sets up Cloudflare Tunnel (cloudflared) for secure, zero-trust service exposure:
- Per-service tunnel isolation
- systemd service management
- Automatic DNS routing via Cloudflare API
- SSH-over-Tunnel support

See [CF-tunnels.md](scripts/tools/cloudflare/CF-tunnels.md) for detailed architecture and usage.

### Tailscale (`scripts/tools/tailscale/`)
Configures Tailscale for secure mesh networking:
- Automatic key rotation
- Exit node configuration
- Subnet routing for LAN access
- ACL tagging for device groups

## Templates

The `templates/` directory contains reusable script patterns:
- **tools-installer-template.md** - Parallel, fault-tolerant installer pattern for CLI tools

## Documentation

- [AGENT.md](AGENT.md) - AI agent configuration and cross-references (Obsidian-style links)
- [CHANGELOG.md](CHANGELOG.md) - Version history and release notes
- [scripts/network/README.md](scripts/network/README.md) - Network setup details
- [scripts/zsh/README.md](scripts/zsh/README.md) - Zsh configuration guide
- [scripts/tools/README.md](scripts/tools/README.md) - Tools inventory and usage
- [scripts/tools/cloudflare/README.md](scripts/tools/cloudflare/README.md) - Cloudflare quick reference
- [scripts/tools/cloudflare/CF-tunnels.md](scripts/tools/cloudflare/CF-tunnels.md) - Cloudflare Tunnels deep dive
- [scripts/tools/tailscale/README.md](scripts/tools/tailscale/README.md) - Tailscale configuration
- [templates/README.md](templates/README.md) - Template library index
- [templates/tools-installer-template.md](templates/tools-installer-template.md) - Installer template reference

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## License

MIT License - see [LICENSE](LICENSE) for details.

## Support

- Issues: [GitHub Issues](https://github.com/your-org/fresh-VPS-setup/issues)
- Discussions: [GitHub Discussions](https://github.com/your-org/fresh-VPS-setup/discussions)