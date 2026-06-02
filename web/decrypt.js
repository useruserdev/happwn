// Client-side Happ decrypt. Pure functions: the same code runs in the browser
// (bare imports resolved by the import map in index.html) and in Node tests
// (resolved from devDependencies). Keys are passed in, not embedded.
import forge from "node-forge";
import { chacha20poly1305 } from "@noble/ciphers/chacha";

const _keyCache = new Map();

function swapPairs(s) {
  const a = [...s];
  for (let i = 0; i + 1 < a.length; i += 2) [a[i], a[i + 1]] = [a[i + 1], a[i]];
  return a.join("");
}
function b64DecodeUrlSafe(s) {
  s = s.replace(/-/g, "+").replace(/_/g, "/");
  while (s.length % 4) s += "=";
  return Uint8Array.from(atob(s), (c) => c.charCodeAt(0));
}
function uint8ToLatinStr(a) {
  let s = "";
  for (let i = 0; i < a.length; i++) s += String.fromCharCode(a[i]);
  return s;
}
function latinStrToUint8(str) {
  const o = new Uint8Array(str.length);
  for (let i = 0; i < str.length; i++) o[i] = str.charCodeAt(i) & 0xff;
  return o;
}
function blockPairSwap(s) {
  const full = s.length - (s.length % 4);
  let o = "";
  for (let i = 0; i < full; i += 4) o += s.slice(i + 2, i + 4) + s.slice(i, i + 2);
  return o + s.slice(full);
}
function loadForgeKey(b64, header) {
  const c = _keyCache.get(b64);
  if (c) return c;
  const lines = b64.replace(/\s/g, "").match(/.{1,64}/g).join("\n");
  const pem = `-----BEGIN ${header}-----\n${lines}\n-----END ${header}-----`;
  const key = forge.pki.privateKeyFromPem(pem);
  _keyCache.set(b64, key);
  return key;
}
function rsaDecrypt(pk, cipher) {
  return pk.decrypt(uint8ToLatinStr(cipher));
}

function decryptCrypt1to4(ordinal, payload, pkcs1Keys) {
  const key = loadForgeKey(pkcs1Keys[ordinal], "RSA PRIVATE KEY");
  const keySize = Math.ceil(key.n.bitLength() / 8);
  const cipher = b64DecodeUrlSafe(payload);
  let plain = "";
  for (let i = 0; i < cipher.length; i += keySize) {
    plain += rsaDecrypt(key, cipher.slice(i, i + keySize));
  }
  return new TextDecoder().decode(latinStrToUint8(plain));
}

function decryptCrypt5(payload, crypt5Keys) {
  const shuffled = blockPairSwap(payload);
  if (shuffled.length < 8) throw new Error("crypt5 payload too short");
  const marker = shuffled.slice(0, 4) + shuffled.slice(-4);
  const body = shuffled.slice(4, -4);
  if (body.length < 13) throw new Error("crypt5 body too short");
  const nonceStr = body.slice(0, 12);
  const rest = body.slice(12);
  const digits = rest.match(/^(\d+)/);
  if (!digits) throw new Error("crypt5 segment length missing");
  const segLen = parseInt(digits[1], 10);
  const packed = rest.slice(digits[1].length);
  if (packed.length < 1 + segLen) throw new Error("crypt5 segment truncated");
  const urlB64 = packed.slice(1, 1 + segLen);
  const encStr = packed.slice(1 + segLen);

  const keyB64 = crypt5Keys[marker];
  if (!keyB64) throw new Error(`no key for marker ${marker}`);
  const pk = loadForgeKey(keyB64, "PRIVATE KEY");
  const rsaPlainStr = rsaDecrypt(pk, b64DecodeUrlSafe(encStr));

  const chachaKey = b64DecodeUrlSafe(swapPairs(rsaPlainStr));
  const nonce = new TextEncoder().encode(nonceStr);
  const intermediate = chacha20poly1305(chachaKey, nonce).decrypt(b64DecodeUrlSafe(urlB64));
  const intermediateStr = new TextDecoder().decode(intermediate);
  return new TextDecoder().decode(b64DecodeUrlSafe(swapPairs(intermediateStr)));
}

/**
 * Decrypt a happ:// link.
 * @param {string} link
 * @param {{ pkcs1: string[], crypt5: Record<string,string> }} keys
 * @returns {{ mode: string, value: string }}
 */
export function decryptLink(link, keys) {
  const path = link.startsWith("happ://") ? link.slice(7) : link;
  if (path.startsWith("crypt5/")) return { mode: "crypt5", value: decryptCrypt5(path.slice(7), keys.crypt5) };
  if (path.startsWith("crypt4/")) return { mode: "crypt4", value: decryptCrypt1to4(3, path.slice(7), keys.pkcs1) };
  if (path.startsWith("crypt3/")) return { mode: "crypt3", value: decryptCrypt1to4(2, path.slice(7), keys.pkcs1) };
  if (path.startsWith("crypt2/")) return { mode: "crypt2", value: decryptCrypt1to4(1, path.slice(7), keys.pkcs1) };
  if (path.startsWith("crypt/")) return { mode: "crypt", value: decryptCrypt1to4(0, path.slice(6), keys.pkcs1) };
  throw new Error(`Unknown link format: ${link}`);
}
