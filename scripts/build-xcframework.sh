#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RUST="$ROOT/rust"
OUT="$ROOT/ios/HappwnCrypto.xcframework"

rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios

( cd "$RUST" && cargo build --release --target aarch64-apple-ios )
( cd "$RUST" && cargo build --release --target aarch64-apple-ios-sim )
( cd "$RUST" && cargo build --release --target x86_64-apple-ios )

SIM_DIR="$RUST/target/universal-sim/release"
mkdir -p "$SIM_DIR"
lipo -create \
  "$RUST/target/aarch64-apple-ios-sim/release/libhappwn.a" \
  "$RUST/target/x86_64-apple-ios/release/libhappwn.a" \
  -output "$SIM_DIR/libhappwn.a"

rm -rf "$OUT"
xcodebuild -create-xcframework \
  -library "$RUST/target/aarch64-apple-ios/release/libhappwn.a" -headers "$RUST/include" \
  -library "$SIM_DIR/libhappwn.a" -headers "$RUST/include" \
  -output "$OUT"

echo "Built $OUT"
