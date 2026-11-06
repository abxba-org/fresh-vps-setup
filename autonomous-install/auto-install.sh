#!/usr/bin/env bash
# =============================================================================
# auto-install.sh — Automated VPS provisioning orchestrator (two-phase)
#
# Phase 1 (Autonomous): Runs fully automatic scripts non-interactively.
# Phase 2 (Interactive): Runs scripts requiring manual confirmation.
#
# Usage: sudo ./auto-install.sh [--phase=1|2] [--skip-interactive]
# =============================================================================
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PHASE=0
SKIP_INTERACTIVE=0

for arg in "$@"; do
    case $arg in
        --phase=1) PHASE=1 ;;
        --phase=2) PHASE=2 ;;
        --skip-interactive) SKIP_INTERACTIVE=1 ;;
        -h|--help)
            cat <<EOF
Usage: sudo ./auto-install.sh [--phase=1|2] [--skip-interactive]

PHASE 1 (Autonomous) — runs non-interactively:
  1. auto-system-update.sh      (unattended-upgrades, preseeded)
  2. install-sys-tools.sh       (terminal tools, Atuin)
  3. CF-setup.sh                (cloudflared package)

PHASE 2 (Interactive) — requires manual confirmation:
  4. secure-vps.sh --apply      (UFW, SSH hardening, fail2ban)
  5. restrict-ssh.sh apply      (nftables SSH guard)
  6. tailscale-setup.sh         (Tailscale join, tagged)
  7. zsh setup                  (manual steps)

Options:
  --phase=1             Run only Phase 1 (autonomous)
  --phase=2             Run only Phase 2 (interactive)
  --skip-interactive    Skip Phase 2 entirely (same as --phase=1)

Default (no args): Run Phase 1, then prompt to continue to Phase 2.
EOF
            exit 0
            ;;
        *) echo "Unknown option: $arg" >&2; exit 1 ;;
    esac
done

