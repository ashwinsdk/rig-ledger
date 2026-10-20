// Fails if a raw color (hex or rgb/rgba/hsl) appears outside the token blocks (CSS custom property declarations).
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const here = path.dirname(fileURLToPath(import.meta.url));
const src = fs.readFileSync(path.resolve(here, '..', 'rigledger_apple_mockup.html'), 'utf8');
const lines = src.split('\n');
const colorRe = /#[0-9a-fA-F]{3,8}\b|\brgba?\(|\bhsla?\(/g;
let bad = 0;
lines.forEach((ln, i) => {
  // allowed: a line whose color usages are all inside a custom property declaration "--name:value"
  const stripped = ln.replace(/--[a-z0-9-]+\s*:\s*[^;}]*[;}]?/gi, '');
  if (/^\s*<meta|^<script>\(function/.test(ln)) return;
  const m = stripped.match(colorRe);
  if (m) { bad++; console.log(`${i + 1}: ${m.join(' ')}  ::  ${ln.trim().slice(0, 110)}`); }
});
console.log(bad ? `RAW COLORS OUTSIDE TOKENS: ${bad} lines` : 'OK: no raw colors outside tokens');
process.exit(bad ? 1 : 0);
