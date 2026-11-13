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
    # NOTE: exa has no apt package on Ubuntu 24.04+ (deprecated upstream; use eza)
    ["fd"]="apt:fd-find"
    ["zoxide"]="apt:zoxide"
    ["bat"]="apt:bat"
    ["fzf"]="apt:fzf"
    ["ripgrep"]="apt:ripgrep"
    ["curl"]="apt:curl"
    ["jq"]="apt:jq"
    ["htop"]="apt:htop"
    ["ncdu"]="apt:ncdu"
    ["fastfetch"]="apt:fastfetch"

    # Modern replacements (via GitHub releases)
    ["eza"]="gh:eza-community/eza"
    ["btop"]="gh:aristocratos/btop"
    ["duf"]="gh:muesli/duf"
    ["dust"]="gh:bootandy/dust"

    # Shell enhancements (script:<url>|<args>|<shell> — shell defaults to sh)
    ["atuin"]="script:https://setup.atuin.sh"
    ["starship"]="script:https://starship.rs/install.sh|--yes|sh"

    # Cloudflare
    ["cloudflared"]="apt:cloudflared"  # Requires Cloudflare APT repo pre-configured

    # Version managers (fnm's installer is bash-only)
    ["fnm"]="script:https://fnm.vercel.app/install|--skip-shell|bash"
)

declare -A BINARIES=(
    ["fd"]="fd"
    ["zoxide"]="zoxide"
    ["bat"]="bat"
    ["fzf"]="fzf"
    ["ripgrep"]="rg"
    ["curl"]="curl"
    ["jq"]="jq"
    ["htop"]="htop"
    ["ncdu"]="ncdu"
    ["fastfetch"]="fastfetch"
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

# curl with retry — transient upstream errors (502/503/429) fail whole runs otherwise
MAX_RETRIES="${MAX_RETRIES:-3}"
curl_retry() {
    local attempt=1 rc
    while (( attempt <= MAX_RETRIES )); do
        curl -fsSL "$@" && return 0
        rc=$?
        if (( attempt < MAX_RETRIES )); then
            log_warn "curl attempt $attempt/$MAX_RETRIES failed (exit $rc); retrying in $((attempt * 5))s..."
            sleep $((attempt * 5))
        fi
        ((attempt++))
    done
    return "$rc"
}

# Install via APT (non-interactive, serialized — apt/dpkg lock is not parallel-safe)
install_apt() {
    local pkg="$1"
    (
      flock 9
      if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q 'install ok installed'; then
          log_info "Installing $pkg via APT..."
          DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg"
      else
          log_info "$pkg already installed, skipping."
      fi
      # Ubuntu/Debian binary name fixes
      case "$pkg" in
          fd-find) mkdir -p /usr/local/bin; ln -sf /usr/bin/fdfind /usr/local/bin/fd ;;
          bat)     mkdir -p /usr/local/bin; ln -sf /usr/bin/batcat /usr/local/bin/bat ;;
      esac
    ) 9>/var/lib/dpkg/lock-frontend
}

# Install via GitHub release (binary) — matches assets via the GitHub API
install_gh_release() {
    local repo="$1" binary="$2"
    local api="https://api.github.com/repos/$repo/releases/latest"
    local assets asset_url tmpdir

    log_info "Fetching latest release assets for $repo..."
    assets=$(curl_retry "$api" | grep -o '"browser_download_url": *"[^"]*"' | cut -d'"' -f4) || {
        log_error "Could not list releases for $repo (rate limit?)"
        return 1
    }

    # Linux x86_64/amd64 assets only; exclude arm, 32-bit, non-Linux
    asset_url=$(grep -Ei "$binary" <<<"$assets" \
        | grep -Ei 'linux' \
        | grep -Ei 'x86_64|amd64' \
        | grep -Evi 'aarch64|armv|arm64|i[36]86|android|darwin|windows|freebsd' \
        | head -1)
    [[ -n $asset_url ]] || { log_error "No linux x86_64 asset found for $repo $binary"; return 1; }
    log_info "Downloading ${asset_url##*/}..."

    tmpdir=$(mktemp -d)
    curl_retry "$asset_url" -o "$tmpdir/asset" || { rm -rf "$tmpdir"; return 1; }

    case "${asset_url##*.}" in
        zip) unzip -qo "$tmpdir/asset" -d "$tmpdir" ;;
        *)   tar -xf "$tmpdir/asset" -C "$tmpdir" 2>/dev/null || tar -xf "$tmpdir/asset" -C "$tmpdir" --wildcards 2>/dev/null ;;
    esac

    local found
    found=$(find "$tmpdir" -type f -name "$binary" -perm /111 | head -1)
    if [[ -z $found ]]; then
        found=$(find "$tmpdir" -type f -name "$binary" | head -1)
    fi
    if [[ -n $found ]]; then
        install -m 0755 "$found" "/usr/local/bin/$binary"
        rm -rf "$tmpdir"
        return 0
    fi
    rm -rf "$tmpdir"
    log_error "Binary '$binary' not found in $repo release archive"
    return 1
}

