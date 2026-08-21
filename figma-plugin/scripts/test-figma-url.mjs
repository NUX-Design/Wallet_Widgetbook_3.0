#!/usr/bin/env node
/**
 * Unit tests for src/figmaUrl.ts (parseFigmaFileKey + buildFigmaUrl).
 *
 * The source is TypeScript, so we transpile it on the fly with esbuild (already a
 * devDependency) and import the result — the test exercises the real shipped code.
 *
 * Run: `npm test` (from figma-plugin/) or `node scripts/test-figma-url.mjs`.
 */
import { build } from 'esbuild';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const built = await build({
  entryPoints: [path.resolve(__dirname, '../src/figmaUrl.ts')],
  bundle: true,
  format: 'esm',
  write: false,
  platform: 'node',
});
const mod = await import(
  'data:text/javascript;base64,' + Buffer.from(built.outputFiles[0].text).toString('base64')
);
const { parseFigmaFileKey, buildFigmaUrl } = mod;

let passed = 0;
const failures = [];
function eq(name, actual, expected) {
  if (actual === expected) passed++;
  else failures.push(name + `  (got ${JSON.stringify(actual)}, want ${JSON.stringify(expected)})`);
}

const KEY = 'FjUOKoNcn6l5FK89YoWMWP';

// --- parseFigmaFileKey: URL shapes ---
eq('design URL', parseFigmaFileKey(`https://www.figma.com/design/${KEY}/Button-dock-2.0?node-id=10449-8136`), KEY);
eq('design URL no node', parseFigmaFileKey(`https://www.figma.com/design/${KEY}/Button-dock-2.0`), KEY);
eq('legacy file URL', parseFigmaFileKey(`https://www.figma.com/file/${KEY}/Some-Name`), KEY);
eq('board URL', parseFigmaFileKey(`https://www.figma.com/board/${KEY}/Jam`), KEY);
eq('slides URL', parseFigmaFileKey(`https://www.figma.com/slides/${KEY}/Deck`), KEY);
eq('proto URL', parseFigmaFileKey(`https://www.figma.com/proto/${KEY}/Proto?node-id=1-2`), KEY);
eq('no www', parseFigmaFileKey(`https://figma.com/design/${KEY}/x`), KEY);
eq('trailing query t=', parseFigmaFileKey(`https://www.figma.com/design/${KEY}/x?node-id=1-2&t=abc-0`), KEY);
eq('whitespace trimmed', parseFigmaFileKey(`   https://www.figma.com/design/${KEY}/x   `), KEY);

// --- parseFigmaFileKey: branch URL prefers the branch key ---
const BRANCH = 'BrAnChKey1234567890';
eq('branch URL -> branch key', parseFigmaFileKey(`https://www.figma.com/design/${KEY}/branch/${BRANCH}/Name`), BRANCH);

// --- parseFigmaFileKey: bare key + rejects ---
eq('bare key', parseFigmaFileKey(KEY), KEY);
eq('reject short bare', parseFigmaFileKey('abc123'), null);
eq('reject prose', parseFigmaFileKey('not a link'), null);
eq('reject empty', parseFigmaFileKey(''), null);
eq('reject whitespace', parseFigmaFileKey('   '), null);
eq('reject null', parseFigmaFileKey(null), null);
eq('reject undefined', parseFigmaFileKey(undefined), null);
eq('reject non-figma host', parseFigmaFileKey(`https://example.com/design/${KEY}/x`), null);

// --- buildFigmaUrl ---
eq(
  'build canonical URL',
  buildFigmaUrl(KEY, 'Button dock 2.0', '10449:8136'),
  `https://www.figma.com/design/${KEY}/Button-dock-2.0?node-id=10449-8136`
);
eq(
  'build strips odd chars from name',
  buildFigmaUrl(KEY, 'My File (v2)!', '1:2'),
  `https://www.figma.com/design/${KEY}/My-File-v2?node-id=1-2`
);
eq(
  'build falls back to "file" for empty name',
  buildFigmaUrl(KEY, '', '1:2'),
  `https://www.figma.com/design/${KEY}/file?node-id=1-2`
);

// Round-trip: a built URL parses back to the same key.
eq('round-trip key', parseFigmaFileKey(buildFigmaUrl(KEY, 'Name', '1:2')), KEY);

console.log(`figma-url tests: ${passed} passed, ${failures.length} failed`);
if (failures.length) {
  for (const f of failures) console.error('  FAIL: ' + f);
  process.exit(1);
}
console.log('OK');
