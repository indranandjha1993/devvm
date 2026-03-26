# CLI Reference

## Lifecycle

| Command | Description |
|---------|-------------|
| `devvm init` | Create VM and install everything |
| `devvm start` | Start the VM |
| `devvm stop` | Stop the VM |
| `devvm restart` | Restart the VM |
| `devvm reset` | Destroy and rebuild from scratch |
| `devvm destroy` | Delete VM permanently |

## Stack Control

All lifecycle commands accept a target to operate on a single stack:

```bash
devvm start mysql
devvm stop redis
devvm restart grafana
devvm logs prometheus
devvm reset postgres           # resets credentials to defaults
```

**Available targets**: `mysql`, `postgres`, `redis`, `nginx`, `grafana`, `prometheus`, `loki`, `tempo`, `promtail`, `cadvisor`, `obs` (all observability), or any registered app name.

## Applications

| Command | Description |
|---------|-------------|
| `devvm app add <name> --path <dir> --type <type>` | Register an app |
| `devvm app create <name> --template <type>` | Scaffold and register |
| `devvm app list` | List all apps |
| `devvm app remove <name>` | Unregister an app |

## Databases

| Command | Description |
|---------|-------------|
| `devvm db mysql` | MySQL shell |
| `devvm db psql` | PostgreSQL shell |
| `devvm db redis` | Redis CLI |

## Credentials

| Command | Description |
|---------|-------------|
| `devvm creds` | List all (passwords masked) |
| `devvm creds show <service>` | Show full credentials |
| `devvm creds set <service> --pass X` | Update credentials |
| `devvm creds reset <service>` | Reset to defaults |

## Debugging

| Command | Description |
|---------|-------------|
| `devvm debug python <file>` | debugpy on :5678 |
| `devvm debug node <file>` | Inspector on :9229 |
| `devvm debug php` | Xdebug instructions |
| `devvm debug go [pkg]` | Delve on :2345 |
| `devvm debug java <class>` | JDWP on :5005 |

## Access

| Command | Description |
|---------|-------------|
| `devvm ssh` | Shell into VM |
| `devvm ssh <command>` | Run a single command |
| `devvm run <cmd>` | Run as user |
| `devvm exec <cmd>` | Run as root |
| `devvm open grafana` | Open web UI in browser |

## Info

| Command | Description |
|---------|-------------|
| `devvm status` | Show everything |
| `devvm ports` | Port map |
| `devvm verify` | Health check |
| `devvm version` | Version |
| `devvm help` | Help |

## Shell Completions

**Bash** — add to `~/.bashrc`:
```bash
source /usr/local/etc/bash_completion.d/devvm
```

**Zsh** — completions are installed to `/usr/local/share/zsh/site-functions/_devvm` automatically.
