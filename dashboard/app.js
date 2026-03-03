const {
    GATEWAY_URL = "",
    GRAFANA_URL = "",
    ENV_NAME = "",
    STATE_SERVICE_URL = "",
} = window.__DASHBOARD_CONFIG__ || {};

const MAX_POINTS = 20;
const reqHistory = { labels: [], datasets: [{ label: "Requests", data: [], borderColor: "#5b8dee", backgroundColor: "rgba(91,141,238,.15)", tension: .3, fill: true, pointRadius: 3 }] };
const tokHistory = { labels: [], datasets: [{ label: "Tokens", data: [], borderColor: "#3ecf8e", backgroundColor: "rgba(62,207,142,.15)", tension: .3, fill: true, pointRadius: 3 }] };

let reqChart;
let tokChart;
let prevReq = null;
let prevTok = null;
let availableModels = [];
let suppressSelectionSync = false;

function escHtml(s) {
    return String(s ?? "")
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/\"/g, "&quot;")
        .replace(/'/g, "&#39;");
}

function deriveEnv(url) {
    if (!url) return null;
    const m = url.match(/pvc-(dev|uat|prod)-/);
    return m ? m[1] : null;
}

function stateServiceConfigured() {
    return Boolean(STATE_SERVICE_URL && STATE_SERVICE_URL.trim() !== "");
}

function getKey() {
    return sessionStorage.getItem("gw_key") || "";
}

function saveKey() {
    const value = document.getElementById("api-key-input").value.trim();
    if (!value) return;
    sessionStorage.setItem("gw_key", value);
    document.getElementById("key-status").textContent = "✓ Key saved for this session";
    refresh();
}

function restoreKey() {
    const key = getKey();
    if (!key) return;
    document.getElementById("api-key-input").value = key;
    document.getElementById("key-status").textContent = "✓ Key loaded from session";
}

function ensureUserId() {
    const existing = localStorage.getItem("dashboard_user_id");
    if (existing && existing.trim()) return existing.trim();
    const generated = `user-${Math.random().toString(36).slice(2, 8)}`;
    localStorage.setItem("dashboard_user_id", generated);
    return generated;
}

function getUserId() {
    const input = document.getElementById("user-id-input");
    const value = (input?.value || "").trim();
    return value || ensureUserId();
}

function persistUserId() {
    localStorage.setItem("dashboard_user_id", getUserId());
}

function restoreUserId() {
    document.getElementById("user-id-input").value = ensureUserId();
}

async function apiFetch(path, opts = {}) {
    const headers = { ...(opts.headers || {}) };
    const key = getKey();
    if (key) headers.Authorization = `Bearer ${key}`;
    const resp = await fetch(`/api${path}`, { ...opts, headers });
    if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
    return resp;
}

async function stateFetch(path, opts = {}) {
    if (!stateServiceConfigured()) throw new Error("State service not configured");
    const headers = { ...(opts.headers || {}), "X-User-Id": getUserId() };
    const resp = await fetch(`/api/state${path}`, { ...opts, headers });
    if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
    return resp;
}

const chartDefaults = {
    type: "line",
    options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
            x: { ticks: { color: "#94a3b8", font: { size: 11 } }, grid: { color: "#2d3147" } },
            y: { ticks: { color: "#94a3b8", font: { size: 11 } }, grid: { color: "#2d3147" }, beginAtZero: true },
        },
    },
};

function initCharts() {
    if (typeof Chart === "undefined") {
        document.querySelectorAll(".chart-card").forEach(card => {
            card.innerHTML = '<p style="color:var(--muted);font-size:12px;text-align:center;padding:20px">Charts unavailable (CDN blocked)</p>';
        });
        return;
    }
    reqChart = new Chart(document.getElementById("req-chart"), { ...chartDefaults, data: reqHistory });
    tokChart = new Chart(document.getElementById("tok-chart"), { ...chartDefaults, data: tokHistory });
}

