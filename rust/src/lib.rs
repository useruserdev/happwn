//! happwn — Happ deep-link decryptor (crypt / crypt2 / crypt3 / crypt4 / crypt5).

pub mod ffi;
pub mod keys;

use crate::keys::{CRYPT5_KEYS, PKCS1_KEYS};
use base64::alphabet;
use base64::engine::{DecodePaddingMode, GeneralPurpose, GeneralPurposeConfig};
use base64::Engine;
use chacha20poly1305::aead::Aead;
use chacha20poly1305::{ChaCha20Poly1305, Key, KeyInit, Nonce};
use once_cell::sync::Lazy;
use rsa::pkcs1::DecodeRsaPrivateKey;
use rsa::pkcs8::DecodePrivateKey;
use rsa::traits::PublicKeyParts; // brings RsaPrivateKey::size() into scope
use rsa::{Pkcs1v15Encrypt, RsaPrivateKey};

/// Result of decrypting a happ:// link.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Decrypted {
    pub mode: String,
    pub value: String,
}

/// Lenient base64 engine that mirrors the browser `atob` behaviour used by the
/// reference implementation (indifferent padding, tolerate trailing bits).
static B64: Lazy<GeneralPurpose> = Lazy::new(|| {
    let cfg = GeneralPurposeConfig::new()
        .with_decode_padding_mode(DecodePaddingMode::Indifferent)
        .with_decode_allow_trailing_bits(true);
    GeneralPurpose::new(&alphabet::STANDARD, cfg)
});

/// URL-safe base64 → bytes. Normalises `-_` to `+/`, pads to a multiple of 4.
pub fn b64_url(s: &str) -> Result<Vec<u8>, String> {
    let mut t: String = s
        .chars()
        .map(|c| match c {
            '-' => '+',
            '_' => '/',
            other => other,
        })
        .collect();
    while t.len() % 4 != 0 {
        t.push('=');
    }
    B64.decode(t.as_bytes()).map_err(|e| format!("base64: {e}"))
}

/// Swap adjacent byte pairs: ABCD → BADC. Trailing odd byte is left in place.
pub fn swap_pairs(b: &[u8]) -> Vec<u8> {
    let mut out = b.to_vec();
    let mut i = 0;
    while i + 1 < out.len() {
        out.swap(i, i + 1);
        i += 2;
    }
    out
}

/// Whole-buffer CDAB permutation: every full 4-byte block ABCD → CDAB.
/// Trailing 1–3 bytes pass through unchanged.
pub fn block_pair_swap(b: &[u8]) -> Vec<u8> {
    let full = b.len() - (b.len() % 4);
    let mut out = Vec::with_capacity(b.len());
    let mut o = 0;
    while o < full {
        out.extend_from_slice(&b[o + 2..o + 4]);
        out.extend_from_slice(&b[o..o + 2]);
        o += 4;
    }
    out.extend_from_slice(&b[full..]);
    out
}

/// crypt / crypt2 / crypt3 / crypt4: base64 → RSA PKCS#1 v1.5, decrypted in
/// modulus-sized chunks, concatenated into the UTF-8 plaintext.
fn decrypt_crypt1to4(ordinal: usize, payload: &str) -> Result<String, String> {
    let key_b64 = PKCS1_KEYS.get(ordinal).ok_or("no key for ordinal")?;
    let der = B64
        .decode(key_b64.as_bytes())
        .map_err(|e| format!("key base64: {e}"))?;
    let key = RsaPrivateKey::from_pkcs1_der(&der).map_err(|e| format!("pkcs1 key: {e}"))?;
    let key_size = key.size();
    let cipher = b64_url(payload)?;

    let mut plain = Vec::new();
    let mut i = 0;
    while i < cipher.len() {
        let end = usize::min(i + key_size, cipher.len());
        let chunk = key
            .decrypt(Pkcs1v15Encrypt, &cipher[i..end])
            .map_err(|e| format!("rsa decrypt: {e}"))?;
        plain.extend_from_slice(&chunk);
        i += key_size;
    }
    String::from_utf8(plain).map_err(|e| format!("utf8: {e}"))
}

