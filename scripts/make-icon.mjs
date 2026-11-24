import fs from "node:fs";
import zlib from "node:zlib";

const SIZE = 1024;
const buf = Buffer.alloc(SIZE * SIZE * 4);

const clamp = (v, a, b) => Math.min(b, Math.max(a, v));

function blend(x, y, r, g, b, a) {
  if (x < 0 || y < 0 || x >= SIZE || y >= SIZE || a <= 0) return;
  const i = (y * SIZE + x) * 4;
  const da = buf[i + 3] / 255;
  const sa = a;
  const oa = sa + da * (1 - sa);
  if (oa <= 0) return;
  buf[i] = (r * sa + buf[i] * da * (1 - sa)) / oa;
  buf[i + 1] = (g * sa + buf[i + 1] * da * (1 - sa)) / oa;
  buf[i + 2] = (b * sa + buf[i + 2] * da * (1 - sa)) / oa;
  buf[i + 3] = oa * 255;
}

const lerp = (a, b, t) => a + (b - a) * t;

// --- rounded-square background -------------------------------------------
const R = 232;
const cx = SIZE / 2;
const cy = SIZE / 2;
const half = SIZE / 2;

function sdRoundBox(px, py, b, r) {
  const qx = Math.abs(px) - (b - r);
  const qy = Math.abs(py) - (b - r);
  return Math.hypot(Math.max(qx, 0), Math.max(qy, 0)) + Math.min(Math.max(qx, qy), 0) - r;
}

for (let y = 0; y < SIZE; y++) {
  for (let x = 0; x < SIZE; x++) {
    const px = x - cx;
    const py = y - cy;
    const d = sdRoundBox(px, py, half - 10, 228);
    const alpha = clamp(0.5 - d / 2.0, 0, 1);
    if (alpha <= 0) continue;

    const t = y / SIZE;
    let r = lerp(18, 7, t);
    let g = lerp(23, 9, t);
    let b = lerp(34, 15, t);

    // warm glow toward the top-left of the glyph area
    const glow = Math.max(0, 1 - Math.hypot(px + 120, py + 150) / 620);
    r += glow * 26;
    g += glow * 17;
    b += glow * 6;

    blend(x, y, r, g, b, alpha);
  }
}

// --- gold crescent + sparkle ---------------------------------------------
function sdCircle(px, py, x, y, r) {
  return Math.hypot(px - x, py - y) - r;
}

const outer = { x: 468, y: 536, r: 292 };
const cut = { x: 604, y: 424, r: 282 };
const star = { x: 762, y: 292, r: 52 };

for (let y = 0; y < SIZE; y++) {
  for (let x = 0; x < SIZE; x++) {
    const px = x - cx;
    const py = y - cy;

    // soft halo behind the mark
    const halo = sdCircle(px, py, outer.x - cx, outer.y - cy, outer.r + 46);
    if (halo < 0) {
      const a = clamp(-halo / 120, 0, 1) * 0.09;
      if (a > 0) blend(x, y, 232, 186, 96, a);
    }

    const outerD = sdCircle(px, py, outer.x - cx, outer.y - cy, outer.r);
    const cutD = sdCircle(px, py, cut.x - cx, cut.y - cy, cut.r);
    const alpha = Math.min(clamp(0.5 - outerD, 0, 1), clamp(0.5 + cutD, 0, 1));
    if (alpha > 0) {
      const t = clamp((y - (outer.y - outer.r)) / (outer.r * 2), 0, 1);
      const r = lerp(248, 201, t);
      const g = lerp(224, 138, t);
      const b = lerp(176, 46, t);
      blend(x, y, r, g, b, alpha);
    }

    // four-point sparkle in the crescent's opening
    const ax = Math.abs(px - (star.x - cx));
    const ay = Math.abs(py - (star.y - cy));
    const starD = Math.pow(ax, 0.55) + Math.pow(ay, 0.55) - Math.pow(star.r, 0.55);
    const starAlpha = clamp(0.7 - starD, 0, 1);
    if (starAlpha > 0) {
      blend(x, y, 246, 219, 163, starAlpha);
    }
  }
}

// --- PNG encode -----------------------------------------------------------
const crcTable = (() => {
  const t = new Int32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    t[n] = c;
  }
  return t;
})();

function crc32(data) {
  let c = -1;
  for (let i = 0; i < data.length; i++) c = crcTable[(c ^ data[i]) & 0xff] ^ (c >>> 8);
  return (c ^ -1) >>> 0;
}

function chunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length);
  const body = Buffer.concat([Buffer.from(type, "ascii"), data]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(body));
  return Buffer.concat([len, body, crc]);
}

const raw = Buffer.alloc(SIZE * (SIZE * 4 + 1));
for (let y = 0; y < SIZE; y++) {
  raw[y * (SIZE * 4 + 1)] = 0;
  buf.copy(raw, y * (SIZE * 4 + 1) + 1, y * SIZE * 4, (y + 1) * SIZE * 4);
}

const ihdr = Buffer.alloc(13);
ihdr.writeUInt32BE(SIZE, 0);
ihdr.writeUInt32BE(SIZE, 4);
ihdr[8] = 8;
ihdr[9] = 6;

const png = Buffer.concat([
  Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
  chunk("IHDR", ihdr),
  chunk("IDAT", zlib.deflateSync(raw, { level: 9 })),
  chunk("IEND", Buffer.alloc(0)),
]);

fs.mkdirSync("assets", { recursive: true });
fs.writeFileSync("assets/app-icon.png", png);
console.log("wrote assets/app-icon.png", (png.length / 1024).toFixed(1), "KB");
