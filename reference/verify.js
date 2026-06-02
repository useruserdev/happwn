// Verification spike: replicate happ decrypt logic with Node built-in crypto.
// Proves keys + algorithm decrypt the user's real crypt4 + crypt5 links.
const fs = require('fs');
const crypto = require('crypto');

// --- pull the 4 PKCS1 keys out of the reference decrypt.js -------------------
const js = fs.readFileSync(__dirname + '/decrypt.js', 'utf8');
const arrBody = js.split('PKCS1_KEYS_B64 = [')[1].split('];')[0];
const PKCS1_KEYS_B64 = [...arrBody.matchAll(/"([A-Za-z0-9+/=]{200,})"/g)].map(m => m[1]);
const crypt5Keys = JSON.parse(fs.readFileSync(__dirname + '/expanded_rsa_keys.json', 'utf8'));

// --- helpers ----------------------------------------------------------------
const swapPairs = (s) => {
  const a = [...s];
  for (let i = 0; i + 1 < a.length; i += 2) [a[i], a[i + 1]] = [a[i + 1], a[i]];
  return a.join('');
};
const b64UrlSafe = (s) => {
  s = s.replace(/-/g, '+').replace(/_/g, '/');
  while (s.length % 4) s += '=';
  return Buffer.from(s, 'base64');
};
const blockPairSwap = (s) => {
  const full = s.length - (s.length % 4);
  let out = '';
  for (let o = 0; o < full; o += 4) out += s.slice(o + 2, o + 4) + s.slice(o, o + 2);
  return out + s.slice(full);
};
const pem = (b64, header) =>
  `-----BEGIN ${header}-----\n${b64.replace(/\s/g, '').match(/.{1,64}/g).join('\n')}\n-----END ${header}-----`;

function rsaDecryptChunks(keyB64, header, cipher) {
  const key = crypto.createPrivateKey(pem(keyB64, header));
  const keySize = key.asymmetricKeyDetails.modulusLength / 8;
  const parts = [];
  for (let i = 0; i < cipher.length; i += keySize) {
    parts.push(crypto.privateDecrypt(
      { key, padding: crypto.constants.RSA_PKCS1_PADDING },
      cipher.subarray(i, i + keySize)));
  }
  return Buffer.concat(parts);
}

function decryptCrypt1to4(ordinal, payload) {
  return rsaDecryptChunks(PKCS1_KEYS_B64[ordinal], 'RSA PRIVATE KEY', b64UrlSafe(payload)).toString('utf8');
}

function decryptCrypt5(payload) {
  const shuffled = blockPairSwap(payload);
  const marker = shuffled.slice(0, 4) + shuffled.slice(-4);
  const body = shuffled.slice(4, -4);
  const nonceStr = body.slice(0, 12);
  const rest = body.slice(12);
  const digits = rest.match(/^(\d+)/)[1];
  const segLen = parseInt(digits, 10);
  const packed = rest.slice(digits.length);
  const urlB64 = packed.slice(1, 1 + segLen);
  const encStr = packed.slice(1 + segLen);

  const keyB64 = crypt5Keys[marker];
  if (!keyB64) throw new Error('no key for marker ' + JSON.stringify(marker));

  // RSA (PKCS8) decrypt -> latin string -> swapPairs -> b64 -> 32-byte chacha key
  const key = crypto.createPrivateKey(pem(keyB64, 'PRIVATE KEY'));
  const rsaPlain = crypto.privateDecrypt({ key, padding: crypto.constants.RSA_PKCS1_PADDING }, b64UrlSafe(encStr));
  const rsaPlainStr = rsaPlain.toString('latin1');
  const chachaKey = b64UrlSafe(swapPairs(rsaPlainStr));
  const nonce = Buffer.from(nonceStr, 'utf8');

  const ct = b64UrlSafe(urlB64);
  const tag = ct.subarray(ct.length - 16);
  const data = ct.subarray(0, ct.length - 16);
  const dec = crypto.createDecipheriv('chacha20-poly1305', chachaKey, nonce, { authTagLength: 16 });
  dec.setAuthTag(tag);
  const intermediate = Buffer.concat([dec.update(data), dec.final()]);
  return b64UrlSafe(swapPairs(intermediate.toString('utf8'))).toString('utf8');
}

function decryptLink(link) {
  const p = link.startsWith('happ://') ? link.slice(7) : link;
  if (p.startsWith('crypt5/')) return ['crypt5', decryptCrypt5(p.slice(7))];
  if (p.startsWith('crypt4/')) return ['crypt4', decryptCrypt1to4(3, p.slice(7))];
  if (p.startsWith('crypt3/')) return ['crypt3', decryptCrypt1to4(2, p.slice(7))];
  if (p.startsWith('crypt2/')) return ['crypt2', decryptCrypt1to4(1, p.slice(7))];
  if (p.startsWith('crypt/'))  return ['crypt',  decryptCrypt1to4(0, p.slice(6))];
  throw new Error('unknown format');
}

console.log('loaded PKCS1 keys:', PKCS1_KEYS_B64.length, '| crypt5 markers:', Object.keys(crypt5Keys).length);
for (const link of process.argv.slice(2)) {
  try {
    const [mode, val] = decryptLink(link);
    console.log(`\n[${mode}] OK -> ${val}`);
  } catch (e) {
    console.log(`\nFAIL -> ${e.message}`);
  }
}
