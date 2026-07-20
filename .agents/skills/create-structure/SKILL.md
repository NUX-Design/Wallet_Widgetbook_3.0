---
name: create-structure
description: Generate structure specifications documenting component dimensions, spacing, padding, and how values change across density, size, and shape variants. Use when the user mentions "structure", "structure spec", "dimensions", "spacing", "density", "sizing", or wants to document a component's dimensional properties.
---

# Create Structure Spec

Generate a structure specification directly in Figma — tables documenting all dimensional properties of a component, organized into sections by variant axis or sub-component, with dynamic columns for size/density variants.

**Execution contract (read first).**
- This file is instructions to RUN, not a document to edit. Invoking the skill = render the structure spec into Figma from the input `.md`.
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

- **Component `.md` spec** (**required**, user-provided path) — the source-of-truth component spec produced by the `create-component-md` skill. **The user tells you where this `.md` lives** — use the exact path they provide; the `.md` may live anywhere. This skill **renders the Structure section from the `.md`**; it does NOT re-extract anything from Figma. `fileKey`, `nodeId`, and `compSetNodeId` come from the `.md`'s `render-meta` block, never from the Figma link.
- **Figma link to the destination** (optional) — placement hint only (which page/frame to drop the rendered spec on, including the cross-file destination). Never the source of structural facts.
- **Description** (optional) — a human nudge (component name, which sections to emphasize). Never a source of dimensions.

There is no screenshot-only path and no component-link extraction path. Without the component `.md` there is nothing to render — see Step 0's fail-fast contract.

## Workflow

Copy this checklist and update as you progress:

```
Task Progress:
- [ ] Step 0: Require + parse the component `.md` (Structure body + render-meta). FAIL FAST if missing.
- [ ] Step 1: Read instruction file (only as needed for row-emission conventions — NOT for re-extraction)
- [ ] Step 2: Verify MCP connection
- [ ] Step 3: Read template key from uspecs.config.json
- [ ] Step 4: Build render inputs from the parsed .md (sections, COLUMNS, ROWS, general notes, provenance) + render-meta (compSetNodeId, variantAxesDefaults, subComponents, slotContents, booleanDefs) — NO extraction
- [ ] Step 5: Navigate to destination (if a separate destination file was provided)
- [ ] Step 6: Re-derive each section's sectionType via the Step 11a decision table (match columns to variantAxes; {slot} — {comp}; subComponents[].name) — NO live reads
- [ ] Step 7: Audit the assembled render inputs against the .md
- [ ] Step 9: Import and detach the Structure template
- [ ] Step 10: Fill header fields
- [ ] Step 11: For each section → render table, determine preview params, populate preview + canvas measurements
- [ ] Step 12: Visual validation
- [ ] Step 13: Completion link
```

### Step 0: Require and parse the component `.md` (fail fast)

**This skill is a consumer of the `.md` source of truth.** It does not re-extract from Figma and does not re-run the dimensional measurement / section-planning layer — that work already happened in `extract-structure`/`create-component-md` and is baked into the `.md`'s Structure section. Your job is to render that section into a Figma frame.

1. **Resolve the `.md` path.** Use the exact path the user gave, else an attached or open `.md` in context. The `.md` may live anywhere; do NOT invent or guess a path. If neither resolves to an existing file, abort per item 2. Never pause to ask the user which file to use.
2. **Require the file.** If no file exists at the resolved `.md` path, **abort immediately** with this exact single-line diagnostic and stop — do NOT fall back to extraction:

   > This skill requires the component's Markdown `.md` spec (produced by create-component-md). Provide the path to it. (create-component-md needs a _base.json from the uSpec Extract plugin.)

3. **Parse the Structure section** (`## Structure`) from the `.md` body. Its layout is defined in `references/component-md/agent-component-md-instruction.md` § **Structure body rendering**:
   - **Confidence header** — the leading italic line (`_Confidence: …_`). Carry it for the Step 7 audit; it does not render into Figma.
   - **General notes** — the blockquote immediately under the confidence header (if present) → `GENERAL_NOTES`.
   - **Typography subsection** (`### Typography`, when present) — a consolidated per-element index. **Skip it when rebuilding row identity** — the per-section typography rows below remain authoritative. Do not emit a separate render section or preview for it.
   - **State deltas subsection** (`### State deltas` / `### {axis} deltas`, when present) — non-dimensional deltas across an axis. Capture it as a candidate state-conditional section, but **dedupe against the dimensional sections** so a property that already appears in a dimensional section is not double-emitted.
   - **Dimensional sections** — each remaining `###` sub-section is one render section: heading = `sectionName`, optional description paragraph, then a Markdown table whose header row is `section.columns`. Parse each section into `{ sectionName, sectionDescription, columns: COLUMNS_JSON, rows: ROWS_JSON }`.
   - **Rows** — for every table row build `{ spec, values, notes, isSubProperty, isLastInGroup, provenance }`:
     - `spec` — the first column with the hierarchy arrow and provenance badge **stripped** to the bare property name. A leading `└ ` means `isSubProperty: true, isLastInGroup: true`; a leading `├ ` means `isSubProperty: true, isLastInGroup: false`; no arrow means `isSubProperty: false`.
     - `provenance` — `inferred` when the cell carried a `[inferred via <token>]` (or `[inferred]`) badge, `not-measured` when it carried `[unmeasured]`, otherwise `measured`. Tag rows that are purely textual / non-dimensional (sizing modes, alignment, typography style names) as `md`.
     - `values` — the pre-formatted `display` cells **verbatim** (e.g. `spacing-100 (16)`, `—`). Do not reformat or recompute them.
     - `notes` — the last column verbatim.
4. **Parse the `render-meta` block** (the fenced JSON between `<!-- render-meta:start v=1 -->` and `<!-- render-meta:end -->`; schema in `agent-component-md-instruction.md` § **RENDER_META_JSON**):
   - `COMP_SET_ID` = `component.compSetNodeId`.
   - `variantAxes` / `variantAxesDefaults` — for Step 6 section-type derivation and Step 11a preview props.
   - `BOOLEAN_DEFS` = reshape `booleanDefs[]` → `{ [key]: default }`. Each `key` is the raw component-property key `setProperties` expects.
   - `subComponents[]` — `{ name, mainComponentName, subCompSetId, subCompVariantAxes, subCompVariantAxesDefaults, booleanOverrides }` for sub-component sections.
   - `slotContents[]` — `{ slotName, slotNodeType, preferredComponents: [{ componentKey, componentName, componentId, componentSetId, isComponentSet, variantAxes, booleanDefs }] }` for slot-content sections.
   - `sectionTargets` / `groupTargets` — per-section / per-group `{ name, nodeId }` (available if a render script needs to resolve a section or group header back to a live node; preview resolution otherwise stays name-match on the live instance).
   - `fileKey`, `nodeId` — for the Step 13 completion link and template placement.
   - `sourceHash` — retain it; it identifies the `_base.json` this `.md` was rendered from (drift detection / provenance footer).

