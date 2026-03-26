import time, random, threading
from http.server import HTTPServer, BaseHTTPRequestHandler
from prometheus_client import (
    Counter, Histogram, Gauge, Info,
    generate_latest, REGISTRY
)
import urllib.request

# Metrics
REQUEST_COUNT = Counter(
    "http_requests_total", "Total HTTP requests",
    ["method", "endpoint", "status"]
)
REQUEST_LATENCY = Histogram(
    "http_request_duration_seconds", "HTTP request latency",
    ["method", "endpoint"],
    buckets=[0.01, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5]
)
ACTIVE_REQUESTS = Gauge("http_active_requests", "Active HTTP requests")
APP_INFO = Info("python_app", "Python demo application info")
APP_INFO.info({"version": "1.0.0", "framework": "stdlib"})


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        ACTIVE_REQUESTS.inc()
        start = time.time()
        try:
            if self.path == "/metrics":
                data = generate_latest(REGISTRY)
                self.send_response(200)
                self.send_header("Content-Type", "text/plain; charset=utf-8")
                self.end_headers()
                self.wfile.write(data)
            elif self.path == "/api/data":
                time.sleep(random.uniform(0.05, 0.5))
                REQUEST_COUNT.labels("GET", "/api/data", "200").inc()
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(b'{"data": [1,2,3], "source": "python"}')
            else:
                time.sleep(random.uniform(0.01, 0.2))
                REQUEST_COUNT.labels("GET", "/", "200").inc()
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(b'{"status": "ok"}')
        finally:
            duration = time.time() - start
            endpoint = "/api/data" if self.path == "/api/data" else "/"
            if self.path != "/metrics":
                REQUEST_LATENCY.labels("GET", endpoint).observe(duration)
            ACTIVE_REQUESTS.dec()

    def log_message(self, format, *args):
        pass


def generate_traffic():
    """Auto-generate traffic every 1-3 seconds."""
    while True:
        try:
            endpoint = random.choice(["/", "/api/data", "/"])
            urllib.request.urlopen(f"http://localhost:8000{endpoint}", timeout=5)
        except Exception:
            pass
        time.sleep(random.uniform(1, 3))


threading.Thread(target=generate_traffic, daemon=True).start()
print("Python demo on :8000, metrics at /metrics")
HTTPServer(("0.0.0.0", 8000), Handler).serve_forever()
