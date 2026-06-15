#!/usr/bin/env bash
# Delta upgrade: 2.2.0 -> 2.3.0
# Adds the ShortGen render service (local ffmpeg, replaces json2video). Idempotent.
set -euo pipefail

echo "==> Applying 2.3.0 upgrades..."

# Install the ShortGen render service — ffmpeg + Oswald + systemd unit on :8088.
# Re-runs only refresh the code and restart; never touches postgres/minio/etc.
bash /opt/dev-vm/provision/install-shortgen-renderer.sh

echo "==> 2.3.0 upgrade complete."
