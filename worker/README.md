# happwn Worker

Fetches a Happ subscription URL with the required headers (`User-Agent` + `X-HWID`, which
a browser cannot send) and hosts the configs as a subscription at `/sub/<token>`.

## Deploy (dashboard, no CLI)

1. Cloudflare dashboard -> Workers & Pages -> Create -> Worker. Name it `happwn`.
2. Edit code -> paste the contents of `worker.js` -> Deploy.
3. Storage & Databases -> KV -> Create a namespace, e.g. `happwn-subs`.
4. Worker -> Settings -> Bindings -> Add -> KV namespace: variable name `SUBS`,
   select `happwn-subs` -> Save and deploy.
5. Copy the Worker URL (e.g. `https://happwn.<you>.workers.dev`).
6. Open the site, go to Settings, and paste your Worker URL. Done — no code edits needed.

By default the worker accepts requests from any origin (`ALLOWED_ORIGIN = "*"`), so it
works with the official site and any fork out of the box. Set `ALLOWED_ORIGIN` to your
site origin in `worker.js` if you want to restrict browser callers.

## Deploy (CLI)

```bash
cd worker
npm i -g wrangler
wrangler kv namespace create SUBS   # paste the id into wrangler.toml
wrangler deploy
```

Then open the site, go to Settings, and paste the Worker URL.

## Endpoints

- `POST /build` — JSON `{ subUrl?, configs?, userAgent, hwid }` -> fetches/normalizes,
  stores a base64 subscription in KV (7-day TTL), returns `{ token, url, count, configs }`.
- `GET /sub/<token>` — returns the base64 subscription as `text/plain` for any VPN client.

Guardrails: request body <= 256 KB, upstream body <= 1 MB, <= 5000 configs, `http(s)` only,
15s fetch timeout, CORS limited to the site origin.
