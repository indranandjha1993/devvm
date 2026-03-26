# Debugging

DevVM includes remote debuggers for all languages, pre-configured for VS Code.

## Quick Start

```bash
devvm debug python app.py      # starts debugpy, waits for VS Code
devvm debug node server.js     # starts Node inspector
devvm debug php                # shows Xdebug setup
devvm debug go ./cmd/app       # starts Delve
devvm debug java App.jar       # starts JVM with JDWP
```

Then attach from VS Code using the launch configs in `vscode/launch.json`.

## VS Code Setup

Copy the provided launch config to your project:

```bash
cp /path/to/dev-vm/vscode/launch.json ~/projects/myapp/.vscode/
```

Or merge the configurations into your existing `launch.json`.

**Path mappings work automatically** — OrbStack mounts your Mac home at the same path in the VM, so no mapping configuration is needed.

## Python

**Tool**: [debugpy](https://github.com/microsoft/debugpy)
**Port**: 5678

```bash
devvm debug python app.py
```

This runs `python3 -m debugpy --listen 0.0.0.0:5678 --wait-for-client app.py`. The script pauses until VS Code attaches.

**VS Code config**: `Python: Remote Attach (dev VM)`

```json
{
  "name": "Python: Remote Attach (dev VM)",
  "type": "debugpy",
  "request": "attach",
  "connect": { "host": "dev.orb.local", "port": 5678 },
  "pathMappings": [
    { "localRoot": "${workspaceFolder}", "remoteRoot": "${workspaceFolder}" }
  ]
}
```

## Node.js

**Tool**: Built-in Node.js Inspector
**Port**: 9229

```bash
devvm debug node server.js
```

This runs `node --inspect=0.0.0.0:9229 server.js`.

**VS Code config**: `Node: Remote Attach (dev VM)`

```json
{
  "name": "Node: Remote Attach (dev VM)",
  "type": "node",
  "request": "attach",
  "address": "dev.orb.local",
  "port": 9229,
  "localRoot": "${workspaceFolder}",
  "remoteRoot": "${workspaceFolder}"
}
```

## PHP

**Tool**: [Xdebug](https://xdebug.org/) (trigger mode)
**Port**: 9003 (reverse — VM connects to your Mac)

Xdebug is always ready. No `devvm debug` command needed — just trigger it:

**Browser**: Add `?XDEBUG_TRIGGER=1` to any URL, or use the [Xdebug browser extension](https://xdebug.org/docs/step_debug#browser-extensions).

**CLI**:
```bash
devvm ssh
XDEBUG_TRIGGER=1 php script.php
```

**VS Code config**: `PHP: Xdebug (dev VM)`

Install the [PHP Debug extension](https://marketplace.visualstudio.com/items?itemName=xdebug.php-debug) first.

```json
{
  "name": "PHP: Xdebug (dev VM)",
  "type": "php",
  "request": "launch",
  "port": 9003,
  "hostname": "0.0.0.0",
  "pathMappings": {
    "${workspaceFolder}": "${workspaceFolder}"
  }
}
```

## Go

**Tool**: [Delve](https://github.com/go-delve/delve)
**Port**: 2345

```bash
devvm debug go ./cmd/myapp
```

This runs `dlv debug --headless --listen=:2345 --api-version=2`.

**Install Delve first** (not pre-installed):
```bash
devvm exec go install github.com/go-delve/delve/cmd/dlv@latest
```

**VS Code config**: `Go: Remote Attach (dev VM)`

```json
{
  "name": "Go: Remote Attach (dev VM)",
  "type": "go",
  "request": "attach",
  "mode": "remote",
  "remotePath": "${workspaceFolder}",
  "host": "dev.orb.local",
  "port": 2345
}
```

## Java

**Tool**: JDWP (Java Debug Wire Protocol)
**Port**: 5005

```bash
devvm debug java MyApp.jar
```

This runs `java -agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=*:5005 -jar MyApp.jar`. The JVM pauses until the debugger attaches.

**VS Code config**: `Java: Remote Attach (dev VM)`

```json
{
  "name": "Java: Remote Attach (dev VM)",
  "type": "java",
  "request": "attach",
  "hostName": "dev.orb.local",
  "port": 5005
}
```

## Port Summary

| Language | Tool | Port | Direction |
|----------|------|------|-----------|
| Python | debugpy | 5678 | Mac -> VM |
| Node.js | Inspector | 9229 | Mac -> VM |
| PHP | Xdebug | 9003 | VM -> Mac (reverse) |
| Go | Delve | 2345 | Mac -> VM |
| Java | JDWP | 5005 | Mac -> VM |
