# Cloudflare Tunnel Setup

Quick reference for installing and configuring `cloudflared` on the VPS.

## Install Script

See [[CF-setup.sh|CF-setup.sh]] for the installation commands:

```bash
# Add Cloudflare GPG key
sudo mkdir -p --mode=0755 /usr/share/keyrings
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null

# Add apt repository
echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' | sudo tee /etc/apt/sources.list.d/cloudflared.list

# Install cloudflared
sudo apt-get update && sudo apt-get install cloudflared
```

## Service Management

```bash
# Before modifying tunnels or scripts, uninstall existing service
sudo cloudflared service uninstall

# Install as systemd service (replace with your tunnel token)
sudo cloudflared service install <TUNNEL_TOKEN>
```

## Tunnel Configuration

For detailed per-service tunnel setup (one tunnel per service, isolated systemd units), see [[CF-tunnels|CF-tunnels.md]].

## DNS Routing

After creating a tunnel, route DNS to it:
```bash
cloudflared tunnel route dns <tunnel-name> <hostname>.example.com
# Creates CNAME <hostname>.example.com → <tunnel-id>.cfargotunnel.com
```

## Cloudflare Access (Zero Trust)

For SSH and HTTP services, configure **Cloudflare Access** policies in the Zero Trust dashboard:
- Add an Access Application for each hostname
- Set policies: Require MFA, specific emails/groups, short session duration
- SSH over tunnel uses: `ssh -o ProxyCommand="cloudflared access ssh --hostname ssh.example.com" user@ssh.example.com`

## Related

- [[CF-tunnels|Detailed tunnels guide]]
- [[CF-setup.sh|Install script]]
- [[../../network/README|Network hardening overview]]
- [[../../../AGENT|Agent instructions]]

---

> **Note:** Agent-vault setup for secret management (tunnel tokens, credentials) is **pending**. Currently tokens are passed inline or stored in local files. Future work: integrate a secrets manager (e.g., 1Password CLI, HashiCorp Vault, or SOPS) to avoid plaintext tokens in scripts.