**FORBIDDEN — do NOT re-extract.** When the component `.md` is present (it always is past Step 0), you MUST NOT run the legacy extraction/tree-walk. Specifically:
- Do NOT run the deleted **Step 4b enhanced extraction script** (`extractDimensions` / `extractChildren` / `extractTypography` / `buildLayoutTree` / the SLOT `preferredValues` resolver), the deleted **Step 4d cross-variant dimensional comparison script**, the deleted **Step 4e non-dimensional axis-diff script**, or the deleted **Step 6b targeted structural-axis re-extraction**. These scripts no longer exist in this skill.
- Do NOT re-run the old Step 4a `figma_navigate` / `figma_take_screenshot` / `figma_get_file_data` context-gathering, or the Step 4c `figma_get_variables` mode walk. Dimensions, tokens, sub-components, slot contents, variant axes, and boolean defs are authored in the `.md` + `render-meta` and consumed verbatim.
- Do NOT re-derive the section plan, re-measure dimensions, or re-classify axes from a live walk. Section identity, columns, rows, and provenance come from the parsed `.md`; section *type* is re-derived in Step 6 from the parsed columns + `render-meta` (no live reads).
- The ONLY Figma calls this skill makes are the **render scripts**: template import/clone (Step 9), header fill (Step 10), and per-section table + preview + canvas-measurement rendering (Step 11). Those resolve elements by name-match on the live rendered/preview instance and read live `bbox` for measurement overlays — that is the cleanest case and needs **no** whitelisted live extraction read.

### Step 1: Read Instructions (only as needed)

The dimensions, sections, columns, rows, notes, and provenance are already authored in the `.md` — you do NOT re-derive them. Read [agent-structure-instruction.md](../../../references/structure/agent-structure-instruction.md) **only** if you need to recall a row-emission convention while shaping render inputs (e.g. how collapsed padding maps to `paddingTop`/`paddingBottom` rows, logical-direction naming, or the annotation allowlist vocabulary). Never use it as a prompt to re-extract.

### Step 2: Verify MCP Connection

Read `mcpProvider` from `uspecs.config.json` to determine which Figma MCP to use.

**If `figma-console`:**
- `figma_get_status` — Confirm Desktop Bridge plugin is active
- If connection fails: *"Please open Figma Desktop and run the Desktop Bridge plugin. Then try again."*

**If `figma-mcp`:**
- Connection is verified implicitly on the first `use_figma` call. No explicit check needed.
- If the first call fails: *"Please verify your FIGMA_API_KEY is set correctly in your MCP configuration."*

### Step 3: Read Template Key

Read the file `uspecs.config.json` and extract:
- The `structureSpec` value from the `templateKeys` object → save as `STRUCTURE_TEMPLATE_KEY`
- The `fontFamily` value → save as `FONT_FAMILY` (default to `Inter` if not set)

If the template key is empty, tell the user:
> The structure template key is not configured. Run the `firstrun` skill with your Figma template library link first.

### Step 4: Build render inputs from the parsed `.md` (no extraction)

Everything the render scripts need is already in the `.md` you parsed in Step 0. Assemble the render inputs directly — there is **no extraction call** here (see the FORBIDDEN directive in Step 0).

Build these values:

