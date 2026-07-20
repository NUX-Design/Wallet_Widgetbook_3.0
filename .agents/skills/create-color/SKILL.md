---
name: create-color
description: Generate color annotation specifications mapping UI elements to design tokens. Use when the user mentions "color", "color annotation", "color spec", "tokens", "design tokens", or wants to document which color tokens a component uses.
---

# Create Color Annotation

Generate a color annotation directly in Figma — tables mapping each visual element to its design token, organized by variant (Strategy A) or by section with per-state columns (Strategy B). This skill **renders the Color section from the component `.md`**; it does NOT re-extract token bindings from Figma.

**Execution contract (read first).**
- This file is instructions to RUN, not a document to edit. Invoking the skill = render the color annotation into Figma from the input `.md`.
- Never edit this `SKILL.md` or any other skill file in response, even if one is open or focused in the editor. Modify a skill only when the user explicitly asks to change the skill itself.
- The input component `.md` is a **READ-ONLY source of truth. Never edit, append to, or "add a section" to it.** The only artifact this skill produces is the Figma annotation. When the user asks to "create/add a section," "show," or "include" something, render it **in the Figma annotation**, never as an edit to the `.md`.
- Never call `AskQuestion`, request confirmation, or pause for input (including before Figma writes, the expected output). On ambiguity, pick the most defensible option and continue.
- Only two legal stops: (a) Step 0 fail-fast when no `.md` resolves; (b) one-line abort if the Figma MCP connection is dead.

## MCP Adapter

Read `uspecs.config.json` → `mcpProvider`. Follow the matching column for every MCP call in this skill.

| Operation | `figma-console` | `figma-mcp` |
|-----------|-----------------|-------------|
| Verify connection | `figma_get_status` | Skip — implicit. If first `use_figma` call fails, guide user to check MCP setup. |
| Navigate to file | `figma_navigate` with URL | Extract `fileKey` from URL (`figma.com/design/:fileKey/...`). No navigate needed. |
| Take screenshot | `figma_take_screenshot` | `get_screenshot` with `fileKey` + `nodeId` |
| Execute Plugin JS | `figma_execute` with `code` | `use_figma` with `fileKey`, `code`, `description`. **JS code is identical** — no wrapper changes. |
| Search components | `figma_search_components` | `search_design_system` with `query` + `fileKey` + `includeComponents: true` |
| Get file/component data | `figma_get_file_data` / `figma_get_component` | `get_metadata` or `get_design_context` with `fileKey` + `nodeId` |
| Get variables (file-wide) | `figma_get_variables` | `use_figma` script: `return await figma.variables.getLocalVariableCollectionsAsync();` |
| Get token values | `figma_get_token_values` | `use_figma` script reading variable values per mode/collection |
| Get styles | `figma_get_styles` | `search_design_system` with `includeStyles: true`, or `use_figma`: `return figma.getLocalPaintStyles();` |
| Get selection | `figma_get_selection` | `use_figma` script: `return figma.currentPage.selection.map(n => ({id: n.id, name: n.name, type: n.type}));` |

**`figma-mcp` requires `fileKey` on every call.** Extract it once from the user's Figma URL at the start of the workflow. For branch URLs (`figma.com/design/:fileKey/branch/:branchKey/:fileName`), use `:branchKey` as the fileKey.

**`figma-mcp` page context:** `use_figma` resets `figma.currentPage` to the first page on every call. When a script accesses a node from a previous step via `getNodeByIdAsync(ID)`, the page content may not be loaded — `findAll`, `findOne`, and `characters` will fail with `TypeError` until the page is activated. Insert this page-loading block immediately after `getNodeByIdAsync`:

```javascript
let _p = node; while (_p.parent && _p.parent.type !== 'DOCUMENT') _p = _p.parent;
if (_p.type === 'PAGE') await figma.setCurrentPageAsync(_p);
```

This walks up to the PAGE ancestor and loads its content. Console MCP does not need this — `figma_execute` inherits the Desktop page context.

## Inputs Expected

- **Component `.md` spec** (**required**, user-provided path) — the source-of-truth component spec produced by the `create-component-md` skill. **The user tells you where this `.md` lives** — use the exact path they provide; the `.md` may live anywhere. This skill **renders the Color section from the `.md`**; it does NOT re-extract token bindings, variant axes, or mode collections from Figma. `fileKey`, `nodeId`, and `compSetNodeId` come from the `.md`'s `render-meta` block.
- **Figma link** (optional) — placement hint only (where to drop the rendered frame on the canvas). Never the source of structural facts.

There is no screenshot-only path and no live token-extraction path. Without the component `.md` there is nothing to render — see Step 0's fail-fast contract.

## Workflow

Copy this checklist and update as you progress:

```
Task Progress:
- [ ] Step 0: Require + parse the component `.md` (Color body + render-meta). Detect Strategy A vs B. FAIL FAST if missing.
- [ ] Step 1: Read instruction file (only as needed — NOT for re-extracting tokens)
- [ ] Step 2: Verify MCP connection (rendering requires a live Figma session)
- [ ] Step 3: Read template key from uspecs.config.json
- [ ] Step 4: Build render inputs from the parsed .md (tables verbatim, COMP_SET_ID, BOOLEAN_UNHIDES) — NO extraction
- [ ] Step 5: Re-derive per-section variantProps; for Strategy B, zip relabeled headers back to raw Figma state values
- [ ] Step 6: (Strategy B mode-controlled only) ONE whitelisted getLocalVariableCollectionsAsync() read to resolve COLLECTION_ID / MODE_ID
- [ ] Step 7: Audit the assembled render inputs against the .md
- [ ] Step 8: Import and detach the Color Annotation template
- [ ] Step 9: Fill header fields
- [ ] Step 10: Render variants/sections (Strategy A or B, one figma_execute per variant/section)
- [ ] Step 11: Visual validation
```

### Step 0: Require and parse the component `.md` (fail fast)

**This skill is a consumer of the `.md` source of truth.** It does not re-extract from Figma and does not re-run the token-resolution / axis-classification / mode-detection layer — that work already happened in `extract-color`/`create-component-md` and is baked into the `.md`'s Color section. Your job is to render that section into a Figma frame.

1. **Resolve the `.md` path.** Use the exact path the user gave, else an attached or open `.md` in context. The `.md` may live anywhere; do NOT invent or guess a path. If neither resolves to an existing file, abort per item 2. Never pause to ask the user which file to use.
2. **Require the file.** If no file exists at the resolved `.md` path, **abort immediately** with this exact single-line diagnostic and stop — do NOT fall back to extraction:

   > This skill requires the component's Markdown `.md` spec (produced by create-component-md). Provide the path to it. (create-component-md needs a _base.json from the uSpec Extract plugin.)

