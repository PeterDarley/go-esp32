// SoftAP + HTTP server for ESP32  (with template engine)
//
// Build & flash:  make flash-softap
// Connect phone:  join "peter_bot" WiFi (open, no password)
// Open browser:   http://192.168.71.1/
//
// Routes
//   GET /              – home page  (auto-refresh every 5 s)
//   GET /api/status    – JSON status  { uptime_s, heap_free, clients, ip }
//   GET /api/clients   – JSON list of connected station MACs
//   *                  – 404

#include <WiFi.h>
#include <WebServer.h>
#include <esp_wifi.h>
// FreeRTOS APIs used to create pinned tasks
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>

// ── AP configuration ───────────────────────────────────────────────────────
static const char*  AP_SSID     = "peter_bot";
static const char*  AP_PASSWORD = "";          // open network
static const int    AP_CHANNEL  = 6;
static const int    AP_MAX_CONN = 4;

static IPAddress    AP_IP     (192, 168, 71, 1);
static IPAddress    AP_GATEWAY(192, 168, 71, 1);
static IPAddress    AP_SUBNET (255, 255, 255, 0);

// ── Template engine ────────────────────────────────────────────────────────
//
// Usage:
//   String html = render(TMPL, { {"KEY", value}, ... });
//
// All occurrences of %KEY% in the template are replaced with value.

struct TVar { const char* key; String val; };

String render(const String& tmpl, std::initializer_list<TVar> vars) {
    String out = tmpl;
    for (auto& v : vars) {
        String token = "%"; token += v.key; token += "%";
        out.replace(token, v.val);
    }
    return out;
}

