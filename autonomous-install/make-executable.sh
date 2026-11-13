#!/usr/bin/env bash
# =============================================================================
# make-executable.sh — Make all setup scripts executable
# Run from: fresh-vps-setup/autonomous-install/
# =============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() { printf '\033[1;36m[make-executable]\033[0m %s\n' "$*"; }

cd "$REPO_ROOT"

scripts=(
    "autonomous-install/auto-install.sh"
    "scripts/network/secure-vps.sh"
    "scripts/network/restrict-ssh.sh"
    "scripts/tools/parallel-tools-installer.sh"
    "scripts/tools/cloudflare/CF-setup.sh"
    "scripts/tools/tailscale/tailscale-setup.sh"
    "scripts/system-update/auto-system-update.sh"
    "scripts/zsh/zsh_script.sh"
    "essentials/install-essentials-tools.sh"
)

log "Making scripts executable..."
for script in "${scripts[@]}"; do
    if [[ -f "$script" ]]; then
        chmod +x "$script"
        log "  ✓ $script"
    else
        log "  ✗ $script (not found)"
    fi
done

log "Done. All scripts are now executable."
