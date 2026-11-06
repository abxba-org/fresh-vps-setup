#!/usr/bin/env bash
set -Eeuo pipefail

echo "Installing Priority 1 AI Tools in parallel..."

(curl -fsSL https://herdr.dev/install.sh | bash) &
PID1=$!
(curl -fsSL https://kilo.ai/cli/install | bash) &
PID2=$!
(curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash) &
PID3=$!
(curl -fsSL https://raw.githubusercontent.com/eugenioenko/ttt/main/install.sh | sh) &
PID4=$!

FAILED=0

for entry in "Herdr:$PID1" "Kilo:$PID2" "Hermes:$PID3" "TTT:$PID4"; do
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
