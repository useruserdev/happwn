# FAQ & troubleshooting

**“Server rejected — check User-Agent and X-HWID”**
The subscription server requires the exact Happ `User-Agent` and your device's `X-HWID`.
Set both in Settings and try again.

**A client shows “App not supported”**
That client has no HWID support, so it can't load the link directly. Use happwn (app or
web) to decrypt and pull the configs, or run the manual `curl` command from
[web.md](web.md#manual-extraction-no-worker).

**“Decrypt failed”**
The link isn't a supported `happ://` scheme (`crypt`–`crypt5`) or it's malformed/truncated.
Copy the full link again.

**Web: “Forge failed” / network error**
Your `Worker URL` isn't set, or the Worker can't reach the subscription server. Confirm
the Worker is deployed with the `SUBS` KV binding and the URL is pasted in Settings.
See [worker/README.md](../worker/README.md).

**Nothing parsed — only a raw response**
The server returned something that isn't a recognized config list. The raw body is shown
so you can inspect it; the link or your headers may be wrong.

**Is my data private?**
Decryption happens on your device. The web subscription is stored in **your own**
Cloudflare KV under a random, unguessable token (7-day expiry). Nothing is sent to us.
