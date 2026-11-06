#!/usr/bin/env bash
# =============================================================================
# parallel-tools-installer.sh — Parallel, fault-tolerant CLI tool installer
#
# Based on: templates/tools-installer-template.md
# Installs terminal tools, cloudflared, and development utilities in parallel.
#
# Usage:
#   sudo ./parallel-tools-installer.sh                    # Install all
#   TIMEOUT=600 ./parallel-tools-installer.sh             # Custom timeout
#   NO_SHELL_MODIFY="atuin" ./parallel-tools-installer.sh # Skip shell mods
#   ./parallel-tools-installer.sh --verify-only           # Only verify
#   ./parallel-tools-installer.sh --list                  # List configured tools
# =============================================================================
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY_ONLY=0
LIST_ONLY=0

for arg in "$@"; do
    case $arg in
        --verify-only) VERIFY_ONLY=1 ;;
        --list) LIST_ONLY=1 ;;
        -h|--help)
            cat <<EOF
Usage: $0 [--verify-only] [--list]

Installs tools in parallel with failure detection and verification.

Environment variables:
  TIMEOUT=300           Install timeout per tool (seconds, default 300)
  NO_SHELL_MODIFY=""    Space-separated tool names to skip shell config changes

Options:
  --verify-only   Only run verification, skip installation
  --list          List configured tools and exit
  -h, --help      Show this help
EOF
            exit 0
            ;;
        *) echo "Unknown option: $arg" >&2; exit 1 ;;
    esac
done

# --- Configuration ---
declare -A TOOLS=(
    # Terminal utilities (via APT)
    ["exa"]="apt:exa"
    ["fd"]="apt:fd-find"
    ["zoxide"]="apt:zoxide"
    ["bat"]="apt:bat"
    ["fzf"]="apt:fzf"
    ["ripgrep"]="apt:ripgrep"
    ["curl"]="apt:curl"
    ["jq"]="apt:jq"
    ["htop"]="apt:htop"
    ["ncdu"]="apt:ncdu"

    # Modern replacements (via GitHub releases)
    ["eza"]="gh: eza-community/eza"
    ["btop"]="gh: aristocratos/btop"
    ["duf"]="gh: muesli/duf"
    ["dust"]="gh: bootandy/dust"

    # Shell enhancements
    ["atuin"]="script:https://setup.atuin.sh"
    ["starship"]="script:https://starship.rs/install.sh"

    # Cloudflare
    ["cloudflared"]="apt:cloudflared"  # Requires Cloudflare APT repo pre-configured

    # Version managers
    ["fnm"]="script:https://fnm.vercel.app/install"
)

declare -A BINARIES=(
    ["exa"]="exa"
    ["fd"]="fd"
    ["zoxide"]="zoxide"
    ["bat"]="bat"
    ["fzf"]="fzf"
    ["ripgrep"]="rg"
    ["curl"]="curl"
    ["jq"]="jq"
    ["htop"]="htop"
    ["ncdu"]="ncdu"
    ["eza"]="eza"
    ["btop"]="btop"
    ["duf"]="duf"
    ["dust"]="dust"
    ["atuin"]="atuin"
    ["starship"]="starship"
    ["cloudflared"]="cloudflared"
    ["fnm"]="fnm"
)

TIMEOUT="${TIMEOUT:-300}"
NO_SHELL_MODIFY="${NO_SHELL_MODIFY:-}"

