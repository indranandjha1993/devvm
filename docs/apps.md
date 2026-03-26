# Application Hosting

DevVM can host your applications with Nginx reverse proxy. Each app gets a `.dev.local` domain, a systemd service, and process management.

## Register an App

```bash
devvm app add myapi --path ~/projects/myapi --type fastapi
```

This creates:
- A systemd service (`app-myapi.service`) that runs your app
- An Nginx vhost so `http://myapi.dev.local` proxies to your app
- A port assignment (starting from 8001, auto-incrementing)

**With a specific port**:
```bash
devvm app add myapi --path ~/projects/myapi --type fastapi --port 8005
```

**With a custom command**:
```bash
devvm app add myapi --path ~/projects/myapi --type custom --cmd "python3 server.py"
```

## Scaffold a New App

```bash
devvm app create blog --template express
```

This creates the project at `~/projects/blog`, installs dependencies, and registers it.

**Available templates**:

| Template | What it creates |
|----------|----------------|
| `laravel` | `composer create-project laravel/laravel` |
| `django` | `django-admin startproject` |
| `flask` | Minimal Flask app with `app.py` |
| `fastapi` | Minimal FastAPI app with `main.py` |
| `express` | Express app with `app.js` + `package.json` |
| `nextjs` | `npx create-next-app` |
| `go-web` | Minimal Go HTTP server |
| `static` | HTML page served by Nginx |
| `wordpress` | Downloads latest WordPress |

## Manage Apps

```bash
devvm app list                 # show all apps with status and URLs

devvm start myapi              # start
devvm stop myapi               # stop
devvm restart myapi            # restart
devvm logs myapi               # tail logs

devvm app remove myapi         # unregister, remove service and Nginx config
```

## Supported Types

| Type | Start command | Framework |
|------|--------------|-----------|
| `laravel` | `php artisan serve --host=0.0.0.0 --port=PORT` | Laravel |
| `wordpress` | `php -S 0.0.0.0:PORT` | WordPress |
| `django` | `python3 manage.py runserver 0.0.0.0:PORT` | Django |
| `flask` | `flask run --host=0.0.0.0 --port=PORT` | Flask |
| `fastapi` | `uvicorn main:app --host 0.0.0.0 --port PORT` | FastAPI |
| `express` | `node app.js` (PORT env var) | Express |
| `nextjs` | `npx next dev -p PORT` | Next.js |
| `spring-boot` | `java -jar *.jar --server.port=PORT` | Spring Boot |
| `go` | `go run .` (PORT env var) | Any Go app |
| `static` | Nginx serves files directly | Static HTML |
| `custom` | Your command via `--cmd` | Anything |

## How It Works

**Systemd service**: Each non-static app gets a service at `/etc/systemd/system/app-NAME.service`. It auto-restarts on crash.

**Nginx vhost**: Each app gets a config at `/etc/nginx/sites-available/NAME.conf` that proxies `NAME.dev.local` to `localhost:PORT`.

**Port assignment**: Ports start at 8001 and auto-increment. Override with `--port`.

**Static apps**: No systemd service. Nginx serves files directly from the path. `devvm start/stop` is a no-op (Nginx always serves them).

## Example: Full Workflow

```bash
# Scaffold a FastAPI project
devvm app create myapi --template fastapi

# It's already running
devvm app list
#   myapi    fastapi    8001   http://myapi.dev.local   active

# Check it
curl http://myapi.dev.local
#   {"status": "ok", "framework": "fastapi"}

# View logs
devvm logs myapi

# Stop it
devvm stop myapi

# Remove it
devvm app remove myapi
```