function pushPoint(history, chart, label, value) {
    if (!chart) return;
    history.labels.push(label);
    history.datasets[0].data.push(value);
    if (history.labels.length > MAX_POINTS) {
        history.labels.shift();
        history.datasets[0].data.shift();
    }
    chart.update("none");
}

function updateModelSelectionState() {
    const toggle = document.getElementById("model-selection-cb");
    const select = document.getElementById("model-select");

    if (!toggle.checked) {
        select.disabled = true;
        select.innerHTML = '<option value="">Model selection disabled</option>';
        return;
    }

    if (availableModels.length === 0) {
        select.disabled = true;
        select.innerHTML = '<option value="">No models available</option>';
        return;
    }

    const previous = select.value;
    select.innerHTML = availableModels.map(id => `<option value="${escHtml(id)}">${escHtml(id)}</option>`).join("");
    select.value = availableModels.includes(previous) ? previous : availableModels[0];
    select.disabled = false;
}

async function persistSelectionState() {
    if (suppressSelectionSync || !stateServiceConfigured()) return;
    const enabled = document.getElementById("model-selection-cb").checked;
    const selectedModel = enabled ? (document.getElementById("model-select").value || null) : null;
    try {
        await stateFetch("/selection", {
            method: "PUT",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ enabled, selected_model: selectedModel }),
        });
    } catch {
    }
}

async function syncCatalogState(status) {
    if (!stateServiceConfigured()) return;
    try {
        await stateFetch("/catalog", {
            method: "PUT",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ models: availableModels, status }),
        });
    } catch {
    }
}

function maskUserId(userId) {
    if (!userId) return "unknown";
    if (userId.length <= 4) return userId;
    return `${userId.slice(0, 2)}***${userId.slice(-2)}`;
}

function renderOtherUsers(items) {
    const container = document.getElementById("other-users-content");
    if (!Array.isArray(items) || items.length === 0) {
        container.innerHTML = '<div class="empty">No other user selections available.</div>';
        return;
    }

    container.innerHTML = `<div class="other-users">${items.map(item => {
        const updated = item.updated_at ? new Date(item.updated_at).toLocaleTimeString() : "unknown";
        const status = item.enabled ? (item.selected_model || "enabled") : "disabled";
        return `<div class="other-user-card"><div class="name">${escHtml(maskUserId(item.user_id || "unknown"))}</div><div class="meta">${escHtml(status)}</div><div class="meta">Updated ${escHtml(updated)}</div></div>`;
    }).join("")}</div>`;
}

async function loadSharedState() {
    const catalogPill = document.getElementById("catalog-status-pill");
    const selectionPill = document.getElementById("my-selection-pill");
    const usersContainer = document.getElementById("other-users-content");

    if (!stateServiceConfigured()) {
        catalogPill.textContent = "Catalog: local-only";
        selectionPill.textContent = "My selection: local-only";
        usersContainer.innerHTML = '<div class="empty">State service not configured yet.</div>';
        return;
    }

    try {
        const [catalogResp, myResp, othersResp] = await Promise.all([
            stateFetch("/catalog"),
            stateFetch("/selection"),
            stateFetch("/selections?limit=10&include_self=false"),
        ]);

        const catalog = await catalogResp.json();
        const mine = await myResp.json();
        const others = await othersResp.json();

        catalogPill.textContent = `Catalog: ${catalog.status || "unknown"} (${(catalog.models || []).length})`;
        selectionPill.textContent = `My selection: ${mine.enabled ? (mine.selected_model || "enabled") : "disabled"}`;

        suppressSelectionSync = true;
        document.getElementById("model-selection-cb").checked = Boolean(mine.enabled);
        if (mine.selected_model && availableModels.includes(mine.selected_model)) {
            document.getElementById("model-select").value = mine.selected_model;
        }
        updateModelSelectionState();
        suppressSelectionSync = false;

        renderOtherUsers(others.items || []);
    } catch {
        catalogPill.textContent = "Catalog: unavailable";
        selectionPill.textContent = "My selection: unavailable";
        usersContainer.innerHTML = '<div class="empty">Could not load other users\' state.</div>';
    }
}

