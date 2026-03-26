#!/bin/bash
set -euo pipefail

echo "==> Installing tools..."

ARCH="$(dpkg --print-architecture)"

# mitmproxy: install on demand with `devvm exec pip3 install mitmproxy`

# --- dive (Docker image explorer) ---
echo "--- Installing dive ---"
if ! command -v dive &>/dev/null; then
    DIVE_VERSION="0.12.0"
    curl -fsSL --retry 3 -o /tmp/dive.deb \
        "https://github.com/wagoodman/dive/releases/download/v${DIVE_VERSION}/dive_${DIVE_VERSION}_linux_${ARCH}.deb" 2>/dev/null && \
    dpkg -i /tmp/dive.deb 2>/dev/null && \
    rm -f /tmp/dive.deb || echo "dive: install from GitHub failed, try 'apt install dive' manually"
fi

# --- ctop (container top) ---
echo "--- Installing ctop ---"
if ! command -v ctop &>/dev/null; then
    CTOP_VERSION="0.7.7"
    CTOP_ARCH="$ARCH"
    [ "$CTOP_ARCH" = "arm64" ] && CTOP_ARCH="arm64"
    [ "$CTOP_ARCH" = "amd64" ] && CTOP_ARCH="amd64"
    curl -fsSL --retry 3 -o /usr/local/bin/ctop \
        "https://github.com/bcicen/ctop/releases/download/v${CTOP_VERSION}/ctop-${CTOP_VERSION}-linux-${CTOP_ARCH}" 2>/dev/null && \
    chmod +x /usr/local/bin/ctop || echo "ctop: install failed"
fi

# --- Prometheus node_exporter ---
echo "--- Installing node_exporter ---"
if ! command -v node_exporter &>/dev/null; then
    NODE_EXPORTER_VERSION="1.7.0"
    NE_ARCH="$ARCH"
    [ "$NE_ARCH" = "arm64" ] && NE_ARCH="arm64"
    [ "$NE_ARCH" = "amd64" ] && NE_ARCH="amd64"
    cd /tmp
    curl -fsSL --retry 3 -o node_exporter.tar.gz \
        "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-${NE_ARCH}.tar.gz"
    tar xzf node_exporter.tar.gz
    cp "node_exporter-${NODE_EXPORTER_VERSION}.linux-${NE_ARCH}/node_exporter" /usr/local/bin/
    chmod +x /usr/local/bin/node_exporter
    rm -rf node_exporter*
fi

echo "==> Tools installed."