- **`COMPONENT_NAME`** — `render-meta.component.componentName` (fallback: the `.md`'s `# {name}` H1).
- **`GENERAL_NOTES`** — the Structure section's general-notes blockquote, verbatim (empty when absent).
- **`SECTIONS`** — one entry per parsed dimensional `###` sub-section, in document order: `{ sectionName, sectionDescription, columns: COLUMNS_JSON, rows: ROWS_JSON }`. `COLUMNS_JSON` is the table header row verbatim (first column `Spec`/`Composition`, last column `Notes`). `ROWS_JSON` is the parsed rows (`{ spec, values, notes, isSubProperty, isLastInGroup, provenance }`) with the pre-formatted `display` cells copied verbatim. The `### State deltas` subsection becomes a state-conditional `SECTIONS` entry; the `### Typography` index is **not** a section — its rows already live inline in the per-section tables.
- **`COMP_SET_ID`** — `render-meta.component.compSetNodeId`.
- **`VARIANT_AXES`** / **`VARIANT_AXES_DEFAULTS`** — `render-meta.variantAxes` / `render-meta.variantAxesDefaults`. Used in Step 6 (section-type derivation) and Step 11a (preview props).
- **`BOOLEAN_DEFS`** — reshape `render-meta.booleanDefs[]` → `{ [key]: default }` (raw component-property keys `setProperties` expects).
- **`SUB_COMPONENTS`** — `render-meta.subComponents[]` (`name`, `mainComponentName`, `subCompSetId`, `subCompVariantAxes`, `subCompVariantAxesDefaults`, `booleanOverrides`). Drives sub-component section previews.
- **`SLOT_CONTENTS`** — `render-meta.slotContents[]` (`slotName`, `preferredComponents[].{componentId, componentSetId, isComponentSet, variantAxes, booleanDefs}`). Drives slot-content section previews.

**Provenance.** Each parsed row carries a `provenance` tag (`md` / `measured` / `inferred` / `not-measured`) from Step 0.3 — keep it on the row so the Step 7 audit can confirm `[unmeasured]` rows render with `—` value cells and `inferred` rows keep their `[inferred via <token>]` reasoning in `notes`. Retain `render-meta.sourceHash` alongside the inputs as the provenance fingerprint of the `_base.json` this `.md` was rendered from.

Row identity is rebuilt from the parsed table rows, **not** from the Typography index, and the State-deltas section is deduped against the dimensional sections so a property is never emitted twice.

Each `SECTIONS` entry's `sectionType` (which preview Step 11a renders) is derived in Step 6.

> The legacy "navigate + screenshot + run the `extractDimensions`/`extractChildren` extraction script + cross-variant comparison + non-dimensional axis diff" flow (old Steps 4a–4e) has been **removed**. Do not reintroduce it. The `.md` + `render-meta` are the complete input.

### Step 5: Navigate to Destination

If the user provided a separate destination file URL:
- `figma_navigate` — Switch to the destination file

If no destination was provided, stay in the current file.

### Step 6: Re-derive each section's `sectionType` (light reasoning, no live reads)

The sections, columns, rows, and notes are already authored in the `.md` and parsed in Step 4 — you neither add nor drop sections, and you do **not** re-plan them. The only thing the Step 11a renderer additionally needs is each section's **`sectionType`**, which selects the preview-parameter row in Step 11a's decision table. Re-derive it cheaply from the parsed columns + `render-meta` — **no Figma reads**.

For each `SECTIONS` entry, match in this order and attach the resulting `sectionType` (plus the recorded metadata each type needs in Step 11a):

- **`composition`** — the first section whose first column header is `Composition` (it maps parent sizes → sub-component variants). No extra metadata.
- **`subComponent`** — the `sectionName` matches a `render-meta.subComponents[].name` (or its `mainComponentName`). Record that entry's `subCompSetId`, `subCompVariantAxes`, `subCompVariantAxesDefaults`, and `booleanOverrides`.
- **`slotContent`** — the `sectionName` matches the `"{slotName} — {componentName}"` pattern, where `{slotName}` is a `render-meta.slotContents[].slotName` and `{componentName}` is one of that slot's `preferredComponents[].componentName`. Record the preferred component's `componentId`, `componentSetId`, `variantAxes`, and `booleanDefs`.
- **`stateConditional`** — the `### State deltas` section, or any section whose value-columns are state names (matching the `state` axis in `render-meta.variantAxes`, or runtime conditions like `focused` / `error`).
- **`boolean-toggled`** — a standalone component (no dimension-affecting `render-meta.variantAxes`) whose value-columns are boolean-combination labels (e.g. `Default`, `With subtext`). The relevant booleans are described by `render-meta.booleanDefs[]`.
- **`variant`** (default) — the section's value-columns (between `Spec` and `Notes`) match the options of a `render-meta.variantAxes` axis whose name matches `/size/i`, `/density/i`, or `/shape/i`. Record which axis it is (`VARIANT_AXIS`) and whether it is size / density / shape (this picks the Size/Density/Shape row in Step 11a).

This is the same decision the old AI interpretation layer produced, but it reads axes, sub-components, and slots from `render-meta` instead of a live walk, and the section list is fixed by the `.md`. Do not re-measure, re-classify axes from a live walk, or run any targeted re-extraction (the old Step 6b is **deleted**).

### Step 7: Audit the assembled render inputs

Before rendering, verify the inputs you built from the `.md`:
- Every `SECTIONS` entry has a `columns` array whose first cell is `Spec` (or `Composition`) and last cell is `Notes`, and every row's `values` length equals `columns.length - 2`.
- Every row's `display` cells are copied verbatim from the `.md` (no reformatting). Rows tagged `provenance: "not-measured"` have `—` in every value cell; rows tagged `inferred` keep their `[inferred via <token>]` reasoning in `notes`.
- Every section resolved a `sectionType` in Step 6. Sub-component / slot-content sections resolved their `render-meta` metadata (`subCompSetId` / preferred `componentId`).
- `COMP_SET_ID`, `BOOLEAN_DEFS`, `VARIANT_AXES`, `SUB_COMPONENTS`, and `SLOT_CONTENTS` all come from `render-meta` — not from any live read.
- The Typography index was **not** re-emitted as its own section, and the State-deltas rows were deduped against the dimensional sections (no property emitted twice).
- You did NOT run an extraction/tree-walk (see Step 0 FORBIDDEN).

To recall a row-emission convention (collapsed padding → `paddingTop`/`paddingBottom` rows, logical-direction naming, the annotation allowlist vocabulary), re-read `agent-structure-instruction.md` (**Common Mistakes** / **Do NOT** / **Property naming** sections). Fix any mismatch by re-parsing the `.md` — never by re-extracting from Figma.

Explicitly audit:
- If a section description says `See X spec`, no table rows restate X's own internal structure (the `.md` already enforces this for `slotContent` sections).
- If a section is `slotContent`, confirm the table documents hosting context and placement-specific deltas only.

There is no Step 8 — the structured data (sections, columns, rows, notes, provenance) is already authored in the `.md` and assembled in Step 4. Do not re-generate it or re-measure dimensions.

### Step 9: Import and Detach Template

**If the user provided a cross-file destination URL** (navigated in Step 5), run via `figma_execute`:

```javascript
const TEMPLATE_KEY = '__STRUCTURE_TEMPLATE_KEY__';

const templateComponent = await figma.importComponentByKeyAsync(TEMPLATE_KEY);
const instance = templateComponent.createInstance();
const { x, y } = figma.viewport.center;
instance.x = x - instance.width / 2;
instance.y = y - instance.height / 2;
const frame = instance.detachInstance();
frame.name = '__COMPONENT_NAME__ Structure';
figma.currentPage.selection = [frame];
figma.viewport.scrollAndZoomIntoView([frame]);
return { frameId: frame.id };
```

**If no destination was provided (default)**, run via `figma_execute` — this places the spec on the component's page, to its right:

```javascript
const TEMPLATE_KEY = '__STRUCTURE_TEMPLATE_KEY__';
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

frame.name = '__COMPONENT_NAME__ Structure';
figma.currentPage.selection = [frame];
figma.viewport.scrollAndZoomIntoView([frame]);
return { frameId: frame.id, pageId: _p.id, pageName: _p.name };
```

Replace `__COMPONENT_NODE_ID__` with `COMP_SET_ID` = `render-meta.component.compSetNodeId` (from the `.md` parsed in Step 0).

Save the returned `frameId` — you need it for all subsequent steps.

**Cross-file note:** All structural facts come from the local component `.md` (Step 0), so nothing needs to run in the component's file before navigating to the destination. The template import above uses `importComponentByKeyAsync` which works across files, and the preview scripts (Step 11c) resolve `COMP_SET_ID` / preferred components by node id via `getNodeByIdAsync`.

### Step 10: Fill Header Fields

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

const notesFrame = frame.findOne(n => n.name === '#general-structure-notes');
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

Replace `__HAS_GENERAL_NOTES__` with `true` or `false`. If `false`, the general notes frame is hidden.

### Step 11: Render Sections (table + preview per section)

Process **one section at a time**, completing both the table and its preview before moving to the next section. For each section, perform sub-steps 11a, 11b, and 11c in order.

#### Step 11a: Determine preview parameters for this section

Before rendering, determine the preview configuration for the current section. This is **mandatory** — every section needs its own preview showing relevant variant instances.

**Preview parameter decision table:**

| Section type | `SUB_COMP_SET_ID` | `VARIANT_AXIS` | `COLUMN_VALUES` | `PROPERTY_OVERRIDES` | `SUB_COMP_OVERRIDES` | `SLOT_POPULATION` |
|---|---|---|---|---|---|---|
| **Size/variant** (columns are size names like Large, Medium, Small) | `''` | The axis name (e.g., `"Size"`) | Size names from the axis | Enable all parent-level booleans from `BOOLEAN_DEFS` (`render-meta.booleanDefs`) to `true` so all documented children are visible in the preview | `[]` | `null` |
| **Density** (columns are density modes from variable collections) | `''` | `''` | Mode names (e.g., `["Compact", "Default", "Spacious"]`) | Enable all parent-level booleans from `BOOLEAN_DEFS` (`render-meta.booleanDefs`) to `true` so all documented children are visible in the preview | `[]` | `null` |
| **Shape** (columns are shape variants) | `''` | The axis name (e.g., `"Shape"`) | Shape names from the axis | Enable all parent-level booleans from `BOOLEAN_DEFS` (`render-meta.booleanDefs`) to `true` so all documented children are visible in the preview | `[]` | `null` |
| **Sub-component** (columns are size names showing a specific child) | The sub-component's own component set ID (from `render-meta.subComponents[].subCompSetId`, recorded in Step 6) | The sub-component's size axis name (from `render-meta.subComponents[].subCompVariantAxes`) | Size names from the sub-component's own size axis | `[]` | Boolean properties to enable on each sub-component instance so all internal children are visible (from `render-meta.subComponents[].booleanOverrides` — set all values to `true`) | `null` |
| **Composition** (columns show sub-component variant mappings) | `''` | `''` | Size names | Configure each column's specific property combination | `[]` | `null` |
| **Behavior/Configuration** (columns are size names) | `''` | Size axis name | Size names from the axis | Enable all parent-level booleans from `BOOLEAN_DEFS` (`render-meta.booleanDefs`) to `true` so all documented children are visible. Do **not** vary the configuration axis — use the default configuration | `[]` | `null` |
| **State-conditional** (columns show default vs active state) | `''` | `''` | State names | Enable all parent-level booleans from `BOOLEAN_DEFS` (`render-meta.booleanDefs`) to `true`, then for each column also set the state variant property for that column | `[]` | `null` |
| **Slot content** (columns are parent size names showing a preferred component placed in the slot) | `''` (preview is sourced from the parent — preferred is nested via `SLOT_POPULATION`) | The parent's size axis name (so the parent renders at each column's size) | Size names from the **parent's** size axis | Enable all parent-level booleans from `BOOLEAN_DEFS` (`render-meta.booleanDefs`) to `true` (so the slot is visible) | `[]` | `{ slotName: '<from Step 6>', preferredComponentId: '<from Step 6>', preferredComponentSetId: '<from Step 6> or null', preferredVariantAxis: '<preferred component\'s size axis name from render-meta.slotContents[].preferredComponents[].variantAxes, or null>', preferredBooleanDefs: { <all render-meta.slotContents[].preferredComponents[].booleanDefs keys → true> } }` |
| **Boolean-toggled** (standalone component with booleans controlling structural elements like slots, accessories, subtext) | `''` | `''` | One label per meaningful boolean combination (e.g., `["Default", "With subtext", "No micro button"]`) | Each entry is a `PROPERTY_OVERRIDES` object setting the relevant booleans for that combination | `[]` | `null` |

**Boolean-toggled previews:** For standalone components with no variant axes, show meaningful boolean combinations as separate labeled preview instances. Always include the default state (all booleans at their defaults) plus the fully-enabled state. When the section documents a specific boolean-controlled element (e.g., heading accessory, subtext), show both the on and off states for that element. Boolean-toggled is the **only** section type that does NOT auto-enable parent booleans or recursively enable nested booleans — its per-column `PROPERTY_OVERRIDES` is the configuration spec and must not be clobbered.

**Sub-component preview sourcing:** When `SUB_COMP_SET_ID` is non-empty, the preview script creates instances from the **sub-component's own component set** instead of the parent's `COMP_SET_ID`. This ensures sub-component section previews show the sub-component in isolation (e.g., four Label instances at different sizes) rather than four full parent component instances. The `SUB_COMP_OVERRIDES` parameter specifies boolean properties to enable on each sub-component instance after creation, so optional internal children (e.g., character count, status icon) are visible in the preview. Both `subCompSetId` and `booleanOverrides` come from `render-meta.subComponents[]` (parsed in Step 4, matched to the section in Step 6) — no `figma_execute` exploration is needed to discover them.

**Slot content preview sourcing:** `slotContent` previews show the parent component with the preferred component **nested inside the actual SLOT node** (not as a standalone preview). The script sources the parent inst at the column's parent size, locates the SLOT node by `SLOT_POPULATION.slotName`, creates an instance of the preferred component (matched to its own size axis when present), and `slotNode.appendChild(prefInst)`. This makes the preview a faithful reference for the table — the SLOT's contextual padding, sizing mode, and spacing are live in the inst tree, so canvas measurements drawn on this preview correctly reflect the slot-imposed values the table documents. If `appendChild` fails for any reason, the preferred component is placed as a 0.6-opacity ghost overlay at the slot's bbox and annotation is skipped for that column. Row ownership in the table is unchanged: it still documents only the hosting container and slot-imposed deltas, not a second full structure spec for the preferred component.

**Recursive nested-boolean enable:** Every section type **except `boolean-toggled`** runs a recursive walker (mirrors the equivalent walker in the `create-color` skill) after `createInstance` + `setProperties`. The walker descends every nested INSTANCE in the inst tree and enables every BOOLEAN property on it. This guarantees that any optional child documented in the section's table is visible in the preview even when it's gated by a sub-component's own boolean (e.g., a Label's "Show character count" inside a Text Field's Size section). Boolean-toggled sections are excluded so their per-column `PROPERTY_OVERRIDES` remains authoritative.

**Build the annotation plan (mandatory before 11c):**

The annotation plan controls which canvas measurement overlays Step 11c draws on each preview instance. It is built **strictly from the section's `ROWS`** — never from inspecting the inst — so overlays can only ever reflect what the table documents.

For each value-column index `i`, build `annotationPlan[i]` — an object whose keys are drawn ONLY from this allowlist:

| Row `spec` (from the parsed `.md`, Step 4) | `annotationPlan[i]` keys emitted | Notes |
|---|---|---|
| `padding` | `paddingTop`, `paddingBottom`, `paddingStart`, `paddingEnd` (all four with the same `{token}`) | Uniform padding |
| `verticalPadding` | `paddingTop`, `paddingBottom` | Symmetric vertical |
| `horizontalPadding` | `paddingStart`, `paddingEnd` | Symmetric horizontal |
| `paddingTop` / `paddingBottom` / `paddingStart` / `paddingEnd` | that one side | Per-side |
| `itemSpacing` / `contentSpacing` / `gapBetween` / `iconLabelSpacing` | `itemSpacing` | Auto-layout gap |
| `minWidth` / `maxWidth` / `minHeight` / `maxHeight` | that one constraint | Single-axis overlay with `freeText: "min N"` / `"max N"` |

Each entry is `{ token: string|null }`. `token` is the variable name when the row's `display` cell was token-bound (`"spacing-md (16)"` → `token = "spacing-md"`), or `null` when hardcoded (`"16"` → `token = null`). Derive `token` from the parsed row's `display` cell (the text before `" ("`); the `.md` already pre-formatted these cells, so a simple split is all that is needed.

**Explicit blocklist** — any row with one of these `spec` names contributes nothing to `annotationPlan`, even if it appears in the table:

`cornerRadius`, `cornerRadiusTopStart`, `cornerRadiusTopEnd`, `cornerRadiusBottomStart`, `cornerRadiusBottomEnd`, `borderWidth`, `strokeWeight`, `width`, `height`, `fixedWidth`, `fixedHeight`, `iconSize`, `leadingIconSize`, `trailingIconSize`, `slotWidth`, `slotMinWidth`, `slotMaxWidth`, `widthMode`, `heightMode`, `verticalAlignment`, `horizontalAlignment`, `clipsContent`, `textStyle`, `fontSize`, `fontWeight`, `lineHeight`, `letterSpacing`, `iconName`, `leadingIcon`, `trailingIcon`, group-header rows (all-`–` values), and anything not in the allowlist above.

If `annotationPlan[i]` is empty for every column (e.g., a shape-only or typography-only section), 11c draws nothing and `measurementCount` is `0` by design. That is the correct outcome.

**Padding anchor rule (mandatory):** Padding rows are drawn between the container edge and the **child whose edge sits on the container's inner-content edge for that side** (within a 0.5-px epsilon of `paddingTop` / `paddingBottom` / `paddingLeft` / `paddingRight`). This guarantees the line length — and therefore Figma's default numeric label — equals the autolayout value the table documents, even when other children are HUG-sized and centered along the cross-axis. If no child aligns to that edge, the line is drawn against the first/last visible child with a `freeText` override carrying the autolayout value so the label still matches the table. The Step 11c `annotate` function implements this via `findEdgeAnchor`; no per-row configuration is required.

**Annotation scope (`ANNOTATE_SCOPE`):**

- `"rootOnly"` for variant / density / shape / composition / behavior / state-conditional / boolean-toggled sections (the table documents the root container's own auto-layout settings).
- `"fullTree"` for `subComponent` and `slotContent` sections (the table documents the inst's internal structure, including the SLOT node for `slotContent`). Recursion stops at nested INSTANCE boundaries — those have their own spec sections.

#### Step 11b: Render the table

Run **one `figma_execute` call** for this section's table. Replace all `__PLACEHOLDER__` values with the section's data from Step 4 (the parsed `.md` sections / columns / rows).

```javascript
const FRAME_ID = '__FRAME_ID__';
const SECTION_NAME = '__SECTION_NAME__';
const SECTION_DESCRIPTION = '__SECTION_DESCRIPTION__';
const HAS_DESCRIPTION = __HAS_DESCRIPTION__;
const COLUMNS = __COLUMNS_JSON__;
const ROWS = __ROWS_JSON__;

