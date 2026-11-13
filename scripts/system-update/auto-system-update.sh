#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y unattended-upgrades
if [[ "${AUTO_INSTALL_NONINTERACTIVE:-0}" != "1" ]]; then
  dpkg-reconfigure --priority=low unattended-upgrades
fi
