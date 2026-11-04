# Agent Instructions — Fresh VPS Setup Repository

This file guides AI agents working in this repository. It uses **Obsidian-style links** (`[[path/to/file|Display Name]]`) to cross-reference related files for easy human navigation.

## Repository Purpose

A collection of bash scripts and configurations to **harden a fresh Ubuntu VPS**, install **modern CLI tools**, configure **Zsh with plugins**, and set up **secure remote access** via Cloudflare Tunnels and Tailscale.

## File Map & Cross-References

### Root
- [[README|Project overview, quick start, security model]]
- [[AGENT|This file]]

### Network Hardening (`scripts/network/`)
- [[scripts/network/README|Network docs index]]
- [[scripts/network/secure-vps.sh|Full VPS hardening (UFW, Fail2ban, SSH, idle timeout)]]
- [[scripts/network/restrict-ssh.sh|nftables SSH guard: only loopback + tailscale0 → tcp/22]]

### System Updates (`scripts/system-update/`)
- [[scripts/system-update/auto-system-update.sh|Unattended upgrades setup]]

### CLI Tools (`scripts/tools/`)
- [[scripts/tools/README|Tools documentation index]]
- [[scripts/tools/install-sys-tools.sh|System tools installer (exa, fd, zoxide, bat, fzf, ripgrep, atuin, neofetch)]]
- [[scripts/tools/tools.sh|Placeholder]]

#### Cloudflare (`scripts/tools/cloudflare/`)
- [[scripts/tools/cloudflare/README|Cloudflare setup index]]
- [[scripts/tools/cloudflare/CF-setup.sh|cloudflared install script]]
- [[scripts/tools/cloudflare/CF-tunnels|Deep dive: per-service tunnels, systemd, DNS, troubleshooting]]

#### Tailscale (`scripts/tools/tailscale/`)
- [[scripts/tools/tailscale/README|Tailscale setup index]]
- [[scripts/tools/tailscale/tailscale-setup.sh|Tailscale install, join tag:hermes-vps, enable SSH]]

### Zsh Configuration (`scripts/zsh/`)
- [[scripts/zsh/README|Zsh docs index]]
- [[scripts/zsh/.zshrc|Full .zshrc with Zinit, Powerlevel10k, plugins, integrations]]
- [[scripts/zsh/zsh_script.sh|Quick interactive install helper]]

## Key Architectural Decisions

1. **Two-path SSH access only** (no direct IP):
   - Path 1: Cloudflare Access → cloudflared tunnel (loopback) → sshd
   - Path 2: Tailscale SSH → tailscale0 interface → sshd
   - Enforced by [[scripts/network/restrict-ssh.sh|restrict-ssh.sh]] nftables guard

2. **One tunnel per service** (Cloudflare):
   - Isolated systemd units, independent lifecycle
   - See [[scripts/tools/cloudflare/CF-tunnels|CF-tunnels.md]] for details

3. **Tagged Tailscale node** (`tag:hermes-vps`):
   - Key expiry disabled (documented exception for unattended server)
   - ACL tag ownership required in admin console

4. **Safe apply pattern** (all `--apply` scripts):
   - Snapshot known-good state
   - Schedule 5-min `at` rollback job
   - Require manual `confirm` after testing
   - Break-glass: provider console/rescue always works

## Script Conventions

- Shebang: `#!/usr/bin/env bash` or `#!/usr/bin/env bash`
- `set -euo pipefail` (or `set -Eeuo pipefail` for trap on ERR)
- Root checks: `[[ $EUID -eq 0 ]] || die "run as root (sudo)"`
- Logging: `log() { printf '[prefix] %s\n' "$*"; }`
- Error handling: `die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }`
- Idempotent where possible (delete before recreate)

## When Editing

- Update this file's cross-references if you add/move/rename files
- Keep Obsidian links working: `[[relative/path|Display Name]]`
- Update [[README|README.md]] if new scripts or workflows are added
- Document security exceptions inline (like Tailscale key expiry)

## Testing Checklist

Before confirming any `--apply` run:
1. Keep current SSH session open
2. Open second terminal → test new SSH login
3. Verify `sudo` works in second session
4. Run script's `--verify` or `status` command
5. Only then run `confirm`

## Known Gaps / Future Work

> **⚠️ Agent-Vault Setup Pending**
>
> Secret management for automated provisioning is not yet implemented:
> - **Cloudflare tunnel tokens** — Currently passed inline or stored in local files
> - **Tailscale auth keys** — Currently uses interactive `tailscale up` auth URL
> - **SSH keys / API tokens** — No centralized secrets store
>
> **Planned:** Integrate a secrets manager (1Password CLI, HashiCorp Vault, SOPS/age, or similar) to enable fully automated, non-interactive node provisioning and credential rotation.
>
> **Files to update when implemented:**
> - [[scripts/tools/cloudflare/CF-setup.sh|CF-setup.sh]] — Read tunnel token from vault
> - [[scripts/tools/tailscale/tailscale-setup.sh|tailscale-setup.sh]] — Read auth key from vault
> - [[scripts/network/secure-vps.sh|secure-vps.sh]] — Potentially read SSH keys from vault