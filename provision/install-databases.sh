#!/bin/bash
set -euo pipefail

echo "==> Configuring databases..."

# --- MySQL ---
echo "--- Configuring MySQL ---"
systemctl start mysql || true

# Bind to all interfaces
if ! grep -q "^bind-address.*0.0.0.0" /etc/mysql/mysql.conf.d/mysqld.cnf 2>/dev/null; then
    sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf 2>/dev/null || true
fi

systemctl restart mysql || true

# Create dev user and database
mysql -u root << 'MYSQL_EOF' 2>/dev/null || true
CREATE DATABASE IF NOT EXISTS devdb;
CREATE USER IF NOT EXISTS 'dev'@'%' IDENTIFIED BY 'dev';
GRANT ALL PRIVILEGES ON *.* TO 'dev'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
MYSQL_EOF

echo "MySQL: configured (dev/dev on port 3306)"

# --- PostgreSQL ---
echo "--- Configuring PostgreSQL ---"
systemctl start postgresql || true

PG_VERSION=$(ls /etc/postgresql/ 2>/dev/null | head -1 || echo "16")
PG_CONF="/etc/postgresql/${PG_VERSION}/main"

# Listen on all interfaces
if [ -f "${PG_CONF}/postgresql.conf" ]; then
    sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "${PG_CONF}/postgresql.conf"
fi

# Allow remote connections with password
if [ -f "${PG_CONF}/pg_hba.conf" ]; then
    if ! grep -q "host.*all.*all.*0.0.0.0/0.*md5" "${PG_CONF}/pg_hba.conf"; then
        echo "host all all 0.0.0.0/0 md5" >> "${PG_CONF}/pg_hba.conf"
    fi
fi

systemctl restart postgresql || true

# Create dev user and database
sudo -u postgres psql -c "CREATE USER dev WITH PASSWORD 'dev' SUPERUSER;" 2>/dev/null || true
sudo -u postgres psql -c "CREATE DATABASE devdb OWNER dev;" 2>/dev/null || true

echo "PostgreSQL: configured (dev/dev on port 5432, db: devdb)"

# --- Redis ---
echo "--- Configuring Redis ---"
REDIS_CONF="/etc/redis/redis.conf"
if [ -f "$REDIS_CONF" ]; then
    sed -i 's/^bind 127.0.0.1.*/bind 0.0.0.0/' "$REDIS_CONF"
    sed -i 's/^protected-mode yes/protected-mode no/' "$REDIS_CONF"
fi
systemctl restart redis-server || true

echo "Redis: configured (port 6379, no auth)"

# --- Adminer ---
echo "--- Installing Adminer ---"
mkdir -p /opt/adminer
if [ ! -f /opt/adminer/index.php ]; then
    curl -fsSL -o /opt/adminer/index.php \
        "https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php"
fi

echo "Adminer: installed at /opt/adminer"

echo "==> All databases configured."
