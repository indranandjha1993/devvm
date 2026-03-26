#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "============================================"
echo "  Dev VM Post-Init Provisioning"
echo "============================================"
echo ""

# Ensure we're root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: This script must be run as root (sudo)."
    exit 1
fi

echo "==> Step 1/4: Installing language stacks..."
bash "$SCRIPT_DIR/install-languages.sh"

echo ""
echo "==> Step 2/4: Configuring databases..."
bash "$SCRIPT_DIR/install-databases.sh"

echo ""
echo "==> Step 3/4: Configuring debugging tools..."
bash "$SCRIPT_DIR/configure-debugging.sh"

echo ""
echo "==> Step 4/4: Installing additional tools..."
bash "$SCRIPT_DIR/install-tools.sh"

echo ""
echo "============================================"
echo "  Post-Init Provisioning Complete!"
echo "============================================"
