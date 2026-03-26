#!/usr/bin/env bash
set -euo pipefail

echo "=== Installing Prometheus Exporters ==="

# ─── mysqld_exporter v0.15.1 ───────────────────────────────────────────────────

MYSQLD_EXPORTER_VERSION="0.15.1"
echo "--- Installing mysqld_exporter ${MYSQLD_EXPORTER_VERSION} ---"

cd /tmp
curl -fsSL --retry 3 "https://github.com/prometheus/mysqld_exporter/releases/download/v${MYSQLD_EXPORTER_VERSION}/mysqld_exporter-${MYSQLD_EXPORTER_VERSION}.linux-arm64.tar.gz" -o mysqld_exporter.tar.gz
tar xzf mysqld_exporter.tar.gz
sudo cp "mysqld_exporter-${MYSQLD_EXPORTER_VERSION}.linux-arm64/mysqld_exporter" /usr/local/bin/
sudo chmod +x /usr/local/bin/mysqld_exporter
rm -rf mysqld_exporter.tar.gz "mysqld_exporter-${MYSQLD_EXPORTER_VERSION}.linux-arm64"

# Create MySQL monitoring user
sudo mysql -e "CREATE USER IF NOT EXISTS 'exporter'@'localhost' IDENTIFIED BY 'exporter';"
sudo mysql -e "GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# MySQL exporter config
sudo tee /etc/.mysqld_exporter.cnf > /dev/null <<'CNFEOF'
[client]
user=exporter
password=exporter
CNFEOF
sudo chmod 600 /etc/.mysqld_exporter.cnf

# Install systemd service
sudo cp /opt/dev-vm/systemd/mysqld-exporter.service /etc/systemd/system/mysqld-exporter.service
sudo systemctl daemon-reload
sudo systemctl enable --now mysqld-exporter
echo "mysqld_exporter installed and running on :9104"

# ─── postgres_exporter v0.15.0 ─────────────────────────────────────────────────

POSTGRES_EXPORTER_VERSION="0.15.0"
echo "--- Installing postgres_exporter ${POSTGRES_EXPORTER_VERSION} ---"

cd /tmp
curl -fsSL --retry 3 "https://github.com/prometheus-community/postgres_exporter/releases/download/v${POSTGRES_EXPORTER_VERSION}/postgres_exporter-${POSTGRES_EXPORTER_VERSION}.linux-arm64.tar.gz" -o postgres_exporter.tar.gz
tar xzf postgres_exporter.tar.gz
sudo cp "postgres_exporter-${POSTGRES_EXPORTER_VERSION}.linux-arm64/postgres_exporter" /usr/local/bin/
sudo chmod +x /usr/local/bin/postgres_exporter
rm -rf postgres_exporter.tar.gz "postgres_exporter-${POSTGRES_EXPORTER_VERSION}.linux-arm64"

# Environment file with connection string
sudo tee /etc/default/postgres_exporter > /dev/null <<'ENVEOF'
DATA_SOURCE_NAME="postgresql://dev:dev@localhost:5432/devdb?sslmode=disable"
ENVEOF
sudo chmod 600 /etc/default/postgres_exporter

# Install systemd service
sudo cp /opt/dev-vm/systemd/postgres-exporter.service /etc/systemd/system/postgres-exporter.service
sudo systemctl daemon-reload
sudo systemctl enable --now postgres-exporter
echo "postgres_exporter installed and running on :9187"

# ─── redis_exporter v1.58.0 ────────────────────────────────────────────────────

REDIS_EXPORTER_VERSION="1.58.0"
echo "--- Installing redis_exporter ${REDIS_EXPORTER_VERSION} ---"

cd /tmp
curl -fsSL --retry 3 "https://github.com/oliver006/redis_exporter/releases/download/v${REDIS_EXPORTER_VERSION}/redis_exporter-v${REDIS_EXPORTER_VERSION}.linux-arm64.tar.gz" -o redis_exporter.tar.gz
tar xzf redis_exporter.tar.gz
sudo cp "redis_exporter-v${REDIS_EXPORTER_VERSION}.linux-arm64/redis_exporter" /usr/local/bin/
sudo chmod +x /usr/local/bin/redis_exporter
rm -rf redis_exporter.tar.gz "redis_exporter-v${REDIS_EXPORTER_VERSION}.linux-arm64"

# Install systemd service
sudo cp /opt/dev-vm/systemd/redis-exporter.service /etc/systemd/system/redis-exporter.service
sudo systemctl daemon-reload
sudo systemctl enable --now redis-exporter
echo "redis_exporter installed and running on :9121"

# ─── Done ───────────────────────────────────────────────────────────────────────

echo ""
echo "=== All exporters installed ==="
echo "  mysqld_exporter   -> http://localhost:9104/metrics"
echo "  postgres_exporter  -> http://localhost:9187/metrics"
echo "  redis_exporter     -> http://localhost:9121/metrics"
echo ""
echo "Note: cAdvisor runs as a Docker container via docker-compose (port 8081)."
