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
  el.style.color = ok ? "#7ddba0" : "#ff8d8d";
}

function refreshBuildEnabled() {
  $("build").disabled = !(decrypted && store.worker);
}

async function onDecrypt() {
  const link = $("link").value.trim();
  if (!link) return;
  setStatus("");
  $("decoded").hidden = true;
  $("result").hidden = true;
  decrypted = null;
  try {
    decrypted = decryptLink(link, await keys());
    $("decoded").hidden = false;
    $("decoded").textContent = `${decrypted.mode}\n${decrypted.value}`;
    if (!store.worker) setStatus("Decrypted. Set a Worker URL in settings to build a subscription.", true);
    else setStatus("Decrypted.", true);
  } catch (e) {
    setStatus(`Decrypt failed: ${e.message}`);
  }
  refreshBuildEnabled();
}

async function onBuild() {
  if (!decrypted || !store.worker) return;
  setStatus("Building subscription…", true);
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
    renderResult(data);
    setStatus(`Done — ${data.count} configs.`, true);
  } catch (e) {
    setStatus(`Build failed: ${e.message}`);
  } finally {
    refreshBuildEnabled();
  }
}

function renderResult(data) {
  $("result").hidden = false;
  $("result-meta").textContent = `${data.count} configs`;
  $("sub-url").textContent = data.url;
  QRCode.toCanvas($("qr"), data.url, { width: 180, margin: 1 });
  const ul = $("configs");
  ul.innerHTML = "";
  for (const uri of data.configs) {
    const li = document.createElement("li");
    li.textContent = uri;
    li.title = "Click to copy";
    li.onclick = () => navigator.clipboard.writeText(uri);
    ul.appendChild(li);
  }
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
