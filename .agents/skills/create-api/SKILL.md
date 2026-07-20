---
name: create-api
description: Generate API overview specifications documenting component properties, values, defaults, and configuration examples. Use when the user mentions "api", "api spec", "props", "properties", "component api", or wants to document a component's configurable properties.
---

# Create API Overview

Generate an API overview directly in Figma — property tables with values, defaults, required status, sub-component tables, and configuration examples.

**Execution contract (read first).**
- This file is instructions to RUN, not a document to edit. Invoking the skill = render the API overview into Figma from the input `.md`.
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

- **Component `.md` spec** (**required**, user-provided path) — the source-of-truth component spec produced by the `create-component-md` skill. **The user tells you where this `.md` lives** — use the exact path they provide; the `.md` may live anywhere. This skill **renders the API section from the `.md`**; it does NOT re-extract anything from Figma and does NOT re-identify properties. `fileKey`, `nodeId`, and `compSetNodeId` come from the `.md`'s `render-meta` block.
- **Figma link** (optional) — placement hint only (where to drop the rendered frame on the canvas) and the target for the single whitelisted TEXT-node listing in Step 5. Never the source of structural facts or the property contract.

There is no screenshot-only path. Without the component `.md` there is nothing to render — see Step 0's fail-fast contract.

## Workflow

Copy this checklist and update as you progress:

```
Task Progress:
- [ ] Step 0: Require + parse the component `.md` (API body + render-meta). FAIL FAST if missing.
- [ ] Step 1: Read instruction file (only as needed for example-projection / isSubProperty prose — NOT for re-identifying the API)
- [ ] Step 2: Verify MCP connection
- [ ] Step 3: Read template key from uspecs.config.json
- [ ] Step 4: Build render inputs from the parsed .md (main table, sub-component tables, config examples, referenced components) — NO extraction
- [ ] Step 5: Re-derive light values (required, isSubProperty, example→raw-key projection, slot insertions) + the ONE whitelisted TEXT-node listing for preview text overrides
- [ ] Step 6: (folded into Step 4 — the property/sub-component tables are ALREADY authored in the .md)
- [ ] Step 7: Audit the assembled render inputs against the .md
- [ ] Step 8: Import and detach the API template
- [ ] Step 9: Fill header fields
- [ ] Step 10: Fill main API table
- [ ] Step 11: Fill sub-component tables (if any)
- [ ] Step 12: Fill configuration examples
- [ ] Step 13: Visual validation
```

### Step 0: Require and parse the component `.md` (fail fast)

**This skill is a consumer of the `.md` source of truth.** It does not re-extract from Figma and does not re-run the property-identification reasoning layer — that work already happened in `extract-api`/`create-component-md` and is baked into the `.md`'s API section (Properties table, sub-component tables, configuration examples, referenced-components tables). Your job is to render that section into a Figma frame.

1. **Resolve the `.md` path.** Use the exact path the user gave, else an attached or open `.md` in context. The `.md` may live anywhere; do NOT invent or guess a path. If neither resolves to an existing file, abort per item 2. Never pause to ask the user which file to use.
2. **Require the file.** If no file exists at the resolved `.md` path, **abort immediately** with this exact single-line diagnostic and stop — do NOT fall back to extraction:

   > This skill requires the component's Markdown `.md` spec (produced by create-component-md). Provide the path to it. (create-component-md needs a _base.json from the uSpec Extract plugin.)