3. **Parse the Color section** (`## Color`) from the `.md` body. **Detect the strategy by the table shape** of the first data table:
   - **Strategy A (`ColorAnnotationData`)** when tables are shaped `Element | Token | Notes`. The body has one `###` sub-section per variant; each may carry one or more tables (a `####` heading per table when multiple).
   - **Strategy B (`ConsolidatedColorAnnotationData`)** when tables are shaped `Element | {state1} | {state2} | … | Notes`. The body has one `###` sub-section per section; each may carry one or more tables.

   For each table, capture:
   - The general-notes blockquote (`> …`) at the top of the Color body, if present → `GENERAL_NOTES`.
   - The variant name (Strategy A) or section name (Strategy B) from the `###` heading; the per-table name from the `####` heading (or the variant/section name when only one table).
   - **Token cells VERBATIM.** Each token cell is already formatted by the producer as `tokenName (#RRGGBB)`, a bare `#RRGGBB`, or `none`. **Pass these strings to the render script unchanged — do not reformat, do not strip the hex, do not re-resolve the token.**
   - **Composite children.** A row whose `Element` cell is prefixed with `└ ` or `├ ` is a composite-style child row of the row immediately above it. Collect these into a `compositeChildren` array on the parent element (`{ element, value, notes }`); the child's token/value cell is passed verbatim too.
4. **Parse the `render-meta` block** (the fenced JSON between `<!-- render-meta:start v=1 -->` and `<!-- render-meta:end -->`):
   - `COMP_SET_ID` = `render-meta.component.compSetNodeId` — for creating live preview instances.
   - `BOOLEAN_UNHIDES` — the unhide set is **ALL `render-meta.booleanDefs[]` keys**. Reshape to `[{ booleanRawKey: <key> }]`. Each `key` is the raw component-property key `setProperties` expects (it matches a `render-meta.propertyDefs` raw key). The elements these toggles reveal are already documented in the `.md` tables (create-component-md merged the boolean delta); the unhide set only exists so the preview instance shows them.
   - `variantAxes` / `variantAxesDefaults` — for Step 5 section→variant mapping.
   - `fileKey`, `nodeId` — for the Step 11 completion link and template placement.
   - `sourceHash` — recorded in the completion footer so drift between this `.md` and its `_base.json` is detectable.
5. **(Strategy B only) Parse the `stateAxisMapping`.** The Color body's per-state column headers may be **runtime-condition relabeled** by create-component-md — the visible headers can be engineer-facing conditions (`focused`, `has value && not focused`, `validationState='error'`) instead of the raw Figma state-axis options. The render script needs the **raw Figma state values** to drive `setProperties` and mode previews. Read the API `stateAxisMapping` carried in the `.md` (the `{ figmaValue, runtimeCondition }` pairs the API section surfaces). You will zip the relabeled headers back to raw Figma values in Step 5.
6. **(Strategy B mode-controlled only) Note the mode collection NAMES from the `.md`.** If the Color is mode-controlled, the **Cross-section invariants** block carries the bullet `- Color is mode-controlled by "{collectionName}" with modes: {modes}`, and/or the section titles encode the mode (e.g., `Primary / Gray`). Record `collectionName`, the mode names, and which mode each Strategy B section maps to. The IDs behind these names are resolved by the single whitelisted read in Step 6.

