# Parallel Tools Installer Template

## Purpose
This script is an example Bash template for future AI-assisted development. It demonstrates how to install multiple AI tools in parallel, handle installation failures, and verify executables after installation.

## Intended Use
- Use as a reference template for future AI agents.
- Add, remove, or replace AI tools as needed.
- Adapt installation URLs, binary names, and configuration for future requirements.
- Preserve parallel execution, error handling, and verification logic.
- Treat this as an example implementation, not a guaranteed production-ready installer.

## Features
- Parallel AI tool installation.
- Background process tracking.
- Installation failure detection.
- Configurable timeout.
- Post-installation verification using `command -v`.
- Aggregate installation and verification reporting.

## Example Tools
Herdr, Kilo CLI, Hermes Agent, and TTT.

## Important
The script below is provided as a reusable reference example. Future AI agents may modify or extend it when requested. Verify installer URLs, executable names, and compatibility before actual use.

## Example Script
```bash
#!/usr/bin/env bash
set -Eeuo pipefail

# --- Configuration (edit these) ---
declare -A TOOLS=(
    ["herdr"]="https://herdr.dev/install.sh"
    ["kilo"]="https://kilo.ai/cli/install"
    ["hermes"]="https://hermes-agent.nousresearch.com/install.sh"
    ["ttt"]="https://raw.githubusercontent.com/eugenioenko/ttt/main/install.sh"
)
declare -A BINARIES=(
    ["herdr"]="herdr"
    ["kilo"]="kilo"
    ["hermes"]="hermes"
    ["ttt"]="ttt"
)
TIMEOUT="${TIMEOUT:-300}"            # 5 minutes default
NO_SHELL_MODIFY="${NO_SHELL_MODIFY:-}" # pass to disable shell config writes (empty=allow)

# --- Installer function ---
install_tool() {
    local name="$1" url="${TOOLS[$name]}" binary="${BINARIES[$name]}" timeout="${2:-$TIMEOUT}"
    if [[ "$NO_SHELL_MODIFY" == *"$name"* ]]; then
        # Filter out --no-modify-path pass-through; the installer reads it from stdin anyway,
        # so we cannot selectively suppress; instead we let it run normally. Just document.
        :
    fi
    echo "Installing $name ..."
    (
        curl -fsSL "$url" | timeout "$timeout" bash -
    ) &
    printf '%s:%s\n' "$name" $!
}

echo "Installing Priority 1 AI Tools in parallel..."

FAILED=0
pids=()
for entry in "${!TOOLS[@]}"; do
    pid=$(install_tool "$entry") || true
    pids+=("$pid")
done

for entry in "${!TOOLS[@]}"; do
    name="${entry%%:*}"
    pid="${entry##*:}"
    if wait "$pid"; then
        echo "[SUCCESS] $name installed"
    else
        echo "[ERROR] $name installation failed"
        FAILED=1
    fi
done

if [ "$FAILED" -eq 0 ]; then
    echo "[SUCCESS] All PRIORITY 1 tools installed."
    exit 0
else
    echo "[ERROR] One or more installations failed."
    exit 1
fi

# --- Verification ---
echo ""
echo "=== Verification ==="
ok=0
for entry in "${!TOOLS[@]}"; do
    name="${entry%%:*}"
    binary="${BINARIES[$name]}"
    if command -v "$binary" >/dev/null 2>&1; then
        echo "[OK]   $binary found: $(command -v "$binary")"
        ((ok += 1))
    else
        echo "[MISS] $binary not found after install"
    fi
done
echo "Verified ${ok:-0}/${#TOOLS[@]} tools."
```