const frame = await figma.getNodeByIdAsync(FRAME_ID);
const sectionTemplate = frame.findOne(n => n.name === '#section-template');

const section = sectionTemplate.clone();
sectionTemplate.parent.appendChild(section);
section.name = SECTION_NAME;
section.visible = true;

const textNodes = section.findAll(n => n.type === 'TEXT');
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

const titleFrame = section.findOne(n => n.name === '#section-title');
if (titleFrame) {
  const t = titleFrame.findOne(n => n.type === 'TEXT');
  if (t) t.characters = SECTION_NAME;
}

const descFrame = section.findOne(n => n.name === '#section-description');
if (descFrame) {
  if (!HAS_DESCRIPTION) {
    descFrame.visible = false;
  } else {
    const t = descFrame.findOne(n => n.type === 'TEXT');
    if (t) t.characters = SECTION_DESCRIPTION;
  }
}

const specTable = section.findOne(n => n.name === '#spec-table');

const variantTitleFrame = specTable.findOne(n => n.name === '#variant-title');
if (variantTitleFrame) {
  const t = variantTitleFrame.findOne(n => n.type === 'TEXT');
  if (t) t.characters = COLUMNS[0];
}

const headerRow = specTable.children.find(c => c.name === 'Header row');
const variantValueTemplate = headerRow.findOne(n => n.name === '#variant-value');
const notesHeader = headerRow.findOne(n => n.name === '#notes-header');
const notesIndex = notesHeader ? headerRow.children.indexOf(notesHeader) : -1;
const valueColumns = COLUMNS.slice(1, -1);

