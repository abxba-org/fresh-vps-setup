# Hosting Public Services Securely with Cloudflare Tunnels

A guide to exposing self-hosted services (web apps, SSH, etc.) to the internet through Cloudflare Tunnels — without opening firewall ports. Each service runs behind its own tunnel and its own systemd service, so they're fully isolated from each other.

> This guide uses placeholders like `<service>`, `<tunnel-id>`, and `example.com`. Replace them with your own values.

## How It Works

```
Internet ──> Cloudflare Edge ──(outbound QUIC tunnel)──> cloudflared (your server) ──> local service
                                                              │
                        ┌─────────────────────────────────────┤
                        │                                     │
              cloudflared.service                 cloudflared-ssh.service
              (tunnel A)                          (tunnel B)
              app.example.com → localhost:3000    ssh.example.com → ssh://localhost:22
```

Key points:

- **No open inbound ports.** cloudflared makes *outbound* connections to Cloudflare's edge, so the server can sit behind a strict firewall.
- **One tunnel per service.** If one tunnel dies, the others keep working.
- **One systemd unit per tunnel.** Independent restart, logging, and lifecycle.

## File Layout on the Server

| File | Purpose |
|------|---------|
| `/etc/cloudflared/config-<service>.yml` | Per-tunnel config: tunnel ID, credentials path, ingress rules |
| `/etc/cloudflared/<tunnel-id>.json` | Tunnel credentials (one JSON per tunnel, `chmod 600`, root-owned) |
| `/etc/systemd/system/cloudflared-<service>.service` | Per-tunnel systemd unit |
| `~/.cloudflared/cert.pem` | Account-level certificate from `cloudflared tunnel login` (only needed for management commands) |

## Config File Anatomy

`/etc/cloudflared/config-ssh.yml` as an example:

```yaml
tunnel: <tunnel-id>
credentials-file: /etc/cloudflared/<tunnel-id>.json

ingress:
  - hostname: ssh.example.com
    service: ssh://localhost:22
  - service: http_status:404   # fallback: everything else gets a 404
```

- `tunnel` — the tunnel UUID from your Cloudflare account
- `credentials-file` — the matching JSON (must match the tunnel ID)
- `ingress` — rules evaluated **top to bottom**; first match wins. Always end with a catch-all (`http_status:404` or `http_status:503`)

Common `service` targets:

| Target | Meaning |
|--------|---------|
| `http://localhost:3000` | Any local HTTP service |
| `https://localhost:8443` | Local HTTPS (add `originRequest: noTLSVerify: true` for self-signed certs) |
| `ssh://localhost:22` | SSH over the tunnel |
| `http_status:404` | Catch-all response |

## Setup Steps (Reproduction Guide)

### 1. Install cloudflared

