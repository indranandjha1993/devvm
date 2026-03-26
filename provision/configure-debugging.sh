#!/bin/bash
set -euo pipefail

echo "==> Configuring debugging tools..."

# --- Xdebug (PHP) ---
echo "--- Configuring Xdebug ---"
XDEBUG_INI=$(find /etc/php -name "xdebug.ini" -path "*/mods-available/*" 2>/dev/null | head -1)
if [ -z "$XDEBUG_INI" ]; then
    PHP_VER=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null || echo "8.4")
    XDEBUG_INI="/etc/php/${PHP_VER}/mods-available/xdebug.ini"
fi

cat > "$XDEBUG_INI" << 'XDEBUG_EOF'
zend_extension=xdebug.so
xdebug.mode=debug
xdebug.start_with_request=trigger
xdebug.client_host=host.internal
xdebug.client_port=9003
xdebug.log=/var/log/xdebug.log
xdebug.idekey=VSCODE
XDEBUG_EOF

# Enable xdebug for CLI and FPM
phpenmod xdebug 2>/dev/null || true
echo "Xdebug: configured (port 9003, trigger mode)"

# --- debugpy (Python) ---
echo "--- Creating Python debug helper ---"
cat > /usr/local/bin/python-debug << 'PYDEBUG_EOF'
#!/bin/bash
# Usage: python-debug <script.py> [args...]
# Then attach VS Code debugger to dev.orb.local:5678
set -euo pipefail

if [ $# -eq 0 ]; then
    echo "Usage: python-debug <script.py> [args...]"
    echo "  Starts debugpy on port 5678, waiting for VS Code to attach."
    echo "  In VS Code, use the 'Python: Remote Attach' debug config."
    exit 1
fi

echo "Starting debugpy on port 5678... Waiting for VS Code debugger to attach."
echo "Connect from Mac: VS Code -> Run & Debug -> 'Python: Remote Attach (dev VM)'"
python3 -m debugpy --listen 0.0.0.0:5678 --wait-for-client "$@"
PYDEBUG_EOF
chmod +x /usr/local/bin/python-debug

# --- Node.js Inspector ---
echo "--- Creating Node.js debug helper ---"
cat > /usr/local/bin/node-debug << 'NODEDEBUG_EOF'
#!/bin/bash
# Usage: node-debug <script.js> [args...]
# Then attach VS Code debugger to dev.orb.local:9229
set -euo pipefail

if [ $# -eq 0 ]; then
    echo "Usage: node-debug <script.js> [args...]"
    echo "  Starts Node with --inspect on port 9229."
    echo "  In VS Code, use the 'Node: Remote Attach' debug config."
    exit 1
fi

echo "Starting Node inspector on port 9229..."
echo "Connect from Mac: VS Code -> Run & Debug -> 'Node: Remote Attach (dev VM)'"

# Source fnm if available
export FNM_DIR="/usr/local/share/fnm"
eval "$(fnm env --shell bash 2>/dev/null)" || true

node --inspect=0.0.0.0:9229 "$@"
NODEDEBUG_EOF
chmod +x /usr/local/bin/node-debug

# --- Go Delve ---
echo "--- Creating Go debug helper ---"
cat > /usr/local/bin/go-debug << 'GODEBUG_EOF'
#!/bin/bash
# Usage: go-debug [package-or-binary] [args...]
# Then attach VS Code debugger to dev.orb.local:2345
set -euo pipefail

export PATH="/usr/local/go/bin:$HOME/go/bin:$PATH"

if [ $# -eq 0 ]; then
    echo "Usage: go-debug [package-path] [-- args...]"
    echo "  Starts Delve headless debugger on port 2345."
    echo "  In VS Code, use the 'Go: Remote Attach (dev VM)' debug config."
    exit 1
fi

echo "Starting Delve on port 2345... Waiting for VS Code debugger to attach."
echo "Connect from Mac: VS Code -> Run & Debug -> 'Go: Remote Attach (dev VM)'"
dlv debug --headless --listen=:2345 --api-version=2 --accept-multiclient "$@"
GODEBUG_EOF
chmod +x /usr/local/bin/go-debug

# --- Java JDWP ---
echo "--- Creating Java debug helper ---"
cat > /usr/local/bin/java-debug << 'JAVADEBUG_EOF'
#!/bin/bash
# Usage: java-debug <MainClass-or-jar> [args...]
# Then attach VS Code debugger to dev.orb.local:5005
set -euo pipefail

if [ $# -eq 0 ]; then
    echo "Usage: java-debug <MainClass-or-jar> [args...]"
    echo "  Starts JVM with JDWP on port 5005, suspended."
    echo "  In VS Code, use the 'Java: Remote Attach (dev VM)' debug config."
    exit 1
fi

TARGET="$1"
shift

echo "Starting JVM with JDWP on port 5005... Waiting for debugger to attach."
echo "Connect from Mac: VS Code -> Run & Debug -> 'Java: Remote Attach (dev VM)'"

if [[ "$TARGET" == *.jar ]]; then
    java -agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=*:5005 -jar "$TARGET" "$@"
else
    java -agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=*:5005 "$TARGET" "$@"
fi
JAVADEBUG_EOF
chmod +x /usr/local/bin/java-debug

echo "==> All debug helpers installed."
