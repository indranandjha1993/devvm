#!/bin/bash
set -euo pipefail

echo "==> Setting up config directory..."

mkdir -p /opt/dev-vm/config

# Seed credentials.json if it doesn't exist
if [ ! -f /opt/dev-vm/config/credentials.json ]; then
  cat > /opt/dev-vm/config/credentials.json << 'EOF'
{
  "mysql": {"user": "dev", "pass": "dev", "host": "127.0.0.1", "port": 3306, "db": "devdb"},
  "postgres": {"user": "dev", "pass": "dev", "host": "127.0.0.1", "port": 5432, "db": "devdb"},
  "redis": {"pass": "", "host": "127.0.0.1", "port": 6379},
  "grafana": {"user": "admin", "pass": "admin", "port": 3000}
}
EOF
  echo "  Created credentials.json"
fi

# Seed apps.json if it doesn't exist
if [ ! -f /opt/dev-vm/config/apps.json ]; then
  cat > /opt/dev-vm/config/apps.json << 'EOF'
{"apps": {}, "next_port": 8001}
EOF
  echo "  Created apps.json"
fi

# Seed empty prometheus file_sd for apps
if [ ! -f /opt/dev-vm/config/prometheus-apps.json ]; then
  echo '[]' > /opt/dev-vm/config/prometheus-apps.json
  echo "  Created prometheus-apps.json"
fi

chmod 644 /opt/dev-vm/config/*.json
echo "==> Config ready."