/// crypt5: CDAB permute → split marker/body → parse nonce + length-prefixed
/// segment → RSA-recover the ChaCha key → ChaCha20-Poly1305 decrypt → final base64.
fn decrypt_crypt5(payload: &str) -> Result<String, String> {
    let shuffled = block_pair_swap(payload.as_bytes());
    if shuffled.len() < 8 {
        return Err("crypt5 payload too short".into());
    }
    let n = shuffled.len();
    let marker_bytes = [&shuffled[0..4], &shuffled[n - 4..n]].concat();
    let marker = String::from_utf8(marker_bytes).map_err(|e| format!("marker utf8: {e}"))?;
    let body = &shuffled[4..n - 4];
    if body.len() < 13 {
        return Err("crypt5 body too short".into());
    }

    let nonce_str = &body[0..12];
    let rest = &body[12..];

    // leading ASCII digits = segment length
    let digit_len = rest.iter().take_while(|b| b.is_ascii_digit()).count();
    if digit_len == 0 {
        return Err("crypt5 segment length missing".into());
    }
    let segment_len: usize = std::str::from_utf8(&rest[..digit_len])
        .expect("ascii digits") // digit_len counts is_ascii_digit() bytes, so always valid UTF-8
        .parse()
        .map_err(|_| "crypt5 bad segment length")?;
    let packed = &rest[digit_len..];
    if packed.len() < 1 + segment_len {
        return Err("crypt5 segment truncated".into());
    }
    let url_b64 =
        std::str::from_utf8(&packed[1..1 + segment_len]).map_err(|e| format!("url utf8: {e}"))?;
    let enc_str =
        std::str::from_utf8(&packed[1 + segment_len..]).map_err(|e| format!("enc utf8: {e}"))?;

    let key_b64 = CRYPT5_KEYS
        .get(&marker)
        .ok_or(format!("no key for marker {marker}"))?;
    let der = B64
        .decode(key_b64.as_bytes())
        .map_err(|e| format!("key base64: {e}"))?;
    let rsa_key = RsaPrivateKey::from_pkcs8_der(&der).map_err(|e| format!("pkcs8 key: {e}"))?;

    let rsa_plain = rsa_key
        .decrypt(Pkcs1v15Encrypt, &b64_url(enc_str)?)
        .map_err(|e| format!("rsa decrypt: {e}"))?;

    let chacha_key_bytes = b64_url(
        std::str::from_utf8(&swap_pairs(&rsa_plain)).map_err(|e| format!("rsa plain utf8: {e}"))?,
    )?;
    if chacha_key_bytes.len() != 32 {
        return Err(format!(
            "chacha key must be 32 bytes, got {}",
            chacha_key_bytes.len()
        ));
    }
    if nonce_str.len() != 12 {
        return Err("nonce must be 12 bytes".into());
    }

    let cipher = ChaCha20Poly1305::new(Key::from_slice(&chacha_key_bytes));
    let ct = b64_url(url_b64)?; // ciphertext || 16-byte tag (AEAD format)
    let intermediate = cipher
        .decrypt(Nonce::from_slice(nonce_str), ct.as_ref())
        .map_err(|_| "chacha20poly1305 decrypt failed (auth)".to_string())?;

    let final_bytes = b64_url(
        std::str::from_utf8(&swap_pairs(&intermediate))
            .map_err(|e| format!("intermediate utf8: {e}"))?,
    )?;
    String::from_utf8(final_bytes).map_err(|e| format!("final utf8: {e}"))
}

/// Decrypt a happ:// link. Returns the detected mode and the plaintext (usually a URL).
pub fn decrypt(link: &str) -> Result<Decrypted, String> {
    let path = link.strip_prefix("happ://").unwrap_or(link);

    let (mode, value) = if let Some(p) = path.strip_prefix("crypt5/") {
        ("crypt5", decrypt_crypt5(p)?)
    } else if let Some(p) = path.strip_prefix("crypt4/") {
        ("crypt4", decrypt_crypt1to4(3, p)?)
    } else if let Some(p) = path.strip_prefix("crypt3/") {
        ("crypt3", decrypt_crypt1to4(2, p)?)
    } else if let Some(p) = path.strip_prefix("crypt2/") {
        ("crypt2", decrypt_crypt1to4(1, p)?)
    } else if let Some(p) = path.strip_prefix("crypt/") {
        ("crypt", decrypt_crypt1to4(0, p)?)
    } else {
        return Err(format!("unknown link format: {link}"));
    };

    Ok(Decrypted {
        mode: mode.to_string(),
        value,
    })
}

#[cfg(test)]
mod helper_tests {
    use super::*;

    #[test]
    fn swap_pairs_swaps_adjacent() {
        assert_eq!(swap_pairs(b"ABCD"), b"BADC");
        assert_eq!(swap_pairs(b"ABCDE"), b"BADCE"); // trailing byte stays
    }

    #[test]
    fn block_pair_swap_cdab() {
        assert_eq!(block_pair_swap(b"ABCD"), b"CDAB");
        assert_eq!(block_pair_swap(b"ABCDEF"), b"CDABEF"); // trailing 2 pass through
    }

