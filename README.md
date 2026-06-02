<div align="center">

<img src="assets/icon.png" width="128" alt="happwn icon" />

# happwn — Happ Decrypt for iOS

**Happ decryptor and subscription config extractor, packaged as a sideloaded iOS `.ipa`.**

Decrypt `happ://` links (`crypt`, `crypt2`, `crypt3`, `crypt4`, `crypt5`), follow the
embedded subscription URL with the required `User-Agent` and `X-HWID`, and extract every
config — right on your iPhone.

[![build](https://github.com/useruserdev/happwn/actions/workflows/build.yml/badge.svg)](https://github.com/useruserdev/happwn/actions/workflows/build.yml)
[![platform](https://img.shields.io/badge/platform-iOS%2016%2B-blue)](#install)
[![license](https://img.shields.io/badge/license-Apache--2.0-green)](LICENSE)

</div>

---

## Features

- Full Happ decrypt — all schemes: `crypt`, `crypt2`, `crypt3`, `crypt4`, `crypt5`.
- Subscription fetch — sends your `User-Agent` and `X-HWID` so the server does not reject the request.
- Config extraction — pulls `vless`, `vmess`, `trojan`, `ss`, `ssr`, `hysteria2`, `tuic`, `wireguard` URIs.
- Copy and share — copy one, copy all, share sheet, raw-body fallback.
- On-device — decryption runs locally in a Rust core; no servers of our own, no analytics.
- Sideloaded — installs without the App Store via AltStore, Sideloadly, or TrollStore.

## How it works

```
happ://crypt…  ──decrypt (Rust core + embedded keys)──▶  subscription URL
                                                           │
                  GET with headers  User-Agent + X-HWID    ▼   (rejected without them)
                                                           │
                                                           ▼
                                          subscription body (configs)
                                                           │
                                                           ▼
                          parse ▶ vless / vmess / …  ▶ copy · share · export
```

| Scheme | Pipeline |
| ------ | -------- |
| `crypt` · `crypt2` · `crypt3` · `crypt4` | base64 → RSA PKCS#1 v1.5 |
| `crypt5` | CDAB permutation → RSA key recovery → ChaCha20-Poly1305 → base64 |

## Build

CI builds an unsigned, versioned `.ipa` on every push to `main` and publishes it to
**[Releases](https://github.com/useruserdev/happwn/releases/latest)** (and as a build
artifact). The `rust-tests` job runs the crypto tests against real vectors on every
push — no Mac required.

Run the crypto tests anywhere Rust is installed:

```bash
cargo test --manifest-path rust/Cargo.toml
```

Build locally on macOS:

```bash
bash scripts/build-xcframework.sh
cd ios && xcodegen generate && open happwn.xcodeproj
```

## Install

1. Download the latest `happwn-*.ipa` from **[Releases](https://github.com/useruserdev/happwn/releases/latest)**.
2. Sideload it with AltStore, Sideloadly, or TrollStore.
3. Open the app, set your `User-Agent` and `X-HWID` in Settings, paste a `happ://` link, tap Extract.

## Web

A browser version lives in [`web/`](web/) and is hosted on GitHub Pages:
**https://useruserdev.github.io/happwn/**

It decrypts `happ://` links **client-side** (nothing leaves your browser). Decryption
works immediately, with no setup.

### Build a subscription URL — bring your own Worker

A browser can't send the `Happ` `User-Agent` or do the cross-origin sub fetch, so the
fetch + hosting runs on a tiny **Cloudflare Worker that you deploy and own** (free tier).
Everyone uses their own Worker — your configs stay in your own Cloudflare account, not
ours.

1. Cloudflare dashboard → **Workers & Pages → Create → Worker**, name it `happwn`.
2. **Edit code** → paste the contents of
   [`worker/worker.js`](worker/worker.js) → **Deploy**.
3. **Storage & Databases → KV → Create a namespace** (e.g. `happwn-subs`).
4. Worker → **Settings → Bindings → Add → KV namespace**: variable name **`SUBS`**,
   select your namespace → **Save and deploy**.
5. Copy your Worker URL, e.g. `https://happwn.<you>.workers.dev`
   (open it in a browser — it should reply `happwn worker`).
6. On the site, open **⚙ Settings**, fill in your `User-Agent` + `X-HWID`, and paste your
   **Worker URL**. Done — no code edits needed.

Now **Create subscription** turns the decrypted link into
`https://happwn.<you>.workers.dev/sub/<token>` (base64 sub body + QR) — a real
subscription for any VPN client. Full details: [`worker/README.md`](worker/README.md).

> Want everything under your own account? Fork this repo, enable Pages (Settings → Pages
> → Source: GitHub Actions), and your site is served from `https://<you>.github.io/happwn/`.
> Each visitor still plugs in their own Worker URL.

## Tech

- Rust crypto core (`rsa`, `chacha20poly1305`, `base64`) shipped to iOS as a static `.xcframework`.
- SwiftUI app, `URLSession` networking.
- XcodeGen project, GitHub Actions (macOS) build pipeline.

## Disclaimer

For interoperability and personal use with your own subscriptions. You are responsible
for how you use it.

## License

[Apache-2.0](LICENSE).

---

<div align="center">
<sub>

Keywords: Happ decrypt · Happ decryptor · Happ decrypt iOS · decrypt happ link ·
happ crypt5 · happ crypt4 · Happ subscription · happ config extractor · vless vmess sub

</sub>
</div>