async function fetchHealth() {
    try {
        const resp = await apiFetch("/health");
        const data = await resp.json();
        const healthy = data.status === "healthy" || data.status === "ok";
        const el = document.getElementById("health-val");
        el.textContent = healthy ? "Healthy" : (data.status || "Degraded");
        el.className = `value ${healthy ? "health-ok" : "health-deg"}`;
        document.getElementById("health-sub").textContent = "LiteLLM gateway";
    } catch (e) {
        const el = document.getElementById("health-val");
        el.textContent = "Unreachable";
        el.className = "value health-err";
        document.getElementById("health-sub").textContent = e.message;
    }
}

async function fetchModels() {
    try {
        const resp = await apiFetch("/v1/models");
        const data = await resp.json();
        const modelItems = Array.isArray(data?.data) ? data.data : (Array.isArray(data) ? data : []);
        availableModels = modelItems
            .map(item => (item && typeof item === "object" ? item.id : null))
            .filter(id => typeof id === "string" && id.trim() !== "");

        document.getElementById("models-val").textContent = String(availableModels.length);
        document.getElementById("models-sub").textContent = availableModels.length === 0
            ? "No models available from LiteLLM"
            : availableModels.join(", ").slice(0, 60);

        updateModelSelectionState();
        await syncCatalogState("live");
    } catch (e) {
        availableModels = [];
        document.getElementById("models-val").textContent = "—";
        document.getElementById("models-sub").textContent = getKey() ? `Failed to load models: ${e.message}` : "Auth required";
        updateModelSelectionState();
        await syncCatalogState("unavailable");
    }
}

function parsePrometheus(text) {
    const metrics = {};
    for (const line of text.split("\n")) {
        if (line.startsWith("#") || line.trim() === "") continue;
        const m = line.match(/^([^\s{]+)(?:\{[^}]*\})?\s+([\d.eE+\-NaInf]+)/);
        if (!m) continue;
        const [, name, val] = m;
        const n = parseFloat(val);
        if (!isNaN(n)) metrics[name] = (metrics[name] || 0) + n;
    }
    return metrics;
}

async function fetchMetrics() {
    try {
        const resp = await apiFetch("/metrics");
        const text = await resp.text();
        const m = parsePrometheus(text);

        const totalReq = m["litellm_requests_metric_total"] ?? m["litellm_llm_requests_metric_total"] ?? 0;
        const totalTok = m["litellm_total_tokens"] ?? (m["litellm_input_tokens"] ?? 0) + (m["litellm_output_tokens"] ?? 0);
        const totalErr = m["litellm_llm_api_failed_requests_metric_total"] ?? 0;

        document.getElementById("req-val").textContent = fmtNum(totalReq);
        document.getElementById("tok-val").textContent = fmtNum(totalTok);
        document.getElementById("err-val").textContent = fmtNum(totalErr);
        document.getElementById("err-val").className = `value ${totalErr > 0 ? "health-err" : ""}`;

        const label = new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit", second: "2-digit" });
        const deltaReq = prevReq !== null ? Math.max(0, totalReq - prevReq) : 0;
        const deltaTok = prevTok !== null ? Math.max(0, totalTok - prevTok) : 0;

        prevReq = totalReq;
        prevTok = totalTok;
        pushPoint(reqHistory, reqChart, label, deltaReq);
        pushPoint(tokHistory, tokChart, label, deltaTok);

        document.getElementById("req-sub").textContent = `+${deltaReq} since last refresh`;
        document.getElementById("tok-sub").textContent = `+${deltaTok} since last refresh`;
    } catch {
        if (!getKey()) return;
        document.getElementById("req-val").textContent = "—";
        document.getElementById("tok-val").textContent = "—";
        document.getElementById("err-val").textContent = "—";
    }
}

