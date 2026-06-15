#!/usr/bin/env bash
# Delta upgrade: 2.3.0 -> 2.3.1
# Reliable Oswald font check in the ShortGen render install. Idempotent.
set -euo pipefail

echo "==> Applying 2.3.1 upgrades..."

bash /opt/dev-vm/provision/install-shortgen-renderer.sh

echo "==> 2.3.1 upgrade complete."
