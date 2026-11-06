# Cloudflare Tools

Quick reference for Cloudflare Tunnel (`cloudflared`) installation and basic operations.

## Quick Install

```bash
# Add Cloudflare GPG key
sudo mkdir -p --mode=0755 /usr/share/keyrings
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null

# Add APT repository
echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' | sudo tee /etc/apt/sources.list.d/cloudflared.list

# Install
sudo apt-get update && sudo apt-get install cloudflared
```

## Service Management

### Before Modifying Tunnels
```bash
# Always stop the service first
sudo cloudflared service uninstall
```

### Install as System Service
```bash
# Replace with your tunnel token from Cloudflare Dashboard
sudo cloudflared service install eyJhIjoi********************9In0=
```

### Manual systemd Service (Per-Tunnel)
See [[CF-tunnels.md]] for the recommended per-service architecture.

```ini
# /etc/systemd/system/cloudflared-myapp.service
[Unit]
Description=Cloudflare Tunnel - myapp
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
ExecStart=/usr/bin/cloudflared --no-autoupdate --config /etc/cloudflared/config-myapp.yml tunnel run
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now cloudflared-myapp
```

## DNS Routing

```bash
# Route a hostname to your tunnel
cloudflared tunnel route dns <tunnel-name> <hostname>.example.com

# List routes
cloudflared tunnel route dns list
```

## Tunnel Operations

```bash
# List tunnels
cloudflared tunnel list

# Tunnel details
cloudflared tunnel info <tunnel-name>

# Validate config
cloudflared --config /etc/cloudflared/config-myapp.yml tunnel ingress validate

# View logs
sudo journalctl -u cloudflared-myapp -f

# Delete tunnel
cloudflared tunnel delete <tunnel-name>
```

## Credential Management

```bash
# Credentials are stored as JSON (one per tunnel)
# Location: /etc/cloudflared/<tunnel-id>.json
# Permissions: chmod 600, owned by root

# Copy from user config to system location
sudo cp ~/.cloudflared/<id>.json /etc/cloudflared/<id>.json
sudo chown root:root /etc/cloudflared/<id>.json
sudo chmod 600 /etc/cloudflared/<id>.json
```

## SSH Over Tunnel

### Server Side (in tunnel config)
```yaml
ingress:
  - hostname: ssh.example.com
    service: ssh://localhost:22
  - service: http_status:404
```

### Client Side
```bash
# Install cloudflared on client machine
# Then connect via:
ssh -o ProxyCommand="cloudflared access ssh --hostname ssh.example.com" user@ssh.example.com
```

## Common Commands Reference

| Task | Command |
|------|---------|
| Install cloudflared | `sudo apt-get install cloudflared` |
| Login to Cloudflare | `cloudflared tunnel login` |
| Create tunnel | `cloudflared tunnel create <name>` |
| List tunnels | `cloudflared tunnel list` |
| Show tunnel info | `cloudflared tunnel info <name>` |
| Route DNS | `cloudflared tunnel route dns <name> <host>` |
| Validate config | `cloudflared --config <path> tunnel ingress validate` |
| Run manually | `cloudflared --config <path> tunnel run` |
| Install as service | `cloudflared service install <token>` |
| Uninstall service | `cloudflared service uninstall` |
| View service logs | `sudo journalctl -u cloudflared -f` |

## Related Documentation

- [[README.md]] - Project overview
- [[AGENT.md]] - Agent cross-references
- [[CF-tunnels.md]] - Complete architecture, config, and troubleshooting guide
- [[scripts/tools/README.md]] - Tools inventory
- [[scripts/tools/tailscale/README.md]] - Tailscale VPN (alternative/complement)
- [Cloudflare Tunnels Docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)