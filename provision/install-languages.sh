#!/bin/bash
set -euo pipefail

echo "==> Installing language stacks..."

DEFAULT_USER="${SUDO_USER:-$(logname 2>/dev/null || echo indranandjha)}"
DEFAULT_HOME="/home/${DEFAULT_USER}"

# --- Node.js 22+ via fnm ---
echo "--- Installing Node.js via fnm ---"
if ! command -v fnm &>/dev/null; then
    curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir /usr/local/bin --skip-shell
fi

# Set up fnm for all users
cat > /etc/profile.d/fnm.sh << 'FNMEOF'
export FNM_DIR="/usr/local/share/fnm"
eval "$(fnm env --shell bash)"
FNMEOF

export FNM_DIR="/usr/local/share/fnm"
mkdir -p "$FNM_DIR"
export PATH="/usr/local/bin:$PATH"
eval "$(fnm env --shell bash)" || true

fnm install 22 || true
fnm default 22 || true
fnm use 22 || true

# Install global npm packages
npm install -g pnpm typescript tsx ts-node || true
echo "Node.js: $(node --version 2>/dev/null || echo 'pending shell reload')"

# --- Python (already from apt) ---
echo "--- Configuring Python ---"
python3 -m pip install --break-system-packages pipx 2>/dev/null || python3 -m pip install pipx 2>/dev/null || true
export PATH="/root/.local/bin:$PATH"
pipx install poetry 2>/dev/null || true
pipx install uv 2>/dev/null || true
pipx install debugpy 2>/dev/null || true

# Also install for the default user
sudo -u "$DEFAULT_USER" bash -c '
    python3 -m pip install --break-system-packages pipx 2>/dev/null || python3 -m pip install pipx 2>/dev/null || true
    export PATH="$HOME/.local/bin:$PATH"
    pipx install poetry 2>/dev/null || true
    pipx install uv 2>/dev/null || true
    pipx install debugpy 2>/dev/null || true
' || true

cat > /etc/profile.d/python-tools.sh << 'PYEOF'
export PATH="$HOME/.local/bin:$PATH"
PYEOF

echo "Python: $(python3 --version)"

# --- PHP (already from apt, install Composer + Laravel) ---
echo "--- Installing Composer & Laravel ---"
if ! command -v composer &>/dev/null; then
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
fi
cat > /etc/profile.d/composer.sh << 'COMPEOF'
export PATH="$HOME/.config/composer/vendor/bin:$HOME/.composer/vendor/bin:$PATH"
COMPEOF

echo "PHP: $(php -v | head -1)"
echo "Composer: $(composer --version 2>/dev/null || echo 'installed')"

# --- Go 1.22+ ---
echo "--- Installing Go ---"
GO_VERSION="1.22.5"
ARCH="$(dpkg --print-architecture)"
if [ ! -d /usr/local/go ]; then
    curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz" | tar -C /usr/local -xz
fi

cat > /etc/profile.d/go.sh << 'GOEOF'
export PATH="/usr/local/go/bin:$HOME/go/bin:$PATH"
export GOPATH="$HOME/go"
GOEOF

export PATH="/usr/local/go/bin:$HOME/go/bin:$PATH"
export GOPATH="/root/go"

# Go tools installed on first use: go install golang.org/x/tools/gopls@latest
# go install github.com/go-delve/delve/cmd/dlv@latest

echo "Go: $(go version)"

# --- Rust ---
echo "--- Installing Rust ---"
sudo -u "$DEFAULT_USER" bash -c '
    if ! command -v rustc &>/dev/null; then
        curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path --profile minimal
    fi
' || true

cat > /etc/profile.d/rust.sh << 'RUSTEOF'
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
RUSTEOF

echo "Rust: installed for $DEFAULT_USER"

# --- Java (already from apt) ---
echo "--- Configuring Java ---"
JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
cat > /etc/profile.d/java.sh << JAVAEOF
export JAVA_HOME="${JAVA_HOME}"
export PATH="\$JAVA_HOME/bin:\$PATH"
JAVAEOF

echo "Java: $(java --version 2>&1 | head -1)"

echo "==> All language stacks installed."
