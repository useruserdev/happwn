# iOS app

A config extractor, distributed as an unsigned `.ipa` and sideloaded — no App Store.

## Install

1. Download the latest `happwn-*.ipa` from [Releases](../../../releases/latest).
2. Sideload it with **AltStore**, **Sideloadly**, or **TrollStore**.
3. Open the app → **Settings** → set your `User-Agent` and `X-HWID`.
4. Paste a `happ://` link and tap **Extract**.

## Using it

- Paste a `happ://crypt…` link → the app decrypts it and follows the embedded
  subscription URL using your `User-Agent` + `X-HWID`.
- The configs (`vless`, `vmess`, `trojan`, `ss`, …) are listed — tap to copy one,
  copy all, share, or export.
- If a server returns nothing recognizable, the raw response is shown for inspection.

## Settings

| Field | Meaning |
| ----- | ------- |
| `User-Agent` | The value the subscription server expects (e.g. `Happ/x.y`). |
| `X-HWID` | Your device id; the server binds the subscription to it. |

Both are stored locally on the device only.

## How it builds

CI on GitHub Actions (macOS) compiles the Rust crypto core into an `.xcframework`,
builds the SwiftUI app, runs the tests, and publishes a versioned unsigned `.ipa` to
Releases on every push to `main`. No Mac required to get a build.

Local build (macOS):

```bash
bash scripts/build-xcframework.sh
cd ios && xcodegen generate && open happwn.xcodeproj
```
