# Observability

DevVM runs a full Grafana LGTM stack for metrics, logs, and traces.

## Stack

| Service | Port | Purpose |
|---------|------|---------|
| [Grafana](http://dev.orb.local:3000) | 3000 | Dashboards, exploration, alerting |
| [Prometheus](http://dev.orb.local:9090) | 9090 | Metrics collection and querying |
| Loki | 3100 | Log aggregation |
| Tempo | 3200 | Distributed tracing (OTLP on :4317) |
| Promtail | — | Ships logs to Loki |
| cAdvisor | 8081 | Container and service metrics |

All run as Docker containers managed by docker-compose.

## Open Grafana

```bash
devvm open grafana             # opens http://dev.orb.local:3000
```

No login required (anonymous Editor access). Admin login: `admin` / `admin`.

## Dashboards

9 pre-configured dashboards:

| Dashboard | URL | Source |
|-----------|-----|--------|
| System Metrics | [/d/system-metrics](http://dev.orb.local:3000/d/system-metrics) | node_exporter |
| Services & Containers | [/d/docker](http://dev.orb.local:3000/d/docker) | cAdvisor |
| MySQL | [/d/mysql](http://dev.orb.local:3000/d/mysql) | mysqld_exporter |
| PostgreSQL | [/d/postgresql](http://dev.orb.local:3000/d/postgresql) | postgres_exporter |
| Redis | [/d/redis](http://dev.orb.local:3000/d/redis) | redis_exporter |
| Node.js App | [/d/nodejs](http://dev.orb.local:3000/d/nodejs) | App metrics |
| Python App | [/d/python](http://dev.orb.local:3000/d/python) | App metrics |
| PHP App | [/d/php-fpm](http://dev.orb.local:3000/d/php-fpm) | App metrics |
| Logs Explorer | [/d/logs](http://dev.orb.local:3000/d/logs) | Loki |

## Prometheus Targets

6 exporters scrape metrics automatically:

| Exporter | Port | Metrics |
|----------|------|---------|
| node_exporter | 9100 | CPU, memory, disk, network |
| mysqld_exporter | 9104 | MySQL queries, connections, InnoDB |
| postgres_exporter | 9187 | PostgreSQL connections, transactions, cache |
| redis_exporter | 9121 | Redis clients, memory, commands, keys |
| cAdvisor | 8081 | Container/service CPU and memory |
| Promtail | — | Log volume metrics |

Apps registered via `devvm app add` are automatically discovered if they expose `/metrics`.

## Add Your App's Metrics

**Node.js** — install [prom-client](https://www.npmjs.com/package/prom-client):
```javascript
const client = require('prom-client');
client.collectDefaultMetrics();

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', client.register.contentType);
  res.end(await client.register.metrics());
});
```

**Python** — install [prometheus_client](https://pypi.org/project/prometheus_client/):
```python
from prometheus_client import start_http_server, Counter

REQUEST_COUNT = Counter('http_requests_total', 'Total requests')

start_http_server(8000)  # exposes /metrics on :8000
```

**PHP** — expose metrics as text at `/metrics`:
```php
header('Content-Type: text/plain');
echo "# HELP app_requests_total Total requests\n";
echo "# TYPE app_requests_total counter\n";
echo "app_requests_total " . $count . "\n";
```

## Search Logs

In Grafana Explore, select **Loki** and use LogQL:

```
{job="syslog"}                          # system logs
{job="mysql"}                           # MySQL logs
{job="postgresql"}                      # PostgreSQL logs
{job="redis"}                           # Redis logs
{job="docker"}                          # Docker container logs
{job="apps"}                            # Application logs (/var/log/apps/)
{job="syslog"} |= "error"              # filter for errors
{job="syslog"} | json                   # parse JSON logs
rate({job="syslog"}[5m])                # log rate over time
```

## Send Traces

Send OpenTelemetry traces to Tempo:

```bash
# gRPC (default)
OTEL_EXPORTER_OTLP_ENDPOINT=http://dev.orb.local:4317

# HTTP
OTEL_EXPORTER_OTLP_ENDPOINT=http://dev.orb.local:4318
```

## Manage

```bash
devvm restart obs              # restart all observability
devvm restart grafana          # restart one container
devvm logs grafana             # tail container logs
devvm logs prometheus
devvm stop obs                 # stop all observability
devvm start obs                # start all observability
```
