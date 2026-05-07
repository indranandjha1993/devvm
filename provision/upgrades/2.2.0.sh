#!/usr/bin/env bash
# Delta upgrade: 2.1.0 -> 2.2.0
# Adds MinIO. Idempotent — safe to re-run.
set -euo pipefail

echo "==> Applying 2.2.0 upgrades..."

# 1. Merge minio block into credentials.json (no-op if already present)
bash /opt/dev-vm/provision/setup-config.sh

# 2. Install MinIO (idempotent)
bash /opt/dev-vm/provision/install-minio.sh

# 3. Live-reload Prometheus to pick up new minio scrape target.
#    --web.enable-lifecycle is set in observability/docker-compose.yml,
#    so HTTP POST /-/reload works without restarting the container.
if docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^prometheus$'; then
    if curl -fsSX POST http://127.0.0.1:9090/-/reload >/dev/null 2>&1; then
        echo "Prometheus config reloaded"
    else
        echo "WARN: Prometheus reload failed via HTTP. Run 'devvm restart prometheus' to pick up MinIO scrape target."
    fi
fi

echo "==> 2.2.0 upgrade complete."
