# Tailscale Setup

Installs Tailscale, joins the tailnet as a tagged server node, and enables Tailscale SSH.

## Install & Join

Run the setup script (requires `sudo`):
```bash
sudo ./scripts/tools/tailscale/tailscale-setup.sh
```

This will:
1. Install Tailscale from the official repo
2. Join the tailnet with tag `tag:hermes-vps` (configurable via `TAG` env var)
3. Enable Tailscale SSH (`--ssh`)
4. Disable MagicDNS (`--accept-dns=false`) to avoid resolver conflicts with cloud-init pinned DNS

## Post-Install (Manual, Admin Console)

After the script prints an auth URL, complete these steps in the **Tailscale Admin Console**:

1. **Approve the device** — Authorize the node if device approval is enabled
2. **Disable key expiry** — Go to the machine → "Disable key expiry"
   - *Documented exception:* Unattended servers need persistent connectivity
   - *Risk:* Compromised node identity lives longer
   - *Mitigations:* Tag ownership (`tagOwners`), restricted ACL grants, MFA on operators, OVH rescue path, monitoring, credential rotation
3. **Verify connectivity:**
   ```bash
   tailscale ping <other-node>
   # Test Tailscale SSH from your laptop
   ssh user@hermes-vps  # via Tailscale SSH
   ```
4. **Configure ACLs** — Restrict SSH to operator devices only in `tailnet-policy`

## ACL Tag Requirement

The ACL policy **must** own the tag, otherwise `--advertise-tags` is rejected:
```json
"tagOwners": {
  "tag:hermes-vps": ["autogroup:admin"]
}
```

## Files

- [[tailscale-setup.sh|tailscale-setup.sh]] — Install & join script

## Related

- [[../../network/restrict-ssh.sh|restrict-ssh.sh]] — nftables guard allows tcp/22 only via `tailscale0` interface
- [[../../network/README|Network hardening overview]]
- [[../../../AGENT|Agent instructions]]

---

> **Note:** Agent-vault setup for secret management (auth keys, API tokens) is **pending**. Currently `tailscale up` uses interactive auth URL. Future work: integrate with a secrets manager for automated, non-interactive node provisioning and key rotation.
