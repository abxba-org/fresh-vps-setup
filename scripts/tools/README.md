# Tools Setup

Installs and configures essential development, infrastructure, and cloud tools.

## Quick Start

```bash
# Run as root or with sudo (for system packages)
sudo ./setup.sh

# Verify installations
./verify.sh
```

## Tool Inventory

### Container & Orchestration

| Tool | Version Source | Install Method | Verify Command |
|------|----------------|----------------|----------------|
| Docker Engine | Docker APT repo | `apt` | `docker --version` |
| Docker Compose v2 | Docker APT repo | `apt` (plugin) | `docker compose version` |
| Buildx | Docker APT repo | `apt` (plugin) | `docker buildx version` |
| containerd | Docker APT repo | `apt` | `ctr --version` |
| kubectl | Kubernetes APT repo | `apt` | `kubectl version --client` |
| helm | Helm APT repo | `apt` | `helm version` |
| kind | GitHub releases | Binary | `kind --version` |
| k9s | GitHub releases | Binary | `k9s version` |
| kubectx/kubens | GitHub releases | Binary | `kubectx --help` |

### Infrastructure as Code

| Tool | Version Source | Install Method | Verify Command |
|------|----------------|----------------|----------------|
| Terraform | HashiCorp APT repo | `apt` | `terraform version` |
| Packer | HashiCorp APT repo | `apt` | `packer version` |
| Ansible | Ubuntu universe | `apt` | `ansible --version` |

### Cloud CLIs

| Tool | Version Source | Install Method | Verify Command |
|------|----------------|----------------|----------------|
| AWS CLI v2 | AWS official | Binary installer | `aws --version` |
| Google Cloud CLI | Google APT repo | `apt` | `gcloud --version` |
| Azure CLI | Microsoft APT repo | `apt` | `az --version` |

### Utilities

| Tool | Version Source | Install Method | Verify Command |
|------|----------------|----------------|----------------|
| jq | Ubuntu main | `apt` | `jq --version` |
| yq (v4) | GitHub releases | Binary | `yq --version` |
| bat | GitHub releases | Binary | `bat --version` |
| eza | GitHub releases | Binary | `eza --version` |
| ripgrep (rg) | Ubuntu main | `apt` | `rg --version` |
| fd | Ubuntu main | `apt` | `fd --version` |
| htop | Ubuntu main | `apt` | `htop --version` |
| btop | GitHub releases | Binary | `btop --version` |
| ncdu | Ubuntu main | `apt` | `ncdu --version` |
| dust | GitHub releases | Binary | `dust --version` |
| duf | GitHub releases | Binary | `duf --version` |
| fzf | GitHub releases | Binary | `fzf --version` |
| zoxide | GitHub releases | Binary | `zoxide --version` |

### Version Managers

| Tool | Version Source | Install Method | Verify Command |
|------|----------------|----------------|----------------|
| asdf | GitHub releases | Binary + shell | `asdf version` |
| fnm | GitHub releases | Binary | `fnm --version` |
| pyenv | GitHub releases | Binary + shell | `pyenv --version` |

#### asdf Plugins Installed
- nodejs (latest LTS)
- python (latest 3.x)
- golang (latest)
- rust (stable)

## Installation Architecture

### Parallel Installation Pattern

Based on [[templates/tools-installer-template.md]], tools are installed in parallel with:
- Background process tracking
- Failure detection and aggregation
- Post-install verification
- Configurable timeout (default 300s)

### Idempotency

All installations are idempotent:
- Package managers: `apt` only installs if not present
- Binary installs: Checks version before downloading
- Version managers: Only installs if not already managed

## Configuration

### Environment Variables

```bash
# Installation timeout (seconds)
export TIMEOUT=300

# Skip shell config modifications for specific tools
export NO_SHELL_MODIFY="asdf fnm pyenv"

# Skip entire categories
export SKIP_CONTAINER=1
export SKIP_K8S=1
export SKIP_IAC=1
export SKIP_CLOUD_CLI=1
export SKIP_UTILS=1
export SKIP_VERSION_MGR=1

# Custom versions (pin specific versions)
export TERRAFORM_VERSION=1.8.5
export KUBECTL_VERSION=1.29.0
export HELM_VERSION=3.14.0
```

### Running with Custom Values

