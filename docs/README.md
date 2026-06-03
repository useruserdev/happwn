# happwn docs

happwn decrypts Happ `happ://` links and turns the configs into something you can use —
an iOS app, a web console, or a hosted subscription URL. Everything decrypts on-device.

## Contents

- [iOS app](ios.md) — install the sideloaded `.ipa`, settings, how it builds
- [Web console](web.md) — browser decrypt, manual extraction
- [Subscription Worker](../worker/README.md) — deploy your own Cloudflare Worker
- [How decryption works](crypto.md) — schemes, crypto, keys
- [FAQ & troubleshooting](faq.md)

## At a glance

```
happ://crypt…  ──decrypt──▶  subscription URL
                               │  GET with User-Agent + X-HWID
                               ▼
                          configs (vless / vmess / trojan / …)
```

The subscription server rejects requests that don't carry the Happ `User-Agent` and your
`X-HWID`, so those are set in Settings (app or web).
