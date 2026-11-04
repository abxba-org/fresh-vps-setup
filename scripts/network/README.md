# Network Hardening Scripts

This directory contains scripts for securing network access on a fresh Ubuntu VPS.

## Scripts

### [[secure-vps.sh|secure-vps.sh]] — Full VPS Hardening
**Interactive, idempotent hardening script** with three modes:
- `--check` (default): Read-only inventory of SSH, firewall, Fail2ban, idle timeout, updates
- `--verify`: Post-change verification without modifications
- `--apply`: Interactive configuration with confirmations and rollback safety

**What it configures:**
- **UFW**: Default deny incoming, allow outgoing; allow SSH + custom ports; IPv6 enabled
- **Fail2ban**: SSH jail (5 failures / 10 min, 1-hour ban) via systemd backend
- **SSH Hardening** (`--harden-ssh`): Disables root login, password auth, keyboard-interactive auth via drop-in `/etc/ssh/sshd_config.d/00-vps-hardening.conf`
- **Idle Timeout**: 15-minute TMOUT for new interactive Bash shells (`/etc/profile.d/zz-vps-idle-timeout.sh`)
- **Port Manifest**: Saves allowed ports to `/var/lib/vps-hardening/allowed_ports` for verification

**Safety features:**
- Snapshot + 5-minute `at` rollback job on every `--apply`
- Requires `CONSOLE-READY` confirmation (provider console/rescue access)
- Requires testing second SSH login before confirming
- Preserves `SSH_CONNECTION` through sudo for Match-rule validation

```bash
# Check current state
sudo ./secure-vps.sh --check

# Verify after manual changes
sudo ./secure-vps.sh --verify

# Full interactive apply (with SSH hardening & Fail2ban)
sudo ./secure-vps.sh --apply --harden-ssh

# Apply without Fail2ban
sudo ./secure-vps.sh --apply --no-fail2ban
```

---

### [[restrict-ssh.sh|restrict-ssh.sh]] — nftables SSH Access Guard
**Phase 0.2/0.3 enforcement**: Restricts inbound tcp/22 to exactly two identity-gated paths:
1. **Loopback** — Cloudflare Access tunnel egress (`cloudflared` → `ssh://localhost:22`)
2. **tailscale0** — Tailscale SSH / tailnet sshd

All other sources: rate-limited log (`ssh-guard-drop:`) + drop.

**Usage:**
```bash
# Apply guard (schedules 5-min auto-rollback)
sudo ./restrict-ssh.sh apply

# Confirm after testing both access paths
sudo ./restrict-ssh.sh confirm

# Manual rollback
sudo ./restrict-ssh.sh rollback

# Status: show rules + recent drops
sudo ./restrict-ssh.sh status
```

**Safety:**
- Snapshots full ruleset (with `flush ruleset` for true replace)
- Validates snapshot is nft-loadable (handles UFW/iptables-nft compat)
- Shares rollback slot with `setup-nftables.sh` (one failsafe at a time)
- Break-glass: OVH KVM console / rescue mode unaffected

**Prerequisites:**
- `nftables` installed
- `at` + `atd` running
- Run **from** a Cloudflare Access or Tailscale SSH session (direct IP sessions will be terminated)

---

## Security Model

```
┌─────────────────────────────────────────────────────────────┐
│                    INBOUND TCP/22                           │
├─────────────────────────────────────────────────────────────┤
│  ✅ ALLOW: iifname "lo"        → Cloudflare tunnel path     │
│  ✅ ALLOW: iifname "tailscale0" → Tailscale SSH path        │
│  ❌ DROP:  everything else (logged, rate-limited 5/sec)     │
└─────────────────────────────────────────────────────────────┘
```

**Direct SSH by public IP is denied.** This is the enforced access boundary.

## Related Documentation

- [[../README|Main project README]]
- [[../tools/cloudflare/CF-tunnels|Cloudflare Tunnels deep dive]]
- [[../tools/tailscale/README|Tailscale setup]]
- [[../AGENT|Agent instructions]]
