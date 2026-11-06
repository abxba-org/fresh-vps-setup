# Parallel Tools Installer Template

## Purpose
This script is an example Bash template for future AI-assisted development. It demonstrates how to install multiple CLI tools in parallel, handle installation failures gracefully, and verify executables after installation.

## Intended Use
- Use as a reference template for future AI agents
- Add, remove, or replace tools as needed
- Adapt installation URLs, binary names, and configuration
- Preserve parallel execution, error handling, and verification logic
- Treat as an example implementation, not a guaranteed production-ready installer

## Features
- Parallel tool installation using background processes
- Background process tracking with PID management
- Installation failure detection and aggregation
- Configurable timeout per tool (default 5 minutes)
- Post-installation verification using `command -v`
- Aggregate installation and verification reporting
- Shell modification opt-out via `NO_SHELL_MODIFY`

## Example Tools
Herdr, Kilo CLI, Hermes Agent, and TTT (configured as examples - replace with your tools)

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

## Customization Guide

### Adding Tools
```bash
declare -A TOOLS=(
    ["existing"]="url"
    ["new-tool"]="https://example.com/install.sh"  # Add here
)
declare -A BINARIES=(
    ["existing"]="binary"
    ["new-tool"]="new-tool"                         # And here
)
```

### Overriding at Runtime
```bash
# Custom timeout
TIMEOUT=600 ./installer.sh

# Skip shell modifications for specific tools
NO_SHELL_MODIFY="kilo hermes" ./installer.sh

# Both
TIMEOUT=600 NO_SHELL_MODIFY="kilo" ./installer.sh
```

### Installing from Different Sources
```bash
# APT package
install_apt() {
    local pkg="$1"
    apt-get update && apt-get install -y "$pkg"
}

# GitHub release binary
install_gh_release() {
    local repo="$1" binary="$2" version="$3"
    local url="https://github.com/$repo/releases/download/v$version/${binary}_${version}_linux_amd64.tar.gz"
    curl -fsSL "$url" | tar -xz -C /usr/local/bin "$binary"
}

# Custom installer script
install_custom() {
    local name="$1" url="$2"
    curl -fsSL "$url" | bash -s -- --some-flag
}
```

## Error Handling Patterns

### Retry Logic
```bash
install_with_retry() {
    local name="$1" url="$2" max_attempts=3 attempt=1
    while [ $attempt -le $max_attempts ]; do
        if curl -fsSL "$url" | timeout "$TIMEOUT" bash -; then
            return 0
        fi
        echo "Attempt $attempt failed for $name, retrying..."
        ((attempt++))
        sleep 5
    done
    return 1
}
```

### Partial Failure Handling
```bash
# Continue on failure, collect results
results=()
for tool in "${!TOOLS[@]}"; do
    if install_tool "$tool"; then
        results+=("$tool:success")
    else
        results+=("$tool:failed")
    fi
done

# Report
for result in "${results[@]}"; do
    echo "$result"
done
```

## Verification Strategies

### Basic (command -v)
```bash
command -v "$binary" >/dev/null 2>&1
```

### Version Check
```bash
$binary --version 2>&1 | head -1
```

### Functional Test
```bash
# For tools with health checks
$binary doctor 2>&1 | grep -q "OK"
```

### Path Verification
```bash
# Ensure in expected location
[[ "$(command -v "$binary")" == "/usr/local/bin/$binary" ]]
```

## Integration with Main Scripts

This pattern is used in [[scripts/tools/setup.sh]] for installing:
- Container tools (Docker, kubectl, helm, etc.)
- Infrastructure tools (Terraform, Packer, Ansible)
- Cloud CLIs (AWS, GCP, Azure)
- Utilities (bat, eza, rg, fd, etc.)
- Version managers (asdf, fnm, pyenv)

## Best Practices

1. **Always verify URLs** before adding to TOOLS array
2. **Pin versions** where possible for reproducibility
3. **Test in clean environment** before committing
4. **Handle interactive prompts** - use `--yes`, `-y`, or `DEBIAN_FRONTEND=noninteractive`
5. **Clean up on failure** - trap EXIT for temp files
6. **Log extensively** - use consistent log levels (INFO/WARN/ERROR)
7. **Respect NO_SHELL_MODIFY** - some tools modify .bashrc/.zshrc

## Related Documentation

- [[README.md]] - Project overview
- [[AGENT.md]] - Agent cross-references
- [[templates/README.md]] - Template library index
- [[scripts/tools/README.md]] - Tools module using this pattern