#!/usr/bin/env bash
set -euo pipefail

echo "=== Installing MinIO ==="

# Defaults — override via env or by editing /etc/default/minio after install
MINIO_USER="${MINIO_USER:-minio-user}"
MINIO_GROUP="${MINIO_GROUP:-minio-user}"
MINIO_HOME="${MINIO_HOME:-/var/lib/minio}"
MINIO_DATA="${MINIO_DATA:-${MINIO_HOME}/data}"
MINIO_BIN="/usr/local/bin/minio"
MC_BIN="/usr/local/bin/mc"

CRED_FILE="/opt/dev-vm/config/credentials.json"
ROOT_USER="dev"
ROOT_PASS="devdevdev"
if [ -f "${CRED_FILE}" ]; then
    ROOT_USER=$(python3 -c "import json; print(json.load(open('${CRED_FILE}')).get('minio',{}).get('user','dev'))" 2>/dev/null || echo dev)
    ROOT_PASS=$(python3 -c "import json; print(json.load(open('${CRED_FILE}')).get('minio',{}).get('pass','devdevdev'))" 2>/dev/null || echo devdevdev)
fi

# --- System user ---
if ! id "${MINIO_USER}" &>/dev/null; then
    groupadd -r "${MINIO_GROUP}" 2>/dev/null || true
    useradd -r -g "${MINIO_GROUP}" -s /sbin/nologin -d "${MINIO_HOME}" -M "${MINIO_USER}"
    echo "Created system user ${MINIO_USER}"
fi

# --- Data dir ---
mkdir -p "${MINIO_DATA}"
chown -R "${MINIO_USER}:${MINIO_GROUP}" "${MINIO_HOME}"
chmod 750 "${MINIO_HOME}"

# --- minio binary ---
if [ ! -x "${MINIO_BIN}" ]; then
    echo "--- Downloading minio (linux-arm64) ---"
    curl -fsSL --retry 3 \
        "https://dl.min.io/server/minio/release/linux-arm64/minio" \
        -o "${MINIO_BIN}.tmp"
    chmod +x "${MINIO_BIN}.tmp"
    mv "${MINIO_BIN}.tmp" "${MINIO_BIN}"
fi
echo "minio: $(${MINIO_BIN} --version 2>/dev/null | head -1 || echo installed)"

# --- mc client ---
if [ ! -x "${MC_BIN}" ]; then
    echo "--- Downloading mc client (linux-arm64) ---"
    curl -fsSL --retry 3 \
        "https://dl.min.io/client/mc/release/linux-arm64/mc" \
        -o "${MC_BIN}.tmp"
    chmod +x "${MC_BIN}.tmp"
    mv "${MC_BIN}.tmp" "${MC_BIN}"
fi
echo "mc: installed at ${MC_BIN}"

# --- Env file (overwritten on every run to reflect current credentials.json) ---
cat > /etc/default/minio <<EOF
# Managed by devvm. To change credentials, use 'devvm creds set minio --pass <new>'.
MINIO_ROOT_USER="${ROOT_USER}"
MINIO_ROOT_PASSWORD="${ROOT_PASS}"
MINIO_VOLUMES="${MINIO_DATA}"
MINIO_OPTS="--address :9000 --console-address :9001"
MINIO_PROMETHEUS_AUTH_TYPE=public
MINIO_BROWSER_REDIRECT_URL=http://dev.orb.local:9001
EOF
chmod 640 /etc/default/minio
chown root:"${MINIO_GROUP}" /etc/default/minio

# --- systemd unit ---
if [ -f /opt/dev-vm/systemd/minio.service ]; then
    cp /opt/dev-vm/systemd/minio.service /etc/systemd/system/minio.service
    systemctl daemon-reload
fi

# Enable + (re)start. Restart picks up env-file changes on re-runs.
if systemctl is-active --quiet minio; then
    systemctl restart minio
else
    systemctl enable --now minio
fi

# --- Wait for ready, then bootstrap default bucket ---
ready=0
for _ in 1 2 3 4 5 6 7 8 9 10 11 12; do
    if curl -fs http://127.0.0.1:9000/minio/health/live &>/dev/null; then
        ready=1; break
    fi
    sleep 1
done

if [ "${ready}" = "1" ]; then
    # Use MC_HOST inline; avoids polluting any user's ~/.mc/config.json
    MC_HOST_local="http://${ROOT_USER}:${ROOT_PASS}@127.0.0.1:9000" \
        "${MC_BIN}" mb --ignore-existing local/dev >/dev/null 2>&1 || true
    echo "MinIO ready (default bucket: dev)"
else
    echo "WARN: MinIO started but health check timed out — check 'journalctl -u minio'"
fi

echo "=== MinIO done ==="
echo "  API:     http://localhost:9000"
echo "  Console: http://localhost:9001"
echo "  User:    ${ROOT_USER}"
