# Databases

Three databases are pre-installed and running as systemd services.

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
devvm creds reset mysql                  # back to dev/dev
```

Changing credentials updates the actual database user, exporter configs, and the stored config. The `devvm db` command automatically uses the current credentials.
