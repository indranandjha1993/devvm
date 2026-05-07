#!/bin/bash
set -euo pipefail

echo "==> Setting up config directory..."

mkdir -p /opt/dev-vm/config

# Seed/merge credentials.json. On fresh install creates the file; on upgrade
# adds any missing service blocks without overwriting existing values.
CRED_FILE=/opt/dev-vm/config/credentials.json
python3 - <<'PY'
import json, os

path = "/opt/dev-vm/config/credentials.json"
defaults = {
    "mysql":    {"user": "dev", "pass": "dev", "host": "127.0.0.1", "port": 3306, "db": "devdb"},
    "postgres": {"user": "dev", "pass": "dev", "host": "127.0.0.1", "port": 5432, "db": "devdb"},
    "redis":    {"pass": "", "host": "127.0.0.1", "port": 6379},
    "grafana":  {"user": "admin", "pass": "admin", "port": 3000},
    "minio":    {"user": "dev", "pass": "devdevdev", "host": "127.0.0.1", "port": 9000, "console": 9001},
}

if os.path.exists(path):
    with open(path) as f:
        current = json.load(f)
    added = []
    for k, v in defaults.items():
        if k not in current:
            current[k] = v
            added.append(k)
    if added:
        with open(path, "w") as f:
            json.dump(current, f, indent=2)
        print(f"  Merged into credentials.json: {', '.join(added)}")
    else:
        print("  credentials.json already up to date")
else:
    with open(path, "w") as f:
        json.dump(defaults, f, indent=2)
    print("  Created credentials.json")
PY

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