```bash
# Skip Kubernetes tools, pin Terraform
SKIP_K8S=1 TERRAFORM_VERSION=1.8.5 sudo -E ./setup.sh

# Minimal install: only container tools
SKIP_K8S=1 SKIP_IAC=1 SKIP_CLOUD_CLI=1 SKIP_UTILS=1 SKIP_VERSION_MGR=1 sudo -E ./setup.sh
```

## File Structure

```
scripts/tools/
├── setup.sh              # Main entry point (parallel orchestrator)
├── verify.sh             # Verification script
├── lib/
│   ├── container.sh      # Docker, containerd, buildx, compose
│   ├── kubernetes.sh     # kubectl, helm, kind, k9s, kubectx
│   ├── iac.sh            # Terraform, Packer, Ansible
│   ├── cloud-cli.sh      # AWS, GCP, Azure CLIs
│   ├── utils.sh          # jq, yq, bat, eza, rg, fd, htop, btop, etc.
│   ├── version-mgr.sh    # asdf, fnm, pyenv + plugins
│   └── common.sh         # Shared helpers (logging, version checks)
├── config/
│   ├── docker-daemon.json      # Docker daemon config
│   ├── containerd-config.toml  # containerd config
│   └── asdf-plugins.txt        # asdf plugin list
└── README.md             # This file
```

## Verification

Run the verification script:

```bash
./verify.sh
```

Output example:
```
=== Container Tools ===
[OK]   docker: Docker version 25.0.3
[OK]   docker compose: Docker Compose version v2.24.5
[OK]   buildx: docker buildx version 0.13.1
[OK]   kubectl: Client Version: v1.29.0
[OK]   helm: version.BuildInfo{Version:"v3.14.0",...}
[OK]   kind: kind v0.23.0
[OK]   k9s: Version: 0.32.4
[OK]   kubectx: 0.9.5

=== Infrastructure ===
[OK]   terraform: Terraform v1.8.5
[OK]   packer: Packer v1.10.3
[OK]   ansible: ansible [core 2.16.3]

=== Cloud CLIs ===
[OK]   aws: aws-cli/2.15.3
[OK]   gcloud: Google Cloud SDK 470.0.0
[OK]   az: azure-cli 2.58.0

=== Utilities ===
[OK]   jq: jq-1.7.1
[OK]   yq: yq v4.43.1
[OK]   bat: bat 0.24.0
[OK]   eza: eza 0.18.10
[OK]   rg: ripgrep 14.1.0
[OK]   fd: fd 8.7.0
[OK]   htop: htop 3.3.0
[OK]   btop: btop 1.3.2
[OK]   ncdu: ncdu 2.3
[OK]   dust: dust 1.1.0
[OK]   duf: duf 0.8.1
[OK]   fzf: 0.54.3
[OK]   zoxide: zoxide 0.9.4

=== Version Managers ===
[OK]   asdf: v0.14.0
[OK]   fnm: 1.35.1
[OK]   pyenv: 2.3.33
[OK]   asdf plugins: nodejs, python, golang, rust

Verified 38/38 tools.
```

## Troubleshooting

### Docker permission denied
```bash
# Add user to docker group (run as root)
usermod -aG docker $USER
# Log out and back in
```

### kubectl version mismatch
```bash
# Install specific version
curl -LO "https://dl.k8s.io/release/v1.29.0/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

### asdf plugins not loading
```bash
# Add to shell config (~/.zshrc or ~/.bashrc)
. "$HOME/.asdf/asdf.sh"
. "$HOME/.asdf/completions/asdf.bash"
exec zsh
```

### Binary not in PATH after install
```bash
# Verify install location
ls -la ~/.local/bin/
# Add to PATH if missing
export PATH="$HOME/.local/bin:$PATH"
```

## Related Documentation

- [[README.md]] - Project overview
- [[AGENT.md]] - Agent cross-references
- [[scripts/network/README.md]] - Network setup (run first)
- [[scripts/zsh/README.md]] - Shell setup (run before for version managers)
- [[templates/tools-installer-template.md]] - Installer pattern reference
- [[scripts/tools/cloudflare/README.md]] - Cloudflare tools
- [[scripts/tools/tailscale/README.md]] - Tailscale tools

## Security Notes

- All APT repositories added with signed GPG keys
- Binary downloads verified via checksums (SHA256) where available
- Version managers install to user directory (`~/.asdf`, `~/.fnm`, `~/.pyenv`)
- Cloud CLIs require separate authentication (`aws configure`, `gcloud auth`, `az login`)