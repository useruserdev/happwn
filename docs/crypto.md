# How decryption works

`happ://` links are encrypted; happwn reverses the scheme entirely on-device.

| Scheme | Pipeline |
| ------ | -------- |
| `crypt` · `crypt2` · `crypt3` · `crypt4` | base64 → RSA PKCS#1 v1.5 |
| `crypt5` | CDAB permutation → RSA key recovery → ChaCha20-Poly1305 → base64 |

The decrypted payload is usually a **subscription URL**. Fetching it with the Happ
`User-Agent` + `X-HWID` returns the actual configs (`vless`, `vmess`, `trojan`, `ss`,
`ssr`, `hysteria2`, `tuic`, `wireguard`).

## Two implementations, one result

| Platform | Crypto |
| -------- | ------ |
| iOS | Rust core (`rsa`, `chacha20poly1305`, `base64`) shipped as a static `.xcframework` |
| Web | JavaScript (`node-forge` for RSA, `@noble/ciphers` for ChaCha20-Poly1305) |

Both embed the same keys and produce identical output. CI verifies each against the same
real `crypt4` and `crypt5` vectors on every push, so the two implementations can't drift.

## Keys

The RSA keys (4 PKCS#1 keys for `crypt`–`crypt4`, 34 marker-indexed PKCS#8 keys for
`crypt5`) are bundled with the app and site — they are what makes offline decryption
possible. They live in `rust/data/` (iOS) and `web/` (browser).
