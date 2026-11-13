# Autonomous Install

Two-phase automated VPS provisioning orchestrator. Runs from the `autonomous-install/` directory.

## Quick Start

```bash
cd autonomous-install

# Phase 1: Fully automatic (unattended-upgrades, terminal tools, cloudflared)
sudo ./auto-install.sh --phase=1

# Phase 2: Interactive (UFW, SSH hardening, nftables guard, Tailscale, Zsh)
sudo ./auto-install.sh --phase=2
```

Or run both phases with a prompt between:
```bash
sudo ./auto-install.sh
```

## Usage

| Command | Description |
|---------|-------------|
| `sudo ./auto-install.sh` | Run Phase 1, then prompt for Phase 2 |
| `sudo ./auto-install.sh --phase=1` | Run only Phase 1 (autonomous) |
| `sudo ./auto-install.sh --phase=2` | Run only Phase 2 (interactive) |
| `sudo ./auto-install.sh --skip-interactive` | Same as `--phase=1` |
| `./auto-install.sh -h` | Show help |

## Phase 1 — Autonomous (Non-Interactive)

Runs without any prompts:

| Step | Script | Description |
|------|--------|-------------|
| 1 | `../scripts/system-update/auto-system-update.sh` | Configures `unattended-upgrades` (preseeded via debconf) |
| 2 | `../scripts/tools/cloudflare/CF-setup.sh` | Adds Cloudflare APT repo, installs `cloudflared` |
| 3 | `../scripts/tools/parallel-tools-installer.sh` | Installs 18 terminal tools in parallel: fd, zoxide, bat, fzf, ripgrep, curl, jq, htop, ncdu, fastfetch, cloudflared, eza, btop, duf, dust, atuin, starship, fnm |

**Prerequisites:** Run as root (`sudo`). Internet access required.

**Post-Phase 1 manual steps:**
- `cloudflared tunnel login` — authenticate with Cloudflare
- Create tunnels via Cloudflare dashboard or CLI

## Phase 2 — Interactive (Requires Confirmation)

Requires manual input at each step. **Keep provider console/rescue access ready.**

| Step | Script | Description | Key Prompts |
|------|--------|-------------|-------------|
| 4 | `../scripts/network/secure-vps.sh --apply --harden-ssh` | UFW firewall, SSH hardening, fail2ban, idle timeout | `CONSOLE-READY`, SSH port, `APPLY-FIREWALL`, test 2nd SSH, `DISABLE-SSH-PASSWORDS` |
| 5 | `../scripts/network/restrict-ssh.sh apply` | nftables SSH guard (loopback + Tailscale only) | Must be on CF Access/Tailscale SSH; 5-min auto-rollback |
| 6 | `../scripts/tools/tailscale/tailscale-setup.sh` | Join Tailscale tailnet with tag, enable Tailscale SSH | Open auth URL, approve in admin console, disable key expiry |
| 7 | Zsh setup | Manual instructions for Oh My Zsh + plugins | Follow printed steps |

### Critical Requirements for Phase 2

**Step 5 (restrict-ssh.sh):**
- You **MUST** be connected via **Cloudflare Access SSH** or **Tailscale SSH**
- Direct-IP SSH sessions **WILL BE TERMINATED**
- After `apply`, you have **5 minutes** to test and run `sudo ./restrict-ssh.sh confirm`
- If not confirmed, auto-rollback restores previous rules

**Step 4 (secure-vps.sh):**
- Keep a **second SSH session open** to test after firewall changes
- Have **provider console/rescue access** ready in case of lockout

**Step 6 (tailscale-setup.sh):**
- ACL tag `tag:hermes-vps` must exist in Tailscale admin console policy
- After join: approve node in admin console → disable key expiry

## Scripts Referenced

All scripts are in the parent directory (`../scripts/`):

```
../scripts/
├── network/
│   ├── secure-vps.sh          # UFW, SSH hardening, fail2ban
│   └── restrict-ssh.sh        # nftables SSH guard (apply/confirm/rollback)
├── tools/
│   ├── parallel-tools-installer.sh   # 18 tools in parallel (replaces the removed install-sys-tools.sh)
│   ├── cloudflare/
│   │   └── CF-setup.sh        # Cloudflare APT repo + cloudflared
│   └── tailscale/
│       └── tailscale-setup.sh # Tailscale join with tag
└── system-update/
    └── auto-system-update.sh  # unattended-upgrades
```

## Related Tools

| Tool | Location | Description |
|------|----------|-------------|
| Parallel Tools Installer | `../scripts/tools/parallel-tools-installer.sh` | Installs 18 tools in parallel (template-based, tested 18/18 on Ubuntu 24.04) |
| Zsh Setup Guide | `../scripts/zsh/README.md` | Full Zsh/Oh My Zsh/Powerlevel10k configuration |
| Cloudflare Tunnels | `../scripts/tools/cloudflare/CF-tunnels.md` | Deep-dive on tunnel architecture |

## Safety Notes

- **Test in a disposable VPS first** — Phase 2 modifies SSH/firewall
- **Phase 2 step 5** has a 5-minute automatic rollback via `at` job
- **Backups** created by `secure-vps.sh` at `/root/vps-hardening-backups/`
- **Rollback** for restrict-ssh.sh: `sudo ./restrict-ssh.sh rollback`

## License

MIT — see root [LICENSE](../LICENSE).