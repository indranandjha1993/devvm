#!/bin/bash
set -euo pipefail

echo "==> Installing Nginx..."

if ! command -v nginx &>/dev/null; then
  apt-get update -qq
  apt-get install -y -qq nginx > /dev/null
fi

# Setup sites structure
mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled

# Remove default site
rm -f /etc/nginx/sites-enabled/default

# Base config: catch-all returns 404, include sites-enabled
cat > /etc/nginx/conf.d/devvm.conf << 'NGINX'
# DevVM: app reverse proxy configs are in /etc/nginx/sites-enabled/
# Each app gets NAME.dev.local -> localhost:PORT

server {
    listen 80 default_server;
    server_name _;
    return 404;
}
NGINX

# Include sites-enabled in main config if not already
if ! grep -q "sites-enabled" /etc/nginx/nginx.conf 2>/dev/null; then
  sed -i '/http {/a\    include /etc/nginx/sites-enabled/*.conf;' /etc/nginx/nginx.conf
fi

nginx -t 2>/dev/null
systemctl enable nginx
systemctl restart nginx

echo "==> Nginx installed and running on :80"
