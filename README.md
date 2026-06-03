<div align="center">

<img src="assets/icon.png" width="92" alt="happwn" />

# happwn

**Happ decrypt for iOS & web.**
Unlock `happ://` links and forge a subscription URL — on your device.

[![build](https://github.com/useruserdev/happwn/actions/workflows/build.yml/badge.svg)](https://github.com/useruserdev/happwn/actions)
&nbsp;[![license](https://img.shields.io/badge/license-Apache--2.0-555)](LICENSE)

</div>

---

happwn decrypts a `happ://` link, follows the embedded subscription with the required
`User-Agent` + `X-HWID`, and gives you back the raw configs — as an app, a web console,
or a ready-to-use subscription link.

<br>

|            |                                                                                   |
| ---------- | --------------------------------------------------------------------------------- |
| **iOS**    | Sideload the `.ipa` from [**Releases**](../../releases/latest) (AltStore · Sideloadly · TrollStore) |
| **Web**    | Open the console → [**useruserdev.github.io/happwn**](https://useruserdev.github.io/happwn/) |
| **Subscription** | Deploy your own free Cloudflare [**Worker**](worker/README.md), paste its URL in Settings |

<br>

**Schemes** `crypt` · `crypt2` · `crypt3` · `crypt4` · `crypt5`
&nbsp;&nbsp;—&nbsp;&nbsp;RSA PKCS#1 v1.5 and ChaCha20-Poly1305, decrypted locally.

<br>

<sub>Apache-2.0 · for interoperability and personal use with your own subscriptions</sub>