if (notesHeader) {
  notesHeader.layoutSizingHorizontal = 'FILL';
}

const headerClones = [];
for (let i = 0; i < valueColumns.length; i++) {
  const clone = variantValueTemplate.clone();
  headerClones.push(clone);
  if (notesIndex >= 0) {
    headerRow.insertChild(notesIndex + i, clone);
  } else {
    headerRow.appendChild(clone);
  }
}
variantValueTemplate.remove();

for (let i = 0; i < headerClones.length; i++) {
  headerClones[i].layoutSizingHorizontal = 'FILL';
  const textNode = headerClones[i].children.find(c => c.type === 'TEXT');
  if (textNode) textNode.characters = valueColumns[i];
}

const rowTemplate = specTable.findOne(n => n.name === '#row-template');

for (const rowData of ROWS) {
  const row = rowTemplate.clone();
  specTable.appendChild(row);
  row.name = 'Row ' + rowData.spec;

  const propNameFrame = row.findOne(n => n.name === '#property-name');
  if (propNameFrame) {
    const t = propNameFrame.findOne(n => n.type === 'TEXT');
    if (t) t.characters = rowData.spec;
  }

  const propNotesFrame = row.findOne(n => n.name === '#property-notes');
  if (propNotesFrame) {
    const t = propNotesFrame.findOne(n => n.type === 'TEXT');
    if (t) t.characters = rowData.notes;
    propNotesFrame.layoutSizingHorizontal = 'FILL';
  }

  const hierarchyFrame = row.findOne(n => n.name === '#hierarchy-indicator');
  if (hierarchyFrame) {
    if (rowData.isSubProperty) {
      hierarchyFrame.visible = true;
      const withinGroup = hierarchyFrame.children.find(c => c.name === 'within-group');
      const lastInGroup = hierarchyFrame.children.find(c => c.name === '#hierarchy-indicator-last');
      if (rowData.isLastInGroup) {
        if (withinGroup) withinGroup.visible = false;
        if (lastInGroup) lastInGroup.visible = true;
      } else {
        if (withinGroup) withinGroup.visible = true;
        if (lastInGroup) lastInGroup.visible = false;
      }
    } else {
      hierarchyFrame.visible = false;
    }
  }

  const valueCellTemplate = row.findOne(n => n.name === '#property-value-cell');
  const notesCell = row.findOne(n => n.name === '#property-notes');
  const notesCellIndex = notesCell ? row.children.indexOf(notesCell) : -1;

  const cellClones = [];
  for (let i = 0; i < rowData.values.length; i++) {
    const clone = valueCellTemplate.clone();
    cellClones.push(clone);
    if (notesCellIndex >= 0) {
      row.insertChild(notesCellIndex + i, clone);
    } else {
      row.appendChild(clone);
    }
  }
  valueCellTemplate.remove();

  for (let i = 0; i < cellClones.length; i++) {
    cellClones[i].layoutSizingHorizontal = 'FILL';
    const textNode = cellClones[i].children.find(c => c.type === 'TEXT');
    if (textNode) textNode.characters = rowData.values[i];
  }
}

rowTemplate.remove();
return { success: true, section: SECTION_NAME, sectionId: section.id };
```

Save the returned `sectionId` — pass it to Step 11c as `__SECTION_ID__` so the preview script can locate the section by ID instead of by name.

#### Step 11c: Populate this section's preview

**Immediately after** the table is rendered for this section, populate its `#Preview` frame with annotated component instances. Use the preview parameters determined in Step 11a.

Replace the following placeholders with the values from Step 11a:

- `__SECTION_ID__` — the section's node ID returned by Step 11b (`sectionId` in the return value)
- `__COMP_SET_NODE_ID__` — the component set (or standalone component) node ID
- `__SUB_COMP_SET_NODE_ID__` — the sub-component's own component set ID from `render-meta.subComponents[].subCompSetId` (empty string `''` for non-sub-component sections; also `''` for `slotContent` — the preferred component is nested via `SLOT_POPULATION`, not sourced as `SUB_COMP_SET_ID`)
- `__DEFAULT_PROPS_JSON__` — object mapping all variant axis names to their default values (from `render-meta.variantAxesDefaults`). When `SUB_COMP_SET_ID` is non-empty, use the sub-component's own variant-axes defaults from `render-meta.subComponents[].subCompVariantAxesDefaults` instead.
- `__VARIANT_AXIS__` — from the decision table in Step 11a
- `__COLUMN_VALUES_JSON__` — from the decision table in Step 11a
- `__PROPERTY_OVERRIDES_JSON__` — from the decision table in Step 11a
- `__SUB_COMP_OVERRIDES_JSON__` — object mapping sub-component boolean property keys to `true`, from `render-meta.subComponents[].booleanOverrides` (empty object `{}` for non-sub-component sections)
- `__SLOT_POPULATION_JSON__` — from the decision table in Step 11a (`null` for every section type EXCEPT `slotContent`; an object describing the slot to populate for `slotContent` sections). When non-null, the script sources from the parent, locates the slot by `slotName`, and `slotNode.appendChild()` an instance of the preferred component.
- `__IS_BOOLEAN_TOGGLED__` — `true` only for `boolean-toggled` sections; `false` everywhere else. When `false`, the script runs the recursive nested-boolean enabler so all documented optional children are visible. When `true`, it's skipped because per-column `PROPERTY_OVERRIDES` is the configuration spec.
- `__ANNOTATION_PLAN_JSON__` — from "Build the annotation plan" in Step 11a. Array of length `COLUMN_VALUES.length`. Each entry is either `{}` (no annotations for that column) or an object whose keys are drawn from the allowlist (`paddingTop`, `paddingBottom`, `paddingStart`, `paddingEnd`, `itemSpacing`, `minWidth`, `maxWidth`, `minHeight`, `maxHeight`) and whose values are `{ token: string|null }`.
- `__ANNOTATE_SCOPE__` — `"rootOnly"` or `"fullTree"`, from Step 11a's annotation-scope rule.

