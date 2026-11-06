# Tailscale Setup

Configures Tailscale for secure mesh networking, remote access, and subnet routing.

## Quick Start

```bash
# Run as root or with sudo
sudo ./setup.sh

# Or with auth key for headless setup
TAILSCALE_AUTH_KEY=tskey-auth-... sudo -E ./setup.sh
```

## What Gets Configured

| Feature | Description |
|---------|-------------|
| **Tailscale Installation** | From official APT repository |
| **Auth Key Join** | Headless join via `TAILSCALE_AUTH_KEY` |
| **Exit Node** | Optional: route all traffic through this node |
| **Subnet Router** | Optional: advertise local LAN subnets |
| **ACL Tags** | Optional: tag device for ACL policies |
| **Auto-Updates** | Daily update timer with service restart |
| **SSH Integration** | `tailscale ssh` for key-less SSH access |

## Prerequisites

- Tailscale account (free for personal use)
- Auth key from [Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys)
- For subnet routing: network interface and CIDR to advertise

## Configuration

### Environment Variables

```bash
# Required for headless setup
export TAILSCALE_AUTH_KEY="tskey-auth-..."

# Optional: Advertise as exit node
export TAILSCALE_EXIT_NODE=1

# Optional: Subnet routes to advertise (space-separated)
export TAILSCALE_SUBNET_ROUTES="10.0.0.0/24 192.168.1.0/24"

# Optional: ACL tags (comma-separated)
export TAILSCALE_TAGS="tag:server,tag:database"

# Optional: Hostname override
export TAILSCALE_HOSTNAME="my-vps"

# Optional: Accept DNS from tailnet
export TAILSCALE_ACCEPT_DNS=1

# Optional: Accept routes from tailnet
export TAILSCALE_ACCEPT_ROUTES=1
```

### Running with Custom Values

```bash
TAILSCALE_AUTH_KEY=tskey-auth-... \
TAILSCALE_EXIT_NODE=1 \
TAILSCALE_SUBNET_ROUTES="10.0.0.0/8" \
TAILSCALE_TAGS="tag:server" \
sudo -E ./setup.sh
```

## Post-Install Setup

### 1. Approve Routes (Admin Console)
After subnet router starts, approve in admin console:
```
Machines → [device] → ... → Edit route settings → Approve
```

### 2. Enable Exit Node (Admin Console)
```
Machines → [device] → ... → Edit exit node settings → Enable
```

### 3. Configure ACLs (Admin Console)
```
Access controls → ACLs → Add rules using tags
Example: {"action": "accept", "src": ["tag:admin"], "dst": ["tag:server:*"]}
```

## File Structure

```
scripts/tools/tailscale/
├── setup.sh              # Main entry point
├── lib/
│   ├── install.sh        # APT repo + package install
│   ├── configure.sh      # tailscale up with options
│   ├── exit-node.sh      # Exit node configuration
│   ├── subnet-router.sh  # Subnet router setup
│   ├── acl-tags.sh       # ACL tag assignment
│   └── auto-update.sh    # Daily update timer
├── config/
│   └── tailscale-updater.service    # systemd service for updates
│   └── tailscale-updater.timer      # Daily timer
└── README.md             # This file
```

## Verification

```bash
# Check status
tailscale status

# Verify connectivity
tailscale ping <other-device>

# Check exit node
tailscale exit-node status

# Check subnet routes
tailscale subnet-routes

# View logs
sudo journalctl -u tailscaled -f
```

Expected `tailscale status` output:
```
100.x.y.z    my-vps        linux   active; direct; exit-node; subnet-router
100.a.b.c    laptop        macos   active; direct
100.d.e.f    phone         ios     active; relay
```

## Common Operations

### Add/Remove Subnet Routes
```bash
# Add
sudo tailscale set --advertise-routes=10.10.0.0/16

# Remove
sudo tailscale set --advertise-routes=
```

### Toggle Exit Node
```bash
# Enable
sudo tailscale set --advertise-exit-node

# Disable
sudo tailscale set --advertise-exit-node=false
```

### Update ACL Tags
```bash
sudo tailscale set --advertise-tags=tag:server,tag:database
```

### Force Update
```bash
sudo tailscale update
```

### Debug Connection Issues
```bash
# Check daemon status
systemctl status tailscaled

# Test connectivity to coordination server
curl -I https://controlplane.tailscale.com

# Check derp map
tailscale netcheck

# View detailed logs
sudo journalctl -u tailscaled -n 200 --no-pager
```

## Troubleshooting

### Stuck at "Starting..."
```bash
# Check if another instance is running
sudo systemctl stop tailscaled
sudo tailscaled --cleanup
sudo systemctl start tailscaled
```

### Auth Key Expired/Invalid
```bash
# Generate new key in admin console
# Re-run setup with new key
TAILSCALE_AUTH_KEY=new-key sudo -E ./setup.sh
```

### Subnet Routes Not Working
1. Verify routes approved in admin console
2. Check IP forwarding enabled:
   ```bash
   sysctl net.ipv4.ip_forward
   # Should be 1
   ```
3. Check firewall allows forwarding:
   ```bash
   sudo ufw status
   # Ensure FORWARD chain allows
   ```

### Exit Node Not Routing
1. Verify exit node approved in admin console
2. Client must select exit node:
   ```bash
   tailscale set --exit-node=my-vps
   ```
3. Check client DNS settings

### SSH Not Working
```bash
# Enable SSH on device
sudo tailscale set --ssh

# Connect from client
tailscale ssh user@my-vps
```

## Security Notes

- Auth keys are single-use (ephemeral) or reusable (pre-auth)
- Prefer ephemeral keys for automation
- ACL tags enforce zero-trust network segmentation
- Exit nodes see all traffic - only enable for trusted devices
- Subnet routers expose LAN - approve routes carefully
- Keys never stored in scripts - passed via environment only

## Related Documentation

- [[README.md]] - Project overview
- [[AGENT.md]] - Agent cross-references
- [[scripts/tools/README.md]] - Tools inventory
- [[scripts/tools/cloudflare/README.md]] - Cloudflare Tunnels (alternative for service exposure)
- [[scripts/network/README.md]] - Network firewall (coordinate with Tailscale)
- [Tailscale Docs](https://tailscale.com/kb/)
- [ACL Guide](https://tailscale.com/kb/1018/acls/)
- [Subnet Router Guide](https://tailscale.com/kb/1019/subnets/)
- [Exit Node Guide](https://tailscale.com/kb/1103/exit-nodes/)