    #[test]
    fn b64_url_decodes_urlsafe() {
        assert_eq!(b64_url("TWFu").unwrap(), b"Man");
        assert_eq!(b64_url("TWE").unwrap(), b"Ma");
    }
}

#[cfg(test)]
mod crypt1to4_tests {
    use super::*;

    const CRYPT4_PAYLOAD: &str = "LOlGv0ZXi8lPDPNEPT4NjoA5GOck+iV4io1Rhmd8GS13HmQ0h7mHwylUdicX6/JFvXeAq/H/XoHbYNU1DT9pVaUjY82tmTqh42FkxZ5GzHmu45tobtPeM5fjabS3JcGTiNVO/a8YtBhpcnLFD/wZ7Ie3koAJlrWXUDmeDAxLsL649WLBE0JtN3Yehnsxh+0MG8BHSvUQDrxAW5X4A6JvRvGjZ2Nt/vvSuLQNrY8intgYlcATaDNhAcGZWIcXESe6sf8CGTbY5KIRmr2+uBERoDOvulDtHzeZxUxODoq3qPbVjURI5vUYm6o4p5KAaTDPQG2ZbJWA2uEsOogbaRCo9oxIkF/vMIBMd5IKy6KQd4Ug6KR0qqHByhcQtJc3CcPQnix7dDYLYEcnK0qP+eCYMtdLl4+o4eKPrmx5dPPdrKcp83SOvhYbm9g6MGlyqyCfh8IdO5zfGQB6MnjTzpRUKan32iFiuTBPDzFOL1aAyoA17/ZloRG+jVUYPNjqxczvUxPojruZkmA0I9FJFL/zgtE5FAUd7WBHTwBkSKHOEiPMePZfHizP+J22ZlSgSCnTOiwcyKYGiQLf7TbKsuUmqn29zidStjmMkKOEkjk21yuiD6QUDnZnGko79Jg67m3/hk4/km12ZOqH9V64T+p67/NqR0/KVIXA/jrvbtL4H2s=";

    #[test]
    fn decrypts_real_crypt4() {
        let out = decrypt_crypt1to4(3, CRYPT4_PAYLOAD).unwrap();
        assert_eq!(out, "https://premiumt.shop/sub/5ESXeShpoSc_mbKK");
    }
}

#[cfg(test)]
mod crypt5_tests {
    use super::*;

    const CRYPT5_PAYLOAD: &str = "neirLBO3s2Y9dNfS0s14I20jIyBax2hdTEBzyJCM4og3aIxdvMC8+ocHYSeouvAtcztQV6TogDHy/CFp9KokhGguo/KptKbd4haxc6AwQOA7cT1nmGOhaXwOBS2PrUPIllVeS2wwMUGeCSI/9CfO0lSB4Wd70=rybuRkSgvpp+gKKJLC2sFFqH4VOwalpFPy2HFcpebqEaoFGG5xsp6BmAxaoseVfuiDZx1Y7qbv9JdBB1jWV17sVU7PQLkcSxlQA9/NLerxQfSWFQUBPgwroA0QAyLxaqc43GJHhZl0ozxhZ2LqnEVXJ+7186i78l4RI43qvazSzSY78k3hh6dcxwwVS9l/vBeSu1gWPp606cRDOwnR8f50WQ1zY+/hzkBfJDX59tLxwhV4c9ZKfIOTQdzW7sYqp2BO5QacpMZZDMc+u/m/RHkrKwIJVUhupSNHQ2nxntXW/i8FGlm8NCg21dSQ+go29N6tef9iTeU6+jugQ5c620uOuY5VzH99G1V6oZtWooCcdIiStC1GFB8cXHb5Q0uDaf288YporSMR7BJwlAgfa1ry/vcd9IDrGXFvhgITSw8BmAKlSK8B/84SxAbgEBZdaBR7I7+MQG/5VY8VKTA8aFSAy/N+e5NVeRoGZZKj2+bQhx2jic8CeVIuHV8XKpNEQfceSQhpIutyWsMSnG9SEWzxjGTs3sDvjSA/B1j3uMK2HAR+WfHXfOALjQD2shSI5GtomGoKZqD147uqbUlTGwdI4FCBAxg28rJh2zG+5CRC33R9VwLh3oMQuIzNn8BujyGfV5MNPa6A5diRrNvpLUpVIM3yUgYTrQ2+VUA4h4ibg=Abftjv";

    #[test]
    fn decrypts_real_crypt5() {
        let out = decrypt_crypt5(CRYPT5_PAYLOAD).unwrap();
        assert_eq!(
            out,
            "https://ph4nt0m.megafaber.ru/sub/djMsMTA1LDE3ODAyMzg0NjIf6ec469212"
        );
    }
}