```javascript
const SECTION_ID = '__SECTION_ID__';
const COMP_SET_ID = '__COMP_SET_NODE_ID__';
const SUB_COMP_SET_ID = '__SUB_COMP_SET_NODE_ID__';
const DEFAULT_PROPS = __DEFAULT_PROPS_JSON__;
const VARIANT_AXIS = '__VARIANT_AXIS__';
const COLUMN_VALUES = __COLUMN_VALUES_JSON__;
const PROPERTY_OVERRIDES = __PROPERTY_OVERRIDES_JSON__;
const SUB_COMP_OVERRIDES = __SUB_COMP_OVERRIDES_JSON__;
const SLOT_POPULATION = __SLOT_POPULATION_JSON__;
const IS_BOOLEAN_TOGGLED = __IS_BOOLEAN_TOGGLED__;
const ANNOTATION_PLAN = __ANNOTATION_PLAN_JSON__;
const ANNOTATE_SCOPE = '__ANNOTATE_SCOPE__';
const FONT_FAMILY = '__FONT_FAMILY__';

async function loadAllFonts(rootNode) {
  const textNodes = rootNode.findAll(n => n.type === 'TEXT');
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
    }
    if ('children' in node && node.children) {
      for (const child of node.children) { try { enableNestedBooleans(child); } catch {} }
    }
  } catch {}
}

const section = await figma.getNodeByIdAsync(SECTION_ID);
if (!section) return { error: 'Section not found: ' + SECTION_ID };

let _p = section; while (_p.parent && _p.parent.type !== 'DOCUMENT') _p = _p.parent;
if (_p.type === 'PAGE') await figma.setCurrentPageAsync(_p);
const page = _p.type === 'PAGE' ? _p : figma.currentPage;

const preview = section.findOne(n => n.name === '#Preview');
if (!preview) return { error: 'No #Preview frame in section: ' + SECTION_ID };

const useSubComp = SUB_COMP_SET_ID && SUB_COMP_SET_ID !== '';
const sourceId = useSubComp ? SUB_COMP_SET_ID : COMP_SET_ID;
const compNode = await figma.getNodeByIdAsync(sourceId);
if (!compNode) return { error: 'Component not found: ' + sourceId };
const isComponentSet = compNode.type === 'COMPONENT_SET';

const instances = [];
for (let i = 0; i < COLUMN_VALUES.length; i++) {
  const colValue = COLUMN_VALUES[i];
  const variantProps = { ...DEFAULT_PROPS };
  if (VARIANT_AXIS && VARIANT_AXIS !== '') {
    variantProps[VARIANT_AXIS] = colValue;
  }
  if (PROPERTY_OVERRIDES.length > i) {
    for (const [k, v] of Object.entries(PROPERTY_OVERRIDES[i])) {
      variantProps[k] = v;
    }
  }

  let targetVariant = null;
  if (isComponentSet) {
    let bestFallback = null;
    let bestFallbackScore = -1;
    for (const child of compNode.children) {
      const vp = child.variantProperties || {};
      let score = 0;
      let exactMatch = true;
      for (const [k, v] of Object.entries(variantProps)) {
        if (vp[k] === v) { score++; } else { exactMatch = false; }
      }
      if (exactMatch) { targetVariant = child; break; }
      if (score > bestFallbackScore) { bestFallbackScore = score; bestFallback = child; }
    }
    if (!targetVariant) targetVariant = bestFallback;
  } else {
    targetVariant = compNode;
  }

  instances.push({ colValue, targetVariant, overrideIndex: i });
}

const LABEL_FONT = await loadFontWithFallback(FONT_FAMILY, 'Medium');
const wrappers = [];
for (const entry of instances) {
  const wrapper = figma.createFrame();
  wrapper.name = 'Instance ' + entry.colValue;
  wrapper.layoutMode = 'VERTICAL';
  wrapper.primaryAxisAlignItems = 'CENTER';
  wrapper.counterAxisAlignItems = 'CENTER';
  wrapper.layoutSizingHorizontal = 'HUG';
  wrapper.layoutSizingVertical = 'HUG';
  wrapper.itemSpacing = 10;
  wrapper.fills = [];

  if (!entry.targetVariant) {
    const placeholder = figma.createText();
    await figma.loadFontAsync({ family: 'Inter', style: 'Regular' });
    placeholder.characters = 'Variant unavailable';
    placeholder.fontSize = 12;
    placeholder.fills = [{ type: 'SOLID', color: { r: 0.6, g: 0.6, b: 0.6 } }];
    wrapper.appendChild(placeholder);
  } else {
    const inst = entry.targetVariant.createInstance();
    await loadAllFonts(inst);
    if (useSubComp && Object.keys(SUB_COMP_OVERRIDES).length > 0) {
      inst.setProperties(SUB_COMP_OVERRIDES);
      await loadAllFonts(inst);
    }
    if (!useSubComp && PROPERTY_OVERRIDES.length > entry.overrideIndex && Object.keys(PROPERTY_OVERRIDES[entry.overrideIndex]).length > 0) {
      inst.setProperties(PROPERTY_OVERRIDES[entry.overrideIndex]);
      await loadAllFonts(inst);
    }
    if (!IS_BOOLEAN_TOGGLED) {
      enableNestedBooleans(inst);
      await loadAllFonts(inst);
    }
    wrapper.appendChild(inst);
    entry._inst = inst;
    entry._ghostOnly = false;
  }

  const label = figma.createText();
  label.fontName = LABEL_FONT;
  label.characters = entry.colValue;
  label.fontSize = 14;
  label.fills = [{ type: 'SOLID', color: { r: 0.29, g: 0.29, b: 0.29 } }];
  wrapper.appendChild(label);

  preview.appendChild(wrapper);
  wrappers.push({ wrapper, entry });
}

if (SLOT_POPULATION && SLOT_POPULATION.slotName) {
  const prefSourceId = SLOT_POPULATION.preferredComponentSetId || SLOT_POPULATION.preferredComponentId;
  const prefSourceNode = await figma.getNodeByIdAsync(prefSourceId);
  const prefIsCS = prefSourceNode && prefSourceNode.type === 'COMPONENT_SET';
  const prefBoolDefs = SLOT_POPULATION.preferredBooleanDefs || {};
  const prefAxis = SLOT_POPULATION.preferredVariantAxis || '';

  for (let i = 0; i < wrappers.length; i++) {
    const entry = wrappers[i].entry;
    if (!entry._inst || !prefSourceNode) continue;
    const slotNode = entry._inst.findOne(n => n.type === 'SLOT' && n.name === SLOT_POPULATION.slotName);
    if (!slotNode) continue;

    let prefVariant = prefSourceNode;
    if (prefIsCS) {
      const target = {};
      if (prefAxis) target[prefAxis] = entry.colValue;
      let bestFallback = prefSourceNode.children[0];
      let bestScore = -1;
      for (const child of prefSourceNode.children) {
        const vp = child.variantProperties || {};
        let score = 0;
        let exact = true;
        for (const [k, v] of Object.entries(target)) {
          if (vp[k] === v) { score++; } else { exact = false; }
        }
        if (exact) { prefVariant = child; break; }
        if (score > bestScore) { bestScore = score; bestFallback = child; }
      }
      if (prefVariant === prefSourceNode) prefVariant = bestFallback;
    }
    if (!prefVariant || (prefVariant.type !== 'COMPONENT' && prefVariant.type !== 'INSTANCE')) continue;

    let prefInst;
    try { prefInst = prefVariant.createInstance(); } catch { continue; }
    await loadAllFonts(prefInst);
    if (Object.keys(prefBoolDefs).length > 0) {
      try { prefInst.setProperties(prefBoolDefs); } catch {}
      await loadAllFonts(prefInst);
    }
    enableNestedBooleans(prefInst);
    await loadAllFonts(prefInst);

    let inserted = false;
    try { slotNode.appendChild(prefInst); inserted = true; } catch {}
    if (!inserted) {
      try {
        wrappers[i].wrapper.layoutMode = 'NONE';
        wrappers[i].wrapper.appendChild(prefInst);
        const slotAbsX = slotNode.absoluteTransform[0][2];
        const slotAbsY = slotNode.absoluteTransform[1][2];
        const wrapAbsX = wrappers[i].wrapper.absoluteTransform[0][2];
        const wrapAbsY = wrappers[i].wrapper.absoluteTransform[1][2];
        prefInst.x = Math.round(slotAbsX - wrapAbsX + (slotNode.width - prefInst.width) / 2);
        prefInst.y = Math.round(slotAbsY - wrapAbsY + (slotNode.height - prefInst.height) / 2);
        prefInst.opacity = 0.6;
        entry._ghostOnly = true;
      } catch {}
    }
  }
}

function findEdgeAnchor(container, side, kids) {
  if (!kids || kids.length === 0) return null;
  const EPS = 0.5;
  let pTop = 0, pBottom = 0, pLeft = 0, pRight = 0;
  try { pTop = Number(container.paddingTop) || 0; } catch {}
  try { pBottom = Number(container.paddingBottom) || 0; } catch {}
  try { pLeft = Number(container.paddingLeft) || 0; } catch {}
  try { pRight = Number(container.paddingRight) || 0; } catch {}
  let cw = 0, ch = 0;
  try { cw = Number(container.width) || 0; } catch {}
  try { ch = Number(container.height) || 0; } catch {}
  const innerTop = pTop;
  const innerBottom = ch - pBottom;
  const innerLeft = pLeft;
  const innerRight = cw - pRight;
  for (const k of kids) {
    let kx = 0, ky = 0, kw = 0, kh = 0;
    try { kx = Number(k.x) || 0; } catch {}
    try { ky = Number(k.y) || 0; } catch {}
    try { kw = Number(k.width) || 0; } catch {}
    try { kh = Number(k.height) || 0; } catch {}
    if (side === 'TOP'    && Math.abs(ky - innerTop) <= EPS) return k;
    if (side === 'BOTTOM' && Math.abs((ky + kh) - innerBottom) <= EPS) return k;
    if (side === 'LEFT'   && Math.abs(kx - innerLeft) <= EPS) return k;
    if (side === 'RIGHT'  && Math.abs((kx + kw) - innerRight) <= EPS) return k;
  }
  return null;
}

function annotate(node, plan, isRoot, scope) {
  if (!node.visible) return 0;
  let count = 0;
  const isAuto = node.layoutMode && node.layoutMode !== 'NONE';
  const kids = ('children' in node) ? node.children.filter(c => c.visible) : [];
  const first = kids[0], last = kids[kids.length - 1];

  if (isAuto && first) {
    const sideToProp = { TOP: 'paddingTop', BOTTOM: 'paddingBottom', LEFT: 'paddingLeft', RIGHT: 'paddingRight' };
    const paddingSides = [
      { key: 'paddingTop',    side: 'TOP',    fallback: first },
      { key: 'paddingBottom', side: 'BOTTOM', fallback: last  },
      { key: 'paddingStart',  side: 'LEFT',   fallback: first },
      { key: 'paddingEnd',    side: 'RIGHT',  fallback: last  },
    ];
    for (const { key, side, fallback } of paddingSides) {
      const entry = plan && plan[key];
      if (!entry) continue;
      const anchor = findEdgeAnchor(node, side, kids);
      const child = anchor || fallback;
      let from, to;
      if (side === 'TOP')         { from = { node: node,  side: 'TOP'    }; to = { node: child, side: 'TOP'    }; }
      else if (side === 'BOTTOM') { from = { node: child, side: 'BOTTOM' }; to = { node: node,  side: 'BOTTOM' }; }
      else if (side === 'LEFT')   { from = { node: node,  side: 'LEFT'   }; to = { node: child, side: 'LEFT'   }; }
      else                        { from = { node: child, side: 'RIGHT'  }; to = { node: node,  side: 'RIGHT'  }; }
      let opts;
      if (entry.token) {
        opts = { freeText: entry.token };
      } else if (!anchor) {
        let autoVal = 0;
        try { autoVal = Number(node[sideToProp[side]]) || 0; } catch {}
        opts = { freeText: String(Math.round(autoVal)) };
      }
      try { page.addMeasurement(from, to, opts); count++; } catch {}
    }

    const gapEntry = plan && plan.itemSpacing;
    if (gapEntry && kids.length > 1 && (node.itemSpacing || 0) > 0) {
      const isH = node.layoutMode === 'HORIZONTAL';
      const opts = gapEntry.token ? { freeText: gapEntry.token } : undefined;
      for (let i = 0; i < kids.length - 1; i++) {
        try {
          page.addMeasurement(
            { node: kids[i],     side: isH ? 'RIGHT' : 'BOTTOM' },
            { node: kids[i + 1], side: isH ? 'LEFT'  : 'TOP'    },
            opts
          );
          count++;
        } catch {}
      }
    }
  }

  for (const [key, axis] of [['minWidth','H'],['maxWidth','H'],['minHeight','V'],['maxHeight','V']]) {
    const entry = plan && plan[key];
    if (!entry) continue;
    const v = node[key];
    if (typeof v !== 'number' || v <= 0 || v >= 10000) continue;
    const prefix = key.startsWith('min') ? 'min ' : 'max ';
    try {
      page.addMeasurement(
        { node: node, side: axis === 'H' ? 'LEFT' : 'TOP' },
        { node: node, side: axis === 'H' ? 'RIGHT' : 'BOTTOM' },
        { freeText: prefix + Math.round(v) }
      );
      count++;
    } catch {}
  }

  if (scope === 'fullTree' && (isRoot || node.type !== 'INSTANCE')) {
    for (const c of kids) count += annotate(c, plan, false, scope);
  }
  return count;
}

let measurementCount = 0;
let plannedColumns = 0;
for (let i = 0; i < wrappers.length; i++) {
  const entry = wrappers[i].entry;
  if (!entry._inst || entry._ghostOnly) continue;
  const plan = ANNOTATION_PLAN[i];
  if (!plan || Object.keys(plan).length === 0) continue;
  plannedColumns++;
  try { for (const m of page.getMeasurementsForNode(entry._inst)) page.deleteMeasurement(m.id); } catch {}
  measurementCount += annotate(entry._inst, plan, true, ANNOTATE_SCOPE);
}

return { success: true, section: SECTION_ID, measurementCount: measurementCount, plannedColumns: plannedColumns };
```

