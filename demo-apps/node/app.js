const express = require("express");
const client = require("prom-client");

const app = express();
const register = client.register;

// Collect default metrics (CPU, memory, event loop, GC, etc.)
client.collectDefaultMetrics({ prefix: "" });

// Custom HTTP metrics
const httpRequestDuration = new client.Histogram({
  name: "http_request_duration_seconds",
  help: "Duration of HTTP requests in seconds",
  labelNames: ["method", "route", "status"],
  buckets: [0.01, 0.05, 0.1, 0.5, 1, 2, 5],
});

const httpRequestsTotal = new client.Counter({
  name: "http_requests_total",
  help: "Total number of HTTP requests",
  labelNames: ["method", "route", "status"],
});

// Routes
app.get("/", (req, res) => {
  const start = Date.now();
  const delay = Math.random() * 200;
  setTimeout(() => {
    const duration = (Date.now() - start) / 1000;
    httpRequestDuration.observe({ method: "GET", route: "/", status: "200" }, duration);
    httpRequestsTotal.inc({ method: "GET", route: "/", status: "200" });
    res.json({ status: "ok", latency_ms: Math.round(delay) });
  }, delay);
});

app.get("/api/users", (req, res) => {
  const start = Date.now();
  const delay = Math.random() * 500;
  setTimeout(() => {
    const duration = (Date.now() - start) / 1000;
    httpRequestDuration.observe({ method: "GET", route: "/api/users", status: "200" }, duration);
    httpRequestsTotal.inc({ method: "GET", route: "/api/users", status: "200" });
    res.json({ users: ["alice", "bob", "charlie"] });
  }, delay);
});

app.get("/metrics", async (req, res) => {
  res.set("Content-Type", register.contentType);
  res.end(await register.metrics());
});

app.listen(3001, "0.0.0.0", () => console.log("Node demo on :3001, metrics at /metrics"));

// Auto-generate traffic every 2 seconds
setInterval(() => {
  const routes = ["/", "/api/users", "/"];
  const route = routes[Math.floor(Math.random() * routes.length)];
  fetch("http://localhost:3001" + route).catch(() => {});
}, 2000);
