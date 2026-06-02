# happwn

iOS config extractor for Happ subscriptions, distributed as a sideloaded `.ipa`.

Paste a `happ://` link → it is decrypted → the embedded subscription URL is fetched
with your `User-Agent` + `X-HWID` → the configs (vless / vmess / trojan / ss / …) are
listed and exportable.

## How it works

- `crypt` / `crypt2` / `crypt3` / `crypt4`: base64 → RSA PKCS#1 v1.5.
- `crypt5`: CDAB permutation → RSA key recovery → ChaCha20-Poly1305 → base64.
- Decryption runs in a Rust core (`rust/`) shipped to iOS as a static `.xcframework`.
- The subscription server requires the `Happ` `User-Agent` and your `X-HWID`; set both
  in **Settings**.

## Build

CI builds an unsigned `.ipa` on every push to `main`
(Actions → `build` → `ios` job → `happwn-ipa` artifact). The `rust-tests` job runs the
crypto tests on every push.

Local (macOS):

```bash
bash scripts/build-xcframework.sh
cd ios && xcodegen generate && open happwn.xcodeproj
```

Run the crypto tests on any platform with Rust:

```bash
cargo test --manifest-path rust/Cargo.toml
```

Install the `.ipa` with AltStore, Sideloadly, or TrollStore.

## License

Apache-2.0.
