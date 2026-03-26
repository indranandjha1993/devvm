#!/bin/bash
# Verification script - runs inside the VM
set -uo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

check() {
    local name="$1"
    local cmd="$2"
    if eval "$cmd" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $name"
        ((PASS++))
    else
        echo -e "  ${RED}✗${NC} $name"
        ((FAIL++))
    fi
}

check_version() {
    local name="$1"
    local cmd="$2"
    local version
    version=$(eval "$cmd" 2>/dev/null | head -1) || version="not found"
    if [ "$version" != "not found" ] && [ -n "$version" ]; then
        echo -e "  ${GREEN}✓${NC} $name: $version"
        ((PASS++))
    else
        echo -e "  ${RED}✗${NC} $name: not found"
        ((FAIL++))
    fi
}

check_port() {
    local name="$1"
    local port="$2"
    if ss -tlnp 2>/dev/null | grep -q ":${port} " || netstat -tlnp 2>/dev/null | grep -q ":${port} "; then
        echo -e "  ${GREEN}✓${NC} $name (port $port)"
        ((PASS++))
    else
        echo -e "  ${RED}✗${NC} $name (port $port not listening)"
        ((FAIL++))
    fi
}

check_service() {
    local name="$1"
    local status
    status=$(systemctl is-active "$name" 2>/dev/null || echo "inactive")
    if [ "$status" = "active" ]; then
        echo -e "  ${GREEN}✓${NC} $name (active)"
        ((PASS++))
    else
        echo -e "  ${YELLOW}○${NC} $name ($status)"
        ((WARN++))
    fi
}

echo -e "${BOLD}============================================${NC}"
echo -e "${BOLD}  Dev VM Health Check${NC}"
echo -e "${BOLD}============================================${NC}"
echo ""

# Source PATH for tools installed outside apt
export FNM_DIR="/usr/local/share/fnm"
eval "$(fnm env --shell bash 2>/dev/null)" || true
export PATH="/usr/local/go/bin:$HOME/go/bin:$PATH"

echo -e "${BOLD}Language Runtimes:${NC}"
check_version "Node.js" "node --version"
check_version "Python"  "python3 --version"
check_version "PHP"     "php -v"
check_version "Go"      "go version"
check_version "Java"    "java --version"

# Rust is installed for user, not root
DEFAULT_USER="${SUDO_USER:-$(logname 2>/dev/null || echo indranandjha)}"
RUST_VER=$(sudo -u "$DEFAULT_USER" bash -c 'source "$HOME/.cargo/env" 2>/dev/null; rustc --version' 2>/dev/null || echo "")
if [ -n "$RUST_VER" ]; then
    echo -e "  ${GREEN}✓${NC} Rust: $RUST_VER"
    ((PASS++))
else
    echo -e "  ${RED}✗${NC} Rust: not found"
    ((FAIL++))
fi

echo ""
echo -e "${BOLD}Package Managers:${NC}"
check_version "pnpm"     "pnpm --version 2>/dev/null || npm ls -g pnpm --depth=0 2>/dev/null"
check_version "Composer" "composer --version"
check         "Poetry"   "sudo -u $DEFAULT_USER bash -c 'export PATH=\$HOME/.local/bin:\$PATH; poetry --version'"
check         "uv"       "sudo -u $DEFAULT_USER bash -c 'export PATH=\$HOME/.local/bin:\$PATH; uv --version'"

echo ""
echo -e "${BOLD}System Services:${NC}"
check_service "mysql"
check_service "postgresql"
check_service "redis-server"
check_service "docker"

echo ""
echo -e "${BOLD}Database Ports:${NC}"
check_port "MySQL"      3306
check_port "PostgreSQL" 5432
check_port "Redis"      6379
check_port "Adminer"    8080

echo ""
echo -e "${BOLD}Observability (Docker):${NC}"
for container in grafana prometheus loki tempo promtail; do
    status=$(docker inspect -f '{{.State.Status}}' "$container" 2>/dev/null || echo "not found")
    if [ "$status" = "running" ]; then
        echo -e "  ${GREEN}✓${NC} $container (running)"
        ((PASS++))
    else
        echo -e "  ${RED}✗${NC} $container ($status)"
        ((FAIL++))
    fi
done

echo ""
echo -e "${BOLD}Observability Ports:${NC}"
check_port "Grafana"    3000
check_port "Prometheus" 9090
check_port "Loki"       3100
check_port "Tempo"      3200

echo ""
echo -e "${BOLD}Debug Helpers:${NC}"
check "python-debug" "which python-debug"
check "node-debug"   "which node-debug"
check "go-debug"     "which go-debug"
check "java-debug"   "which java-debug"

echo ""
echo -e "${BOLD}Additional Tools:${NC}"
check "Docker"    "docker ps"
check "httpie"    "which http"
check "curl"      "which curl"
check "jq"        "which jq"
check "tmux"      "which tmux"
check "git"       "which git"

echo ""
echo -e "${BOLD}Connectivity:${NC}"
check "Grafana API"    "curl -sf http://localhost:3000/api/health"
check "Prometheus API" "curl -sf http://localhost:9090/-/healthy"

echo ""
echo -e "${BOLD}============================================${NC}"
echo -e "  ${GREEN}Passed: $PASS${NC}  ${RED}Failed: $FAIL${NC}  ${YELLOW}Warnings: $WARN${NC}"
echo -e "${BOLD}============================================${NC}"

if [ $FAIL -gt 0 ]; then
    exit 1
fi
