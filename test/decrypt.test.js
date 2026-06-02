import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { decryptLink } from "../web/decrypt.js";

const read = (p) => JSON.parse(readFileSync(new URL(p, import.meta.url)));
const keys = {
  pkcs1: read("../web/pkcs1_keys.json"),
  crypt5: read("../web/expanded_rsa_keys.json"),
};

const CRYPT4 = "happ://crypt4/LOlGv0ZXi8lPDPNEPT4NjoA5GOck+iV4io1Rhmd8GS13HmQ0h7mHwylUdicX6/JFvXeAq/H/XoHbYNU1DT9pVaUjY82tmTqh42FkxZ5GzHmu45tobtPeM5fjabS3JcGTiNVO/a8YtBhpcnLFD/wZ7Ie3koAJlrWXUDmeDAxLsL649WLBE0JtN3Yehnsxh+0MG8BHSvUQDrxAW5X4A6JvRvGjZ2Nt/vvSuLQNrY8intgYlcATaDNhAcGZWIcXESe6sf8CGTbY5KIRmr2+uBERoDOvulDtHzeZxUxODoq3qPbVjURI5vUYm6o4p5KAaTDPQG2ZbJWA2uEsOogbaRCo9oxIkF/vMIBMd5IKy6KQd4Ug6KR0qqHByhcQtJc3CcPQnix7dDYLYEcnK0qP+eCYMtdLl4+o4eKPrmx5dPPdrKcp83SOvhYbm9g6MGlyqyCfh8IdO5zfGQB6MnjTzpRUKan32iFiuTBPDzFOL1aAyoA17/ZloRG+jVUYPNjqxczvUxPojruZkmA0I9FJFL/zgtE5FAUd7WBHTwBkSKHOEiPMePZfHizP+J22ZlSgSCnTOiwcyKYGiQLf7TbKsuUmqn29zidStjmMkKOEkjk21yuiD6QUDnZnGko79Jg67m3/hk4/km12ZOqH9V64T+p67/NqR0/KVIXA/jrvbtL4H2s=";
const CRYPT5 = "happ://crypt5/neirLBO3s2Y9dNfS0s14I20jIyBax2hdTEBzyJCM4og3aIxdvMC8+ocHYSeouvAtcztQV6TogDHy/CFp9KokhGguo/KptKbd4haxc6AwQOA7cT1nmGOhaXwOBS2PrUPIllVeS2wwMUGeCSI/9CfO0lSB4Wd70=rybuRkSgvpp+gKKJLC2sFFqH4VOwalpFPy2HFcpebqEaoFGG5xsp6BmAxaoseVfuiDZx1Y7qbv9JdBB1jWV17sVU7PQLkcSxlQA9/NLerxQfSWFQUBPgwroA0QAyLxaqc43GJHhZl0ozxhZ2LqnEVXJ+7186i78l4RI43qvazSzSY78k3hh6dcxwwVS9l/vBeSu1gWPp606cRDOwnR8f50WQ1zY+/hzkBfJDX59tLxwhV4c9ZKfIOTQdzW7sYqp2BO5QacpMZZDMc+u/m/RHkrKwIJVUhupSNHQ2nxntXW/i8FGlm8NCg21dSQ+go29N6tef9iTeU6+jugQ5c620uOuY5VzH99G1V6oZtWooCcdIiStC1GFB8cXHb5Q0uDaf288YporSMR7BJwlAgfa1ry/vcd9IDrGXFvhgITSw8BmAKlSK8B/84SxAbgEBZdaBR7I7+MQG/5VY8VKTA8aFSAy/N+e5NVeRoGZZKj2+bQhx2jic8CeVIuHV8XKpNEQfceSQhpIutyWsMSnG9SEWzxjGTs3sDvjSA/B1j3uMK2HAR+WfHXfOALjQD2shSI5GtomGoKZqD147uqbUlTGwdI4FCBAxg28rJh2zG+5CRC33R9VwLh3oMQuIzNn8BujyGfV5MNPa6A5diRrNvpLUpVIM3yUgYTrQ2+VUA4h4ibg=Abftjv";

test("decrypts real crypt4 to its sub URL", () => {
  assert.deepEqual(decryptLink(CRYPT4, keys), { mode: "crypt4", value: "https://premiumt.shop/sub/5ESXeShpoSc_mbKK" });
});

test("decrypts real crypt5 to its sub URL", () => {
  assert.deepEqual(decryptLink(CRYPT5, keys), { mode: "crypt5", value: "https://ph4nt0m.megafaber.ru/sub/djMsMTA1LDE3ODAyMzg0NjIf6ec469212" });
});

test("unknown format throws", () => {
  assert.throws(() => decryptLink("happ://nope/x", keys));
});