# --- Logging ---
log_info() { printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
log_warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*" >&2; }
log_error() { printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2; }
log_success() { printf '\033[1;32m[OK]\033[0m %s\n' "$*"; }

# --- Helpers ---
has_command() { command -v "$1" >/dev/null 2>&1; }

# Install via APT (non-interactive)
install_apt() {
    local pkg="$1"
    if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q 'install ok installed'; then
        log_info "Installing $pkg via APT..."
        DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg" >/dev/null
    else
        log_info "$pkg already installed, skipping."
    fi
}

# Install via GitHub release (binary)
install_gh_release() {
    local repo="$1" binary="$2"
    local latest_url="https://api.github.com/repos/$repo/releases/latest"
    local version download_url

    log_info "Fetching latest release for $repo..."
    version=$(curl -fsSL "$latest_url" | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": "\([^"]*\)".*/\1/')
    [[ -n $version ]] || { log_error "Failed to get version for $repo"; return 1; }

    # Try common naming patterns
    for pattern in \
        "${binary}_${version#v}_linux_amd64.tar.gz" \
        "${binary}_${version}_linux_amd64.tar.gz" \
        "${binary}-${version#v}-linux-amd64.tar.gz" \
        "${binary}-${version}-linux-amd64.tar.gz"; do
        download_url="https://github.com/$repo/releases/download/$version/$pattern"
        if curl -fsSLI "$download_url" >/dev/null 2>&1; then
            log_info "Downloading $pattern..."
            curl -fsSL "$download_url" | tar -xz -C /usr/local/bin "$binary" 2>/dev/null || \
                curl -fsSL "$download_url" | tar -xz -C /usr/local/bin --wildcards "*/$binary" --transform 's|.*/||' 2>/dev/null || true
            [[ -x /usr/local/bin/$binary ]] && return 0
        fi
    done
    log_error "No matching asset found for $repo $binary"
    return 1
}

# Install via curl|bash script
install_script() {
    local url="$1" name="$2"
    log_info "Running installer script for $name..."
    curl -fsSL "$url" | bash -s -- -y 2>/dev/null || curl -fsSL "$url" | bash - 2>/dev/null
}

# Generic installer dispatcher
install_tool() {
    local name="$1" spec="${TOOLS[$name]}" binary="${BINARIES[$name]}"
    local type="${spec%%:*}" value="${spec#*:}"

    if [[ "$NO_SHELL_MODIFY" == *"$name"* ]]; then
        log_info "Skipping shell modifications for $name (NO_SHELL_MODIFY)"
    fi

    case $type in
        apt)
            install_apt "$value"
            ;;
        gh)
            install_gh_release "$value" "$binary"
            ;;
        script)
            install_script "$value" "$name"
            ;;
        *)
            log_error "Unknown install type '$type' for $name"
            return 1
            ;;
    esac
}

# --- List tools ---
if (( LIST_ONLY )); then
    echo "Configured tools:"
    for tool in "${!TOOLS[@]}"; do
        printf "  %-15s %-10s %s\n" "$tool" "${BINARIES[$tool]}" "${TOOLS[$tool]}"
    done | sort
    exit 0
fi

# --- Verification ---
verify_tools() {
    local ok=0 total=${#TOOLS[@]}
    echo
    log_info "=== Verification ==="
    for tool in "${!TOOLS[@]}"; do
        binary="${BINARIES[$tool]}"
        if has_command "$binary"; then
            local version=$("$binary" --version 2>&1 | head -1 || echo "version unknown")
            log_success "$binary: $version"
            ((ok++))
        else
            log_error "$binary not found"
        fi
    done
    echo
    log_info "Verified $ok/$total tools."
    [[ $ok -eq $total ]] && return 0 || return 1
}

if (( VERIFY_ONLY )); then
    verify_tools
    exit $?
fi

# --- Parallel Installation ---
log_info "Installing ${#TOOLS[@]} tools in parallel (timeout: ${TIMEOUT}s each)..."

declare -A PIDS
FAILED=0

for tool in "${!TOOLS[@]}"; do
    (
        install_tool "$tool"
    ) &
    PIDS[$tool]=$!
done

# Wait for all and collect results
for tool in "${!TOOLS[@]}"; do
    pid=${PIDS[$tool]}
    if wait "$pid"; then
        log_success "$tool installed"
    else
        log_error "$tool installation failed"
        FAILED=1
    fi
done

if [[ $FAILED -eq 0 ]]; then
    log_success "All tools installed successfully."
else
    log_error "One or more installations failed."
fi

# --- Verification ---
verify_tools
exit $?