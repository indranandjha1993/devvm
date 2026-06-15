#!/usr/bin/env bash
set -euo pipefail

echo "=== Installing ShortGen Render Service (FFmpeg) ==="

SVC_USER="shortgen"
SVC_GROUP="shortgen"
SVC_HOME="/opt/shortgen-renderer"
REPO_DIR="${REPO_DIR:-/opt/dev-vm}"
FONT_DIR="/usr/share/fonts/truetype/oswald"

# --- System user ---
if ! id "${SVC_USER}" &>/dev/null; then
    groupadd -r "${SVC_GROUP}" 2>/dev/null || true
    useradd -r -g "${SVC_GROUP}" -s /sbin/nologin -d "${SVC_HOME}" -M "${SVC_USER}"
    echo "Created system user ${SVC_USER}"
fi

# --- Dependencies: ffmpeg (with libass) + fontconfig ---
# NEEDRESTART_SUSPEND stops apt from auto-restarting unrelated live services
# (postgres/minio/etc.) when shared libraries are updated.
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_SUSPEND=1
export NEEDRESTART_MODE=l
apt-get update -y
apt-get install -y --no-install-recommends ffmpeg fontconfig curl
echo "ffmpeg: $(ffmpeg -version 2>/dev/null | head -1 || echo 'install failed')"

# --- Oswald font (Google Fonts variable TTF; covers all weights) ---
mkdir -p "${FONT_DIR}"
if [ ! -s "${FONT_DIR}/Oswald.ttf" ]; then
    curl -fsSL --retry 3 -o "${FONT_DIR}/Oswald.ttf" \
        "https://github.com/google/fonts/raw/main/ofl/oswald/Oswald%5Bwght%5D.ttf" || true
    [ -s "${FONT_DIR}/Oswald.ttf" ] || rm -f "${FONT_DIR}/Oswald.ttf"
fi
fc-cache -f "${FONT_DIR}" >/dev/null 2>&1 || true
fc-cache -f >/dev/null 2>&1 || true
# fc-match is what libass resolves with — the reliable "is Oswald usable?" check.
if fc-match Oswald 2>/dev/null | grep -qi oswald; then
    echo "Oswald font: OK"
else
    echo "WARN: Oswald not registered — captions will use the default sans"
fi

# --- Service code ---
mkdir -p "${SVC_HOME}"
cp "${REPO_DIR}/provision/renderer/renderer.py" "${SVC_HOME}/renderer.py"
chown -R "${SVC_USER}:${SVC_GROUP}" "${SVC_HOME}"
chmod 755 "${SVC_HOME}/renderer.py"

# --- systemd unit ---
if [ -f "${REPO_DIR}/systemd/shortgen-renderer.service" ]; then
    cp "${REPO_DIR}/systemd/shortgen-renderer.service" /etc/systemd/system/shortgen-renderer.service
    systemctl daemon-reload
fi

if systemctl is-active --quiet shortgen-renderer; then
    systemctl restart shortgen-renderer
else
    systemctl enable --now shortgen-renderer
fi

# --- Wait for ready ---
ready=0
for _ in $(seq 1 10); do
    if curl -fs http://127.0.0.1:8088/health &>/dev/null; then
        ready=1; break
    fi
    sleep 1
done

if [ "${ready}" = "1" ]; then
    echo "Renderer ready on :8088 (reachable from containers at http://dev.orb.local:8088)"
else
    echo "WARN: renderer started but health check timed out — check 'journalctl -u shortgen-renderer'"
fi

echo "=== ShortGen Render Service done ==="
