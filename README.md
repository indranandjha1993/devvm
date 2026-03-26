# DevVM

A single-command developer machine on macOS. Runs an Ubuntu VM via [OrbStack](https://orbstack.dev) with six language stacks, three databases, full observability, and remote debugging — all managed through one CLI.

```
devvm up        # start everything
devvm status    # see what's running
devvm db mysql  # connect to MySQL
devvm ssh       # shell into the VM
```

## What's Inside

### Language Stacks

| Stack | Version | Included |
|-------|---------|----------|
| Node.js | 22 | pnpm, TypeScript, tsx |
| Python | 3.13 | pip, Poetry, uv, debugpy |
| PHP | 8.4 | Composer, Laravel, Xdebug |
| Go | 1.22 | gopls, Delve |
| Rust | latest | rust-analyzer |
| Java | 21 | OpenJDK |

### Databases

| Database | Port | Credentials |
|----------|------|-------------|
| MySQL | 3306 | `dev` / `dev` |
| PostgreSQL | 5432 | `dev` / `dev` / db: `devdb` |
| Redis | 6379 | no auth |
| Adminer (web UI) | 8080 | — |

### Observability (Grafana LGTM Stack)

| Service | Port | Purpose |
|---------|------|---------|
| Grafana | 3000 | Dashboards and exploration |
| Prometheus | 9090 | Metrics collection |
| Loki | 3100 | Log aggregation |
| Tempo | 3200 | Distributed tracing (OTLP on 4317) |

**9 pre-configured dashboards**: System Metrics, Docker/Services, MySQL, PostgreSQL, Redis, Node.js, Python, PHP, Logs Explorer.

**6 Prometheus exporters** scraping automatically: node_exporter, mysqld_exporter, postgres_exporter, redis_exporter, cAdvisor, Promtail.

### Remote Debugging

| Language | Tool | Port | VS Code Config |
|----------|------|------|----------------|
| PHP | Xdebug | 9003 | `PHP: Xdebug (dev VM)` |
| Python | debugpy | 5678 | `Python: Remote Attach (dev VM)` |
| Node.js | Inspector | 9229 | `Node: Remote Attach (dev VM)` |
| Go | Delve | 2345 | `Go: Remote Attach (dev VM)` |
| Java | JDWP | 5005 | `Java: Remote Attach (dev VM)` |

Pre-built VS Code launch configurations are in `vscode/launch.json`.

---

## Prerequisites

- **macOS** (Apple Silicon or Intel)
- **[OrbStack](https://orbstack.dev)** (free for personal use) — install via `brew install orbstack` or from the website

## Installation

### Quick Start (from source)

```bash
git clone https://github.com/indranandjha/dev-vm.git
cd dev-vm
sudo make install
```

### Development (symlink)

```bash
git clone https://github.com/indranandjha/dev-vm.git
cd dev-vm
sudo make link    # symlinks cli/dev -> /usr/local/bin/devvm
```

### Homebrew

```bash
brew tap indranandjha/tap
brew install devvm
```

### Manual

```bash
sudo ln -sf /path/to/dev-vm/cli/dev /usr/local/bin/devvm
```

## Setup

```bash
# 1. Create the VM
devvm init

# 2. Install all stacks, databases, and observability
devvm provision

# 3. Verify everything works
devvm verify
```

The full provision takes 5-10 minutes on first run. After that, `devvm up` starts everything in seconds.

---

## CLI Reference

### Machine Lifecycle

```bash
devvm init [cloud-init.yaml]   # Create VM (optional custom cloud-init)
devvm provision                # Install stacks, databases, observability
devvm up                       # Start VM + all services
devvm down                     # Stop VM
devvm restart                  # Stop + start
devvm reboot                   # Graceful in-VM reboot (preserves data)
devvm destroy                  # Delete VM and all data permanently
```

### Accessing the VM

```bash
devvm ssh                      # Interactive shell
devvm ssh ls /opt              # Run a single command
devvm run node --version       # Run command as user
devvm exec systemctl status    # Run command as root
```

### Service Management

```bash
devvm status                   # Overview of everything
devvm service start mysql      # Start a systemd service
devvm service stop redis-server
devvm service restart postgresql
devvm service status mysql     # Detailed systemd status
devvm service logs demo-node   # Tail service logs (journalctl)
```

### Observability

```bash
devvm obs up                   # Start Grafana + Prometheus + Loki + Tempo
devvm obs down                 # Stop the stack
devvm obs restart              # Restart all containers
devvm obs restart grafana      # Restart one container
devvm obs logs                 # Tail all logs
devvm obs logs prometheus      # Tail one service
devvm obs status               # Check container states
```

### Web UIs

```bash
devvm open grafana             # http://dev.orb.local:3000
devvm open adminer             # http://dev.orb.local:8080
devvm open prometheus          # http://dev.orb.local:9090
```

Grafana is pre-configured with anonymous Editor access — no login required. To make admin changes, login with `admin` / `admin`.

### Databases

```bash
devvm db mysql                 # mysql -u dev -pdev
devvm db psql                  # psql -U dev devdb
devvm db redis                 # redis-cli
```

You can also connect from your Mac using any database client:

| Database | Host | Port | User | Password | Database |
|----------|------|------|------|----------|----------|
| MySQL | `dev.orb.local` | 3306 | `dev` | `dev` | — |
| PostgreSQL | `dev.orb.local` | 5432 | `dev` | `dev` | `devdb` |
| Redis | `dev.orb.local` | 6379 | — | — | — |

### Debugging

```bash
devvm debug python app.py      # Start debugpy, waiting for VS Code
devvm debug node server.js     # Start Node inspector
devvm debug php                # Show Xdebug trigger instructions
devvm debug go ./cmd/myapp     # Start Delve headless
devvm debug java MyApp.jar     # Start JVM with JDWP
```

Then attach from VS Code using the configs in `vscode/launch.json`.

**Path mappings work automatically** — OrbStack mounts your Mac home directory at the same path inside the VM, so `/Users/you/project` on Mac = `/Users/you/project` in the VM.

### Info

```bash
devvm ports                    # Show all ports and access URLs
devvm verify                   # Run health check on all components
devvm version                  # Show version
devvm help                     # Show all commands
```

---

## Grafana Dashboards

All dashboards are at **http://dev.orb.local:3000/dashboards** and have live data out of the box.

| Dashboard | URL | Data Source |
|-----------|-----|-------------|
| System Metrics | `/d/system-metrics` | node_exporter |
| Services & Containers | `/d/docker` | cAdvisor |
| MySQL | `/d/mysql` | mysqld_exporter |
| PostgreSQL | `/d/postgresql` | postgres_exporter |
| Redis | `/d/redis` | redis_exporter |
| Logs Explorer | `/d/logs` | Loki |
| Node.js Application | `/d/nodejs` | App metrics (prom-client) |
| Python Application | `/d/python` | App metrics (prometheus_client) |
| PHP Application | `/d/php-fpm` | App metrics |

### Adding Your App Metrics

**Node.js** — install `prom-client`, expose `/metrics`:
```javascript
const client = require('prom-client');
client.collectDefaultMetrics();
// Serve client.register.metrics() at /metrics
```

**Python** — install `prometheus_client`, expose `/metrics`:
```python
from prometheus_client import start_http_server
start_http_server(8000)  # Exposes /metrics on port 8000
```

Then add a scrape job to `observability/prometheus/prometheus.yml`:
```yaml
- job_name: "my-app"
  static_configs:
    - targets: ["host.docker.internal:YOUR_PORT"]
```

Reload Prometheus:
```bash
devvm exec docker exec prometheus kill -HUP 1
```

### Sending Traces (OpenTelemetry)

Send OTLP traces to Tempo:
```
OTEL_EXPORTER_OTLP_ENDPOINT=http://dev.orb.local:4317
```

### Querying Logs (Loki)

In Grafana Explore, select **Loki** and use LogQL:
```
{job="syslog"}                          # System logs
{job="mysql"}                           # MySQL logs
{job="docker"}                          # Docker container logs
{job="syslog"} |= "error"              # Filter for errors
rate({job="syslog"}[5m])                # Log rate over time
```

---

## Architecture

```
Mac (macOS)
  |
  |-- devvm CLI (/usr/local/bin/devvm)
  |     Controls everything via `orb` commands
  |
  |-- OrbStack
        |
        |-- Ubuntu VM "dev"
              |
              |-- Systemd Services
              |     mysql, postgresql, redis-server
              |     node-exporter, mysqld-exporter, postgres-exporter, redis-exporter
              |     adminer (PHP built-in server on :8080)
              |
              |-- Docker Containers (via docker-compose)
              |     grafana, prometheus, loki, tempo, promtail, cadvisor
              |
              |-- Language Runtimes
              |     node (fnm), python3, php, go, rustc, java
              |
              |-- Debug Helpers
                    python-debug, node-debug, go-debug, java-debug
```

Your Mac home directory is mounted inside the VM at the same path. All services are accessible at `dev.orb.local:<port>`.

## File Structure

```
dev-vm/
├── cli/dev                     # The devvm CLI (bash)
├── cloud-init/user-data.yaml   # VM bootstrap config
├── completions/                # Bash + Zsh tab completion
├── demo-apps/                  # Sample apps with Prometheus metrics
│   ├── node/                   #   Express + prom-client
│   ├── python/                 #   stdlib + prometheus_client
│   └── php/                    #   Built-in server + custom metrics
├── homebrew/devvm.rb           # Homebrew formula
├── Makefile                    # install / uninstall / link
├── observability/
│   ├── docker-compose.yml      # Grafana, Prometheus, Loki, Tempo, Promtail, cAdvisor
│   ├── grafana/                # Provisioned datasources + 9 dashboards
│   ├── prometheus/             # Scrape config (9 targets)
│   ├── loki/                   # Storage + retention config
│   ├── tempo/                  # OTLP receiver config
│   └── promtail/               # Log collection (system, DB, Docker, apps)
├── provision/
│   ├── post-init.sh            # Master provisioning script
│   ├── install-languages.sh    # Node, Python, PHP, Go, Rust, Java
│   ├── install-databases.sh    # MySQL, PostgreSQL, Redis, Adminer
│   ├── install-exporters.sh    # Prometheus exporters
│   ├── install-tools.sh        # httpie, mitmproxy, dive, ctop
│   └── configure-debugging.sh  # Xdebug, debugpy, helpers
├── setup.sh                    # One-shot setup (init + provision)
├── systemd/                    # Service unit files
├── verify.sh                   # Health check (39 checks)
└── vscode/launch.json          # Debug configs for all languages
```

## Troubleshooting

**VM won't start**
```bash
orb doctor              # Check OrbStack health
devvm init              # Recreate from scratch
```

**Service not running**
```bash
devvm service status mysql        # Check systemd status
devvm service logs mysql          # Check logs
devvm service restart mysql       # Restart it
```

**Observability container failing**
```bash
devvm obs logs tempo              # Check container logs
devvm obs restart tempo           # Restart container
devvm obs down && devvm obs up    # Full restart
```

**Port already in use**
```bash
devvm ports                       # See what's mapped where
lsof -i :3000                    # Check what's using the port on Mac
```

**DNS not resolving `dev.orb.local`**
```bash
ping dev.orb.local               # Should resolve via OrbStack
orb doctor                       # Check OrbStack networking
```

**Provisioning failed mid-way**
```bash
devvm provision                   # Safe to re-run (scripts are idempotent)
```

## License

MIT