function renderLogRow(row) {
    const ts = row.startTime || row.start_time || row.created_at || row.timestamp || "";
    const model = row.model || row.request_model || "—";
    const tIn = row.prompt_tokens || row.input_tokens || row.usage?.prompt_tokens || "—";
    const tOut = row.completion_tokens || row.output_tokens || row.usage?.completion_tokens || "—";
    const lat = row.response_time != null ? row.response_time.toFixed(2) : "—";
    const ok = (row.status_code ?? row.status ?? 200) < 400;
    const status = row.status_code || row.status || (ok ? 200 : "err");
    const user = row.user || row.metadata?.user || "—";
    const tsFmt = ts ? new Date(ts).toLocaleTimeString() : "—";

    return `<tr>
    <td>${escHtml(tsFmt)}</td><td>${escHtml(model)}</td><td>${escHtml(tIn)}</td><td>${escHtml(tOut)}</td>
    <td>${escHtml(lat)}</td>
    <td class="${ok ? "status-ok" : "status-err"}">${escHtml(status)}</td>
    <td>${escHtml(user)}</td>
  </tr>`;
}

async function fetchLogs() {
    const container = document.getElementById("logs-content");
    if (!getKey()) {
        container.innerHTML = '<div class="empty">Enter your gateway key above to load logs.</div>';
        return;
    }

    try {
        const resp = await apiFetch("/logs");
        const data = await resp.json();
        const rows = Array.isArray(data) ? data : (data.data || data.logs || []);

        if (rows.length === 0) {
            container.innerHTML = '<div class="empty">No log entries found.</div>';
            return;
        }

        const recent = rows.slice(-50).reverse();
        container.innerHTML = `<table><thead><tr>
      <th>Time</th><th>Model</th><th>Tokens In</th><th>Tokens Out</th>
      <th>Latency (s)</th><th>Status</th><th>User</th>
    </tr></thead><tbody>${recent.map(renderLogRow).join("")}</tbody></table>`;
    } catch (e) {
        container.innerHTML = `<div class="empty">Could not load logs: ${escHtml(e.message)}</div>`;
    }
}

function fmtNum(n) {
    if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M`;
    if (n >= 1_000) return `${(n / 1_000).toFixed(1)}k`;
    return String(Math.round(n));
}

async function refresh() {
    await Promise.allSettled([fetchHealth(), fetchModels(), fetchMetrics(), fetchLogs()]);
    await loadSharedState();
    document.getElementById("last-updated").textContent = `Last updated: ${new Date().toLocaleTimeString()}`;
}

function openGrafana() {
    if (GRAFANA_URL) window.open(GRAFANA_URL, "_blank", "noopener");
}

document.addEventListener("DOMContentLoaded", () => {
    const envLabel = ENV_NAME || deriveEnv(GATEWAY_URL) || "gateway";
    document.getElementById("env-badge").textContent = envLabel;

    const gwLink = document.getElementById("gateway-link");
    gwLink.href = GATEWAY_URL;
    gwLink.textContent = GATEWAY_URL;

    if (GRAFANA_URL) {
        const btn = document.getElementById("grafana-btn");
        btn.classList.remove("hidden");
        btn.addEventListener("click", openGrafana);
    }

    initCharts();
    restoreKey();
    restoreUserId();

    document.getElementById("apply-key-btn").addEventListener("click", saveKey);
    document.getElementById("refresh-btn").addEventListener("click", refresh);
    document.getElementById("model-selection-cb").addEventListener("change", async () => {
        updateModelSelectionState();
        await persistSelectionState();
    });
    document.getElementById("model-select").addEventListener("change", persistSelectionState);
    document.getElementById("user-id-input").addEventListener("change", async () => {
        persistUserId();
        await loadSharedState();
    });

    updateModelSelectionState();
    refresh();

    setInterval(() => {
        if (document.getElementById("auto-refresh-cb").checked) refresh();
    }, 30000);
});