log() { printf '\n\033[1;36m[auto-install]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "Run with sudo: sudo ./auto-install.sh"

# =============================================================================
# PHASE 1: AUTONOMOUS (fully automatic)
# =============================================================================
run_phase1() {
    log "========== PHASE 1: AUTONOMOUS =========="
    
    # Step 1: Automatic security updates (preseeded)
    log "Step 1/3: Configuring unattended-upgrades..."
    export DEBIAN_FRONTEND=noninteractive
    echo 'unattended-upgrades unattended-upgrades/enable_auto_updates boolean true' | debconf-set-selections
    "$SCRIPT_DIR/scripts/system-update/auto-system-update.sh"
    log "unattended-upgrades configured."

    # Step 2: Terminal tools + Atuin
    log "Step 2/3: Installing terminal tools (exa, fd, zoxide, bat, fzf, rg, Atuin)..."
    "$SCRIPT_DIR/scripts/tools/install-sys-tools.sh"
    log "Terminal tools installed."

    # Step 3: Cloudflare cloudflared
    log "Step 3/3: Installing cloudflared from Cloudflare APT repo..."
    "$SCRIPT_DIR/scripts/tools/cloudflare/CF-setup.sh"
    log "cloudflared installed."

    log "========== PHASE 1 COMPLETE =========="
    log "Next steps (manual):"
    log "  - cloudflared: run 'cloudflared tunnel login' then create tunnels"
    log "  - Run Phase 2: sudo ./auto-install.sh --phase=2"
}

# =============================================================================
# PHASE 2: INTERACTIVE (requires manual confirmation)
# =============================================================================
run_phase2() {
    log "========== PHASE 2: INTERACTIVE =========="
    warn "These steps require manual confirmation. Keep provider console/rescue access ready."
    warn "For restrict-ssh.sh: you MUST be on Cloudflare Access SSH or Tailscale SSH."
    read -rp "Press Enter to continue to Phase 2, or Ctrl+C to abort... "

    # Step 4: secure-vps.sh --apply
    log "Step 4/7: Running secure-vps.sh --apply (UFW, SSH hardening, fail2ban)..."
    warn "Prompts you will see:"
    warn "  1. 'CONSOLE-READY' — confirm provider console/rescue access"
    warn "  2. SSH port + additional ports (e.g., 80/tcp,443/tcp)"
    warn "  3. 'APPLY-FIREWALL' — applies UFW rules"
    warn "  4. Test SECOND SSH login in another terminal"
    warn "  5. 'DISABLE-SSH-PASSWORDS' — after confirming key login works"
    read -rp "Press Enter to continue... "
    "$SCRIPT_DIR/scripts/network/secure-vps.sh" --apply --harden-ssh
    log "secure-vps.sh --apply completed."

    # Step 5: restrict-ssh.sh apply
    log "Step 5/7: Running restrict-ssh.sh apply (nftables SSH guard)..."
    warn "REQUIREMENT: You must be connected via Cloudflare Access SSH or Tailscale SSH."
    warn "Direct-IP SSH sessions WILL BE TERMINATED."
    warn "After apply, you have 5 MINUTES to test and run 'sudo ./restrict-ssh.sh confirm'."
    read -rp "Are you on Cloudflare Access/Tailscale SSH? Press Enter to continue... "
    "$SCRIPT_DIR/scripts/network/restrict-ssh.sh" apply
    log "restrict-ssh.sh apply completed."
    warn "TEST NOW: Open a new SSH session via Cloudflare Access or Tailscale."
    warn "Then run: sudo ./restrict-ssh.sh confirm"

    # Step 6: tailscale-setup.sh
    log "Step 6/7: Running tailscale-setup.sh (join tailnet with tag)..."
    warn "This prints an auth URL. You must:"
    warn "  1. Open the URL from an authenticated device"
    warn "  2. Approve the node in Tailscale admin console"
    warn "  3. Disable key expiry (admin console -> machine -> ... -> Disable key expiry)"
    warn "  4. Verify 'tailscale ping' and Tailscale SSH from your laptop"
    read -rp "Press Enter to continue... "
    "$SCRIPT_DIR/scripts/tools/tailscale/tailscale-setup.sh"
    log "tailscale-setup.sh completed. Complete admin console steps above."

    # Step 7: Zsh setup
    log "Step 7/7: Zsh setup (manual steps)..."
    cat <<'ZSH_EOF'

Zsh setup requires manual steps (scripts/zsh/zsh_script.sh is notes only):

  # 1. Install zoxide
  sudo apt update && sudo apt install -y zoxide

  # 2. Install Oh My Zsh (unattended)
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

  # 3. Clone config repo and copy .zshrc
  git clone https://github.com/abxba-org/fresh_VPS
  cp fresh_VPS/zsh-config/.zshrc ~/.zshrc

  # 4. Install Powerlevel10k theme
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k

  # 5. Install plugins
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
  git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-completions

  # 6. Restart shell
  exec zsh

  # 7. Configure Powerlevel10k
  p10k configure

ZSH_EOF

    log "========== PHASE 2 COMPLETE =========="
    log "Remaining manual follow-ups:"
    log "  - cloudflared: 'cloudflared tunnel login' then create tunnels"
    log "  - restrict-ssh.sh: 'sudo ./restrict-ssh.sh confirm' after testing"
    log "  - tailscale: approve node + disable key expiry in admin console"
    log "  - zsh: follow steps above"
}

# =============================================================================
# MAIN
# =============================================================================
case $PHASE in
    1) run_phase1 ;;
    2) run_phase2 ;;
    0)
        run_phase1
        echo
        read -rp "Run Phase 2 (interactive) now? [y/N]: " ans
        [[ $ans =~ ^[Yy]$ ]] && run_phase2 || log "Phase 2 skipped. Run later with: sudo ./auto-install.sh --phase=2"
        ;;
esac