3. **Parse the API section body** (`## API`) from the `.md`. Copy these verbatim — they are already authored, do not re-derive them:
   - **General notes** — the blockquote (`> …`) immediately under the confidence header, if present → `GENERAL_NOTES`.
   - **Properties table** — the table with columns `Property | Type | Values | Default | Notes` → the main table rows. Each row carries `property` (the `Property` cell), `values` (the `Values` cell, pipe-joined verbatim), `default` (the `Default` cell), and `notes` (the `Notes` cell).
   - **Sub-component tables** — each `### {name}` sub-section (with optional description) whose body is a `Property | Type | Values | Default | Notes` table → one sub-component entry `{ name, description, properties: [...] }`.
   - **Configuration examples** — each `### {name}` sub-section consisting of a description paragraph + a fenced `code` block → one example entry `{ name, description, code }`. The fenced block is the `example.code` string; keep it intact for the Step 5 projection.
   - **Referenced components** — the `### Referenced components` sub-section (when present): each `#### {displayName}` lead paragraph + `Prop passed to … | Value in this context | Notes` table → one referenced-component entry. These render as additional sub-component tables (the `.md` is the source of truth for the referenced child's placement props; its full property surface lives in its own spec).
4. **Parse the `render-meta` block** (the fenced JSON between `<!-- render-meta:start v=1 -->` and `<!-- render-meta:end -->`):
   - `COMP_SET_ID` = `component.compSetNodeId` — the target for live preview instances (Step 12) and the single whitelisted read (Step 5).
   - `propertyDefs` — keyed by **raw component-property key** (e.g. `"clear button#10225:1"`); each entry `{ type, default?, values?, preferredComponentKey?, associatedLayerName?, associatedLayerId? }`. This is the raw-key dictionary used to project human prop names in configuration examples to the keys `setProperties` expects.
   - `booleanDefs[]` — `{ key, default, associatedLayerName, associatedLayerId }`; `key` is the raw component-property key.
   - `slotContents[]` — for resolving configuration-example slot insertions: each entry `{ slotName, slotNodeType, preferredComponents: [{ componentKey, componentName, componentId, … }] }`. The `componentId` is the live node id to instantiate into a slot.
   - `fileKey`, `nodeId` — for the Step 14 completion link and template placement.
   - `sourceHash` — record it; the completion footer reports it so downstream readers can detect drift between this render and the `_base.json` that produced the `.md`.

**FORBIDDEN — do NOT re-extract / do NOT re-identify.** When the component `.md` is present (it always is past Step 0), you MUST NOT run the legacy extraction or the property-identification reasoning pass. Specifically:
- The old **Step 4b extraction script** (the `componentPropertyDefinitions` walk that rebuilt `variantAxes`, `booleanProps`, `instanceSwapProps`, `slotProps`, `composableChildren`, `ownershipHints`, `textNodeMap`, etc.) is **deleted** — it does not exist in this skill anymore. Do NOT run any `figma_execute` / `use_figma` script that walks the component tree to rebuild the property surface.
- The old **Step 4 context-gathering** (navigate / screenshot / `figma_get_file_data` / `figma_get_component` / `figma_get_variables`), the old **Step 4c working-evidence-set**, and the old **Step 5–6 property-identification reasoning** (variant decomposition, override-promotion pass, variable-mode classification, ownership/nesting decisions, sub-component pattern selection, `ApiOverviewData` synthesis) are all **deleted/demoted**. The Properties table, sub-component tables, configuration examples, and referenced-components tables are **already authored** in the `.md` — copy them verbatim; do NOT re-identify properties.
- The ONLY Figma reads this skill makes are: the **single whitelisted TEXT-node listing** in Step 5 (bounded below), the template import (Step 8), the header fill (Step 9), the table fills (Steps 10–11), and the configuration-example previews (Step 12). No other live reads are permitted.

### Step 1: Read References (only as needed)

The property contract is already authored in the `.md` — you do NOT re-identify it. Read [agent-api-instruction.md](../../../references/api/agent-api-instruction.md) **only** if you need to reason about a narrow rendering detail while building inputs:
- the `isSubProperty` Notes-prose convention (the `"Only meaningful when {parentProperty} = {triggerValue}. …"` template) when re-deriving the hierarchy flag in Step 5;
- the configuration-example `code` shape when projecting human prop names to raw `render-meta.propertyDefs` keys in Step 5.

Skip this step entirely when the `.md`'s configuration examples have no slot/variant overrides to project. Do NOT use the instruction file to re-run property identification — that reasoning is demoted (see Step 0 FORBIDDEN).

### Step 2: Verify MCP Connection

Read `mcpProvider` from `uspecs.config.json` and verify the connection (rendering — and the single whitelisted Step 5 read — require a live Figma session):

**If `figma-console`:**
- `figma_get_status` — Confirm Desktop Bridge plugin is active
- If connection fails: *"Please open Figma Desktop and run the Desktop Bridge plugin. Then try again."*

**If `figma-mcp`:**
- Connection is verified implicitly on the first `use_figma` call. No explicit check needed.
- If the first call fails: *"Please verify your FIGMA_API_KEY is set correctly in your MCP configuration."*

### Step 3: Read Template Key

Read the file `uspecs.config.json` and extract the `apiOverview` value from the `templateKeys` object.

Save this key as `API_TEMPLATE_KEY`. If the key is empty, tell the user:
> The API overview template key is not configured. Run the `firstrun` skill with your Figma template library link first.

### Step 4: Build render inputs from the parsed `.md` (no extraction)

Everything the render scripts need comes from the `.md` you parsed in Step 0. Assemble the render inputs directly — there is **no extraction call** here (see the FORBIDDEN directive in Step 0). Copy the authored content verbatim:

- **`GENERAL_NOTES`** — the API section's general-notes blockquote, verbatim. Empty when the `.md` has no general notes (`HAS_GENERAL_NOTES = false`).
- **`PROPERTIES` (main table)** — one row per Properties-table row in the `.md`: `{ property, values, default, notes, required?, isSubProperty? }`. The `property`, `values`, `default`, and `notes` cells are copied verbatim. `required` and `isSubProperty` are re-derived in Step 5 (they are not stored as their own columns in the `.md`).
- **`SUB_COMPONENT_TABLES`** — one entry per `### {name}` sub-component sub-section in the `.md`: `{ name, description, properties: [{ property, values, default, notes, required?, isSubProperty? }] }`. Rows copied verbatim; `required` / `isSubProperty` re-derived in Step 5.
- **`REFERENCED_COMPONENTS`** — the `### Referenced components` block (when present). Each `#### {displayName}` renders as an additional sub-component table whose rows come from the referenced child's `Prop passed to … | Value in this context | Notes` table (verbatim). The referenced child's full property surface lives in its own spec and is **not** re-expanded here.
- **`CONFIG_EXAMPLES`** — one entry per `### {name}` configuration example: `{ name, description, code }`, where `code` is the fenced `code` block string. The live-preview inputs (`VARIANT_PROPS`, `CHILD_OVERRIDES`, `TEXT_OVERRIDES`, `SLOT_INSERTIONS`, `EXAMPLE_PROPERTIES`) are projected from `code` + `render-meta` in Step 5.
- **`COMP_SET_ID`** — `render-meta.component.compSetNodeId`.

**Provenance.** Tag each emitted row by origin as you assemble it: `md` for anything copied verbatim from the `.md` body (Properties table, sub-component tables, referenced-components tables, example descriptions/code); `inferred` for the light Step 5 re-derivations (`required`, `isSubProperty`, the example→raw-key projection, slot-insertion targeting); `measured` for the live TEXT-node listing read in Step 5. Carry `sourceHash` from `render-meta` through to the Step 14 completion footer.

> The legacy "gather context + run the `componentPropertyDefinitions` extraction script" flow has been **removed**. Do not reintroduce it. The `.md` + `render-meta` are the complete input.

### Step 5: Re-derive light values + the one whitelisted live read

The `.md` already authored the property contract. Only a few render-time values are not stored as their own columns — re-derive them cheaply, **without** re-identifying properties:

**`required`** — derive from the `Default` cell using the existing rule: a row with an empty / absent default is `required` (`Yes`); a row with any default value is not required (`No`). Do not re-reason about the property's semantics — read the `default` cell only.

**`isSubProperty`** — derive from the `Notes` prose, not from a live tree. A row whose `Notes` cell begins with the authored template `"Only meaningful when {parentProperty} = {triggerValue}. …"` is a sub-property (`isSubProperty = true`); it renders with the hierarchy indicator and stays immediately after its parent row (the `.md` already orders it that way). Rows without that prose are top-level. The same rule applies inside sub-component tables.

**Configuration-example projection** — for each `CONFIG_EXAMPLES` entry, parse the fenced `code` string into the (human prop name → value) pairs it sets, then build:
- **`EXAMPLE_PROPERTIES`** — the example table rows `{ property, value, notes }`, one per pair shown in the `code` (human-readable names, verbatim from the example).
- **`VARIANT_PROPS`** / **`CHILD_OVERRIDES`** — the same pairs projected to the **raw component-property keys** `setProperties` expects, by mapping each human prop name onto the matching `render-meta.propertyDefs` raw key (e.g. the human `clear button` → `"clear button#10225:1"`). Variant axes and boolean toggles go in `VARIANT_PROPS`; per-child overrides for composable slot children go in `CHILD_OVERRIDES`.
- **`SLOT_INSERTIONS`** — when the example places content into a slot, build `{ slotName, componentNodeId, nestedOverrides?, textOverrides? }`. Resolve `slotName` against `render-meta.slotContents[].slotName` and `componentNodeId` against `render-meta.slotContents[].preferredComponents[].componentId`. Use `[]` when the example needs no slot population.
- **`TEXT_OVERRIDES`** — any literal text the example shows that differs from the component's default text, keyed by the **live TEXT layer name** discovered by the whitelisted read below. Use `{}` when the example shows no custom text.

**WHITELISTED MINIMAL LIVE READ (the ONLY Figma read this skill makes beyond rendering).** To set preview text on the configuration-example instances, you may run **one** read-only `figma_execute` / `use_figma` script that lists the TEXT nodes on `COMP_SET_ID` (`render-meta.component.compSetNodeId`) ONLY, to learn the live TEXT layer names (`textNodeMap`) and key your `TEXT_OVERRIDES` against them. This read is strictly bounded:
- **TEXT-node listing only** — return `{ name, characters }` for TEXT nodes on the default variant of `COMP_SET_ID`. Do NOT walk the component tree, do NOT read property definitions, variant axes, booleans, slots, variable collections, or ownership — that is property re-extraction and is FORBIDDEN (Step 0).
- **`<= 30` lines** of script. If you cannot express the listing in 30 lines, you are doing too much — trim it back to the TEXT-node names.
- **No layer-name guessing.** `TEXT_OVERRIDES` keys MUST come from this listing (or from `render-meta.propertyDefs[].associatedLayerName` where it already names the text layer). Never invent or infer a layer name.

```javascript
const COMP_SET_ID = '__COMP_SET_NODE_ID__';
const node = await figma.getNodeByIdAsync(COMP_SET_ID);
let _p = node; while (_p.parent && _p.parent.type !== 'DOCUMENT') _p = _p.parent;
if (_p.type === 'PAGE') await figma.setCurrentPageAsync(_p);
const variant = node.type === 'COMPONENT_SET' ? (node.defaultVariant || node.children[0]) : node;
const textNodes = variant.findAll ? variant.findAll(n => n.type === 'TEXT') : [];
return textNodes.map(tn => ({ name: tn.name, characters: tn.characters }));
```

Skip this read entirely when no configuration example sets custom preview text.

There is no Step 6 — the property contract (Properties table, sub-component tables, configuration examples, referenced components) is already authored in the `.md` and assembled in Step 4. Do not re-run the property-identification reasoning (variant decomposition, override-promotion pass, variable-mode classification, ownership/nesting decisions, sub-component pattern selection). That pass is deleted (see Step 0 FORBIDDEN).

### Step 7: Audit the assembled render inputs

Before rendering, verify the inputs you built from the `.md` (do NOT re-audit the property contract — that was decided in `create-component-md`):
- Every `PROPERTIES` / sub-component row's `property`, `values`, `default`, and `notes` match the `.md` table cells verbatim — no normalization of capitalization or punctuation, no invented rows.
- Every `required` flag follows the `default`-cell rule (empty/absent default ⇒ `Yes`), and every `isSubProperty` flag follows the `"Only meaningful when …"` Notes prose. No `isSubProperty` row was promoted/demoted by re-reasoning.
- Each `CONFIG_EXAMPLES` entry's `EXAMPLE_PROPERTIES` come from its `code` string, and its `VARIANT_PROPS` / `CHILD_OVERRIDES` keys are real `render-meta.propertyDefs` raw keys (not human names). `SLOT_INSERTIONS[].componentNodeId` resolves to a `render-meta.slotContents[].preferredComponents[].componentId`.
- Every `TEXT_OVERRIDES` key came from the whitelisted TEXT-node listing (or `render-meta.propertyDefs[].associatedLayerName`) — none were guessed.
- `COMP_SET_ID`, `propertyDefs`, `booleanDefs`, and `slotContents` come from `render-meta` — not from any live property extraction.
- You did NOT run an extraction/tree-walk or re-identify properties (see Step 0 FORBIDDEN).

Fix any mismatch by re-parsing the `.md` — never by re-extracting from Figma.

### Step 8: Import and Detach Template

Run via `figma_execute` (replace `__API_TEMPLATE_KEY__` with `API_TEMPLATE_KEY`, `__COMPONENT_NAME__` with the `.md` component name, and `__COMPONENT_NODE_ID__` with `render-meta.component.compSetNodeId`):

```javascript
const TEMPLATE_KEY = '__API_TEMPLATE_KEY__';
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

frame.name = '__COMPONENT_NAME__ API';
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

const notesFrame = frame.findOne(n => n.name === '#general-api-notes');
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

### Step 10: Fill Main API Table

Run via `figma_execute`. Replace `__FRAME_ID__` and `__PROPERTIES_JSON__` with the main table properties array.

```javascript
const FRAME_ID = '__FRAME_ID__';
const PROPERTIES = __PROPERTIES_JSON__;

const frame = await figma.getNodeByIdAsync(FRAME_ID);
const mainTable = frame.findOne(n => n.name === '#main-api-table');
const rowTemplate = mainTable.findOne(n => n.name === '#api-row-template');

const textNodes = mainTable.findAll(n => n.type === 'TEXT');
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

for (const prop of PROPERTIES) {
  const row = rowTemplate.clone();
  mainTable.appendChild(row);
  row.name = 'Row ' + prop.property;

  const nameFrame = row.findOne(n => n.name === '#property-name');
  if (nameFrame) {
    const t = nameFrame.findOne(n => n.type === 'TEXT');
    if (t) t.characters = prop.property;
  }

  const valuesFrame = row.findOne(n => n.name === '#property-values');
  if (valuesFrame) {
    const t = valuesFrame.findOne(n => n.type === 'TEXT');
    if (t) t.characters = prop.values;
  }

  const requiredFrame = row.findOne(n => n.name === '#property-required');
  if (requiredFrame) {
    const t = requiredFrame.findOne(n => n.type === 'TEXT');
    if (t) t.characters = prop.required ? 'Yes' : 'No';
  }

  const defaultFrame = row.findOne(n => n.name === '#property-default');
  if (defaultFrame) {
    const t = defaultFrame.findOne(n => n.type === 'TEXT');
    if (t) t.characters = prop.default;
  }

  const notesFrame = row.findOne(n => n.name === '#property-notes');
  if (notesFrame) {
    const t = notesFrame.findOne(n => n.type === 'TEXT');
    if (t) t.characters = prop.notes;
  }

  // Handle hierarchy indicator for sub-properties
  const hierarchyIndicator = row.findOne(n => n.name === '#hierarchy-indicator');
  if (hierarchyIndicator) {
    hierarchyIndicator.visible = !!prop.isSubProperty;
  }
}

rowTemplate.remove();
return { success: true };
```

### Step 11: Fill Sub-component Tables

If there are sub-component tables, run **one `figma_execute` call per sub-component** to avoid timeouts. If there are NO sub-component tables, run a single call to hide the template.

#### 11a: When sub-components exist

For each sub-component table, run:

```javascript
const FRAME_ID = '__FRAME_ID__';
const SUB_NAME = '__SUBCOMPONENT_NAME__';
const SUB_DESCRIPTION = '__SUBCOMPONENT_DESCRIPTION__';
const HAS_DESCRIPTION = __HAS_DESCRIPTION__;
const SUB_PROPERTIES = __SUBCOMPONENT_PROPERTIES_JSON__;

const frame = await figma.getNodeByIdAsync(FRAME_ID);
const subTemplate = frame.findOne(n => n.name === '#subcomponent-chapter-template');

const section = subTemplate.clone();
subTemplate.parent.appendChild(section);
section.name = SUB_NAME;
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

// Set sub-component title
const titleFrame = section.findOne(n => n.name === '#subcomponent-title');
if (titleFrame) {
  const t = titleFrame.findOne(n => n.type === 'TEXT');
  if (t) t.characters = SUB_NAME;
}

// Set description (optional)
const descFrame = section.findOne(n => n.name === '#subcomponent-description');
if (descFrame) {
  if (!HAS_DESCRIPTION) {
    descFrame.visible = false;
  } else {
    const t = descFrame.findOne(n => n.type === 'TEXT');
    if (t) t.characters = SUB_DESCRIPTION;
  }
}

// Fill sub-component table
const subTable = section.findOne(n => n.name === '#subcomponent-table');
const rowTemplate = subTable.findOne(n => n.name === '#subcomponent-row-template');

for (const prop of SUB_PROPERTIES) {
  const row = rowTemplate.clone();
  subTable.appendChild(row);
  row.name = 'Row ' + prop.property;

  const nameFrame = row.findOne(n => n.name === '#subprop-name');
  if (nameFrame) {
    const t = nameFrame.findOne(n => n.type === 'TEXT');
    if (t) t.characters = prop.property;
  }

  const valuesFrame = row.findOne(n => n.name === '#subprop-values');
  if (valuesFrame) {
    const t = valuesFrame.findOne(n => n.type === 'TEXT');
    if (t) t.characters = prop.values;
  }

  const requiredFrame = row.findOne(n => n.name === '#subprop-required');
  if (requiredFrame) {
    const t = requiredFrame.findOne(n => n.type === 'TEXT');
    if (t) t.characters = prop.required ? 'Yes' : 'No';
  }

  const defaultFrame = row.findOne(n => n.name === '#subprop-default');
  if (defaultFrame) {
    const t = defaultFrame.findOne(n => n.type === 'TEXT');
    if (t) t.characters = prop.default;
  }

  const notesFrame = row.findOne(n => n.name === '#subprop-notes');
  if (notesFrame) {
    const t = notesFrame.findOne(n => n.type === 'TEXT');
    if (t) t.characters = prop.notes;
  }

  const hierarchyIndicator = row.findOne(n => n.name === '#subprop-hierarchy-indicator');
  if (hierarchyIndicator) {
    hierarchyIndicator.visible = !!prop.isSubProperty;
  }
}

rowTemplate.remove();
return { success: true, subComponent: SUB_NAME };
```

**IMPORTANT:** After all sub-component tables are rendered, you MUST hide the original template by running this script. Skipping this leaves a ghost "{Sub-component-title}" row visible in the output:

```javascript
const frame = await figma.getNodeByIdAsync('__FRAME_ID__');
const subTemplate = frame.findOne(n => n.name === '#subcomponent-chapter-template');
if (subTemplate) subTemplate.visible = false;
return { success: true };
```

#### 11b: When no sub-components exist

Hide the template:

```javascript
const frame = await figma.getNodeByIdAsync('__FRAME_ID__');
const subTemplate = frame.findOne(n => n.name === '#subcomponent-chapter-template');
if (subTemplate) subTemplate.visible = false;
return { success: true };
```

### Step 12: Fill Configuration Examples

Run **one `figma_execute` call per configuration example** to avoid timeouts.

For each example, run (replace `__FRAME_ID__`, `__EXAMPLE_TITLE__`, `__COMPONENT_SET_NODE_ID__` with `render-meta.component.compSetNodeId`, and the JSON placeholders with the values projected in Step 5). All inputs below come from the Step 5 projection of the example's `code` string through `render-meta` — **not** from a live extraction:

- `__VARIANT_PROPERTIES_JSON__` is an object mapping **raw component-property keys** (the `render-meta.propertyDefs` keys, e.g. `"clear button#10225:1"`) to values — the projection of the example's human prop names from Step 5. This instantiates and configures the live preview. Include the variant axes and boolean toggles the example sets.
- `__CHILD_OVERRIDES_JSON__` is an array of per-child property override objects for composable slot children (index 0 = first child). Use `[]` when no child overrides are needed. Each entry maps raw `render-meta.propertyDefs` keys to values, same format as `VARIANT_PROPS`.
- `__TEXT_OVERRIDES_JSON__` is an object mapping **live TEXT layer names** (from the Step 5 whitelisted TEXT-node listing, or `render-meta.propertyDefs[].associatedLayerName`) to new text content (e.g., `{ "Label": "Submit" }`). Applied to TEXT nodes inside the main instance. Use `{}` when no text overrides are needed. Never guess layer names.
- `__SLOT_INSERTIONS_JSON__` is an array of slot insertion objects. Each has `slotName` (`render-meta.slotContents[].slotName`), `componentNodeId` (`render-meta.slotContents[].preferredComponents[].componentId`), and optional `nestedOverrides` (component properties for `setProperties()`) and `textOverrides` (TEXT node content overrides on the inserted child). All overrides are applied **before** `appendChild` into the slot — after adoption, the child's internal nodes get compound IDs and become inaccessible. Use `[]` when no slot insertions are needed.
- `__EXAMPLE_PROPERTIES_JSON__` is the example table rows `{ property, value, notes }` parsed from the example's `code` string in Step 5 (human-readable names, verbatim).

```javascript
const FRAME_ID = '__FRAME_ID__';
const EXAMPLE_TITLE = '__EXAMPLE_TITLE__';
const COMPONENT_SET_ID = '__COMPONENT_SET_NODE_ID__';
const VARIANT_PROPS = __VARIANT_PROPERTIES_JSON__;
const CHILD_OVERRIDES = __CHILD_OVERRIDES_JSON__;
const TEXT_OVERRIDES = __TEXT_OVERRIDES_JSON__;
const SLOT_INSERTIONS = __SLOT_INSERTIONS_JSON__;
const EXAMPLE_PROPERTIES = __EXAMPLE_PROPERTIES_JSON__;

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

const frame = await figma.getNodeByIdAsync(FRAME_ID);
const exampleTemplate = frame.findOne(n => n.name === '#config-example-chapter-template');

const section = exampleTemplate.clone();
exampleTemplate.parent.appendChild(section);
section.name = EXAMPLE_TITLE;
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

// Set example title
const titleFrame = section.findOne(n => n.name === '#example-title');
if (titleFrame) {
  const t = titleFrame.findOne(n => n.type === 'TEXT');
  if (t) t.characters = EXAMPLE_TITLE;
}

// Place live component instance in the Preview frame
const preview = section.findOne(n => n.name === 'Preview');
if (preview) {
  // Remove the asset description text placeholder
  const assetDesc = preview.findOne(n => n.name === '#example-asset-description');
  if (assetDesc) assetDesc.remove();

  // Instantiate component and configure variant/boolean properties
  const compNode = await figma.getNodeByIdAsync(COMPONENT_SET_ID);
  const defaultVariant = compNode.type === 'COMPONENT_SET'
    ? (compNode.defaultVariant || compNode.children[0])
    : compNode;
  const instance = defaultVariant.createInstance();
  await loadAllFonts(instance);
  if (Object.keys(VARIANT_PROPS).length > 0) {
    instance.setProperties(VARIANT_PROPS);
    await loadAllFonts(instance);
  }

  // Apply per-child overrides for composable slot children
  if (CHILD_OVERRIDES && CHILD_OVERRIDES.length > 0) {
    let slot = instance.findOne(n => n.type === 'SLOT');
    if (!slot) slot = instance.children[0];
    if (slot && slot.children) {
      for (let i = 0; i < Math.min(CHILD_OVERRIDES.length, slot.children.length); i++) {
        const child = slot.children[i];
        if (child.type === 'INSTANCE' && Object.keys(CHILD_OVERRIDES[i]).length > 0) {
          try { child.setProperties(CHILD_OVERRIDES[i]); } catch (e) {}
        }
      }
    }
    await loadAllFonts(instance);
  }

  // Apply text overrides to TEXT nodes inside the instance
  if (TEXT_OVERRIDES && Object.keys(TEXT_OVERRIDES).length > 0) {
    await loadAllFonts(instance);
    for (const [layerName, newText] of Object.entries(TEXT_OVERRIDES)) {
      const textNode = instance.findOne(n => n.type === 'TEXT' && n.name === layerName);
      if (textNode) {
        textNode.characters = newText;
      }
    }
  }

  // Insert content into named SLOT nodes
  if (SLOT_INSERTIONS && SLOT_INSERTIONS.length > 0) {
    for (const insertion of SLOT_INSERTIONS) {
      const slotNode = instance.findOne(
        n => n.type === 'SLOT' && n.name === insertion.slotName
      );
      if (slotNode) {
        const comp = await figma.getNodeByIdAsync(insertion.componentNodeId);
        if (comp && comp.type === 'COMPONENT') {
          const child = comp.createInstance();
          await loadAllFonts(child);
          // Apply all overrides BEFORE appendChild — after slot adoption, child nodes get compound IDs and become inaccessible
          if (insertion.nestedOverrides && Object.keys(insertion.nestedOverrides).length > 0) {
            try {
              child.setProperties(insertion.nestedOverrides);
              await loadAllFonts(child);
            } catch (e) {}
          }
          if (insertion.textOverrides && Object.keys(insertion.textOverrides).length > 0) {
            for (const [layerName, newText] of Object.entries(insertion.textOverrides)) {
              const tn = child.findOne(n => n.type === 'TEXT' && n.name === layerName);
              if (tn) {
                tn.characters = newText;
              }
            }
          }
          slotNode.appendChild(child);
          await loadAllFonts(instance);
        }
      }
    }
    await loadAllFonts(instance);
  }

  preview.appendChild(instance);
  instance.layoutAlign = 'INHERIT';
}

// Fill example table
const exampleTable = section.findOne(n => n.name === '#example-table');
const rowTemplate = exampleTable.findOne(n => n.name === '#example-row-template');

for (const prop of EXAMPLE_PROPERTIES) {
  const row = rowTemplate.clone();
  exampleTable.appendChild(row);
  row.name = 'Row ' + prop.property;

  const nameFrame = row.findOne(n => n.name === '#example-prop-name');
  if (nameFrame) {
    const t = nameFrame.findOne(n => n.type === 'TEXT');
    if (t) t.characters = prop.property;
  }

  const valueFrame = row.findOne(n => n.name === '#example-prop-value');
  if (valueFrame) {
    const t = valueFrame.findOne(n => n.type === 'TEXT');
    if (t) t.characters = prop.value;
  }

  const notesFrame = row.findOne(n => n.name === '#example-prop-notes');
  if (notesFrame) {
    const t = notesFrame.findOne(n => n.type === 'TEXT');
    if (t) t.characters = prop.notes;
  }
}

rowTemplate.remove();
return { success: true, example: EXAMPLE_TITLE };
```

**IMPORTANT:** After all examples are rendered, you MUST hide the original template by running this script. Skipping this leaves a ghost "{example-title}" row visible in the output:

```javascript
const frame = await figma.getNodeByIdAsync('__FRAME_ID__');
const exampleTemplate = frame.findOne(n => n.name === '#config-example-chapter-template');
if (exampleTemplate) exampleTemplate.visible = false;
return { success: true };
```

### Step 13: Visual Validation

1. `figma_take_screenshot` with the `frameId` — Capture the completed spec
2. Verify:
   - Main property table has all properties with correct values, required status, and defaults
   - Hierarchy indicators appear on sub-properties
   - Sub-component tables are present (or hidden if none)
   - Configuration examples show correct property/value pairs
   - Each configuration example Preview frame contains a live component instance (no text description)
   - General notes are visible or hidden as expected
3. If issues are found, fix via `figma_execute` and re-capture (up to 3 iterations)

### Step 14: Completion Link

Print a clickable Figma URL to the completed spec in chat. Construct the URL from the `fileKey` (`render-meta.fileKey`) and the `frameId` (returned by Step 8), replacing `:` with `-` in the node ID. Append the `sourceHash` from `render-meta` as a provenance footer so readers can detect drift between this render and the `_base.json` that produced the `.md`:

```
API spec complete: https://www.figma.com/design/{fileKey}/?node-id={frameId}
Source: {mdPath} (render-meta sourceHash {sourceHash})
```

## Notes

- **This skill consumes the component `.md`** (the source of truth produced by the `create-component-md` skill) and renders its API section into Figma. It does NOT extract from Figma and does NOT re-identify properties — see the Step 0 FORBIDDEN directive. The `compSetNodeId`, `propertyDefs` raw keys, `booleanDefs`, `slotContents`, `fileKey`, `nodeId`, and `sourceHash` all come from the `.md`'s `render-meta` block.
- Conditional sub-components: If the `.md` has no sub-component tables (and no referenced-components block), the `#subcomponent-chapter-template` is hidden. If present, each sub-component / referenced component gets its own cloned section with its own property table.
- Hierarchy indicators: Both the main table (`#hierarchy-indicator`) and sub-component tables (`#subprop-hierarchy-indicator`) support `isSubProperty` for indented child rows. `isSubProperty` is re-derived in Step 5 from the `"Only meaningful when {parentProperty} = {triggerValue}. …"` Notes prose authored in the `.md` — never by re-reasoning about ownership.
- `required` is re-derived in Step 5 from the `.md`'s `Default` cell (empty/absent default ⇒ required), not from a live read.
- The target node referenced by `render-meta.component.compSetNodeId` can be either a `COMPONENT_SET` (multi-variant) or a standalone `COMPONENT` (single variant). Instance creation in Step 12 handles both via `compNode.type === 'COMPONENT_SET' ? (defaultVariant || children[0]) : compNode`.
- **Configuration-example previews** are configured by projecting each example's fenced `code` string through `render-meta.propertyDefs` raw keys (Step 5): the human prop names in the example map to the raw component-property keys (including `#nodeId` suffixes) that `setProperties()` expects. Slot insertions resolve through `render-meta.slotContents[].preferredComponents[].componentId`.
- **The single whitelisted live read** is the bounded `<= 30-line` TEXT-node listing on `render-meta.component.compSetNodeId` (Step 5), used only to learn live TEXT layer names for `TEXT_OVERRIDES`. It MUST NOT walk the tree or read property definitions — that is property re-extraction and is FORBIDDEN.
- The instruction file (`../../../references/api/agent-api-instruction.md`) is consulted **only** for the `isSubProperty` Notes-prose convention and the configuration-example projection (Step 1) — not to re-run property identification. Property identification already happened in `extract-api` / `create-component-md` and is baked into the `.md`.
