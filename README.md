# DevVM

Your entire dev infrastructure in one command. An Ubuntu VM on [OrbStack](https://orbstack.dev) with six language stacks, three databases, Grafana observability, and app hosting with Nginx — all managed through `devvm`.

## Quick Start

```bash
brew tap indranandjha/tap && brew install devvm   # or: git clone + sudo make install

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

**Languages**: Node.js 22 (pnpm, TypeScript) / Python 3.13 (Poetry, uv) / PHP 8.4 (Composer, Laravel, Xdebug) / Go 1.22 (Delve) / Rust (rust-analyzer) / Java 21

**Databases**: MySQL :3306 / PostgreSQL :5432 / Redis :6379 / Adminer :8080

**Monitoring**: Grafana :3000 / Prometheus :9090 / Loki :3100 / Tempo :3200 — 9 dashboards

**Hosting**: Nginx reverse proxy — each app gets `appname.dev.local`

---

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
sudo make link
```

Requires [OrbStack](https://orbstack.dev) (free for personal use): `brew install orbstack`

---

## CLI Reference

### Lifecycle

```bash
devvm init               # Create VM and install everything
devvm start              # Start the VM
devvm stop               # Stop the VM
devvm restart            # Restart the VM
devvm reset              # Destroy and rebuild from scratch
devvm destroy            # Delete VM permanently
```

### Control Individual Stacks

Every lifecycle command accepts an optional target:

```bash
devvm stop mysql         # Stop just MySQL
devvm start mysql        # Start it back
devvm restart redis      # Restart Redis
devvm restart grafana    # Restart Grafana container
devvm restart obs        # Restart all observability
devvm logs mysql         # Tail MySQL logs
devvm logs grafana       # Tail Grafana logs
devvm logs promtail      # Tail Promtail logs
devvm reset postgres     # Reset PostgreSQL to defaults (dev/dev)
```

**Available targets**: `mysql`, `postgres`, `redis`, `nginx`, `grafana`, `prometheus`, `loki`, `tempo`, `promtail`, `cadvisor`, `obs` (all observability), or any registered app name.

### Applications

```bash
# Register an existing project
devvm app add mysite --path ~/projects/mysite --type laravel
devvm app add api --path ~/projects/api --type fastapi --port 8005

# Scaffold a new project
devvm app create blog --template express
devvm app create site --template static

# Manage
devvm app list
devvm app remove mysite
```

Once registered, control apps like any other stack:

```bash
devvm start mysite
devvm stop mysite
devvm restart mysite
devvm logs mysite
```

**Supported types:**

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

**Scaffold templates**: `laravel`, `django`, `flask`, `fastapi`, `express`, `nextjs`, `go-web`, `static`, `wordpress`

### Credentials

```bash
devvm creds                              # List all (passwords masked)
devvm creds show mysql                   # Show full credentials
devvm creds set mysql --pass newpass     # Change password
devvm creds set postgres --user admin --pass secret --db mydb
devvm creds reset mysql                  # Reset to defaults
```

**Defaults:**

| Service | User | Password | Port |
|---------|------|----------|------|
| MySQL | `dev` | `dev` | 3306 |
| PostgreSQL | `dev` | `dev` | 5432 |
| Redis | — | (none) | 6379 |
| Grafana | `admin` | `admin` | 3000 |

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

Pre-built VS Code configs in `vscode/launch.json`. Path mappings work automatically — OrbStack mounts your Mac home at the same path in the VM.

### Monitoring

```bash
devvm open grafana     # http://dev.orb.local:3000
devvm open adminer     # http://dev.orb.local:8080
devvm open prometheus  # http://dev.orb.local:9090
```

**9 dashboards**: System Metrics, Services, MySQL, PostgreSQL, Redis, Node.js, Python, PHP, Logs Explorer.

**Add your app's metrics**: expose `/metrics` with [prom-client](https://www.npmjs.com/package/prom-client) (Node), [prometheus_client](https://pypi.org/project/prometheus_client/) (Python), or any Prometheus library.

**Search logs** in Grafana Explore with Loki:
```
{job="syslog"} |= "error"
{job="mysql"}
rate({job="syslog"}[5m])
```

### Access

```bash
devvm ssh                     # Shell into VM
devvm ssh ls /opt             # Run one command
devvm run node --version      # Run as user
devvm exec systemctl status   # Run as root
devvm status                  # Show everything
devvm ports                   # Port map
devvm verify                  # Health check
```

---

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
