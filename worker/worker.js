// Cloudflare Worker: fetch a Happ sub URL with the right headers and host the
// resulting configs as a subscription in KV. See worker/README.md to deploy.

const KNOWN_SCHEMES = [
  "vless", "vmess", "trojan", "ss", "ssr",
  "hysteria", "hysteria2", "hy2", "tuic", "wireguard",
];
const MAX_CONFIGS = 5000;

// "*" lets the worker be used from any happwn site (official or your own fork)
// with no code edits. CORS is not a security boundary anyway — the size/TTL caps
// below are. Set this to your site origin if you want to restrict browser callers.
const ALLOWED_ORIGIN = "*";
const MAX_BODY = 256 * 1024;        // request body cap
const MAX_UPSTREAM = 1024 * 1024;   // fetched sub body cap
const TTL_SECONDS = 7 * 24 * 3600;  // KV expiry

/** True if a line starts with a known proxy scheme. */
function isConfigLine(line) {
  const i = line.indexOf(":");
  if (i < 0) return false;
  return KNOWN_SCHEMES.includes(line.slice(0, i).toLowerCase());
}

/** Decode a subscription body (base64-wrapped or plain) into config URIs. */
export function extractConfigs(body) {
  const raw = String(body || "");
  const compact = raw.replace(/\s+/g, "");
  let text = raw;
  // Try whole-body base64 (standard subscription format).
  if (/^[A-Za-z0-9+/_=-]+$/.test(compact) && compact.length > 0) {
    try {
      const std = compact.replace(/-/g, "+").replace(/_/g, "/");
      const padded = std + "=".repeat((4 - (std.length % 4)) % 4);
      const decoded = atob(padded);
      if (KNOWN_SCHEMES.some((s) => decoded.includes(`${s}://`))) text = decoded;
    } catch {
      /* not base64 — fall through to raw */
    }
  }
  return text
    .split(/\r?\n/)
    .map((l) => l.trim())
    .filter(isConfigLine)
    .slice(0, MAX_CONFIGS);
}

/** Configs -> standard base64 subscription body. */
export function toBase64Sub(configs) {
  return btoa(configs.join("\n"));
}

function cors(extra = {}) {
  return {
    "Access-Control-Allow-Origin": ALLOWED_ORIGIN,
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
    ...extra,
  };
}

function json(obj, status = 200) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: cors({ "Content-Type": "application/json" }),
  });
}

function randomToken() {
  const b = new Uint8Array(16);
  crypto.getRandomValues(b);
  return [...b].map((x) => x.toString(16).padStart(2, "0")).join("");
}

async function handleBuild(request, env) {
  const cl = Number(request.headers.get("content-length") || 0);
  if (cl > MAX_BODY) return json({ error: "request too large" }, 413);

  let payload;
  try {
    payload = await request.json();
  } catch {
    return json({ error: "invalid JSON" }, 400);
  }
  const { subUrl, configs: inlineConfigs, userAgent, hwid } = payload || {};

  let body;
  if (subUrl) {
    if (!/^https?:\/\//i.test(subUrl)) return json({ error: "bad sub URL" }, 400);
    let resp;
    try {
      resp = await fetch(subUrl, {
        headers: { "User-Agent": userAgent || "", "X-HWID": hwid || "" },
        signal: AbortSignal.timeout(15000),
      });
    } catch {
      return json({ error: "fetch failed — check the URL" }, 502);
    }
    if (!resp.ok) {
      return json({ error: `server rejected (${resp.status}) — check User-Agent and X-HWID` }, 502);
    }
    body = (await resp.text()).slice(0, MAX_UPSTREAM);
  } else if (typeof inlineConfigs === "string") {
    body = inlineConfigs.slice(0, MAX_UPSTREAM);
  } else {
    return json({ error: "provide subUrl or configs" }, 400);
  }

  const configs = extractConfigs(body);
  if (configs.length === 0) return json({ error: "no configs found", raw: body.slice(0, 2000) }, 422);

  const token = randomToken();
  await env.SUBS.put(token, toBase64Sub(configs), { expirationTtl: TTL_SECONDS });

  const origin = new URL(request.url).origin;
  return json({ token, url: `${origin}/sub/${token}`, count: configs.length, configs });
}

async function handleSub(token, env) {
  const sub = await env.SUBS.get(token);
  if (sub === null) return new Response("not found", { status: 404 });
  return new Response(sub, { headers: { "Content-Type": "text/plain; charset=utf-8" } });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (request.method === "OPTIONS") return new Response(null, { status: 204, headers: cors() });
    if (request.method === "POST" && url.pathname === "/build") return handleBuild(request, env);
    const m = url.pathname.match(/^\/sub\/([A-Za-z0-9]+)$/);
    if (request.method === "GET" && m) return handleSub(m[1], env);
    if (url.pathname === "/") return new Response("happwn worker", { headers: cors() });
    return new Response("not found", { status: 404 });
  },
};
