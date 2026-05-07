# DevVM

Your entire dev infrastructure in one command. An Ubuntu VM on [OrbStack](https://orbstack.dev) with six language stacks, three databases, Grafana observability, and app hosting with Nginx — all managed through `devvm`.

## Quick Start

```bash
brew tap indranandjha1993/tap && brew install devvm   # or: git clone + sudo make install

devvm init       # creates VM, installs everything (~5 min)
devvm status     # see what's running
```

Done. You now have Node.js, Python, PHP, Go, Rust, Java, MySQL, PostgreSQL, Redis, Grafana, Prometheus, and Nginx ready to go.

## Host an App

```bash
# Existing project
devvm app add myapi --path ~/projects/myapi --type fastapi

# Or scaffold a new one
devvm app create blog --template express

# Check it
devvm app list
```

Your app is live at `http://myapi.dev.local` with Nginx, systemd, and Grafana metrics.

## What's Included

| Category | What you get |
|----------|-------------|
| [**Languages**](docs/languages.md) | Node.js 22, Python 3.13, PHP 8.4, Go 1.22, Rust, Java 21 |
| [**Databases**](docs/databases.md) | MySQL :3306, PostgreSQL :5432, Redis :6379, MinIO :9000/:9001, Adminer :8080 |
| [**Observability**](docs/observability.md) | Grafana :3000, Prometheus :9090, Loki :3100, Tempo :3200 — 9 dashboards |
| [**App Hosting**](docs/apps.md) | Nginx reverse proxy — each app gets `appname.dev.local` |
| [**Debugging**](docs/debugging.md) | Remote debuggers for all languages with VS Code configs |

## Install

**Homebrew**
```bash
brew tap indranandjha1993/tap
brew install devvm
```

**From source**
```bash
git clone https://github.com/indranandjha1993/devvm.git
cd dev-vm
sudo make install
```

**Development**
```bash
git clone https://github.com/indranandjha1993/devvm.git
cd dev-vm
sudo make link
```

Requires [OrbStack](https://orbstack.dev) (free for personal use): `brew install orbstack`

---

## CLI

Full reference: [docs/cli.md](docs/cli.md)

```bash
# Lifecycle
devvm init                     # Create VM and install everything
devvm start [stack]            # Start VM or a specific stack
devvm stop [stack]             # Stop VM or a specific stack
devvm restart [stack]          # Restart VM or a specific stack
devvm reset [stack]            # Rebuild VM or reset a stack
devvm destroy                  # Delete VM permanently

# Logs
devvm logs mysql               # Tail any stack's logs
devvm logs grafana

# Apps
devvm app add mysite --path ~/mysite --type laravel
devvm app create api --template fastapi
devvm app list
devvm app remove mysite

# Databases
devvm db mysql                 # Connect to MySQL
devvm db psql                  # Connect to PostgreSQL
devvm db redis                 # Connect to Redis

# Credentials
devvm creds                    # View all (masked)
devvm creds show mysql         # Full details
devvm creds set mysql --pass X # Change password
devvm creds reset mysql        # Reset to defaults

# Debug
devvm debug python app.py      # Start remote debugger
devvm debug node server.js

# Access
devvm ssh                      # Shell into VM
devvm run node --version       # Run as user
devvm exec systemctl status    # Run as root
devvm open grafana             # Open web UI
devvm status                   # Show everything
devvm verify                   # Health check
```

**Stacks**: `mysql`, `postgres`, `redis`, `minio`, `nginx`, `grafana`, `prometheus`, `loki`, `tempo`, `promtail`, `cadvisor`, `obs`, or any app name.

---

## Documentation

| Guide | What it covers |
|-------|---------------|
| [Languages](docs/languages.md) | Node.js, Python, PHP, Go, Rust, Java — versions, tools, usage |
| [Databases](docs/databases.md) | MySQL, PostgreSQL, Redis — connect, manage, credentials |
| [Observability](docs/observability.md) | Grafana, Prometheus, Loki, Tempo — dashboards, metrics, logs, traces |
| [App Hosting](docs/apps.md) | Register, scaffold, and manage apps with Nginx |
| [Debugging](docs/debugging.md) | Remote debuggers for all languages with VS Code |
| [CLI Reference](docs/cli.md) | All commands |
| [Releasing](docs/releasing.md) | Push code, tag, update Homebrew |

## Troubleshooting

```bash
devvm verify                 # Check all components
devvm logs mysql             # Check service logs
devvm logs grafana           # Check container logs
devvm restart mysql          # Restart a stack
devvm reset                  # Full rebuild (last resort)
orb doctor                   # Check OrbStack health
```

## License

MIT
