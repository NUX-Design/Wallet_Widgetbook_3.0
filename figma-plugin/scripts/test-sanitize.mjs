#!/usr/bin/env node
/**
 * Unit tests for src/sanitize.ts (safeStringify + sanitizeText).
 *
 * The source is TypeScript, so we transpile it on the fly with esbuild (already a
 * devDependency) and import the result — the test exercises the real shipped code,
 * not a copy.
 *
 * Run: `npm test` (from figma-plugin/) or `node scripts/test-sanitize.mjs`.
 */
import { build } from 'esbuild';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const built = await build({
  entryPoints: [path.resolve(__dirname, '../src/sanitize.ts')],
  bundle: true,
  format: 'esm',
  write: false,
  platform: 'node',
});
const mod = await import(
  'data:text/javascript;base64,' + Buffer.from(built.outputFiles[0].text).toString('base64')
);
const { sanitizeText, safeStringify } = mod;

let passed = 0;
const failures = [];
function check(name, cond) {
  if (cond) {
    passed++;
  } else {
    failures.push(name);
  }
}
function eq(name, actual, expected) {
  check(name + `  (got ${JSON.stringify(actual)}, want ${JSON.stringify(expected)})`, actual === expected);
}

// Common code points, by name.
const LS = '\u2028';
const PS = '\u2029';
const NEL = '\u0085';
const ZWSP = '\u200B';
const BOM = '\uFEFF';
const LRM = '\u200E'; // bidi
const RLO = '\u202E'; // bidi
const NUL = '\u0000';
const BEL = '\u0007';
const US = '\u001F';
const DEL = '\u007F';

// --- sanitizeText: line/paragraph separators become \n ---
eq('LS -> \\n', sanitizeText(`a${LS}b`), 'a\nb');
eq('PS -> \\n', sanitizeText(`a${PS}b`), 'a\nb');
eq('NEL -> \\n', sanitizeText(`a${NEL}b`), 'a\nb');
eq('CRLF -> \\n', sanitizeText('a\r\nb'), 'a\nb');
eq('CR -> \\n', sanitizeText('a\rb'), 'a\nb');

// --- sanitizeText: zero-width / BOM / bidi controls are stripped ---
eq('ZWSP stripped', sanitizeText(`a${ZWSP}b`), 'ab');
eq('BOM stripped', sanitizeText(`${BOM}ab`), 'ab');
eq('LRM stripped', sanitizeText(`a${LRM}b`), 'ab');
eq('RLO stripped', sanitizeText(`a${RLO}b`), 'ab');

// --- sanitizeText: C0/C1 control chars stripped, \t and \n kept ---
eq('NUL stripped', sanitizeText(`a${NUL}b`), 'ab');
eq('BEL stripped', sanitizeText(`a${BEL}b`), 'ab');
eq('US stripped', sanitizeText(`a${US}b`), 'ab');
eq('DEL stripped', sanitizeText(`a${DEL}b`), 'ab');
eq('TAB kept', sanitizeText('a\tb'), 'a\tb');
eq('LF kept', sanitizeText('a\nb'), 'a\nb');

// --- sanitizeText: printable content is untouched ---
eq('accents kept', sanitizeText('café'), 'café');
eq('CJK kept', sanitizeText('日本語'), '日本語');
eq('emoji kept', sanitizeText('ok 😀'), 'ok 😀');
eq('null passthrough', sanitizeText(null), null);
eq('undefined passthrough', sanitizeText(undefined), undefined);

// --- sanitizeText: real-world repro (the dock optionalContext shape) ---
eq(
  'multi-LS prose normalized',
  sanitizeText(`Dock has slots${LS}${LS}make sure padding is right.`),
  'Dock has slots\n\nmake sure padding is right.'
);

// --- safeStringify: lossless escaping of LS/PS, no literal terminators on disk ---
const payload = { a: `x${LS}y`, b: `p${PS}q`, name: `layer${LS}name` };
const out = safeStringify(payload);
check('safeStringify: no literal U+2028 in output', !out.includes(LS));
check('safeStringify: no literal U+2029 in output', !out.includes(PS));
check('safeStringify: emits \\u2028 escape', out.includes('\\u2028'));
check('safeStringify: emits \\u2029 escape', out.includes('\\u2029'));

// Round-trip: parsing restores the EXACT original (lossless) — including identity
// strings, which safeStringify must never mutate.
const round = JSON.parse(out);
eq('safeStringify round-trip a', round.a, `x${LS}y`);
eq('safeStringify round-trip b', round.b, `p${PS}q`);
eq('safeStringify round-trip identity name', round.name, `layer${LS}name`);

// safeStringify matches JSON.stringify for content without LS/PS.
const plain = { k: 'café 😀', n: 3, arr: [1, 2] };
eq('safeStringify == JSON.stringify (no LS/PS)', safeStringify(plain), JSON.stringify(plain));

// --- report ---
console.log(`sanitize tests: ${passed} passed, ${failures.length} failed`);
if (failures.length) {
  for (const f of failures) console.error('  FAIL: ' + f);
  process.exit(1);
}
console.log('OK');
