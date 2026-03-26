#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VM_NAME="dev"
VM_TARGET="/opt/dev-vm"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}============================================${NC}"
echo -e "${BOLD}  Dev VM Setup - OrbStack${NC}"
echo -e "${BOLD}============================================${NC}"
echo ""

# Check if VM already exists
if orb list 2>/dev/null | grep -q "$VM_NAME"; then
    echo -e "${YELLOW}VM '$VM_NAME' already exists.${NC}"
    read -p "Delete and recreate? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        echo -e "${YELLOW}Deleting existing VM...${NC}"
        orb delete "$VM_NAME" -f
        sleep 2
    else
        echo "Aborting."
        exit 1
    fi
fi

# Step 1: Create VM with cloud-init
echo -e "${CYAN}[1/7] Creating Ubuntu VM with cloud-init...${NC}"
orb create ubuntu "$VM_NAME" -c "$SCRIPT_DIR/cloud-init/user-data.yaml"
echo -e "${GREEN}VM created.${NC}"

# Step 2: Wait for cloud-init
echo -e "${CYAN}[2/7] Waiting for cloud-init to finish (this may take a few minutes)...${NC}"
orb -m "$VM_NAME" sudo cloud-init status --wait 2>/dev/null || {
    echo -e "${YELLOW}cloud-init wait timed out, continuing...${NC}"
}
echo -e "${GREEN}Cloud-init complete.${NC}"

# Step 3: Push files to VM
echo -e "${CYAN}[3/7] Pushing provisioning files to VM...${NC}"
orb -m "$VM_NAME" sudo mkdir -p "$VM_TARGET"/{provision,observability,systemd}
orb -m "$VM_NAME" sudo chmod 777 "$VM_TARGET" "$VM_TARGET"/{provision,observability,systemd}

# Push each directory
for dir in provision observability systemd; do
    orb push -m "$VM_NAME" "$SCRIPT_DIR/$dir/" "$VM_TARGET/$dir/"
done
orb push -m "$VM_NAME" "$SCRIPT_DIR/verify.sh" "$VM_TARGET/verify.sh"

# Fix ownership and make scripts executable
orb -m "$VM_NAME" sudo chown -R root:root "$VM_TARGET"
orb -m "$VM_NAME" sudo chmod +x "$VM_TARGET/provision/"*.sh "$VM_TARGET/verify.sh"
echo -e "${GREEN}Files pushed.${NC}"

# Step 4: Run provisioning
echo -e "${CYAN}[4/7] Running language & tool provisioning (this takes several minutes)...${NC}"
orb -m "$VM_NAME" sudo bash "$VM_TARGET/provision/post-init.sh"
echo -e "${GREEN}Provisioning complete.${NC}"

# Step 5: Install systemd services
echo -e "${CYAN}[5/7] Installing systemd services...${NC}"
orb -m "$VM_NAME" sudo cp "$VM_TARGET/systemd/"*.service /etc/systemd/system/
orb -m "$VM_NAME" sudo systemctl daemon-reload
orb -m "$VM_NAME" sudo systemctl enable --now node-exporter || true
orb -m "$VM_NAME" sudo systemctl enable --now adminer || true
echo -e "${GREEN}Services installed.${NC}"

# Step 6: Start observability stack
echo -e "${CYAN}[6/7] Starting observability stack (Grafana + Prometheus + Loki + Tempo)...${NC}"
orb -m "$VM_NAME" docker compose -f "$VM_TARGET/observability/docker-compose.yml" up -d
echo -e "${GREEN}Observability stack running.${NC}"

# Step 7: Install CLI and verify
echo -e "${CYAN}[7/7] Installing CLI wrapper...${NC}"
chmod +x "$SCRIPT_DIR/cli/dev"
if ln -sf "$SCRIPT_DIR/cli/dev" /usr/local/bin/dev 2>/dev/null; then
    echo -e "${GREEN}CLI installed at /usr/local/bin/dev${NC}"
else
    echo -e "${YELLOW}Could not symlink to /usr/local/bin/dev (try: sudo ln -sf $SCRIPT_DIR/cli/dev /usr/local/bin/dev)${NC}"
    echo -e "${YELLOW}Or add $SCRIPT_DIR/cli to your PATH.${NC}"
fi

# Run verification
echo ""
echo -e "${CYAN}Running health check...${NC}"
echo ""
orb -m "$VM_NAME" sudo bash "$VM_TARGET/verify.sh" || true

echo ""
echo -e "${BOLD}============================================${NC}"
echo -e "${BOLD}  Setup Complete!${NC}"
echo -e "${BOLD}============================================${NC}"
echo ""
echo -e "${BOLD}Quick Start:${NC}"
echo "  dev ssh                    Open VM shell"
echo "  dev status                 Check everything"
echo "  dev grafana                Open Grafana dashboards"
echo "  dev adminer                Open database admin UI"
echo ""
echo -e "${BOLD}Access URLs:${NC}"
echo "  Grafana:    http://dev.orb.local:3000  (admin/admin)"
echo "  Prometheus: http://dev.orb.local:9090"
echo "  Adminer:    http://dev.orb.local:8080"
echo ""
echo -e "${BOLD}Databases:${NC}"
echo "  MySQL:      dev.orb.local:3306  (user: dev / pass: dev)"
echo "  PostgreSQL: dev.orb.local:5432  (user: dev / pass: dev / db: devdb)"
echo "  Redis:      dev.orb.local:6379"
echo ""
echo -e "${BOLD}Debugging:${NC}"
echo "  dev debug python script.py    Start Python debugger"
echo "  dev debug node app.js         Start Node.js debugger"
echo "  dev debug php                 Xdebug instructions"
echo "  dev debug go ./cmd/app        Start Go debugger"
echo ""
echo "  VS Code configs: $SCRIPT_DIR/vscode/launch.json"
echo "  Run 'dev help' for all commands."
