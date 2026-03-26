<?php
$metricsFile = "/tmp/php_metrics.json";

if (!file_exists($metricsFile)) {
    file_put_contents($metricsFile, json_encode([
        "requests_total" => 0,
        "requests_by_route" => [],
        "request_durations" => [],
        "start_time" => time(),
        "memory_peak" => 0,
    ]));
}

function updateMetrics(string $route, float $duration): void {
    global $metricsFile;
    $m = json_decode(file_get_contents($metricsFile), true);
    $m["requests_total"]++;
    $m["requests_by_route"][$route] = ($m["requests_by_route"][$route] ?? 0) + 1;
    $m["request_durations"][] = $duration;
    if (count($m["request_durations"]) > 1000) {
        $m["request_durations"] = array_slice($m["request_durations"], -500);
    }
    $m["memory_peak"] = memory_get_peak_usage(true);
    file_put_contents($metricsFile, json_encode($m));
}

$uri = parse_url($_SERVER["REQUEST_URI"] ?? "/", PHP_URL_PATH);
$start = microtime(true);

if ($uri === "/metrics") {
    $m = json_decode(file_get_contents($metricsFile), true);
    $uptime = time() - ($m["start_time"] ?? time());
    $durations = $m["request_durations"] ?? [];
    sort($durations);
    $cnt = count($durations);
    $p50 = $cnt > 0 ? $durations[(int)($cnt * 0.5)] : 0;
    $p90 = $cnt > 0 ? $durations[(int)($cnt * 0.9)] : 0;
    $p99 = $cnt > 0 ? $durations[(int)($cnt * 0.99)] : 0;

    header("Content-Type: text/plain");
    $out = "";
    $out .= "# HELP php_requests_total Total HTTP requests\n";
    $out .= "# TYPE php_requests_total counter\n";
    $out .= "php_requests_total " . ($m["requests_total"] ?? 0) . "\n";
    $out .= "# HELP php_request_duration_seconds Request duration summary\n";
    $out .= "# TYPE php_request_duration_seconds summary\n";
    $out .= "php_request_duration_seconds{quantile=\"0.5\"} " . round($p50, 6) . "\n";
    $out .= "php_request_duration_seconds{quantile=\"0.9\"} " . round($p90, 6) . "\n";
    $out .= "php_request_duration_seconds{quantile=\"0.99\"} " . round($p99, 6) . "\n";
    $out .= "php_request_duration_seconds_sum " . round(array_sum($durations), 6) . "\n";
    $out .= "php_request_duration_seconds_count " . $cnt . "\n";
    $out .= "# HELP php_uptime_seconds PHP app uptime\n";
    $out .= "# TYPE php_uptime_seconds gauge\n";
    $out .= "php_uptime_seconds " . $uptime . "\n";
    $out .= "# HELP php_memory_usage_bytes PHP memory usage\n";
    $out .= "# TYPE php_memory_usage_bytes gauge\n";
    $out .= "php_memory_usage_bytes " . memory_get_usage(true) . "\n";
    $out .= "# HELP php_memory_peak_bytes PHP peak memory\n";
    $out .= "# TYPE php_memory_peak_bytes gauge\n";
    $out .= "php_memory_peak_bytes " . ($m["memory_peak"] ?? 0) . "\n";
    $out .= "# HELP process_resident_memory_bytes Resident memory size\n";
    $out .= "# TYPE process_resident_memory_bytes gauge\n";
    $out .= "process_resident_memory_bytes " . memory_get_usage(true) . "\n";
    foreach ($m["requests_by_route"] ?? [] as $route => $count) {
        $out .= "php_requests_by_route{route=\"" . $route . "\"} " . $count . "\n";
    }
    echo $out;
    exit;
}

// Simulate work
usleep(random_int(10000, 200000));

if (str_starts_with($uri, "/api")) {
    header("Content-Type: application/json");
    echo json_encode(["data" => range(1, 5), "source" => "php"]);
    updateMetrics("/api", microtime(true) - $start);
} else {
    header("Content-Type: application/json");
    echo json_encode(["status" => "ok", "php" => PHP_VERSION]);
    updateMetrics("/", microtime(true) - $start);
}