### Step 12: Visual Validation

1. `figma_take_screenshot` with the `frameId` — Capture the completed spec
2. Verify visually (from the screenshot):
   - All sections are present with correct titles
   - Column headers match the expected variants/sizes
   - Row values are filled correctly
   - Hierarchy indicators (├─ / └─) appear on sub-properties
   - General notes are visible or hidden as expected
   - Each section's `#Preview` frame has at least one child instance and the instances are visible
   - **Preview layout**: Instances are placed inside the `#Preview` frame. Each instance has a label below it. The template's `#Preview` frame provides the layout — the script does not override any of its properties.
   - Column widths look balanced — the notes column is not crushed
   - **Sub-component preview correctness**: Sub-component section previews show instances from the sub-component's own component set (not the parent). Verify that the preview shows the sub-component in isolation (e.g., four Label instances at different sizes, not four full Text Field instances). If `SUB_COMP_OVERRIDES` was specified, verify that optional internal children (e.g., character count, icons) are visible on each preview instance.
   - **Slot content preview correctness**: `slotContent` section previews show the parent component with the preferred component nested inside the actual SLOT node (not a standalone preferred-component preview). Verify that the preferred component appears inside the parent at each parent size, with all parent-level booleans enabled so the slot is visible.
   - **Recursive boolean enable**: For every section type except `boolean-toggled`, optional children documented in the table should be visible on every preview instance — even children gated by booleans deep inside nested sub-components.
   - **Behavior variant preview simplicity**: When a behavior/configuration axis exists (e.g., Static vs Interactive), the preview shows only the default configuration — one row of instances at each size. Do NOT duplicate instances for each configuration.