// ── Shared page layout ─────────────────────────────────────────────────────
static const char LAYOUT[] PROGMEM = R"html(<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  %REFRESH%
  <title>%TITLE% – peter_bot</title>
  <style>
    *{box-sizing:border-box}
    body{font-family:system-ui,sans-serif;max-width:520px;margin:2em auto;padding:0 1em;background:#f4f6f9;color:#1a1a2e}
    header{background:#2c7be5;color:#fff;border-radius:8px;padding:1em 1.4em;margin-bottom:1.2em}
    header h1{margin:0;font-size:1.4em}
    header small{opacity:.8;font-size:.85em}
    .card{background:#fff;border-radius:8px;padding:1em 1.4em;margin-bottom:1em;box-shadow:0 1px 4px rgba(0,0,0,.08)}
    .card h2{margin:0 0 .6em;font-size:1em;text-transform:uppercase;letter-spacing:.06em;color:#6c757d}
    table{width:100%;border-collapse:collapse}
    td{padding:.35em 0}
    td:first-child{color:#6c757d;width:50%}
    td:last-child{font-weight:600;text-align:right}
    nav a{color:#fff;text-decoration:none;margin-right:1em;font-size:.85em;opacity:.85}
    nav a:hover{opacity:1}
    .badge{display:inline-block;background:#198754;color:#fff;border-radius:999px;padding:.15em .7em;font-size:.8em}
  </style>
</head>
<body>
<header>
  <nav>
    <a href="/">Home</a>
    <a href="/api/status">API status</a>
    <a href="/api/clients">API clients</a>
  </nav>
  <h1>peter_bot</h1>
  <small>ESP32 SoftAP &nbsp;·&nbsp; 192.168.71.1</small>
</header>
%CONTENT%
</body>
</html>
)html";

// ── Helper: human-readable uptime ──────────────────────────────────────────
String uptimeStr() {
    unsigned long s = millis() / 1000;
    unsigned long m = s / 60; s %= 60;
    unsigned long h = m / 60; m %= 60;
    char buf[24];
    snprintf(buf, sizeof(buf), "%luh %02lum %02lus", h, m, s);
    return String(buf);
}

// ── WebServer ──────────────────────────────────────────────────────────────
WebServer server(80);

// GET /
void handleRoot() {
    wifi_sta_list_t stalist;
    esp_wifi_ap_get_sta_list(&stalist);
    int cnt = stalist.num;

    String content =
        "<div class='card'>"
        "<h2>Network</h2>"
        "<table>"
        "<tr><td>SSID</td><td>%SSID%</td></tr>"
        "<tr><td>IP address</td><td>%IP%</td></tr>"
        "<tr><td>Channel</td><td>%CHAN%</td></tr>"
        "<tr><td>Connected clients</td><td>%CNT% <span class='badge'>live</span></td></tr>"
        "</table></div>"
        "<div class='card'>"
        "<h2>System</h2>"
        "<table>"
        "<tr><td>Uptime</td><td>%UPTIME%</td></tr>"
        "<tr><td>Free heap</td><td>%HEAP% bytes</td></tr>"
        "<tr><td>SDK version</td><td>%SDK%</td></tr>"
        "</table></div>";

    String page = render(String(FPSTR(LAYOUT)), {
        {"TITLE",   "Home"},
        {"REFRESH", "<meta http-equiv='refresh' content='5'>"},
        {"CONTENT", render(content, {
            {"SSID",   String(AP_SSID)},
            {"IP",     WiFi.softAPIP().toString()},
            {"CHAN",   String(AP_CHANNEL)},
            {"CNT",    String(cnt)},
            {"UPTIME", uptimeStr()},
            {"HEAP",   String(ESP.getFreeHeap())},
            {"SDK",    String(ESP.getSdkVersion())},
        })},
    });

    server.send(200, "text/html", page);
}

// GET /api/status  →  JSON
void handleApiStatus() {
    wifi_sta_list_t stalist;
    esp_wifi_ap_get_sta_list(&stalist);

    String json = "{";
    json += "\"uptime_s\":"   + String(millis() / 1000)   + ",";
    json += "\"heap_free\":"  + String(ESP.getFreeHeap())  + ",";
    json += "\"clients\":"    + String(stalist.num)        + ",";
    json += "\"ip\":\""       + WiFi.softAPIP().toString() + "\",";
    json += "\"ssid\":\""     + String(AP_SSID)            + "\",";
    json += "\"sdk\":\""      + String(ESP.getSdkVersion()) + "\"";
    json += "}";

    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.send(200, "application/json", json);
}

// GET /api/clients  →  JSON array of MAC addresses
void handleApiClients() {
    wifi_sta_list_t stalist;
    esp_wifi_ap_get_sta_list(&stalist);

    String json = "[";
    for (int i = 0; i < stalist.num; i++) {
        if (i) json += ",";
        char mac[18];
        uint8_t* m = stalist.sta[i].mac;
        snprintf(mac, sizeof(mac), "%02x:%02x:%02x:%02x:%02x:%02x",
                 m[0], m[1], m[2], m[3], m[4], m[5]);
        json += "\""; json += mac; json += "\"";
    }
    json += "]";

    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.send(200, "application/json", json);
}

// * → 404
void handleNotFound() {
    String page = render(String(FPSTR(LAYOUT)), {
        {"TITLE",   "404"},
        {"REFRESH", ""},
        {"CONTENT", "<div class='card'><h2>404 Not Found</h2><p>" +
                    server.uri() + "</p></div>"},
    });
    server.send(404, "text/html", page);
}

// HTTP server task: polls the WebServer and dispatches handlers.
void httpdTask(void *pvParameters) {
    (void) pvParameters;
    Serial.println("[httpd] httpdTask started");
    for (;;) {
        server.handleClient();
        // Yield to other tasks (10 ms)
        vTaskDelay(pdMS_TO_TICKS(10));
    }
}

// Worker task: placeholder for other background work.
void workerTask(void *pvParameters) {
    (void) pvParameters;
    Serial.println("[worker] workerTask started");
    for (;;) {
        // Example: print a heartbeat; replace with real work.
        Serial.printf("[worker] uptime %lums, free heap %u\n", millis(), ESP.getFreeHeap());
        vTaskDelay(pdMS_TO_TICKS(5000));
    }
}

// ── Setup ──────────────────────────────────────────────────────────────────
void setup() {
    Serial.begin(115200);
    delay(100);
    Serial.println("\n[softap] booting...");

    WiFi.mode(WIFI_AP);
    WiFi.softAPConfig(AP_IP, AP_GATEWAY, AP_SUBNET);

    bool ok = WiFi.softAP(AP_SSID, AP_PASSWORD, AP_CHANNEL, 0, AP_MAX_CONN);
    if (!ok) {
        Serial.println("[softap] ERROR: failed to start AP");
        while (true) delay(1000);
    }

    Serial.print("[softap] SSID:    "); Serial.println(AP_SSID);
    Serial.print("[softap] IP:      "); Serial.println(WiFi.softAPIP());
    Serial.print("[softap] Channel: "); Serial.println(AP_CHANNEL);

    server.on("/",            handleRoot);
    server.on("/api/status",  handleApiStatus);
    server.on("/api/clients", handleApiClients);
    server.onNotFound(handleNotFound);
    server.begin();

    // Create FreeRTOS tasks:
    // - httpdTask: dedicated task for handling HTTP requests
    // - workerTask: does independent background work
    xTaskCreatePinnedToCore(httpdTask, "httpd", 4096, NULL, 1, NULL, 1);
    xTaskCreatePinnedToCore(workerTask, "worker", 4096, NULL, 1, NULL, 1);

    Serial.println("[softap] HTTP server listening on :80 (httpdTask)");
    Serial.println("[softap] Routes: /   /api/status   /api/clients");
}

// loop() is left empty because work is done in FreeRTOS tasks.
void loop() {
    vTaskDelay(pdMS_TO_TICKS(1000));
}
