# Agent Configuration

Configuration and cross-reference guide for AI agents working with this repository. Uses [[Obsidian-style links]] to connect related files for easy human navigation.

## Quick Reference

| Area | Entry Point | Key Files |
|------|-------------|-----------|
| **Project Overview** | [[README.md]] | Project structure, quick start, prerequisites |
| **Network Hardening** | [[scripts/network/README.md]] | UFW, SSH hardening, fail2ban |
| **Zsh Environment** | [[scripts/zsh/README.md]] | Oh My Zsh, plugins, theme, zoxide |
| **Tools Inventory** | [[scripts/tools/README.md]] | All installed tools with versions |
| **Cloudflare Tunnels** | [[scripts/tools/cloudflare/README.md]] | Quick install reference |
| **Cloudflare Deep Dive** | [[scripts/tools/cloudflare/CF-tunnels.md]] | Architecture, config, troubleshooting |
| **Tailscale VPN** | [[scripts/tools/tailscale/README.md]] | Mesh networking, exit nodes, ACLs |
| **Template Library** | [[templates/README.md]] | Available templates and usage |
| **Installer Pattern** | [[templates/tools-installer-template.md]] | Parallel fault-tolerant installation |
| **Change History** | [[CHANGELOG.md]] | Version history and migration notes |

## Agent Instructions

### When Modifying Scripts
1. **Read first** - Understand existing patterns before editing
2. **Preserve idempotency** - Scripts must be safely re-runnable
3. **Use functions** - Encapsulate logic; avoid inline code blocks
4. **Error handling** - Use `set -Eeuo pipefail`; trap errors with cleanup
5. **Logging** - Use consistent `log_info`, `log_warn`, `log_error` functions
6. **Variables** - Define at top; use `readonly` for constants

### When Updating Documentation
1. **Cross-reference** - Use `[[wiki-links]]` to connect related files
2. **Keep examples current** - Test commands before documenting
3. **Version pinning** - Document exact versions or version ranges
4. **Troubleshooting** - Add common failure modes and fixes

### File Organization Rules
- Scripts in `scripts/<category>/` with `setup.sh` as entry point
- Helper functions in `scripts/<category>/lib/` (if needed)
- Config templates in `scripts/<category>/config/`
- Documentation co-located as `README.md` in each directory
- Templates in `templates/` with `.md` extension for reference

## Cross-Reference Map

```
[[README.md]]
├── [[scripts/network/README.md]]
│   ├── UFW configuration
│   ├── SSH hardening
│   └── fail2ban setup
├── [[scripts/zsh/README.md]]
│   ├── Oh My Zsh
│   ├── Powerlevel10k
│   ├── Plugins
│   └── [[zoxide]] integration
├── [[scripts/tools/README.md]]
│   ├── Docker stack
│   ├── Kubernetes tools
│   ├── Infrastructure tools
│   └── Utility CLIs
├── [[scripts/tools/cloudflare/README.md]]
│   └── [[scripts/tools/cloudflare/CF-tunnels.md]]
├── [[scripts/tools/tailscale/README.md]]
└── [[templates/README.md]]
    └── [[templates/tools-installer-template.md]]
```

## Version Requirements

| Component | Minimum Version | Notes |
|-----------|----------------|-------|
| Ubuntu | 22.04 LTS | Or Debian 12+ |
| Bash | 5.0+ | For associative arrays |
| systemd | 249+ | For `Type=notify` |
| cloudflared | 2024.01+ | QUIC support |
| Tailscale | 1.58+ | ACL tags support |

## Common Patterns

### Parallel Installation (from [[templates/tools-installer-template.md]])
```bash
declare -A TOOLS=(["tool"]="url")
declare -A BINARIES=(["tool"]="binary")
for tool in "${!TOOLS[@]}"; do install_tool "$tool" & done
wait for all; verify each with `command -v`
```

### Systemd Service Template
```ini
[Unit]
Description=Service Name
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
ExecStart=/usr/bin/command --config /etc/path/config.yml
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

### Idempotent Package Install
```bash
install_if_missing() {
    local pkg="$1" cmd="${2:-$1}"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        apt-get update && apt-get install -y "$pkg"
    fi
}
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `TIMEOUT` | 300 | Installer timeout (seconds) |
| `NO_SHELL_MODIFY` | "" | Skip shell config modifications |
| `CLOUDFLARE_API_TOKEN` | required | For DNS automation |
| `TAILSCALE_AUTH_KEY` | required | For headless Tailscale join |

## Security Notes

- Never commit credentials (API tokens, tunnel JSONs, Tailscale keys)
- Use `chmod 600` for credential files in `/etc/`
- Rotate keys periodically via automation
- Enable Cloudflare Access policies for sensitive services

## Related Files

- [[README.md]] - Project entry point
- [[CHANGELOG.md]] - Track changes across versions
- [[scripts/network/README.md]] - Network security baseline
- [[scripts/tools/cloudflare/CF-tunnels.md]] - Tunnel architecture details