3. Verify measurements (NOT from the screenshot — measurements are a canvas overlay produced by `page.addMeasurement(...)` and they DO NOT appear in `figma_take_screenshot` / `get_screenshot` output):
   - For each section's Step 11c return value, compare `measurementCount` against `plannedColumns`. If `plannedColumns > 0` and `measurementCount === 0`, the inst was likely missing or hidden — re-run that section's 11c.
   - Sections whose tables contain only blocklisted properties (cornerRadius / borderWidth / typography / sizing modes / icon refs / etc.) are expected to return `plannedColumns === 0` and need no follow-up.
   - For `slotContent` sections specifically, if the preferred component fell back to ghost-overlay placement (`appendChild` failed), annotation is intentionally skipped for that column. Confirm visually in the screenshot that the preferred component is overlaid at the slot bbox at 0.6 opacity — if so, the table values still apply but the overlay can't be drawn for that column.
4. If issues are found, fix via `figma_execute` / `use_figma` and re-capture (up to 3 iterations)

### Step 13: Completion Link

Print a clickable Figma URL to the completed spec in chat. Construct the URL from the `fileKey` (`render-meta.fileKey`) and the `frameId` (returned by Step 9), replacing `:` with `-` in the node ID:

```
Structure spec complete: https://www.figma.com/design/{fileKey}/?node-id={frameId}
```

## Notes

- The target node referenced by `render-meta.component.compSetNodeId` can be either a `COMPONENT_SET` (multi-variant) or a standalone `COMPONENT` (single variant). The Step 11c preview script detects the type at render time (`compNode.type === 'COMPONENT_SET'`) and falls back to `compNode.createInstance()` directly for standalone components. For standalone components `render-meta.variantAxes` is empty and there are no variant columns.
- Dynamic columns: The `#variant-value` template in the header row and `#property-value-cell` in each data row are cloned once per value column, then the original template is removed. Clones are inserted before the Notes column to maintain correct column order. All value columns and the Notes column use `layoutSizingHorizontal = 'FILL'` so Figma's auto-layout distributes width equally across them.
- Each section is rendered in a separate `figma_execute` call to avoid timeouts.
- **Native canvas measurements:** Step 11c annotates each preview instance with native Figma measurement overlays via `page.addMeasurement(...)`. Annotation is gated by the section's table — only properties present in `ANNOTATION_PLAN` (paddings, gap/itemSpacing, min/max width/height) are drawn. Token-bound rows render the token name on the line via `freeText`. Hardcoded padding rows are anchored to the child whose edge sits on the container's inner-content edge for that side (computed from the container's autolayout paddings), so Figma's default numeric label naturally matches the autolayout value the table documents. When no child aligns to that edge — e.g., a horizontal capsule whose children are HUG-sized and `counterAxisAlignItems=CENTER` — the line falls back to the first/last visible child but carries a `freeText` override of the autolayout value so the label still matches the table. Hardcoded gap/itemSpacing rows continue to let Figma's default numeric label show through (consecutive children sit edge-to-edge with the gap by definition). Min/max constraints render with a `"min N"` / `"max N"` prefix. Per-instance idempotency is provided by `getMeasurementsForNode` + `deleteMeasurement` before each annotation pass. Both `figma-console` (`figma_execute`) and `figma-mcp` (`use_figma`) execute the identical JS — no MCP-specific branch is needed. Measurements are a canvas overlay and do NOT appear in screenshot output; verify via the `measurementCount` / `plannedColumns` returned by Step 11c.
- **Slot content preview faithfulness:** `slotContent` previews source the parent component at each column's parent size and use `slotNode.appendChild()` to nest the preferred component inside the actual SLOT node (mirrors the slot-nesting pattern used in the `create-anatomy` skill). This makes the preview a faithful reference for the table — the SLOT's contextual padding, sizing, and spacing are live in the inst tree, so canvas measurements correctly reflect the slot-imposed values. Ghost-overlay fallback (0.6 opacity at the slot's bbox) handles the rare case where `appendChild` fails; annotation is skipped for that column when ghost fallback fires.
- **Recursive nested-boolean enable:** Every section type except `boolean-toggled` runs a recursive walker after `createInstance` + `setProperties` that enables every BOOLEAN property on every nested INSTANCE (mirrors the equivalent walker in the `create-color` skill). This guarantees that any optional child documented in the section's table is visible in the preview, even when it's gated by a sub-component's own boolean (e.g., a Label's "Show character count" inside a Text Field's Size section). Boolean-toggled sections are excluded so their per-column `PROPERTY_OVERRIDES` remains authoritative.