Install the Cloudflare-provided package for your OS (`.deb` for Debian/Ubuntu, per [Cloudflare's docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/)).

### 2. Authenticate and create a tunnel per service

```bash
cloudflared tunnel login          # opens a browser to authorize your Cloudflare account
cloudflared tunnel create <service>   # prints the new tunnel ID and writes ~/.cloudflared/<id>.json
```

### 3. Put credentials where the root service can read them

```bash
sudo cp ~/.cloudflared/<id>.json /etc/cloudflared/<id>.json
sudo chown root:root /etc/cloudflared/<id>.json
sudo chmod 600 /etc/cloudflared/<id>.json
```

### 4. Write the tunnel config

Create `/etc/cloudflared/config-<service>.yml` (anatomy above). Then point DNS at the tunnel:

```bash
cloudflared tunnel route dns <service> <service>.example.com
# creates a CNAME <service>.example.com → <tunnel-id>.cfargotunnel.com
```

### 5. Create the systemd service

`/etc/systemd/system/cloudflared-<service>.service`:

```ini
[Unit]
Description=Cloudflare Tunnel client - <service>
After=network-online.target
Wants=network-online.target

[Service]
TimeoutStartSec=15
Type=notify
ExecStart=/usr/bin/cloudflared --no-autoupdate --config /etc/cloudflared/config-<service>.yml tunnel run
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

### 6. Enable and start

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now cloudflared-<service>
sudo journalctl -u cloudflared-<service> -f     # wait for "Registered tunnel connection" ×4
```

## Adding More Services (Checklist)

For each new service (e.g. a web app on port 8080):

1. **Make sure the service listens locally** and answers: `curl localhost:<port>`
2. **Create a tunnel:**
   ```bash
   cloudflared tunnel login                 # skip if cert.pem already exists
   cloudflared tunnel create <service>
   ```
3. **Copy credentials to /etc** (step 3 above).
4. **Write `/etc/cloudflared/config-<service>.yml`:**
   ```yaml
   tunnel: <id>
   credentials-file: /etc/cloudflared/<id>.json

   ingress:
     - hostname: <service>.example.com
       service: http://localhost:8080
     - service: http_status:404
   ```
5. **Route DNS:**
   ```bash
   cloudflared tunnel route dns <service> <service>.example.com
   ```
6. **Create `/etc/systemd/system/cloudflared-<service>.service`** — copy the template above, change the `Description` and `--config` path.
7. **Start it:**
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable --now cloudflared-<service>
   sudo journalctl -u cloudflared-<service> -f   # expect 4× "Registered tunnel connection"
   ```
8. **Verify:** `cloudflared tunnel info <service>` should show active connectors.

> **Alternative:** one tunnel can host many hostnames — add multiple `hostname:` rules to a single config's `ingress` list. The separate-tunnel-per-service approach is preferred for isolation (each service can be stopped/restarted independently and shows separately in the Cloudflare Zero Trust dashboard).

## SSH Client Access

To SSH into the server through the tunnel, the **client** machine needs cloudflared too:

```bash
ssh -o ProxyCommand="cloudflared access ssh --hostname ssh.example.com" user@ssh.example.com
```

## Troubleshooting

```bash
# Is the service running?
systemctl status cloudflared cloudflared-ssh

# What do the logs say? Look for "Registered tunnel connection"
sudo journalctl -u cloudflared-<service> -n 100 --no-pager

# Does the tunnel have connectors? (0 connectors = down)
cloudflared tunnel info <service>

# Validate a config before deploying it
cloudflared --config /etc/cloudflared/config-<service>.yml tunnel ingress validate

# Is the local service itself up?
curl -I localhost:<port>

# Does DNS point at Cloudflare? (should resolve to Cloudflare edge IPs)
dig +short <service>.example.com
```

Common failure modes:

| Symptom | Cause |
|---------|-------|
| Service fails instantly | Config path wrong in `ExecStart`, or credentials file missing/unreadable |
| Tunnel runs but 0 connectors | No network egress (UDP/QUIC blocked), or credentials don't match the tunnel ID |
| Domain gives DNS error | No CNAME record — run `cloudflared tunnel route dns` |
| Domain gives Cloudflare 404 | Tunnel is up but no ingress rule matches that hostname |
| Worked before, broke after reboot | Service not `enabled` — run `sudo systemctl enable cloudflared-<service>` |

## Security Notes

- Never commit tunnel credential JSON files or `cert.pem` to git — keep them in `/etc/cloudflared/` with `chmod 600`.
- Tunnel UUIDs aren't secrets on their own (they're embedded in public CNAME records), but credentials JSONs definitely are — anyone with that file can impersonate your tunnel.
- Add Cloudflare Access policies (Zero Trust dashboard) in front of sensitive services like SSH for an extra auth layer.
- Each tunnel's credentials should be readable only by the user running the tunnel service (root in this setup).

## Auto-Updates

If you use a daily update timer, remember it typically restarts only the main tunnel service after an update — per-tunnel services keep running the old binary until manually restarted. Either add them to the update logic or restart them manually after updates.
