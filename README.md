# DevVM

Your entire dev infrastructure in one command. An Ubuntu VM on [OrbStack](https://orbstack.dev) with six language stacks, three databases, Grafana observability, and app hosting with Nginx — all managed through `devvm`.

## Quick Start

```bash
brew tap indranandjha/tap && brew install devvm  # or: git clone + make install

devvm init          # create the VM
devvm provision     # install everything (~5 min first time)
devvm status        # see what's running
```

That's it. You now have Node.js, Python, PHP, Go, Rust, Java, MySQL, PostgreSQL, Redis, Grafana, Prometheus, and Nginx ready to use.

## Host Your First App

```bash
# Option 1: Point to an existing project
devvm app add myapi --path ~/projects/myapi --type fastapi

# Option 2: Scaffold a new one
devvm app create blog --template express

# See what's running
devvm app list
```

Your app is now live at `http://myapi.dev.local` with Nginx reverse proxy, systemd process management, and Grafana metrics.

## What's Included

**Languages**: Node.js 22 (pnpm, TypeScript) / Python 3.13 (Poetry, uv) / PHP 8.4 (Composer, Laravel, Xdebug) / Go 1.22 (Delve) / Rust (rust-analyzer) / Java 21

**Databases**: MySQL :3306 / PostgreSQL :5432 / Redis :6379 / Adminer :8080

**Monitoring**: Grafana :3000 / Prometheus :9090 / Loki :3100 / Tempo :3200 — with 9 pre-built dashboards

**Hosting**: Nginx reverse proxy — each app gets `appname.dev.local`

## Install

**Homebrew**
```bash
brew tap indranandjha/tap
brew install devvm
```

**From source**
```bash
git clone https://github.com/indranandjha/dev-vm.git
cd dev-vm
sudo make install
```

**Development**
```bash
git clone https://github.com/indranandjha/dev-vm.git
cd dev-vm
sudo make link   # symlink, edits take effect immediately
```

Requires [OrbStack](https://orbstack.dev) (free for personal use): `brew install orbstack`

## CLI Reference

### Machine

```bash
devvm init              # Create the VM
devvm provision         # Install all stacks + databases + monitoring
devvm up                # Start VM + all services
devvm down              # Stop VM
devvm restart           # Stop + start
devvm reboot            # Graceful in-VM reboot
devvm destroy           # Delete VM permanently
devvm status            # Show everything
```

### Host Applications

```bash
# Register an existing project
devvm app add mysite --path ~/projects/mysite --type laravel
devvm app add api --path ~/projects/api --type fastapi --port 8005

# Scaffold a new project
devvm app create blog --template express
devvm app create site --template static

# Manage
devvm app list
devvm app start mysite
devvm app stop mysite
devvm app restart mysite
devvm app logs mysite
devvm app remove mysite
```

**Supported app types:**

| Type | How it runs |
|------|------------|
| `laravel` | `php artisan serve` |
| `wordpress` | PHP built-in server |
| `django` | `manage.py runserver` |
| `flask` | `flask run` |
| `fastapi` | `uvicorn` |
| `express` | `node app.js` |
| `nextjs` | `npx next dev` |
| `spring-boot` | `java -jar` |
| `go` | `go run .` |
| `static` | Nginx serves files directly |
| `custom` | Your command via `--cmd` |

**Scaffold templates** (for `devvm app create`): `laravel`, `django`, `flask`, `fastapi`, `express`, `nextjs`, `go-web`, `static`, `wordpress`

### Credentials

```bash
devvm creds                              # List all (passwords masked)
devvm creds show mysql                   # Show MySQL credentials
devvm creds set mysql --pass newpass     # Update password
devvm creds set postgres --user admin --pass secret --db mydb
devvm creds reset mysql                  # Reset to defaults
```

Default credentials:

| Service | User | Password | Database |
|---------|------|----------|----------|
| MySQL | `dev` | `dev` | `devdb` |
| PostgreSQL | `dev` | `dev` | `devdb` |
| Redis | — | (none) | — |
| Grafana | `admin` | `admin` | — |

### Databases

```bash
devvm db mysql          # MySQL shell
devvm db psql           # PostgreSQL shell
devvm db redis          # Redis CLI
```

Connect from any Mac client at `dev.orb.local:PORT` with the credentials above.

### Debugging

```bash
devvm debug python app.py    # debugpy on :5678
devvm debug node server.js   # Node inspector on :9229
devvm debug php              # Xdebug instructions
devvm debug go ./cmd/app     # Delve on :2345
devvm debug java App.jar     # JDWP on :5005
```

Pre-built VS Code launch configs in `vscode/launch.json`. Path mappings work automatically — OrbStack mounts your Mac home at the same path in the VM.

### Monitoring

Open Grafana: `devvm open grafana` or visit http://dev.orb.local:3000

**9 dashboards** with live data:
- System Metrics, Services & Containers
- MySQL, PostgreSQL, Redis
- Node.js, Python, PHP application metrics
- Logs Explorer (Loki)

**Add your app's metrics**: expose a `/metrics` endpoint with [prom-client](https://www.npmjs.com/package/prom-client) (Node), [prometheus_client](https://pypi.org/project/prometheus_client/) (Python), or any Prometheus library.

**Search logs**: In Grafana Explore, select Loki and query:
```
{job="syslog"} |= "error"
{job="mysql"}
rate({job="syslog"}[5m])
```

### Services & Observability

```bash
devvm service restart mysql          # Manage any systemd service
devvm service logs demo-node         # Tail service logs
devvm obs up                         # Start Grafana + Prometheus + Loki + Tempo
devvm obs logs grafana               # Tail container logs
devvm obs restart prometheus         # Restart one container
```

### Access

```bash
devvm ssh                   # Shell into VM
devvm run node --version    # Run command as user
devvm exec systemctl status # Run command as root
devvm open grafana          # Open web UIs
devvm ports                 # Show all ports
devvm verify                # Run health check
```

## Troubleshooting

```bash
devvm verify                          # Check all 39 components
devvm service status mysql            # Check specific service
devvm service logs mysql              # Check service logs
devvm obs logs tempo                  # Check container logs
devvm provision                       # Re-run (idempotent, safe)
orb doctor                            # Check OrbStack health
```

## License

MIT
