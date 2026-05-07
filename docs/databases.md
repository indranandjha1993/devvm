# Databases

Four data services are pre-installed and running as systemd services: MySQL, PostgreSQL, Redis, and MinIO (S3-compatible object storage).

## MySQL

| | |
|-|-|
| Port | 3306 |
| User | `dev` |
| Password | `dev` |
| Default DB | `devdb` |

**Connect from CLI**:
```bash
devvm db mysql
devvm db mysql -e "SHOW DATABASES;"
```

**Connect from Mac** (any client — TablePlus, DBeaver, DataGrip):
```
Host: dev.orb.local
Port: 3306
User: dev
Password: dev
```

**Create a database**:
```bash
devvm db mysql -e "CREATE DATABASE myapp;"
```

**Manage**:
```bash
devvm stop mysql
devvm start mysql
devvm restart mysql
devvm logs mysql
devvm reset mysql              # resets to dev/dev credentials
```

**Monitoring**: MySQL metrics are scraped by Prometheus via mysqld_exporter. View the [MySQL dashboard](http://dev.orb.local:3000/d/mysql) in Grafana.

## PostgreSQL

| | |
|-|-|
| Port | 5432 |
| User | `dev` |
| Password | `dev` |
| Default DB | `devdb` |

**Connect from CLI**:
```bash
devvm db psql
devvm db psql -c "SELECT version();"
```

**Connect from Mac**:
```
Host: dev.orb.local
Port: 5432
User: dev
Password: dev
Database: devdb
```

**Create a database**:
```bash
devvm db psql -c "CREATE DATABASE myapp;"
```

**Manage**:
```bash
devvm stop postgres
devvm start postgres
devvm restart postgres
devvm logs postgres
devvm reset postgres           # resets to dev/dev credentials
```

**Monitoring**: PostgreSQL metrics via postgres_exporter. View the [PostgreSQL dashboard](http://dev.orb.local:3000/d/postgresql) in Grafana.

## Redis

| | |
|-|-|
| Port | 6379 |
| Password | (none) |

**Connect from CLI**:
```bash
devvm db redis
devvm db redis PING            # PONG
devvm db redis SET foo bar
devvm db redis GET foo
```

**Connect from Mac**:
```
Host: dev.orb.local
Port: 6379
Password: (none)
```

**Manage**:
```bash
devvm stop redis
devvm start redis
devvm restart redis
devvm logs redis
devvm reset redis              # removes any password
```

**Monitoring**: Redis metrics via redis_exporter. View the [Redis dashboard](http://dev.orb.local:3000/d/redis) in Grafana.

## MinIO (S3-compatible object storage)

| | |
|-|-|
| API port | 9000 |
| Console port | 9001 |
| User | `dev` |
| Password | `devdevdev` (≥ 8 chars required by MinIO) |
| Default bucket | `dev` |
| Data dir | `/var/lib/minio/data` |

**Connect from CLI** (uses bundled `mc` client, alias `local`):
```bash
devvm db minio ls local                  # list buckets
devvm db minio mb local/photos           # create a new bucket
devvm db minio cp ./file.txt local/dev/  # upload
devvm db minio cat local/dev/file.txt    # read
```

**Connect from Mac** with any S3 SDK / tool:
```
Endpoint:   http://dev.orb.local:9000
Region:     us-east-1   (any value works for MinIO)
Access key: dev
Secret key: devdevdev
Path-style: true        (required — MinIO does not support virtual-hosted-style)
```

**Web console**: http://dev.orb.local:9001 — login with `dev` / `devdevdev`. Or:
```bash
devvm open minio
```

**Manage**:
```bash
devvm stop minio
devvm start minio
devvm restart minio
devvm logs minio
devvm reset minio        # resets to dev/devdevdev (data preserved)
```

**Monitoring**: MinIO exposes Prometheus metrics at `/minio/v2/metrics/cluster`. The scrape job `minio` is pre-configured in Prometheus (no auth — set via `MINIO_PROMETHEUS_AUTH_TYPE=public`).

**Use in code** (Python):
```python
import boto3
s3 = boto3.client(
    "s3",
    endpoint_url="http://dev.orb.local:9000",
    aws_access_key_id="dev",
    aws_secret_access_key="devdevdev",
    region_name="us-east-1",
)
s3.upload_file("local.txt", "dev", "remote.txt")
```

## Adminer

Web-based database admin UI at **http://dev.orb.local:8080**.

Supports MySQL and PostgreSQL. Login with the credentials above.

## Credentials

View and manage credentials:

```bash
devvm creds                              # list all (masked)
devvm creds show mysql                   # full details
devvm creds set mysql --pass newpass     # change password
devvm creds set postgres --user admin --pass secret --db mydb
devvm creds set minio --pass NewSecret8  # MinIO requires ≥ 8 chars
devvm creds reset mysql                  # back to dev/dev
```

Changing credentials updates the actual database user, exporter configs, and the stored config. The `devvm db` command automatically uses the current credentials.
