# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project structure with modular scripts
- Network hardening module (UFW, SSH, fail2ban)
- Zsh environment setup with Oh My Zsh and plugins
- Tools installer with parallel execution pattern
- Cloudflare Tunnels module with per-service isolation
- Tailscale mesh networking module
- Installer template for AI-assisted development
- `scripts/tools/parallel-tools-installer.sh` — parallel, fault-tolerant installer (18 tools; tested end-to-end on Ubuntu 24.04, 18/18 verified)
- `autonomous-install/` — two-phase provisioning orchestrator (`auto-install.sh`: Phase 1 autonomous, Phase 2 interactive)

### Changed
- `neofetch` replaced by `fastfetch` (actively maintained fork)
- `exa` dropped — no apt package on Ubuntu 24.04+, deprecated upstream; `eza` (GitHub release) covers it
- `install-sys-tools.sh`'s tool set fully absorbed by `parallel-tools-installer.sh`, including Ubuntu binary-name symlinks (`fdfind`→`fd`, `batcat`→`bat`)
- APT installs serialized via `flock` (parallel apt/dpkg runs are not lock-safe); one-time `apt-get update` before parallel phase

### Removed
- `scripts/tools/install-sys-tools.sh` — superseded by `scripts/tools/parallel-tools-installer.sh`
- `scripts/tools/tools.sh` — empty placeholder file

### Fixed
- `parallel-tools-installer.sh`: `set -e` abort from `((ok++))` during verification; `set -u` unbound-variable abort in `local` declaration; GitHub-release asset matching now API-driven (eza/btop/duf/dust); `install_script` runs per-tool shell (`sh` for starship/atuin, `bash` for fnm) and no longer starves `sh -s` stdin; user-level installs (atuin, fnm) symlinked into `/usr/local/bin`

### Deprecated
- N/A

### Security
- N/A

---

## [1.0.0] - 2026-01-15

### Added
- **Network Module**
  - UFW default-deny firewall with SSH/HTTP/HTTPS allow rules
  - SSH hardening: key-only auth, port change, MaxAuthTries, ClientAliveInterval
  - fail2ban with sshd, nginx, and custom filters
  - Unattended-upgrades for security patches

- **Zsh Module**
  - Oh My Zsh installation with unattended mode
  - Powerlevel10k theme with instant prompt
  - Plugins: zsh-autosuggestions, zsh-syntax-highlighting, zsh-completions, fzf, zoxide
  - Custom aliases: `ll`, `la`, `cat=bat`, `grep=rg`, `find=fd`, `top=btop`
  - Directory jump with `z` (zoxide)

- **Tools Module**
  - Docker Engine + Compose v2 + Buildx
  - Kubernetes: kubectl, helm, kind, k9s, kubectx, kubens
  - Infrastructure: Terraform, Packer, Ansible
  - Cloud CLIs: AWS CLI v2, Google Cloud CLI, Azure CLI
  - Utilities: jq, yq, bat, eza, ripgrep, fd, htop, btop, ncdu, dust
  - Version managers: asdf (with nodejs, python, golang, rust plugins), fnm, pyenv

- **Cloudflare Module**
  - cloudflared installation from Cloudflare APT repo
  - Per-service tunnel architecture (one tunnel per service)
  - systemd service templates with `Type=notify`
  - DNS automation via Cloudflare API
  - SSH-over-Tunnel client configuration
  - Credential management with `chmod 600` in `/etc/cloudflared/`

- **Tailscale Module**
  - Tailscale installation from official APT repo
  - Auth key-based headless join
  - Exit node configuration
  - Subnet router for LAN access
  - ACL tag assignment

- **Templates**
  - Parallel tools installer template with:
    - Associative array configuration
    - Background process tracking
    - Failure detection and aggregation
    - Post-install verification with `command -v`
    - Configurable timeout and shell modification flags

### Changed
- N/A

### Deprecated
- N/A

### Removed
- N/A

### Fixed
- N/A

### Security
- All credential files set to `chmod 600` root-owned
- No inbound firewall ports required for Cloudflare Tunnels
- Tailscale ACL tags for device classification
- SSH key-only authentication enforced

---

## Release Process

1. Update version in `VERSION` file (or package.json equivalent)
2. Update this CHANGELOG.md with release notes
3. Create git tag: `git tag -a v1.0.0 -m "Release v1.0.0"`
4. Push tag: `git push origin v1.0.0`
5. GitHub Actions builds and publishes artifacts

## Versioning Notes

- **Major** (X.0.0): Breaking changes to script interfaces, config formats, or directory structure
- **Minor** (X.Y.0): New modules, tools, or features; backward compatible
- **Patch** (X.Y.Z): Bug fixes, documentation updates, dependency version bumps

## Migration Guides

### From Pre-1.0 (if applicable)
No prior releases. Fresh installation only.

---

## Links

- [[README.md]] - Project overview
- [[AGENT.md]] - Agent configuration and cross-references
- [[scripts/network/README.md]] - Network module details
- [[scripts/zsh/README.md]] - Zsh module details
- [[scripts/tools/README.md]] - Tools module details
- [[scripts/tools/cloudflare/CF-tunnels.md]] - Cloudflare Tunnels architecture