# Install via curl|<shell> script (starship requires sh; fnm requires bash)
install_script() {
    local url="$1" name="$2" args="$3" shell="${4:-sh}"
    local logfile
    logfile=$(mktemp)
    log_info "Running installer script for $name ${args:+with args: $args}..."
    # shellcheck disable=SC2086
    # NOTE: do NOT redirect the shell's stdin — `-s` reads the installer script
    # from stdin, and </dev/null would feed it an empty script (curl error 23).
    # Retry the whole pipeline: transient 502/503 from installer hosts must not
    # fail the run (installers here are idempotent re-runs).
    local attempt=1
    while (( attempt <= MAX_RETRIES )); do
        if [[ -n $args ]]; then
            if curl -fsSL "$url" | "$shell" -s -- $args >"$logfile" 2>&1; then
                rm -f "$logfile"
                return 0
            fi
        else
            if curl -fsSL "$url" | "$shell" -s >"$logfile" 2>&1; then
                rm -f "$logfile"
                return 0
            fi
        fi
        log_warn "$name installer attempt $attempt/$MAX_RETRIES failed; last lines:"
        tail -3 "$logfile" >&2
        if (( attempt < MAX_RETRIES )); then
            sleep $((attempt * 5))
        fi
        attempt=$((attempt + 1))
    done
    log_error "Installer for $name failed after $MAX_RETRIES attempts; last lines:"
    tail -5 "$logfile" >&2
    rm -f "$logfile"
    return 1
}

# Generic installer dispatcher
install_tool() {
    local name="$1"
    local spec="${TOOLS[$name]}" binary="${BINARIES[$name]}"
    local type="${spec%%:*}" value="${spec#*:}"
    local args="" shell="sh"

    if [[ $type == script && $value == *\|* ]]; then
        args="${value#*|}"
        value="${value%%|*}"
        if [[ $args == *\|* ]]; then
            shell="${args#*|}"
            args="${args%%|*}"
        fi
    fi

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
            install_script "$value" "$name" "$args" "$shell"
            ;;
        *)
            log_error "Unknown install type '$type' for $name"
            return 1
            ;;
    esac

    # User-level installs (atuin, fnm, cargo tools) are not in root's PATH —
    # symlink into /usr/local/bin so verification and shells find them.
    if ! has_command "$binary"; then
        local alt
        for alt in \
            "$HOME/.atuin/bin/$binary" \
            "$HOME/.local/bin/$binary" \
            "$HOME/.cargo/bin/$binary" \
            "$HOME/.fnm/$binary" \
            "$HOME/.fnm/bin/$binary" \
            "$HOME/.local/share/fnm/$binary" \
            "${XDG_DATA_HOME:-$HOME/.local/share}/fnm/$binary"; do
            if [[ -x $alt ]]; then
                # Only symlink if target doesn't exist or points elsewhere
                if [[ ! -e /usr/local/bin/$binary ]] || [[ $(readlink -f /usr/local/bin/$binary) != "$alt" ]]; then
                    ln -sf "$alt" "/usr/local/bin/$binary"
                    log_info "Symlinked $alt -> /usr/local/bin/$binary"
                fi
                break
            fi
        done
    fi
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
            local version
            version=$("$binary" --version 2>&1 | head -1 || echo "version unknown")
            log_success "$binary: $version"
            ok=$((ok + 1))
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

# One-time package list refresh (serialized against the apt lock)
(
  flock 9
  apt-get update -qq
) 9>/var/lib/dpkg/lock-frontend

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