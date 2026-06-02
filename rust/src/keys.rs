//! Embedded RSA key material, loaded once at runtime.

use once_cell::sync::Lazy;
use std::collections::HashMap;

/// crypt / crypt2 / crypt3 / crypt4 — PKCS#1 private keys (base64 DER), index = ordinal.
pub static PKCS1_KEYS: Lazy<Vec<String>> = Lazy::new(|| {
    serde_json::from_str(include_str!("../data/pkcs1_keys.json"))
        .expect("pkcs1_keys.json must be a JSON array of base64 strings")
});

/// crypt5 — marker (8 chars) → PKCS#8 private key (base64 DER).
pub static CRYPT5_KEYS: Lazy<HashMap<String, String>> = Lazy::new(|| {
    serde_json::from_str(include_str!("../data/expanded_rsa_keys.json"))
        .expect("expanded_rsa_keys.json must be a JSON object marker→key")
});

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn loads_all_keys() {
        assert_eq!(PKCS1_KEYS.len(), 4);
        assert_eq!(CRYPT5_KEYS.len(), 34);
    }
}
