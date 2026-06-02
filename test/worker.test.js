import { test } from "node:test";
import assert from "node:assert/strict";
import worker, { extractConfigs, toBase64Sub } from "../worker/worker.js";

test("extractConfigs parses a plain list", () => {
  const body = "vless://a@h:443#A\nnope\ntrojan://p@h:443#B";
  assert.deepEqual(extractConfigs(body), ["vless://a@h:443#A", "trojan://p@h:443#B"]);
});

test("extractConfigs parses a base64-wrapped list", () => {
  const inner = "vless://a@h:443#A\nvmess://b";
  const body = Buffer.from(inner, "utf8").toString("base64");
  assert.deepEqual(extractConfigs(body), ["vless://a@h:443#A", "vmess://b"]);
});

test("extractConfigs returns empty when nothing recognized", () => {
  assert.deepEqual(extractConfigs("hello world"), []);
});

test("toBase64Sub round-trips", () => {
  const configs = ["vless://a@h:443#A", "trojan://p@h:443#B"];
  const decoded = Buffer.from(toBase64Sub(configs), "base64").toString("utf8");
  assert.equal(decoded, configs.join("\n"));
});

function mockKV() {
  const store = new Map();
  return {
    store,
    async put(k, v) { store.set(k, v); },
    async get(k) { return store.has(k) ? store.get(k) : null; },
  };
}

test("POST /build fetches sub URL with UA+HWID and stores a subscription", async () => {
  const seen = {};
  const realFetch = globalThis.fetch;
  globalThis.fetch = async (u, opts) => {
    seen.url = u; seen.headers = opts.headers;
    return new Response("vless://a@h:443#A\ntrojan://p@h:443#B", { status: 200 });
  };
  try {
    const env = { SUBS: mockKV() };
    const req = new Request("https://w.dev/build", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ subUrl: "https://sub.example/x", userAgent: "Happ/9", hwid: "HW-1" }),
    });
    const res = await worker.fetch(req, env);
    assert.equal(res.status, 200);
    const data = await res.json();
    assert.equal(seen.url, "https://sub.example/x");
    assert.equal(seen.headers["User-Agent"], "Happ/9");
    assert.equal(seen.headers["X-HWID"], "HW-1");
    assert.equal(data.count, 2);
    assert.match(data.url, /^https:\/\/w\.dev\/sub\/[a-f0-9]{32}$/);

    const subReq = new Request(data.url, { method: "GET" });
    const subRes = await worker.fetch(subReq, env);
    assert.equal(subRes.status, 200);
    const decoded = Buffer.from(await subRes.text(), "base64").toString("utf8");
    assert.equal(decoded, "vless://a@h:443#A\ntrojan://p@h:443#B");
  } finally {
    globalThis.fetch = realFetch;
  }
});

test("POST /build maps upstream rejection to a clear error", async () => {
  const realFetch = globalThis.fetch;
  globalThis.fetch = async () => new Response("", { status: 403 });
  try {
    const req = new Request("https://w.dev/build", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ subUrl: "https://sub.example/x", userAgent: "x", hwid: "y" }),
    });
    const res = await worker.fetch(req, { SUBS: mockKV() });
    assert.equal(res.status, 502);
    assert.match((await res.json()).error, /check User-Agent and X-HWID/);
  } finally {
    globalThis.fetch = realFetch;
  }
});

test("GET /sub/<unknown> is 404", async () => {
  const res = await worker.fetch(new Request("https://w.dev/sub/deadbeef", { method: "GET" }), { SUBS: mockKV() });
  assert.equal(res.status, 404);
});
