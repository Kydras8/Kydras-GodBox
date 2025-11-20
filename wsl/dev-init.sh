#!/usr/bin/env bash
# Kydras-GodBox WSL Dev Profile (Phase 1 Skeleton)
set -euo pipefail

echo "[Kydras-GodBox][dev-init] Starting WSL dev profile (skeleton)..."

# Detect distro + basic info
if command -v lsb_release >/dev/null 2>&1; then
  distro=$(lsb_release -ds)
else
  distro="$(uname -s)"
fi

echo "[dev-init] Distro: $distro"
echo "[dev-init] Phase 1: no packages installed yet."
echo "[dev-init] Later phases will:"
echo "  - Install dev toolchain (git, python, node, etc.)"
echo "  - Configure K:/ and D:/ mounts for projects"
echo "  - Set zsh as default shell if desired"

echo "[Kydras-GodBox][dev-init] Done (skeleton)."