**FORBIDDEN — do NOT re-extract.** When the component `.md` is present (it always is past Step 0), you MUST NOT run the legacy extraction/tree-walk. Specifically:
- Do NOT run any `figma_execute` / `use_figma` script that walks the component tree to rebuild color bindings, classify variant axes, enrich booleans, or detect mode collections. **The old Step 4 / Step 4b "Consolidated Extraction Script" (the `extractColorBindings` / `walkTree` / `axisClassification` / `booleanDelta` / `modeDetection` walk) is DELETED — it does not exist in this skill anymore.** The container re-run (re-targeting the extraction at a sub-component's node ID) is **also DELETED** — container detection and per-child specs are handled by `create-component-md`'s Follow-ups, not here.
- Do NOT re-derive tokens, hex values, strategy selection, axis classification, or mode token maps — they are authored in the `.md` and copied verbatim.
- **The ONE whitelisted live read** (the ONLY Figma read beyond template import and rendering) is in Step 6: `figma.variables.getLocalVariableCollectionsAsync()` — and ONLY to resolve `COLLECTION_ID` / `MODE_ID` for Strategy B mode previews by matching the collection/mode **names** surfaced in the `.md`. This read fetches **variable collections only** — it performs **NO component-tree walk, NO color extraction, NO token-binding resolution**. It runs only when the parsed Color is Strategy B *and* mode-controlled; skip it otherwise. Any other live read is forbidden.

### Step 1: Read Instructions (only as needed)

The tokens, hex values, strategy, and per-state columns are already authored in the `.md` — you do NOT re-derive them. Read [agent-color-instruction.md](../../../references/color/agent-color-instruction.md) **only** if you need to reason about how a parsed table should map to template structure (e.g., composite-child hierarchy indicators, Strategy A vs B layout). Skip it for straightforward annotations.

### Step 2: Verify MCP Connection

Read `mcpProvider` from `uspecs.config.json` and verify the connection (rendering requires a live Figma session):

**If `figma-console`:**
- `figma_get_status` — Confirm Desktop Bridge plugin is active
- If connection fails: *"Please open Figma Desktop and run the Desktop Bridge plugin. Then try again."*

**If `figma-mcp`:**
- Connection is verified implicitly on the first `use_figma` call. No explicit check needed.
- If the first call fails: *"Please verify your FIGMA_API_KEY is set correctly in your MCP configuration."*

### Step 3: Read Template Key

Read the file `uspecs.config.json` and extract:
- The `colorAnnotation` value from the `templateKeys` object → save as `COLOR_TEMPLATE_KEY`
- The `fontFamily` value → save as `FONT_FAMILY` (default to `Inter` if not set)

If the template key is empty, tell the user:
> The color annotation template key is not configured. Run the `firstrun` skill with your Figma template library link first.

### Step 4: Build render inputs from the parsed `.md` (no extraction)

Everything the render scripts need is already in the `.md` you parsed in Step 0. Assemble the render inputs directly — there is **no extraction call** here (see the FORBIDDEN directive in Step 0).

Build these values:

- **`COMPONENT_NAME`** — `render-meta.component.componentName` (or the `.md`'s top-level `# {name}` heading).
- **`GENERAL_NOTES`** / **`HAS_GENERAL_NOTES`** — the Color body's general-notes blockquote, verbatim (and whether one exists).
- **`COMPONENT_SET_ID`** — `render-meta.component.compSetNodeId`.
- **`BOOLEAN_UNHIDES`** — `render-meta.booleanDefs[]` keys reshaped to `[{ booleanRawKey }]` (the full set; see Step 0.4). Use `[]` only when `booleanDefs` is empty.
- **`TABLES` (Strategy A)** — one entry per parsed variant table: `{ name, elements: [{ element, token, notes, compositeChildren? }] }`. The `token` field is the token cell **verbatim** from the `.md` (`tokenName (#RRGGBB)` / bare hex / `none`). `compositeChildren[]` are the `└`/`├` child rows with `{ element, value, notes }` (`value` verbatim).
- **`TABLES` (Strategy B)** — one entry per parsed section table: `{ name, elements: [{ element, tokensByState, notes, compositeChildren? }] }`. `tokensByState` maps the **raw Figma state value** (re-derived in Step 5) → token cell verbatim. `compositeChildren[]` carry a single `value` repeated across states (verbatim), matching the `.md`.

Every emitted row is sourced from the `.md` and tagged provenance **`md`**. The only non-`md` data is the live `bbox`/mode-id resolution the render path performs itself (tagged `measured`); nothing is `inferred` unless a parsed cell is missing and you must note a drift fill.

> The legacy "gather context + run the consolidated extraction script" flow has been **removed**. Do not reintroduce it. The `.md` + `render-meta` are the complete input.

### Step 5: Re-derive variant props (and, for Strategy B, the raw state values)

`VARIANT_PROPS` (and Strategy B's `STATE_COLUMNS` / `STATE_AXIS_NAME`) are the only values not copied verbatim from the `.md` — they are cheaply re-derived from `render-meta`, with no Figma reads.

- **Per-variant / per-section `VARIANT_PROPS`.** Match the variant name (Strategy A) or section name (Strategy B) to `render-meta.variantAxes` (case-insensitive option match). When a name component matches an option on an axis, set that axis to the matching value; leave the other axes at `render-meta.variantAxesDefaults`. When there is no match (behavioral/section grouping that is not a Figma variant), use `variantAxesDefaults` verbatim. The render script's scored variant matching is the safety net — `VARIANT_PROPS` is the primary lever.
- **Strategy B — zip relabeled headers back to raw Figma state values.** The render script uses `STATE_COLUMNS` to both (a) match the state variant child via `setProperties`/scoring and (b) label the columns; it therefore needs the **raw Figma state-axis options**. For each Color state column header in order, find the `stateAxisMapping[]` entry whose `runtimeCondition` equals that header and take its `figmaValue`. Build:
  - `STATE_AXIS_NAME` = the Figma state-axis name (the axis in `render-meta.variantAxes` whose options are the `stateAxisMapping[].figmaValue` set).
  - `STATE_COLUMNS` = the ordered list of `figmaValue`s, one per Color state column.
  - and key each element's `tokensByState` by those `figmaValue`s (positionally — the `.md`'s token cells are indexed by the original Figma state values; only the headers were relabeled).
  - **Abort the section with a diagnostic** if `stateAxisMapping` cannot zip 1:1 to the Color state columns (a header has no matching `runtimeCondition`, or the counts differ) — surface `Color section "{name}": stateAxisMapping does not zip 1:1 to the {N} state columns; cannot recover raw Figma state values.` and skip that section rather than rendering the wrong states. When the headers are NOT relabeled (no `stateAxisMapping`, or it does not cover the columns), the headers are already raw Figma values — use them verbatim as `STATE_COLUMNS`.

### Step 6: Resolve mode IDs (Strategy B, mode-controlled only — the single whitelisted read)

Run this **only** when the parsed Color is Strategy B *and* mode-controlled (Step 0.6 found a mode collection). This is the ONE live Figma read this skill performs beyond template import and rendering. It fetches variable collections **only** — no tree walk, no color extraction:

```javascript
return (await figma.variables.getLocalVariableCollectionsAsync())
  .map(c => ({ id: c.id, name: c.name, modes: c.modes.map(m => ({ name: m.name, modeId: m.modeId })) }));
```

From the result:
- `COLLECTION_ID` = the `id` of the collection whose `name` equals the `collectionName` recorded in Step 0.6.
- `MODE_ID` (per Strategy B section) = the `modeId` of the mode whose `name` matches the mode the section maps to (from the `.md` section title / mode list).

Set `COLLECTION_ID = ''` and `MODE_ID = ''` for any section that is not mode-controlled. Do not extend this script to read anything beyond collections/modes.

### Step 7: Audit the assembled render inputs

Before rendering, verify the inputs you built from the `.md`:
- The strategy (A vs B) matches the parsed table shape.
- Every token cell is the **verbatim** `.md` string (`tokenName (#RRGGBB)` / bare hex / `none`) — not re-resolved, not reformatted.
- Composite child rows (`└`/`├`) were collected into `compositeChildren[]` with their `value` verbatim.
- `COMPONENT_SET_ID` and `BOOLEAN_UNHIDES` come from `render-meta` — not from any live read.
- **Strategy B:** every section's `STATE_COLUMNS` are raw Figma state values (zipped from `stateAxisMapping`, or already-raw headers), and any section that failed the 1:1 zip was aborted with the diagnostic — not rendered with guessed states.
- You did NOT run an extraction/tree-walk, and you ran `getLocalVariableCollectionsAsync()` at most once (Strategy B mode-controlled only). See Step 0 FORBIDDEN.

Fix any mismatch by re-parsing the `.md` — never by re-extracting from Figma.

### Step 8: Import and Detach Template

Run via `figma_execute` (replace `__COLOR_TEMPLATE_KEY__`, `__COMPONENT_NAME__`, and `__COMPONENT_NODE_ID__` with `COMPONENT_SET_ID` = `render-meta.component.compSetNodeId`):

```javascript
const TEMPLATE_KEY = '__COLOR_TEMPLATE_KEY__';
const COMP_NODE_ID = '__COMPONENT_NODE_ID__';

const compNode = await figma.getNodeByIdAsync(COMP_NODE_ID);
let _p = compNode;
while (_p.parent && _p.parent.type !== 'DOCUMENT') _p = _p.parent;
if (_p.type === 'PAGE') await figma.setCurrentPageAsync(_p);

const templateComponent = await figma.importComponentByKeyAsync(TEMPLATE_KEY);
const instance = templateComponent.createInstance();
const frame = instance.detachInstance();

const GAP = 200;
frame.x = compNode.x + compNode.width + GAP;
frame.y = compNode.y;

frame.name = '__COMPONENT_NAME__ Color';
figma.currentPage.selection = [frame];
figma.viewport.scrollAndZoomIntoView([frame]);
return { frameId: frame.id, pageId: _p.id, pageName: _p.name };
```

Save the returned `frameId` — you need it for all subsequent steps.

### Step 9: Fill Header Fields

Run via `figma_execute` (replace `__FRAME_ID__`, `__COMPONENT_NAME__`, and `__GENERAL_NOTES__`):

```javascript
const frame = await figma.getNodeByIdAsync('__FRAME_ID__');
const textNodes = frame.findAll(n => n.type === 'TEXT');
const fontSet = new Set();
const fontsToLoad = [];
for (const tn of textNodes) {
  try {
    const fn = tn.fontName;
    if (fn && fn !== figma.mixed && fn.family) {
      const key = fn.family + '|' + fn.style;
      if (!fontSet.has(key)) { fontSet.add(key); fontsToLoad.push(fn); }
    }
  } catch {}
}
await Promise.all(fontsToLoad.map(f => figma.loadFontAsync(f).catch(() => {})));

const compNameFrame = frame.findOne(n => n.name === '#compName');
if (compNameFrame) {
  const t = compNameFrame.findOne(n => n.type === 'TEXT');
  if (t) t.characters = '__COMPONENT_NAME__';
}

const notesFrame = frame.findOne(n => n.name === '#general-color-assignment-description');
if (notesFrame) {
  const hasNotes = __HAS_GENERAL_NOTES__;
  if (!hasNotes) {
    notesFrame.visible = false;
  } else {
    const t = notesFrame.findOne(n => n.type === 'TEXT');
    if (t) t.characters = '__GENERAL_NOTES__';
  }
}

return { success: true };
```

Replace `__HAS_GENERAL_NOTES__` with `true` or `false` (from `HAS_GENERAL_NOTES`).

### Step 10: Render Variants

Use the rendering strategy detected in Step 0. Run **one `figma_execute` call per variant (Strategy A) or per section (Strategy B)** to avoid timeouts. All inputs come from the parsed `.md` + `render-meta` (Step 4/5) and, for Strategy B mode previews, the `COLLECTION_ID` / `MODE_ID` resolved in Step 6.

#### Strategy A: Simple Layout

For each variant in the data, run the following script. Replace all `__PLACEHOLDER__` values with actual data. `__TABLES_JSON__` is the tables array for this variant (each element has `element`, `token`, `notes`, and optionally `compositeChildren` — an array of `{ element, value, notes }` objects for multi-layer style breakdowns). All values are the verbatim `.md` strings parsed in Step 0.

- `__COMPONENT_SET_NODE_ID__` is the node ID of the component set (`render-meta.component.compSetNodeId`). Set to `''` if not available.
- `__VARIANT_PROPERTIES_JSON__` is an object mapping **Figma property keys** to values for this variant (re-derived in Step 5 from `render-meta.variantAxes`). Set to `{}` if not available.
- `__FONT_FAMILY__` is the `fontFamily` value from `uspecs.config.json` (default: `Inter`).
- `__BOOLEAN_UNHIDES_JSON__` is `BOOLEAN_UNHIDES` (= `render-meta.booleanDefs[]` keys reshaped to `[{ booleanRawKey }]`). Set to `[]` if `booleanDefs` is empty.

```javascript
const FRAME_ID = '__FRAME_ID__';
const VARIANT_NAME = '__VARIANT_NAME__';
const COMPONENT_NAME = '__COMPONENT_NAME__';
const COMPONENT_SET_ID = '__COMPONENT_SET_NODE_ID__';
const VARIANT_PROPS = __VARIANT_PROPERTIES_JSON__;
const TABLES = __TABLES_JSON__;
const FONT_FAMILY = '__FONT_FAMILY__';
const BOOLEAN_UNHIDES = __BOOLEAN_UNHIDES_JSON__;

async function loadAllFonts(rootNode) {
  const textNodes = [];
  function collect(node) {
    try {
      if (node.type === 'TEXT') textNodes.push(node);
      if ('children' in node && node.children) {
        for (const c of node.children) { try { collect(c); } catch {} }
      }
    } catch {}
  }
  collect(rootNode);
  const fontSet = new Set();
  const fontsToLoad = [];
  for (const tn of textNodes) {
    try {
      const fn = tn.fontName;
      if (fn && fn !== figma.mixed && fn.family) {
        const key = fn.family + '|' + fn.style;
        if (!fontSet.has(key)) { fontSet.add(key); fontsToLoad.push(fn); }
      }
    } catch {}
  }
  await Promise.all(fontsToLoad.map(f => figma.loadFontAsync(f).catch(() => {})));
}

async function loadFontWithFallback(family, preferredStyle, fallbackStyle) {
  fallbackStyle = fallbackStyle || 'Regular';
  const allFonts = await figma.listAvailableFontsAsync();
  const familyFonts = allFonts.filter(f => f.fontName.family === family);
  const match = familyFonts.find(f => f.fontName.style === preferredStyle);
  if (match) { await figma.loadFontAsync(match.fontName); return match.fontName; }
  const fallback = familyFonts.find(f => f.fontName.style === fallbackStyle);
  if (fallback) { await figma.loadFontAsync(fallback.fontName); return fallback.fontName; }
  if (familyFonts.length > 0) { await figma.loadFontAsync(familyFonts[0].fontName); return familyFonts[0].fontName; }
  await figma.loadFontAsync({ family: 'Inter', style: 'Regular' });
  return { family: 'Inter', style: 'Regular' };
}

function enableNestedBooleans(node) {
  try {
    if (node.type === 'INSTANCE') {
      try {
        const childProps = node.componentProperties;
        if (childProps) {
          const childBoolProps = {};
          for (const [key, val] of Object.entries(childProps)) {
            if (val.type === 'BOOLEAN') childBoolProps[key] = true;
          }
          if (Object.keys(childBoolProps).length > 0) {
            try { node.setProperties(childBoolProps); } catch {}
          }
        }
      } catch {}
    }
    if ('children' in node && node.children) {
      for (const child of node.children) { try { enableNestedBooleans(child); } catch {} }
    }
  } catch {}
}

const frame = await figma.getNodeByIdAsync(FRAME_ID);
const variantTemplate = frame.findOne(n => n.name === '#variant-template');

const variant = variantTemplate.clone();
variantTemplate.parent.appendChild(variant);
variant.name = VARIANT_NAME;
variant.visible = true;

await loadAllFonts(variant);

// Set variant title
const titleFrame = variant.findOne(n => n.name === '#variant-title');
if (titleFrame) {
  const t = titleFrame.findOne(n => n.type === 'TEXT');
  if (t) t.characters = VARIANT_NAME;
}

const previewContainer = variant.findOne(n => n.name === '#preview');
if (previewContainer && COMPONENT_SET_ID) {
  const componentSet = await figma.getNodeByIdAsync(COMPONENT_SET_ID);
  if (componentSet) {
    const isCompSet = componentSet.type === 'COMPONENT_SET';
    let targetVariant = null;
    if (isCompSet && VARIANT_PROPS && Object.keys(VARIANT_PROPS).length > 0) {
      let bestFallback = null;
      let bestScore = -1;
      for (const child of componentSet.children) {
        const vp = child.variantProperties || {};
        let score = 0;
        let exactMatch = true;
        for (const [k, v] of Object.entries(VARIANT_PROPS)) {
          if (vp[k] === v) { score++; } else { exactMatch = false; }
        }
        if (exactMatch) { targetVariant = child; break; }
        if (score > bestScore) { bestScore = score; bestFallback = child; }
      }
      if (!targetVariant) targetVariant = bestFallback;
    }
    if (!targetVariant) {
      targetVariant = isCompSet
        ? (componentSet.defaultVariant || componentSet.children[0])
        : componentSet;
    }
    const LABEL_FONT = await loadFontWithFallback(FONT_FAMILY, 'Medium');
    for (const containerName of ['Light theme preview placeholder']) {
      const container = previewContainer.findOne(n => n.name === containerName);
      if (container) {
        const placeholder = container.findOne(n => n.name === 'Placeholder');
        if (placeholder) placeholder.remove();

        const wrapper = figma.createFrame();
        wrapper.name = VARIANT_NAME;
        wrapper.layoutMode = 'VERTICAL';
        wrapper.primaryAxisAlignItems = 'CENTER';
        wrapper.counterAxisAlignItems = 'CENTER';
        wrapper.itemSpacing = 8;
        wrapper.fills = [];
        wrapper.primaryAxisSizingMode = 'AUTO';
        wrapper.counterAxisSizingMode = 'AUTO';
        container.appendChild(wrapper);

        const instance = targetVariant.createInstance();
        await loadAllFonts(instance);
        if (BOOLEAN_UNHIDES.length > 0) {
          const boolProps = {};
          for (const bu of BOOLEAN_UNHIDES) boolProps[bu.booleanRawKey] = true;
          instance.setProperties(boolProps);
          await loadAllFonts(instance);
        }
        wrapper.appendChild(instance);

        enableNestedBooleans(instance);
        await loadAllFonts(instance);

        const label = figma.createText();
        label.fontName = LABEL_FONT;
        label.characters = VARIANT_NAME;
        label.fontSize = 14;
        label.fills = [{ type: 'SOLID', color: { r: 0.29, g: 0.29, b: 0.29 } }];
        wrapper.appendChild(label);
      }
    }
  }
} else {
  const previewText = VARIANT_NAME === COMPONENT_NAME
    ? COMPONENT_NAME
    : COMPONENT_NAME + ' ' + VARIANT_NAME;

  const lightFrame = variant.findOne(n => n.name === '#preview-instruction-light');
  if (lightFrame) {
    const textNodesInFrame = lightFrame.children.filter(c => c.type === 'TEXT');
    if (textNodesInFrame[1]) textNodesInFrame[1].characters = previewText;
  }
}

// Clone and fill tables (Strategy A: Element | Token | Notes)
const tableTemplate = variant.findOne(n => n.name === '#color-table-template');

for (let t = 0; t < TABLES.length; t++) {
  const tableData = TABLES[t];
  const tableClone = tableTemplate.clone();
  tableTemplate.parent.appendChild(tableClone);
  tableClone.name = tableData.name;
  tableClone.visible = true;

  const tableTitleFrame = tableClone.findOne(n => n.name === '#table-title');
  if (tableTitleFrame) {
    const txt = tableTitleFrame.findOne(n => n.type === 'TEXT');
    if (txt) txt.characters = tableData.name;
  }

  // Rename header: "State" → "Token"
  const headerRow = tableClone.findOne(n => n.name === '#color-table')?.findOne(n => n.name === '#header-row');
  if (headerRow) {
    const stateTitle = headerRow.findOne(n => n.name === '#state-title');
    if (stateTitle) {
      const txt = stateTitle.findOne(n => n.type === 'TEXT');
      if (txt) txt.characters = 'Token';
    }
  }

  const colorTable = tableClone.findOne(n => n.name === '#color-table');
  const rowTemplate = colorTable.findOne(n => n.name === '#element-row-template');

  function showIndicator(row, isLast) {
    const ind = row.findOne(n => n.name === '#hierarchy-indicator');
    if (ind) {
      ind.visible = true;
      const wg = ind.findOne(n => n.name === 'within-group');
      const last = ind.findOne(n => n.name === '#hierarchy-indicator-last');
      if (wg) wg.visible = !isLast;
      if (last) last.visible = isLast;
    }
  }

  for (const element of tableData.elements) {
    const row = rowTemplate.clone();
    colorTable.appendChild(row);
    row.name = 'Row ' + element.element;

    const elemFrame = row.findOne(n => n.name === '#element-name');
    if (elemFrame) {
      const txt = elemFrame.findOne(n => n.type === 'TEXT');
      if (txt) txt.characters = element.element;
    }

    const tokenFrame = row.findOne(n => n.name === '#state-name');
    if (tokenFrame) {
      const txt = tokenFrame.findOne(n => n.type === 'TEXT');
      if (txt) txt.characters = element.token;
    }

    const notesFrame = row.findOne(n => n.name === '#element-notes');
    if (notesFrame) {
      const txt = notesFrame.findOne(n => n.type === 'TEXT');
      if (txt) txt.characters = element.notes;
    }

    if (element.compositeChildren && element.compositeChildren.length > 0) {
      for (let ci = 0; ci < element.compositeChildren.length; ci++) {
        const child = element.compositeChildren[ci];
        const childRow = rowTemplate.clone();
        colorTable.appendChild(childRow);
        childRow.name = 'Row ' + child.element;
        showIndicator(childRow, ci === element.compositeChildren.length - 1);

        const cElem = childRow.findOne(n => n.name === '#element-name');
        if (cElem) {
          const txt = cElem.findOne(n => n.type === 'TEXT');
          if (txt) txt.characters = child.element;
        }
        const cToken = childRow.findOne(n => n.name === '#state-name');
        if (cToken) {
          const txt = cToken.findOne(n => n.type === 'TEXT');
          if (txt) txt.characters = child.value;
        }
        const cNotes = childRow.findOne(n => n.name === '#element-notes');
        if (cNotes) {
          const txt = cNotes.findOne(n => n.type === 'TEXT');
          if (txt) txt.characters = child.notes;
        }
      }
    }
  }

  rowTemplate.remove();
}

tableTemplate.remove();
return { success: true, variant: VARIANT_NAME };
```

#### Strategy B: Consolidated Multi-Column Layout

For each section in the data, run the following script. Replace all `__PLACEHOLDER__` values with actual data.

- `__STATE_COLUMNS_JSON__` is the ordered array of **raw Figma state values** that become column headers and drive `setProperties` (re-derived in Step 5 by zipping the relabeled `.md` headers back through `stateAxisMapping`). e.g. `["Enabled", "Hovered", "Pressed", "Active", "Disabled"]`.
- `__STATE_AXIS_NAME__` is the Figma variant axis name for states (e.g. `"State"`), from Step 5.
- `__TABLES_JSON__` is the tables array for this section. Each element has `element`, `tokensByState` (object mapping **raw Figma state value** → token cell verbatim from the `.md`), `notes`, and optionally `compositeChildren` — an array of `{ element, value, notes }` objects for multi-layer style breakdowns.
- `__COLLECTION_ID__` is the variable collection ID for mode-controlled colors (from the Step 6 whitelisted read). Set to `''` if not mode-controlled.
- `__MODE_ID__` is the variable mode ID for this section (from the Step 6 whitelisted read, matched by mode name). Set to `''` if not mode-controlled.
- `__FONT_FAMILY__` is the `fontFamily` value from `uspecs.config.json` (default: `Inter`).
- `__BOOLEAN_UNHIDES_JSON__` is `BOOLEAN_UNHIDES` (= `render-meta.booleanDefs[]` keys reshaped to `[{ booleanRawKey }]`). Set to `[]` if `booleanDefs` is empty.

```javascript
const FRAME_ID = '__FRAME_ID__';
const VARIANT_NAME = '__VARIANT_NAME__';
const COMPONENT_NAME = '__COMPONENT_NAME__';
const COMPONENT_SET_ID = '__COMPONENT_SET_NODE_ID__';
const VARIANT_PROPS = __VARIANT_PROPERTIES_JSON__;
const STATE_COLUMNS = __STATE_COLUMNS_JSON__;
const STATE_AXIS_NAME = '__STATE_AXIS_NAME__';
const TABLES = __TABLES_JSON__;
const COLLECTION_ID = '__COLLECTION_ID__';
const MODE_ID = '__MODE_ID__';
const FONT_FAMILY = '__FONT_FAMILY__';
const BOOLEAN_UNHIDES = __BOOLEAN_UNHIDES_JSON__;

async function loadAllFonts(rootNode) {
  const textNodes = [];
  function collect(node) {
    try {
      if (node.type === 'TEXT') textNodes.push(node);
      if ('children' in node && node.children) {
        for (const c of node.children) { try { collect(c); } catch {} }
      }
    } catch {}
  }
  collect(rootNode);
  const fontSet = new Set();
  const fontsToLoad = [];
  for (const tn of textNodes) {
    try {
      const fn = tn.fontName;
      if (fn && fn !== figma.mixed && fn.family) {
        const key = fn.family + '|' + fn.style;
        if (!fontSet.has(key)) { fontSet.add(key); fontsToLoad.push(fn); }
      }
    } catch {}
  }
  await Promise.all(fontsToLoad.map(f => figma.loadFontAsync(f).catch(() => {})));
}

async function loadFontWithFallback(family, preferredStyle, fallbackStyle) {
  fallbackStyle = fallbackStyle || 'Regular';
  const allFonts = await figma.listAvailableFontsAsync();
  const familyFonts = allFonts.filter(f => f.fontName.family === family);
  const match = familyFonts.find(f => f.fontName.style === preferredStyle);
  if (match) { await figma.loadFontAsync(match.fontName); return match.fontName; }
  const fallback = familyFonts.find(f => f.fontName.style === fallbackStyle);
  if (fallback) { await figma.loadFontAsync(fallback.fontName); return fallback.fontName; }
  if (familyFonts.length > 0) { await figma.loadFontAsync(familyFonts[0].fontName); return familyFonts[0].fontName; }
  await figma.loadFontAsync({ family: 'Inter', style: 'Regular' });
  return { family: 'Inter', style: 'Regular' };
}

function enableNestedBooleans(node) {
  try {
    if (node.type === 'INSTANCE') {
      try {
        const childProps = node.componentProperties;
        if (childProps) {
          const childBoolProps = {};
          for (const [key, val] of Object.entries(childProps)) {
            if (val.type === 'BOOLEAN') childBoolProps[key] = true;
          }
          if (Object.keys(childBoolProps).length > 0) {
            try { node.setProperties(childBoolProps); } catch {}
          }
        }
      } catch {}
    }
    if ('children' in node && node.children) {
      for (const child of node.children) { try { enableNestedBooleans(child); } catch {} }
    }
  } catch {}
}

const frame = await figma.getNodeByIdAsync(FRAME_ID);
const variantTemplate = frame.findOne(n => n.name === '#variant-template');

const variant = variantTemplate.clone();
variantTemplate.parent.appendChild(variant);
variant.name = VARIANT_NAME;
variant.visible = true;

await loadAllFonts(variant);

const titleFrame = variant.findOne(n => n.name === '#variant-title');
if (titleFrame) {
  const t = titleFrame.findOne(n => n.type === 'TEXT');
  if (t) t.characters = VARIANT_NAME;
}

let collection = null;
if (COLLECTION_ID) {
  const collections = await figma.variables.getLocalVariableCollectionsAsync();
  collection = collections.find(c => c.id === COLLECTION_ID) || null;
}

function clearModesRecursive(node, col) {
  try { node.clearExplicitVariableModeForCollection(col); } catch {}
  if ('children' in node) {
    for (const child of node.children) clearModesRecursive(child, col);
  }
}

const previewContainer = variant.findOne(n => n.name === '#preview');
if (previewContainer && COMPONENT_SET_ID) {
  const componentSet = await figma.getNodeByIdAsync(COMPONENT_SET_ID);
  if (componentSet) {
    const isCompSet = componentSet.type === 'COMPONENT_SET';
    const LABEL_FONT = await loadFontWithFallback(FONT_FAMILY, 'Medium');

    for (const containerName of ['Light theme preview placeholder']) {
      const container = previewContainer.findOne(n => n.name === containerName);
      if (!container) continue;
      const placeholder = container.findOne(n => n.name === 'Placeholder');
      if (placeholder) placeholder.remove();
      container.itemSpacing = 24;

      for (let s = 0; s < STATE_COLUMNS.length; s++) {
        const stateProps = { ...VARIANT_PROPS };
        stateProps[STATE_AXIS_NAME] = STATE_COLUMNS[s];

        let targetVariant = null;
        let bestFallback = null;
        let bestScore = -1;
        for (const child of componentSet.children) {
          const vp = child.variantProperties || {};
          let score = 0;
          let exactMatch = true;
          for (const [k, v] of Object.entries(stateProps)) {
            if (vp[k] === v) { score++; } else { exactMatch = false; }
          }
          if (exactMatch) { targetVariant = child; break; }
          if (score > bestScore) { bestScore = score; bestFallback = child; }
        }
        if (!targetVariant) targetVariant = bestFallback;
        if (!targetVariant) targetVariant = isCompSet ? (componentSet.defaultVariant || componentSet.children[0]) : componentSet;

        const wrapper = figma.createFrame();
        wrapper.name = STATE_COLUMNS[s];
        wrapper.layoutMode = 'VERTICAL';
        wrapper.primaryAxisAlignItems = 'CENTER';
        wrapper.counterAxisAlignItems = 'CENTER';
        wrapper.itemSpacing = 8;
        wrapper.fills = [];
        wrapper.primaryAxisSizingMode = 'AUTO';
        wrapper.counterAxisSizingMode = 'AUTO';
        container.appendChild(wrapper);

        if (collection && MODE_ID) {
          wrapper.setExplicitVariableModeForCollection(collection, MODE_ID);
        }

        const inst = targetVariant.createInstance();
        await loadAllFonts(inst);
        if (BOOLEAN_UNHIDES.length > 0) {
          const boolProps = {};
          for (const bu of BOOLEAN_UNHIDES) boolProps[bu.booleanRawKey] = true;
          inst.setProperties(boolProps);
          await loadAllFonts(inst);
        }
        wrapper.appendChild(inst);
        if (collection) clearModesRecursive(inst, collection);

        enableNestedBooleans(inst);
        await loadAllFonts(inst);

        const label = figma.createText();
        label.fontName = LABEL_FONT;
        label.characters = STATE_COLUMNS[s];
        label.fontSize = 14;
        label.fills = [{ type: 'SOLID', color: { r: 0.29, g: 0.29, b: 0.29 } }];
        wrapper.appendChild(label);
      }
    }
  }
} else {
  const previewText = VARIANT_NAME === COMPONENT_NAME
    ? COMPONENT_NAME
    : COMPONENT_NAME + ' ' + VARIANT_NAME;

  const lightFrame = variant.findOne(n => n.name === '#preview-instruction-light');
  if (lightFrame) {
    const textNodesInFrame = lightFrame.children.filter(c => c.type === 'TEXT');
    if (textNodesInFrame[1]) textNodesInFrame[1].characters = previewText;
  }
}

// Clone and fill tables (Strategy B: Element | State1 | State2 | ... | Notes)
const N = STATE_COLUMNS.length;

const tableTemplate = variant.findOne(n => n.name === '#color-table-template');

for (let t = 0; t < TABLES.length; t++) {
  const tableData = TABLES[t];
  const tableClone = tableTemplate.clone();
  tableTemplate.parent.appendChild(tableClone);
  tableClone.name = tableData.name;
  tableClone.visible = true;

  const tableTitleFrame = tableClone.findOne(n => n.name === '#table-title');
  if (tableTitleFrame) {
    const txt = tableTitleFrame.findOne(n => n.type === 'TEXT');
    if (txt) txt.characters = tableData.name;
  }

  const colorTable = tableClone.findOne(n => n.name === '#color-table');

  const headerRow = colorTable.findOne(n => n.name === '#header-row');
  if (headerRow) {
    const stateTitle = headerRow.findOne(n => n.name === '#state-title');
    const notesTitle = headerRow.findOne(n => n.name === '#notes-title');
    const notesIndex = notesTitle ? headerRow.children.indexOf(notesTitle) : -1;

    if (stateTitle) {
      const headerClones = [];
      for (let s = 0; s < N; s++) {
        const col = stateTitle.clone();
        headerClones.push(col);
        if (notesIndex >= 0) {
          headerRow.insertChild(notesIndex + s, col);
        } else {
          headerRow.appendChild(col);
        }
      }
      stateTitle.remove();
      for (let s = 0; s < headerClones.length; s++) {
        headerClones[s].name = 'state-col-' + s;
        headerClones[s].layoutSizingHorizontal = 'FILL';
        const txt = headerClones[s].findOne(n => n.type === 'TEXT');
        if (txt) txt.characters = STATE_COLUMNS[s];
      }
    }

    if (notesTitle) {
      notesTitle.layoutSizingHorizontal = 'FILL';
    }
  }

  const rowTemplate = colorTable.findOne(n => n.name === '#element-row-template');

  function showIndicator(row, isLast) {
    const ind = row.findOne(n => n.name === '#hierarchy-indicator');
    if (ind) {
      ind.visible = true;
      const wg = ind.findOne(n => n.name === 'within-group');
      const last = ind.findOne(n => n.name === '#hierarchy-indicator-last');
      if (wg) wg.visible = !isLast;
      if (last) last.visible = isLast;
    }
  }

  function expandStateCols(row, values) {
    const stateCell = row.findOne(n => n.name === '#state-name');
    const notesFrame = row.findOne(n => n.name === '#element-notes');
    const notesCellIndex = notesFrame ? row.children.indexOf(notesFrame) : -1;
    if (stateCell) {
      const cellClones = [];
      for (let s = 0; s < N; s++) {
        const col = stateCell.clone();
        cellClones.push(col);
        if (notesCellIndex >= 0) {
          row.insertChild(notesCellIndex + s, col);
        } else {
          row.appendChild(col);
        }
      }
      stateCell.remove();
      for (let s = 0; s < cellClones.length; s++) {
        cellClones[s].name = 'state-val-' + s;
        cellClones[s].layoutSizingHorizontal = 'FILL';
        const txt = cellClones[s].findOne(n => n.type === 'TEXT');
        if (txt) txt.characters = values[s] || 'none';
      }
    }
    if (notesFrame) notesFrame.layoutSizingHorizontal = 'FILL';
  }

  for (const element of tableData.elements) {
    const row = rowTemplate.clone();
    colorTable.appendChild(row);
    row.name = 'Row ' + element.element;

    const elemFrame = row.findOne(n => n.name === '#element-name');
    if (elemFrame) {
      const txt = elemFrame.findOne(n => n.type === 'TEXT');
      if (txt) txt.characters = element.element;
    }

    const stateValues = STATE_COLUMNS.map(s => element.tokensByState[s] || 'none');
    expandStateCols(row, stateValues);

    const notesFrame = row.findOne(n => n.name === '#element-notes');
    if (notesFrame) {
      const txt = notesFrame.findOne(n => n.type === 'TEXT');
      if (txt) txt.characters = element.notes;
    }

    if (element.compositeChildren && element.compositeChildren.length > 0) {
      for (let ci = 0; ci < element.compositeChildren.length; ci++) {
        const child = element.compositeChildren[ci];
        const childRow = rowTemplate.clone();
        colorTable.appendChild(childRow);
        childRow.name = 'Row ' + child.element;
        showIndicator(childRow, ci === element.compositeChildren.length - 1);

        const cElem = childRow.findOne(n => n.name === '#element-name');
        if (cElem) {
          const txt = cElem.findOne(n => n.type === 'TEXT');
          if (txt) txt.characters = child.element;
        }
        const childStateValues = STATE_COLUMNS.map(() => child.value);
        expandStateCols(childRow, childStateValues);
        const cNotes = childRow.findOne(n => n.name === '#element-notes');
        if (cNotes) {
          const txt = cNotes.findOne(n => n.type === 'TEXT');
          if (txt) txt.characters = child.notes;
        }
      }
    }
  }

  rowTemplate.remove();
}

tableTemplate.remove();
return { success: true, variant: VARIANT_NAME };
```

### Step 11: Visual Validation

1. `figma_take_screenshot` with the `frameId` — Capture the completed annotation
2. Verify:
   - All variant/section sections are present with correct titles (for mode-controlled components: one section per Type × Mode combination, matching the `.md` section headings)
   - Tables within each variant/section have correct element-to-token mappings — every token cell matches the `.md` **verbatim** (`tokenName (#RRGGBB)` / bare hex / `none`); no token was re-resolved or reformatted
   - **Strategy B previews**: Each section's preview container shows **all state instances side by side with labels** (the raw Figma state values), and the variant children resolved correctly via `setProperties` on the re-derived `STATE_COLUMNS`
   - **Strategy A previews**: Each variant's preview container shows a labeled component instance
   - For mode-controlled components, preview instances display the correct color mode (the `COLLECTION_ID` / `MODE_ID` from the Step 6 whitelisted read)
   - **Composite breakdowns**: Elements with multi-layer styles show nested child rows with hierarchy indicators (vertical line + elbow for middle children, elbow-only for last child). Top-level rows have indicators hidden.
   - General notes are visible or hidden as expected
3. Fix any mismatch by re-parsing the `.md` (or, if a `.md` value is itself wrong, flag it — re-run `create-component-md`); never by re-extracting from Figma. Re-capture (up to 3 iterations).

### Step 12: Completion Link

Print a clickable Figma URL to the completed spec in chat. Construct the URL from the `fileKey` (`render-meta.fileKey`) and the `frameId` (returned by Step 8), replacing `:` with `-` in the node ID. Append the provenance footer recording the `sourceHash` from `render-meta` (so drift between this `.md` and its `_base.json` is auditable):

```
Color spec complete: https://www.figma.com/design/{fileKey}/?node-id={frameId}
Source: {mdPath} (render-meta sourceHash: {sourceHash}) — rows tagged `md`; mode/variant resolution tagged `measured`.
```

## Notes

- The color annotation template key is stored in `uspecs.config.json` under `templateKeys.colorAnnotation` and is configured via the `firstrun` skill.
- **This skill consumes the component `.md`** (the source of truth produced by the `create-component-md` skill) and renders its Color section into Figma. It does NOT extract from Figma — see the Step 0 FORBIDDEN directive. The `compSetNodeId`, variant axes, boolean defs, strategy, tokens, hex values, and per-state columns all come from the `.md`'s Color body + `render-meta`. The only live read is the single whitelisted `getLocalVariableCollectionsAsync()` call (Strategy B mode-controlled only) used to resolve `COLLECTION_ID` / `MODE_ID`.
- The target node referenced by `render-meta.component.compSetNodeId` can be either a `COMPONENT_SET` (multi-variant) or a standalone `COMPONENT` (single variant); the render script handles both via `defaultVariant || children[0]` and scored variant matching. When the node is a standalone component, the Color body has a single variant entry and no variant axes.
- **Strategy detection comes from the `.md` table shape**, not from a live axis classification: `Element | Token | Notes` ⇒ Strategy A; `Element | {state…} | Notes` ⇒ Strategy B. The producer (`extract-color` → `create-component-md`) already chose the strategy; this skill only mirrors it.
- **Token cells are verbatim.** The producer applies the `tokenName (#RRGGBB)` hex-in-token formatter (and bare-hex / `none` fallbacks). This skill passes those exact strings into the template text nodes — it never re-resolves a variable binding or recomputes a hex. Composite-style children arrive as `└`/`├`-prefixed rows and are rendered with the template's hierarchy indicators.
- **Strategy B state columns:** the `.md`'s state column headers may be runtime-condition relabeled. The render script needs raw Figma state values to drive `setProperties` (variant scoring) and mode previews, so Step 5 zips each relabeled header back to its `stateAxisMapping[].figmaValue`. If the zip is not 1:1 the section is aborted with a diagnostic rather than rendered against guessed states. When headers are not relabeled they are already raw Figma values and used as-is.
- **Boolean unhides:** the preview-instance unhide set is the full `render-meta.booleanDefs[]` key set. The elements those toggles reveal are already merged into the `.md` tables by `create-component-md`; the unhide set only ensures the live preview shows them.
- Three-level cloning: variants/sections → tables → rows. Each variant/section is cloned from `#variant-template`, each table from `#color-table-template`, and each row from `#element-row-template`.
- **Template defaults:** `#variant-template` is hidden by default (`visible=false`) — cloned variants must be set to `visible=true`. No post-render hiding step is needed. The `#hierarchy-indicator` frame inside `#element-row-template` is hidden by default with both vectors (`within-group`, `#hierarchy-indicator-last`) hidden — only composite child rows show it.
- Preview instructions: The `#preview-instruction-light` frame contains multiple TEXT nodes. The second TEXT node (index 1) receives the preview text formatted as "{ComponentName} {VariantName}".
- The instruction file (`../../../references/color/agent-color-instruction.md`) is consulted **only** to reason about how a parsed table maps to template structure. Strategy selection, token resolution, axis classification, and mode detection already happened upstream and are baked into the `.md` — this skill does not redo them.
- Preview frames: Each variant/section has a light theme preview container. The `Placeholder` child is removed and replaced with live component instances.
  - **Strategy A**: One labeled instance per container (wrapper frame with instance + text label).
  - **Strategy B**: Multiple labeled instances per container — one per state column (raw Figma state value). Each instance is wrapped in a vertical frame with a text label showing the state name. The preview container uses `HORIZONTAL` layout with `itemSpacing: 24` so instances flow left to right.
- **Mode-controlled previews**: For components with a variable mode collection, each preview instance wrapper has `setExplicitVariableModeForCollection(collection, modeId)` applied so the correct color mode renders. After creating each instance, `clearModesRecursive` removes any baked-in modes so the instance inherits from the wrapper. The `COLLECTION_ID` / `MODE_ID` come from the single whitelisted `getLocalVariableCollectionsAsync()` read (Step 6), matched by the collection/mode names surfaced in the `.md`'s Cross-section invariants bullet and section titles.
- **Mode-expanded sections**: When the `.md` is mode-controlled, every mode is its own Strategy B section — one per Type × Mode combination, e.g. `"Primary / Gray"`. Tokens are already resolved per mode in the `.md`; this skill only applies the matching `MODE_ID` to the section's previews.
- The script uses scored variant matching (exact match first, then best partial match by score) to find the correct variant child directly, rather than creating from the default and calling `setProperties()`. This handles sparse component sets where some variant combinations may not exist.
- **Column header rename:** The template's `#state-title` layer originally displays "State". Strategy A renames it to "Token" at render time (the column holds token names). Strategy B replaces the column entirely with per-state columns.
- **Provenance:** every emitted row is sourced from the `.md` and tagged `md`; the variant/mode resolution the render path performs (scored matching, `MODE_ID` application) is tagged `measured`; nothing is `inferred` unless a parsed cell is missing and you must note a drift fill. The completion footer records the `render-meta` `sourceHash`.
