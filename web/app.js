import { decryptLink } from "./decrypt.js";
import QRCode from "qrcode";

const $ = (id) => document.getElementById(id);

const store = {
  get ua() { return localStorage.getItem("happwn.ua") ?? "Happ/1.0"; },
  set ua(v) { localStorage.setItem("happwn.ua", v); },
  get hwid() { return localStorage.getItem("happwn.hwid") ?? ""; },
  set hwid(v) { localStorage.setItem("happwn.hwid", v); },
  get worker() { return (localStorage.getItem("happwn.worker") ?? "").replace(/\/+$/, ""); },
  set worker(v) { localStorage.setItem("happwn.worker", v); },
};

let keysCache = null;
let decrypted = null; // { mode, value }

async function keys() {
  if (!keysCache) {
    const [pkcs1, crypt5] = await Promise.all([
      fetch("./pkcs1_keys.json").then((r) => r.json()),
      fetch("./expanded_rsa_keys.json").then((r) => r.json()),
    ]);
    keysCache = { pkcs1, crypt5 };
  }
  return keysCache;
}

function setStatus(msg, ok = false) {
  const el = $("status");
  el.textContent = msg;
  el.style.color = ok ? "var(--cyan)" : "var(--red)";
}

function stage(id, state) {
  $(id).className = "stage" + (state ? " " + state : "");
}
function resetStages() {
  ["st-decrypt", "st-fetch", "st-forge"].forEach((id) => stage(id, ""));
}

function refreshBuildEnabled() {
  $("build").disabled = !(decrypted && store.worker);
}

function schemeOf(uri) {
  const i = uri.indexOf("://");
  return i > 0 ? uri.slice(0, i) : uri.split(":")[0];
}

async function onDecrypt() {
  const link = $("link").value.trim();
  if (!link) return;
  setStatus("");
  resetStages();
  $("decoded").hidden = true;
  $("result").hidden = true;
  decrypted = null;
  stage("st-decrypt", "active");
  try {
    decrypted = decryptLink(link, await keys());
    stage("st-decrypt", "done");
    $("decoded").hidden = false;
    $("decoded").textContent = `mode: ${decrypted.mode}\n${decrypted.value}`;
    setStatus(
      store.worker ? "Decrypted. Ready to forge." : "Decrypted. Add a Worker URL in settings to forge a subscription.",
      true
    );
  } catch (e) {
    stage("st-decrypt", "error");
    setStatus(`Decrypt failed: ${e.message}`);
  }
  refreshBuildEnabled();
}

async function onBuild() {
  if (!decrypted || !store.worker) return;
  setStatus("Forging subscription…", true);
  stage("st-fetch", "active");
  $("build").disabled = true;
  const value = decrypted.value.trim();
  const payload = /^https?:\/\//i.test(value)
    ? { subUrl: value, userAgent: store.ua, hwid: store.hwid }
    : { configs: value, userAgent: store.ua, hwid: store.hwid };
  try {
    const res = await fetch(`${store.worker}/build`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.error || `HTTP ${res.status}`);
    stage("st-fetch", "done");
    stage("st-forge", "done");
    renderResult(data);
    setStatus(`Done — ${data.count} configs forged.`, true);
  } catch (e) {
    stage("st-fetch", "error");
    setStatus(`Forge failed: ${e.message}`);
  } finally {
    refreshBuildEnabled();
  }
}

function renderResult(data) {
  $("result").hidden = false;
  $("result-meta").textContent = `${data.count} CONFIGS`;
  $("sub-url").textContent = data.url;
  QRCode.toCanvas($("qr"), data.url, { width: 172, margin: 1, color: { dark: "#06070e", light: "#ffffff" } });
  const ul = $("configs");
  ul.innerHTML = "";
  data.configs.forEach((uri, i) => {
    const li = document.createElement("li");
    li.title = "Click to copy";
    li.onclick = () => navigator.clipboard.writeText(uri);

    const idx = document.createElement("span");
    idx.className = "idx";
    idx.textContent = String(i + 1).padStart(2, "0");

    const sch = document.createElement("span");
    sch.className = "scheme";
    sch.textContent = schemeOf(uri);

    const u = document.createElement("span");
    u.className = "uri";
    u.textContent = uri;

    li.append(idx, sch, u);
    ul.appendChild(li);
  });
  $("result").scrollIntoView({ behavior: "smooth", block: "nearest" });
}

function initSettings() {
  $("ua").value = store.ua;
  $("hwid").value = store.hwid;
  $("worker").value = store.worker;
  $("ua").oninput = (e) => { store.ua = e.target.value; };
  $("hwid").oninput = (e) => { store.hwid = e.target.value; };
  $("worker").oninput = (e) => { store.worker = e.target.value; refreshBuildEnabled(); };
  $("settings-toggle").onclick = () => { $("settings").hidden = !$("settings").hidden; };
}

$("decrypt").onclick = onDecrypt;
$("build").onclick = onBuild;
$("copy-sub").onclick = () => navigator.clipboard.writeText($("sub-url").textContent);
initSettings();
refreshBuildEnabled();
