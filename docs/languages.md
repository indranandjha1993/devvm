# Languages

DevVM comes with six language runtimes pre-installed. All are available system-wide inside the VM.

## Node.js 22

Installed via [fnm](https://github.com/Schniz/fnm) (Fast Node Manager).

```bash
devvm run node --version       # v22.22.2
devvm run npm --version
devvm run pnpm --version
```

**Included**: pnpm, TypeScript, tsx

**Switch versions**:
```bash
devvm ssh
fnm install 20
fnm use 20
```

**Run a script**:
```bash
devvm run node app.js
devvm debug node app.js        # with inspector on :9229
```

## Python 3.13

System Python from Ubuntu, with modern tooling via pipx.

```bash
devvm run python3 --version    # 3.13.7
devvm run poetry --version
devvm run uv --version
```

**Included**: pip, venv, [Poetry](https://python-poetry.org/), [uv](https://github.com/astral-sh/uv), debugpy

**Create a virtual environment**:
```bash
devvm ssh
cd ~/projects/myapp
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

**Run a script**:
```bash
devvm run python3 app.py
devvm debug python app.py      # with debugpy on :5678
```

## PHP 8.4

Installed from Ubuntu's default packages with Xdebug.

```bash
devvm run php --version        # 8.4.11
devvm run composer --version   # 2.9.5
```

**Included**: Composer, Xdebug, extensions (mysql, pgsql, redis, mbstring, xml, curl, zip, gd, intl, bcmath)

**Install Laravel CLI** (on demand):
```bash
devvm exec composer global require laravel/installer
```

**Create a Laravel project**:
```bash
devvm app create mysite --template laravel
# or manually:
devvm ssh
composer create-project laravel/laravel mysite
```

**Debugging**: Xdebug is in trigger mode. See [Debugging](debugging.md#php).

## Go 1.22

Installed from the official tarball.

```bash
devvm run go version           # go1.22.5
```

**Install tools** (on demand):
```bash
devvm exec go install golang.org/x/tools/gopls@latest       # language server
devvm exec go install github.com/go-delve/delve/cmd/dlv@latest  # debugger
```

**Run a project**:
```bash
devvm run go run .
devvm debug go ./cmd/myapp     # with Delve on :2345
```

## Rust

Installed via [rustup](https://rustup.rs/) with minimal profile.

```bash
devvm run rustc --version      # 1.94.1
devvm run cargo --version
```

**Install tools** (on demand):
```bash
devvm exec rustup component add rust-analyzer
devvm exec rustup component add clippy
```

**Build a project**:
```bash
devvm ssh
cd ~/projects/myapp
cargo build
cargo run
```

## Java 21

OpenJDK 21 from Ubuntu packages.

```bash
devvm run java --version       # 21.0.10
devvm run javac --version
```

**Run a JAR**:
```bash
devvm run java -jar app.jar
devvm debug java App.jar       # with JDWP on :5005
```

## Path Notes

All language binaries are available inside the VM. OrbStack mounts your Mac home directory at the same path, so `~/projects/myapp` on Mac = `~/projects/myapp` in the VM.

```bash
# These all work — your Mac files are accessible
devvm run node ~/projects/api/server.js
devvm run python3 ~/projects/ml/train.py
devvm run go run ~/projects/service/.
```
