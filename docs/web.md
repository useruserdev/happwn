# Web console

**https://useruserdev.github.io/happwn/**

Decrypts `happ://` links right in the browser — nothing leaves your device. Decryption
needs no setup. To turn the configs into a subscription URL, deploy your own Worker.

## Flow

1. Paste a `happ://` link → **Decrypt** (runs locally). The decrypted value (usually a
   subscription URL) appears with a copy button.
2. **Forge subscription** → sends the URL to your Worker, which fetches it with the right
   headers and returns a hosted `…workers.dev/sub/<token>` link, with a QR and the
   config list.

Settings (gear): `User-Agent`, `X-HWID`, and your `Worker URL` — all stored in the
browser's localStorage.

## Why a Worker is needed

A browser **cannot** set the `User-Agent` header (it's a forbidden header) and is blocked
by **CORS** from fetching the subscription server directly. So the authenticated fetch
runs server-side on a small Cloudflare Worker that you deploy and own. Setup:
[worker/README.md](../worker/README.md).

## Manual extraction (no Worker)

When a client shows **“App not supported”** (it lacks HWID support), pull the configs
yourself in a terminal:

```bash
curl -fsSL -H "User-Agent: Happ/1.0" -H "X-HWID: <your-hwid>" "<sub-url>" | base64 -d
```

The web console builds this exact command for you from the decrypted link and your
settings — just copy it.
