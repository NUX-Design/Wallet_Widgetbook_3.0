---
name: create-property
description: Generate a visual property annotation in Figma showing each configurable property axis with component instance previews. Use when the user mentions "property", "properties", "property annotation", "create property", or wants to document a component's configurable properties visually.
---

# Create Property Annotation

Generate a visual property annotation directly in Figma — one exhibit per variant axis and boolean toggle, each showing the available options as component instances with a summary table.

**Execution contract (read first).**
- This file is instructions to RUN, not a document to edit. Invoking the skill = render the property annotation into Figma from the input `.md`.
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
| Execute Plugin JS | `figma_execute` with `code` | `use_figma` with `fileKey`, `code`, `description`. **Core logic is identical** — see font loading note below for the one API difference (`getRangeAllFontNames` → `tn.fontName`). |
| Search components | `figma_search_components` | `search_design_system` with `query` + `fileKey` + `includeComponents: true` |
| Get file/component data | `figma_get_file_data` / `figma_get_component` | `get_metadata` or `get_design_context` with `fileKey` + `nodeId` |
| Get variables (file-wide) | `figma_get_variables` | `use_figma` script: `return await figma.variables.getLocalVariableCollectionsAsync();` |
| Get token values | `figma_get_token_values` | `use_figma` script reading variable values per mode/collection |
| Get styles | `figma_get_styles` | `search_design_system` with `includeStyles: true`, or `use_figma`: `return figma.getLocalPaintStyles();` |
| Get selection | `figma_get_selection` | `use_figma` script: `return figma.currentPage.selection.map(n => ({id: n.id, name: n.name, type: n.type}));` |

**`figma-mcp` requires `fileKey` on every call.** Extract it once from the user's Figma URL at the start of the workflow. For branch URLs (`figma.com/design/:fileKey/branch/:branchKey/:fileName`), use `:branchKey` as the fileKey.

**`figma-mcp` page context:** `use_figma` resets `figma.currentPage` to the first page on every call. When a script accesses a node from a previous step via `getNodeByIdAsync(ID)`, the page content may not be loaded — `findAll`, `findOne`, and `characters` will fail with `TypeError` until the page is activated. Insert this page-loading block at the **start** of every script that references a previously-created node:

```javascript
const pages = figma.root.children;
const targetPage = pages.find(p => p.name === '__PAGE_NAME__');
if (targetPage) await figma.setCurrentPageAsync(targetPage);
```

Replace `__PAGE_NAME__` with the actual page name (determined during Step 7 when the template is placed). This loads the page content so child nodes are accessible.

**`figma-mcp` font loading:** `getRangeAllFontNames` is not available in the `use_figma` sandbox and will throw `TypeError`. Replace it with `tn.fontName` (returns `{ family, style }` for single-font text, or `figma.mixed` for mixed-font text). `findAll` and `findOne` work normally after `setCurrentPageAsync` — they do not need replacement.

Replace the font-collection loop in every script from:
```javascript
const fonts = tn.getRangeAllFontNames(0, tn.characters.length);
for (const f of fonts) {
  const key = f.family + '|' + f.style;
  if (!fontSet.has(key)) { fontSet.add(key); fontsToLoad.push(f); }
}
```
to:
```javascript
try {
  const fn = tn.fontName;
  if (fn && fn !== figma.mixed && fn.family) {
    const key = fn.family + '|' + fn.style;
    if (!fontSet.has(key)) { fontSet.add(key); fontsToLoad.push(fn); }
  }
} catch {}
```

And add `.catch(() => {})` to the batch load: `await Promise.all(fontsToLoad.map(f => figma.loadFontAsync(f).catch(() => {})));`

## Inputs Expected

- **Component `.md` spec** (**required**, user-provided path) — the source-of-truth component spec produced by the `create-component-md` skill. **The user tells you where this `.md` lives** — use the exact path they provide; the `.md` may live anywhere. This skill rebuilds its property model from the `.md`'s `render-meta` block; it does NOT re-extract the property surface from Figma. `fileKey`, `nodeId`, and `compSetNodeId` come from `render-meta`, never from a Figma link.
- **Figma link** (optional) — placement hint only (which page/frame to drop the rendered annotation on, including a cross-file destination) and the target for the two whitelisted minimal live reads in Steps 4a/4b. Never the source of the property contract.

**Asymmetry from the other consumers.** Unlike the Structure / Color / Voice consumers, the `.md` has **no dedicated "Property" body section** to copy. So create-property takes **identity only** from `render-meta` (which lets it skip extraction) and still authors its own property model, normalization, and exhibit plans with light in-memory reasoning. It does not parse a Property section body — there isn't one.

There is no screenshot-only path and no component-link extraction path. Without the component `.md` there is nothing to build from — see Step 0's fail-fast contract.

## Workflow

Copy this checklist and update as you progress:

```
Task Progress:
- [ ] Step 0: Require the component `.md`; parse render-meta. FAIL FAST if missing.
- [ ] Step 1: Read instruction file (only as needed for normalization / exhibit-planning reasoning — NOT for re-extraction)
- [ ] Step 2: Verify MCP connection
- [ ] Step 3: Read template key from uspecs.config.json
- [ ] Step 4: Rebuild the property model from render-meta (variant axes, booleans, slots, instance-swaps, constitutive sub-components) — NO extraction
- [ ] Step 4a: WHITELISTED LIVE READ #2 — bounded variant-gated-boolean scan for requiredVariantOverrides
- [ ] Step 4b: WHITELISTED LIVE READ #1 — variable-collection lookup for the 6c variable-mode exhibit
- [ ] Step 4d: Normalize child properties IN MEMORY (coupled / unified slot / sibling boolean grouping) — no Figma reads
- [ ] Step 4e: Exhibit planning + context axis + briefDescription IN MEMORY — no Figma reads
- [ ] Step 5: Re-read instruction file (Pre-Render Validation Checklist, Common Mistakes, Do NOT) and audit
- [ ] Step 6: Navigate to destination (if different file)
- [ ] Step 7: Import and detach the Property template
- [ ] Step 8: Fill header fields
- [ ] Step 9: Build property exhibits with component instances
- [ ] Step 10: Visual validation
- [ ] Step 11: Completion link (reports sourceHash from render-meta)
```

### Step 0: Require the component `.md` and parse `render-meta` (fail fast)

**This skill is a consumer of the `.md` source of truth.** It does not re-extract the property surface from Figma — `extract-api`/`create-component-md` already captured the component's variant axes, booleans, slots, instance-swaps, and constitutive sub-components into the `.md`'s `render-meta` block. Your job is to rebuild the property model from `render-meta` and author the exhibits.

**Asymmetry from the other consumers.** The `.md` has NO dedicated "Property" body section to parse. So this skill gets **identity only** from `render-meta` (to skip extraction) and still authors its own property model + exhibit plans with light in-memory reasoning. There is no Property section body — `render-meta` is the only thing you read from the `.md`.

1. **Resolve the `.md` path.** Use the exact path the user gave, else an attached or open `.md` in context. The `.md` may live anywhere; do NOT invent or guess a path. If neither resolves to an existing file, abort per item 2. Never pause to ask the user which file to use.
2. **Require the file.** If no file exists at the resolved `.md` path, **abort immediately** with this exact single-line diagnostic and stop — do NOT fall back to extraction:

   > This skill requires the component's Markdown `.md` spec (produced by create-component-md). Provide the path to it. (create-component-md needs a _base.json from the uSpec Extract plugin.)

3. **Parse the `render-meta` block** (the fenced JSON between `<!-- render-meta:start v=1 -->` and `<!-- render-meta:end -->`; schema in `references/component-md/agent-component-md-instruction.md` § **RENDER_META_JSON**). Capture:
   - `component` = `{ componentName, compSetNodeId, isComponentSet }`.
   - `variantAxes` — `{ <axisName>: [<option>, …] }`.
   - `variantAxesDefaults` — `{ <axisName>: <default> }`.
   - `booleanDefs[]` — `{ key, default, associatedLayerName, associatedLayerId }`. Each `key` is the raw component-property key `setProperties` expects.
   - `propertyDefs` — keyed by raw key; each `{ type, default?, values?, preferredComponentKey?, associatedLayerName?, associatedLayerId? }`. `type` ∈ `VARIANT | BOOLEAN | INSTANCE_SWAP | SLOT | TEXT | NUMBER`.
   - `slotContents[]` — `{ slotName, slotNodeType, preferredComponents: [{ componentKey, componentName, componentId, componentSetId, isComponentSet, variantAxes, booleanDefs }] }`.
   - `subComponents[]` — `{ name, mainComponentName, subCompSetId, subCompVariantAxes, subCompVariantAxesDefaults, booleanOverrides }`.
   - `fileKey`, `nodeId` — for template placement and the Step 11 completion link.
   - `sourceHash` — record it; the Step 11 completion footer reports it so downstream readers can detect drift between this render and the `_base.json` that produced the `.md`.

4. **Rebuild the property model** in memory — see Step 4. No Figma reads.

**FORBIDDEN — do NOT re-extract.** When the component `.md` is present (it always is past Step 0), you MUST NOT run the legacy extraction/tree-walk. Specifically:
- The old **Step 4 extraction script** — the `node.componentPropertyDefinitions` walk that rebuilt `variantAxes`, `booleanProps`, `instanceSwapProps`, and `slotProps` from scratch — is **deleted**. It does not exist in this skill anymore. The property surface comes from `render-meta` (Step 4).
- The old **Step 4a full variant-gating script** (the one that re-enumerated every `boolDef` and every `variantAxis` from `propDefs` and walked every variant child for every boolean) is **deleted** and replaced by the **bounded** Step 4a scan below — which is whitelisted live read #2.
- The old **Step 4c child-discovery walk** (`walkForInstances` recursing the default variant for nested instances + the boolean-linkage resolver) is **deleted**. Constitutive child chapters now come from `render-meta.subComponents` (Step 4). Do NOT run any `figma_execute` / `use_figma` script that walks the component tree to rediscover child components or rebuild their property surface.
- The ONLY Figma reads this skill makes beyond the render scripts are the **two whitelisted minimal live reads**, both bounded:
  1. **Variable-collection lookup (Step 4b)** — resolve `COLLECTION_ID` / `MODE_ID` / `MODES_JSON` for the 6c variable-mode exhibit by listing **variable collections only**. No component tree walk; no property re-enumeration.
  2. **Variant-gated-boolean scan (Step 4a)** — a small, bounded scan of *only the booleans already in the model* (from `render-meta.booleanDefs`) to learn which ones are only meaningful under specific variant values (`requiredVariantOverrides`). It does NOT rebuild `propertyDefs` / `variantAxes` / `slotProps` and does NOT discover new properties.
  Everything else (variant axes, boolean defs, slots, instance-swaps, constitutive sub-components) is read from `render-meta` and consumed verbatim. Normalization (Step 4d) and exhibit planning (Step 4e) run entirely in memory.

### Step 1: Read Instructions (only as needed)

Read [agent-property-instruction.md](../../../references/property/agent-property-instruction.md) when you need it for the **Data Validation**, **Exhibit Planning**, **Pre-Render Validation Checklist**, **Common Mistakes**, and **Do NOT** reasoning that Steps 4d/4e/5 perform over the `render-meta`-derived model. Do NOT use it as a prompt to re-extract — the property surface is supplied by `render-meta` (Step 4).

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
- The `propertyOverview` value from the `templateKeys` object → save as `PROPERTY_TEMPLATE_KEY`
- The `fontFamily` value → save as `FONT_FAMILY` (default to `Inter` if not set)

If the template key is empty, tell the user:
> The property template key is not configured. Run the `firstrun` skill with your Figma template library link first.

### Step 4: Rebuild the property model from `render-meta` (no extraction)

Everything the normalization, exhibit planner, and render scripts need about the property surface comes from the `render-meta` block parsed in Step 0 — there is **no extraction call** here (see the Step 0 FORBIDDEN directive). Rebuild this in-memory model from `render-meta` (the field names below are exactly what the render scripts in Step 9 expect):

- **`componentName` / `compSetNodeId` / `isComponentSet`** — from `render-meta.component` (`componentName`, `compSetNodeId`, `isComponentSet`). `compSetNodeId` is the `COMP_SET_NODE_ID` every render script consumes.
- **`variantAxes`** — reshape `render-meta.variantAxes` (`{ axisName: [options] }`) joined with `render-meta.variantAxesDefaults` (`{ axisName: default }`) into `[{ name, options, defaultValue }]`, one entry per axis.
- **`defaultProps`** — `render-meta.variantAxesDefaults` verbatim (`{ <axisName>: <default> }`). This is the `DEFAULT_PROPS` baseline for 6a/6a-ctx/6a-matrix.
- **`booleanProps`** — one entry per `render-meta.booleanDefs[]`: `{ name: key.split('#')[0], defaultValue: <default>, associatedLayer: associatedLayerName, rawKey: key, controlsSlot, slotPreferredNames }`. **Carry the raw `key` as `rawKey`** — `setProperties()` needs the raw-key form (cross-check `propertyDefs[key].type === "BOOLEAN"` when in doubt). Derive the slot fields in memory from `render-meta` (no Figma read): `controlsSlot = true` when `associatedLayerName` matches a `render-meta.slotContents[].slotName`; `slotPreferredNames = <that slot's `preferredComponents[].componentName`>` (else `false` / `[]`). These feed the 6b "Controls slot" description.
- **`instanceSwapProps`** — one entry per `render-meta.propertyDefs` entry whose `type === "INSTANCE_SWAP"`: `{ name: rawKey.split('#')[0], defaultValue: def.default, rawKey }`.
- **`slotProps`** — one entry per `render-meta.slotContents[]`: `{ name: slotName, preferredInstances: preferredComponents.map(p => ({ componentKey: p.componentKey, componentName: p.componentName, componentId: p.componentId })), rawKey: <matching propertyDefs SLOT key, when present> }`.
- **`childComponents`** (constitutive sub-component chapters) — from `render-meta.subComponents[]`, **constitutive sets only** (see the SCOPE LIMIT below).

**SCOPE LIMIT — constitutive sub-component-SETS only.** Only entries in `render-meta.subComponents` with a **non-null `subCompSetId`** get full child chapters (rendered in 6e/6f/6g). For each kept entry, map to the `childComponents` shape the render scripts expect:
- `name` = `subComponents[].name`; `mainComponentName` = `subComponents[].mainComponentName`.
- `mainComponentSetId` = `subCompSetId`; `mainComponentId` = `null`; `isComponentSet` = `true`.
- `variantAxes` = reshape `subCompVariantAxes` (joined with `subCompVariantAxesDefaults`) into `[{ name, options, defaultValue }]`.
- `booleanProps` = the child booleans `render-meta` carried for this sub-component (derive from `subComponents[].booleanOverrides` keys when present; otherwise `[]`).
- `visible` = `true` unless a controlling boolean is matched (below).
- `controllingBooleanName` / `controllingBooleanRawKey` = the parent boolean whose `associatedLayerName` (from `booleanProps`/`render-meta.booleanDefs`) matches this sub-component's `name` (light, in-memory name-match; fall back to normalized-name containment). `null` when no parent boolean controls it.

Collect the matched controlling-boolean names into a `controllingBooleanNames` array (Step 4d / 6b consume it).

**DEGRADE GRACEFULLY — do NOT re-extract.** Non-constitutive nested instances and child boolean/instance-swap surfaces that are NOT present in `render-meta.subComponents` (because the producer did not capture them as constitutive sets, or carried only `booleanOverrides`) may not get full chapters. Render what `render-meta` provides; when a child surface is incomplete, add a short note in the affected chapter (or the spec header) that the deeper surface lives in the child's own `./{slug}.md` — do **not** run a live tree walk to rediscover it.

Save the rebuilt model — you will use it in subsequent steps.

### Step 4a: Variant-gated-boolean scan (WHITELISTED LIVE READ #2 — bounded)

This is one of the **only two** Figma reads this skill makes beyond rendering. `render-meta` tells you which booleans exist and the layer each controls (`booleanDefs[].associatedLayerName` / `associatedLayerId`), but it does NOT record which *variant* a boolean's layer only appears under. A small, bounded scan resolves that so 6b can pick the right base variant. Example: a "Dismiss button" boolean may only control a layer that exists in the `Behavior=Interactive` variant, not in `Behavior=Static`; when the default variant lacks the target layer, toggling the boolean produces identical-looking previews.

**Bound.** Scan ONLY the booleans already in the model (from `render-meta.booleanDefs`), checking each one's layer against the default variant and — only when absent — across the variant children to find the minimal override. This is NOT a property re-extraction: it does not rebuild `propertyDefs`, `variantAxes`, `slotProps`, or `booleanProps`, and it does not discover new properties.

Run this bounded scan via `figma_execute`. Replace `TARGET_NODE_ID` with `render-meta.component.compSetNodeId` and `__BOOLEAN_DEFS_JSON__` with the `render-meta.booleanDefs[]` array (`{ key, default, associatedLayerName, associatedLayerId }`):

```javascript
const TARGET_NODE_ID = '__NODE_ID__';
const BOOLEAN_DEFS = __BOOLEAN_DEFS_JSON__;

const node = await figma.getNodeByIdAsync(TARGET_NODE_ID);
if (!node || node.type !== 'COMPONENT_SET') {
  return { skip: true, reason: 'Not a component set — no variant gating possible', interpretedBooleans: [] };
}

const defaultVariant = node.defaultVariant || node.children[0];
const defaultVProps = defaultVariant.variantProperties || {};

const interpretedBooleans = [];

for (const bd of BOOLEAN_DEFS) {
  const rawKey = bd.key || '';
  const nodeIdSuffix = rawKey.split('#')[1] || null;
  const result = { name: rawKey.split('#')[0], requiredVariantOverrides: null, layerName: bd.associatedLayerName || null };
  if (!nodeIdSuffix) { interpretedBooleans.push(result); continue; }

  let layerInDefault = null;
  try {
    const lid = defaultVariant.id.split(';')[0] + ';' + nodeIdSuffix;
    const ln = await figma.getNodeByIdAsync(lid);
    layerInDefault = ln ? ln.name : null;
  } catch {}

  if (layerInDefault) { result.layerName = layerInDefault; interpretedBooleans.push(result); continue; }

  for (const child of node.children) {
    const vp = child.variantProperties || {};
    try {
      const lid = child.id.split(';')[0] + ';' + nodeIdSuffix;
      const ln = await figma.getNodeByIdAsync(lid);
      if (ln) {
        const diffAxis = {};
        for (const [k, v] of Object.entries(vp)) {
          if (defaultVProps[k] !== v) diffAxis[k] = v;
        }
        result.requiredVariantOverrides = diffAxis;
        result.layerName = ln.name;
        break;
      }
    } catch {}
  }
  interpretedBooleans.push(result);
}

return { interpretedBooleans };
```

**How the agent should use this data:**

The scan returns an `interpretedBooleans` array — one entry per boolean from `render-meta.booleanDefs`. Each entry contains:

- `name`: the boolean's clean name
- `requiredVariantOverrides`: an object like `{ "Behavior": "Interactive" }` if the boolean is variant-gated, or `null` if it works on the default variant
- `layerName`: the resolved layer name

For each boolean in `interpretedBooleans`:

- **`requiredVariantOverrides === null`** — No action needed. The boolean works on the default variant. Render normally in 6b.
- **`requiredVariantOverrides` is an object** — The boolean is **variant-gated**. Store the `requiredVariantOverrides` on the boolean entry from Step 4's `booleanProps`. In 6b, use these overrides when looking up the base variant for instance creation. The description should note the dependency (e.g., "Requires Behavior = Interactive").

No AI reasoning is needed — the bounded scan has already resolved which booleans are variant-gated and what overrides they require. This scan is whitelisted live read #2; do not extend it into a full property re-extraction.

### Step 4b: Variable-collection lookup (WHITELISTED LIVE READ #1 — bounded)

Some component properties (e.g., shape, density) are controlled via **Figma variable modes** at the container level, not per-instance. These never appear in `componentPropertyDefinitions` (and so are not part of the `render-meta` property surface). The 6c variable-mode exhibit needs `COLLECTION_ID` / `MODE_ID` / `MODES_JSON`, which only a variable-collection lookup can supply.

**Bound.** This is **variable collections only** — `figma_get_variables` (or the `getLocalVariableCollectionsAsync()` equivalent). No component tree walk, no property re-enumeration, no instance inspection.

Call `figma_get_variables` with `format: "summary"` to get a lightweight overview of all variable collections in the file. Look for collections whose names contain the component name or common mode-property keywords:

- `"[ComponentName] shape"` — e.g., "Button shape" with modes like Rectangular, Rounded
- `"[ComponentName] density"` or `"Density"` — e.g., "Button density" with modes like Default, Compact, Spacious

For each matching collection, extract:
- **Property name**: Derive from the collection name (e.g., "Button shape" → `shape`, "Density" → `density`)
- **Options**: The mode names in the collection (e.g., `["Rectangular", "Rounded"]`)
- **Default value**: The mode named "Default" or "default" if one exists; otherwise the first mode
- **Collection name**: The full collection name for the annotation note
- **Collection ID**: The `id` field of the collection (e.g., `"VariableCollectionId:6028:44006"`) — needed to apply modes via `setExplicitVariableModeForCollection`
- **Modes**: An array of `{ modeId, name }` objects for each mode — needed to apply the correct mode per preview instance

Store these as a `variableModeProps` array alongside `variantAxes` and `booleanProps`:

```
variableModeProps: [
  {
    name: "shape",
    options: ["Rectangular", "Rounded"],
    defaultValue: "Rectangular",
    collectionName: "Button shape",
    collectionId: "VariableCollectionId:1234:5678",
    modes: [{ modeId: "1234:0", name: "Rectangular" }, { modeId: "1234:1", name: "Rounded" }]
  },
  {
    name: "density",
    options: ["Default", "Compact", "Spacious"],
    defaultValue: "Default",
    collectionName: "Button density",
    collectionId: "VariableCollectionId:6028:44006",
    modes: [{ modeId: "6028:0", name: "Default" }, { modeId: "6028:1", name: "Compact" }, { modeId: "6028:2", name: "Spacious" }]
  }
]
```

If no matching collections are found, set `variableModeProps` to an empty array and proceed.

### Step 4c: Child component chapters come from `render-meta` (discovery walk DELETED)

**The legacy Step 4c child-discovery walk is deleted.** The old `walkForInstances` recursion (which walked the default variant for nested INSTANCE children and rebuilt each child's `variantAxes` / `booleanProps` / `instanceSwapProps` from `componentPropertyDefinitions`) plus its boolean-linkage resolver no longer exist in this skill. Do NOT reintroduce a live tree walk to rediscover child components.

The `childComponents` array (with `controllingBooleanName` / `controllingBooleanRawKey` and the matched `controllingBooleanNames`) is rebuilt in **Step 4** from `render-meta.subComponents` (constitutive sub-component-SETS only — those with a non-null `subCompSetId`). Re-read the **SCOPE LIMIT** in Step 4:
- Only constitutive sub-component-SETS get full child chapters (6e/6f/6g).
- Child surfaces beyond what `render-meta.subComponents` carried (non-constitutive nested instances, child booleans/instance-swaps the producer did not capture) **degrade gracefully** — render what's available and note the gap, pointing to the child's own `./{slug}.md`. Never re-extract.

If the rebuilt `childComponents` array is empty, proceed — there are no constitutive sub-component chapters to exhibit.

### Step 4d: Normalize Child Properties (IN MEMORY — no Figma reads)

This is light **in-memory** reasoning over the `render-meta`-derived model from Step 4 — **no `figma_execute`, no Figma reads.** Apply all four sub-analyses (coupled axes, container-gated booleans, unified slots, sibling booleans) to produce the normalization plan. The algorithm below is the reference logic; run it in memory over the model — it touches no Figma node.

Operate over the `variantAxes` array from Step 4 as `PARENT_AXES`, the rebuilt `childComponents` array from Step 4 as `CHILDREN`, and the matched `controllingBooleanNames` array from Step 4 as `CONTROLLING_BOOL_NAMES`:

```javascript
const PARENT_AXES = __PARENT_VARIANT_AXES_JSON__;
const CHILDREN = __CHILD_COMPONENTS_JSON__;
const CONTROLLING_BOOL_NAMES = __CONTROLLING_BOOLEAN_NAMES_JSON__;

// --- 4d-i: Detect coupled axes ---
for (const child of CHILDREN) {
  for (const axis of child.variantAxes) {
    axis.coupled = false;
    for (const pAxis of PARENT_AXES) {
      if (axis.name.toLowerCase() === pAxis.name.toLowerCase()) {
        const childSet = new Set(axis.options.map(o => o.toLowerCase()));
        const parentSet = new Set(pAxis.options.map(o => o.toLowerCase()));
        const isSubset = [...childSet].every(o => parentSet.has(o));
        if (isSubset) { axis.coupled = true; break; }
      }
    }
  }
}

// --- 4d-ii/iii: Container-gated booleans + unified slot chapters ---
const unifiedSlotChapters = [];
const unifiedSubBooleanNames = [];

function shortName(boolName, containerName) {
  const prefixWords = containerName.toLowerCase().split(/\s+/);
  const boolWords = boolName.split(/\s+/);
  let stripped = boolWords.filter(w => !prefixWords.includes(w.toLowerCase()));
  if (stripped.length === 0) stripped = boolWords;
  return stripped.join(' ');
}

function stripVerbs(name) {
  return name.replace(/^(Show|Has|With|Enable|Toggle|Display)\s+/i, '');
}

for (const child of CHILDREN) {
  if (!child.controllingBooleanName || child.booleanProps.length === 0) continue;

  const subBools = child.booleanProps;
  const containerBoolName = child.controllingBooleanName;
  const containerBoolRawKey = child.controllingBooleanRawKey;

  const combos = [];
  combos.push({ label: 'None', containerOn: false, subValues: {} });

  if (subBools.length <= 5) {
    const count = subBools.length;
    const total = 1 << count;
    const comboEntries = [];
    for (let mask = 1; mask < total; mask++) {
      const subValues = {};
      const onNames = [];
      for (let i = 0; i < count; i++) {
        const on = Boolean(mask & (1 << i));
        subValues[subBools[i].name] = on;
        if (on) onNames.push(stripVerbs(shortName(subBools[i].name, containerBoolName)));
      }
      comboEntries.push({ label: onNames.join(' + '), containerOn: true, subValues, onCount: onNames.length });
    }
    comboEntries.sort((a, b) => a.onCount - b.onCount);
    const capped = comboEntries.length > 5 ? [...comboEntries.slice(0, 4), comboEntries[comboEntries.length - 1]] : comboEntries;
    for (const c of capped) { delete c.onCount; combos.push(c); }
  } else {
    for (const sb of subBools) {
      const subValues = {};
      for (const s of subBools) subValues[s.name] = (s.name === sb.name);
      combos.push({ label: stripVerbs(shortName(sb.name, containerBoolName)), containerOn: true, subValues });
    }
    const allOn = {};
    for (const s of subBools) allOn[s.name] = true;
    combos.push({ label: subBools.map(s => stripVerbs(shortName(s.name, containerBoolName))).join(' + '), containerOn: true, subValues: allOn });
  }

  if (subBools.length === 1) {
    combos[1].label = stripVerbs(shortName(subBools[0].name, containerBoolName));
  }

  const parentBoolDef = CONTROLLING_BOOL_NAMES.includes(containerBoolName);
  let defaultLabel = 'None';
  if (parentBoolDef) {
    const defaultSubValues = {};
    for (const sb of subBools) defaultSubValues[sb.name] = sb.defaultValue;
    const match = combos.find(c => c.containerOn && Object.entries(c.subValues).every(([k, v]) => defaultSubValues[k] === v));
    if (match) defaultLabel = match.label;
  }

  unifiedSlotChapters.push({
    chapterName: child.name + ' -- ' + containerBoolName,
    childName: child.name,
    containerBoolName,
    containerBoolRawKey,
    subBooleans: subBools,
    previewCombinations: combos,
    defaultLabel
  });

  for (const sb of subBools) unifiedSubBooleanNames.push(sb.name);
}

// --- 4d-iv: Sibling boolean collapsing ---
const siblingBoolChapters = [];
const siblingBoolNames = [];
const consumedByUnified = new Set(unifiedSubBooleanNames);

for (const child of CHILDREN) {
  if (child.controllingBooleanName && child.booleanProps.length > 0) continue;

  const remaining = child.booleanProps.filter(b => !consumedByUnified.has(b.name));
  if (remaining.length < 2) continue;

  const combos = [];
  const count = remaining.length;
  const total = 1 << count;
  const comboEntries = [];
  for (let mask = 0; mask < total; mask++) {
    const subValues = {};
    const onNames = [];
    for (let i = 0; i < count; i++) {
      const on = Boolean(mask & (1 << i));
      subValues[remaining[i].name] = on;
      if (on) onNames.push(stripVerbs(remaining[i].name));
    }
    const label = onNames.length === 0 ? 'None' : onNames.join(' + ');
    comboEntries.push({ label, subValues, onCount: onNames.length });
  }
  comboEntries.sort((a, b) => a.onCount - b.onCount);
  const capped = comboEntries.length > 6 ? [...comboEntries.slice(0, 4), comboEntries[comboEntries.length - 2], comboEntries[comboEntries.length - 1]] : comboEntries;
  for (const c of capped) { delete c.onCount; combos.push(c); }

  const defaultSubValues = {};
  for (const b of remaining) defaultSubValues[b.name] = b.defaultValue;
  const defaultMatch = combos.find(c => Object.entries(c.subValues).every(([k, v]) => defaultSubValues[k] === v));
  const defaultLabel = defaultMatch ? defaultMatch.label : 'None';

  siblingBoolChapters.push({
    chapterName: child.name,
    childName: child.name,
    booleans: remaining,
    previewCombinations: combos,
    defaultLabel
  });

  for (const b of remaining) siblingBoolNames.push(b.name);
}

return {
  childComponents: CHILDREN,
  unifiedSlotChapters,
  unifiedSubBooleanNames,
  siblingBoolChapters,
  siblingBoolNames
};
```

Save the normalization output. It produces:

- **`childComponents`** — Updated with `coupled: true` flags on child variant axes that mirror parent axes (4d-i). In Step 9 (6e-i), skip axes where `coupled === true`.
- **`unifiedSlotChapters`** — Array of chapter entries for container + sub-boolean combinations (4d-ii/iii). Each entry has `chapterName`, `childName`, `containerBoolName`, `containerBoolRawKey`, `subBooleans`, `previewCombinations`, and `defaultLabel`. Rendered in 6f.
- **`unifiedSubBooleanNames`** — Array of sub-boolean names consumed by unified slot chapters. These are skipped in 6e-ii.
- **`siblingBoolChapters`** — Array of chapter entries for sibling boolean combinations (4d-iv). Each entry has `chapterName`, `childName`, `booleans`, `previewCombinations`, and `defaultLabel`. Rendered in 6g.
- **`siblingBoolNames`** — Array of boolean names consumed by sibling boolean chapters. These are skipped in 6e-ii.

**Label generation rules** (handled by the script):
- Sub-boolean short names are derived by stripping the common prefix shared with the container name, plus common verbs ("Show", "Has", "With", "Enable", "Toggle", "Display")
- `"None"` = container off (unified) or all booleans off (sibling)
- Multi-on combos are joined with " + "
- Default label is computed from actual boolean default values

**Combination cap** (handled by the script): Power sets with more than 5-6 entries are capped to the most meaningful combinations (individually-on states, plus the all-on state).

**Graceful fallback**: If a child has only 1 remaining boolean after filtering (not consumed by unified slots), it is NOT added to `siblingBoolChapters` — it stays as a standard boolean chapter rendered in 6e-ii.

### Step 4e: Validation and Exhibit Planning (IN MEMORY — no Figma reads)

After the model is rebuilt and normalized (Steps 4–4d), perform validation and exhibit planning **in memory** over the `render-meta`-derived model — **no Figma reads**. Follow the **Data Validation** and **Exhibit Planning** sections in the instruction file ([agent-property-instruction.md](../../../references/property/agent-property-instruction.md)).

This step has two phases: **Phase A** (Data Validation) sanity-checks the `render-meta`-derived model, **Phase B** (Exhibit Planning) plans what to render and how. Do NOT rely on visual inspection (Step 10) as the primary safety net — this step is the designated reasoning layer. If a child surface looks incomplete because `render-meta.subComponents` did not carry it, treat it as the documented SCOPE LIMIT (degrade with a note) — do NOT re-extract to fill it.

**Context axis identification** — As the first action in Phase B, follow the "Identify context axes" section in the instruction file. Evaluate each variant axis against the heuristics and select 0–1 context axes (rarely 2). Store the result as `contextAxis`:

```
contextAxis: { name: "variant", options: ["primary", "subtle"], defaultValue: "primary" }
// or null if no axis qualifies
```

When `contextAxis` is non-null:
- The context axis's own exhibit plan entry is `presentation: "illustrate"` with `template: "6a"` (standard, non-contextual). This gives engineers a dedicated reference for the axis options.
- All other `"illustrate"` entries use contextual templates (6a-ctx instead of 6a, 6b-ctx instead of 6b).
- Composite chapters use the context rowGroup pattern (see 6a-ctx).
- The `briefDescription` should mention the context axis (e.g., "…available in primary and subtle variants").

Produce the `exhibitPlan` array and `contextAxis` as documented in the instruction file. Also compose the `briefDescription` string for the spec header.

After validation and planning, proceed to the pre-render audit.

### Step 5: Audit

Re-read the instruction file ([agent-property-instruction.md](../../../references/property/agent-property-instruction.md)), focusing on:
- **Pre-Render Validation Checklist** — walk through every item
- **Common Mistakes** section
- **Do NOT** section

Check the exhibit plan and corrected data against each rule. Fix any violations before rendering.

### Step 6: Navigate to Destination

If the user provided a separate destination file URL:
- `figma_navigate` — Switch to the destination file

If no destination was provided, stay in the current file.

### Step 7: Import and Detach Template

**If the user provided a cross-file destination URL** (navigated in Step 6), run via `figma_execute`:

```javascript
const PROPERTY_TEMPLATE_KEY = '__PROPERTY_TEMPLATE_KEY__';

const templateComponent = await figma.importComponentByKeyAsync(PROPERTY_TEMPLATE_KEY);
const instance = templateComponent.createInstance();
const { x, y } = figma.viewport.center;
instance.x = x - instance.width / 2;
instance.y = y - instance.height / 2;
const frame = instance.detachInstance();
frame.name = '__COMPONENT_NAME__ Properties';
figma.currentPage.selection = [frame];
figma.viewport.scrollAndZoomIntoView([frame]);
return { frameId: frame.id };
```

**If no destination was provided (default)**, run via `figma_execute` — this places the spec on the component's page, to its right:

```javascript
const PROPERTY_TEMPLATE_KEY = '__PROPERTY_TEMPLATE_KEY__';
const COMP_NODE_ID = '__COMPONENT_NODE_ID__';

const compNode = await figma.getNodeByIdAsync(COMP_NODE_ID);
let _p = compNode;
while (_p.parent && _p.parent.type !== 'DOCUMENT') _p = _p.parent;
if (_p.type === 'PAGE') await figma.setCurrentPageAsync(_p);

const templateComponent = await figma.importComponentByKeyAsync(PROPERTY_TEMPLATE_KEY);
const instance = templateComponent.createInstance();
const frame = instance.detachInstance();

const GAP = 200;
frame.x = compNode.x + compNode.width + GAP;
frame.y = compNode.y;

frame.name = '__COMPONENT_NAME__ Properties';
figma.currentPage.selection = [frame];
figma.viewport.scrollAndZoomIntoView([frame]);
return { frameId: frame.id, pageId: _p.id, pageName: _p.name };
```

Replace `__COMPONENT_NAME__` with `render-meta.component.componentName`. Replace `__COMPONENT_NODE_ID__` with `render-meta.component.compSetNodeId`.

Save the returned `frameId`.

### Step 8: Fill Header Fields

Run via `figma_execute` (replace `__FRAME_ID__`, `__COMPONENT_NAME__`, `__BRIEF_DESCRIPTION__`). Replace `__BRIEF_DESCRIPTION__` with the `briefDescription` composed during Step 4e:

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

const compNameFrame = frame.findOne(n => n.name === '#comp-name-anatomy');
if (compNameFrame) {
  const t = compNameFrame.findOne(n => n.type === 'TEXT');
  if (t) t.characters = '__COMPONENT_NAME__';
}

const descFrame = frame.findOne(n => n.name === '#brief-component-description');
if (descFrame) {
  const t = descFrame.findOne(n => n.type === 'TEXT');
  if (t) t.characters = '__BRIEF_DESCRIPTION__';
}

const markerExample = frame.findOne(n => n.name === '#marker-example');
if (markerExample) markerExample.visible = false;

return { success: true };
```

### Step 9: Build Property Exhibits

This is the main rendering step. Iterate over the `exhibitPlan` array produced in Step 4e. Each entry specifies the chapter type, rendering mode, and configuration. Do NOT mechanically iterate `variantAxes` then `booleanProps` — the exhibit plan already accounts for matrix chapters, composite chapters, and context axis rendering.

**Template routing based on `contextAxis`:**

| Exhibit type | `contextAxis` is null | `contextAxis` is non-null |
|---|---|---|
| Variant axis chapter | **6a** (standard) | **6a-ctx** (contextual rows) |
| Boolean chapter | **6b** (standard) | **6b-ctx** (contextual rows) |
| Composite chapter | **6a** (custom OPTIONS) | **6a-ctx** (custom OPTIONS + context rows) |
| Sparse matrix | **6a-matrix** | **6a-matrix** (unchanged) |
| Variable mode | **6c** | **6c** (unchanged) |
| Child component | **6e/6f/6g** | **6e/6f/6g** (unchanged) |

When `contextAxis` is non-null, pass `CONTEXT_AXIS_NAME`, `CONTEXT_OPTIONS`, and `CONTEXT_DEFAULT` to the contextual templates. These values come from the `contextAxis` object produced in Step 4e.

Run **one `figma_execute` call per exhibit** to avoid timeouts. The scripts below are templates — select the appropriate template based on each exhibit entry's `template` field.

#### 6a: Standard VARIANT axis chapter

For exhibit plan entries with `template: "6a"` (when `contextAxis` is null). Also used for composite entries without context — supply a customized `OPTIONS` array and `DEFAULT_PROPS` as determined by the exhibit plan:

```javascript
const FRAME_ID = '__FRAME_ID__';
const COMP_SET_ID = '__COMP_SET_NODE_ID__';
const PROPERTY_NAME = '__PROPERTY_NAME__';
const OPTIONS = __OPTIONS_JSON__;
const DEFAULT_VALUE = '__DEFAULT_VALUE__';
const DEFAULT_PROPS = __DEFAULT_PROPS_JSON__;
const FONT_FAMILY = '__FONT_FAMILY__';

const frame = await figma.getNodeByIdAsync(FRAME_ID);
const chapterTemplate = frame.findOne(n => n.name === '#anatomy-section');

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

const chapter = chapterTemplate.clone();
chapterTemplate.parent.appendChild(chapter);
chapter.name = PROPERTY_NAME;
chapter.visible = true;

try {

await loadAllFonts(chapter);

const sectionName = chapter.findOne(n => n.name === '#section-name');
if (sectionName) {
  const t = sectionName.findOne(n => n.type === 'TEXT');
  if (t) t.characters = PROPERTY_NAME;
}

const sectionDesc = chapter.findOne(n => n.name === '#optional-section-description');
if (sectionDesc) {
  const t = sectionDesc.findOne(n => n.type === 'TEXT');
  if (t) t.characters = OPTIONS.length + ' options. Default: ' + DEFAULT_VALUE;
}

const assetPlaceholder = chapter.findOne(n => n.name === '#preview');
while (assetPlaceholder.children.length > 0) {
  assetPlaceholder.children[0].remove();
}
assetPlaceholder.layoutWrap = 'WRAP';
assetPlaceholder.counterAxisSpacing = assetPlaceholder.itemSpacing;

const compSet = await figma.getNodeByIdAsync(COMP_SET_ID);

for (const option of OPTIONS) {
  const variantProps = {};
  for (const [k, v] of Object.entries(DEFAULT_PROPS)) {
    variantProps[k] = v;
  }
  variantProps[PROPERTY_NAME] = option;

  let targetVariant = null;
  let bestFallback = null;
  let bestFallbackScore = -1;
  for (const child of compSet.children) {
    const vp = child.variantProperties || {};
    if (vp[PROPERTY_NAME] !== option) continue;
    let score = 0;
    let exactMatch = true;
    for (const [k, v] of Object.entries(variantProps)) {
      if (vp[k] === v) { score++; } else { exactMatch = false; }
    }
    if (exactMatch) { targetVariant = child; break; }
    if (score > bestFallbackScore) { bestFallbackScore = score; bestFallback = child; }
  }
  if (!targetVariant) targetVariant = bestFallback;

  const wrapper = figma.createFrame();
  wrapper.name = option;
  wrapper.layoutMode = 'VERTICAL';
  wrapper.primaryAxisAlignItems = 'CENTER';
  wrapper.counterAxisAlignItems = 'CENTER';
  wrapper.itemSpacing = 12;
  wrapper.fills = [];
  wrapper.primaryAxisSizingMode = 'AUTO';
  wrapper.counterAxisSizingMode = 'AUTO';
  assetPlaceholder.appendChild(wrapper);

  if (targetVariant) {
    const inst = targetVariant.createInstance();
    await loadAllFonts(inst);
    wrapper.appendChild(inst);
  } else {
    const placeholder = figma.createText();
    await figma.loadFontAsync({ family: 'Inter', style: 'Regular' });
    placeholder.characters = 'Variant unavailable';
    placeholder.fontSize = 12;
    placeholder.fills = [{ type: 'SOLID', color: { r: 0.6, g: 0.6, b: 0.6 } }];
    wrapper.appendChild(placeholder);
  }

  const LABEL_FONT = await loadFontWithFallback(FONT_FAMILY, 'Medium');
  const label = figma.createText();
  label.fontName = LABEL_FONT;
  label.characters = option === DEFAULT_VALUE ? option + ' (default)' : option;
  label.fontSize = 14;
  label.fills = [{ type: 'SOLID', color: { r: 0.29, g: 0.29, b: 0.29 } }];
  wrapper.appendChild(label);
}

return { success: true, property: PROPERTY_NAME };

} catch (e) {
  chapter.remove();
  return { error: e.message, rolledBack: true };
}
```

#### 6a-ctx: Contextual VARIANT axis chapter

When `contextAxis` is non-null, use this template instead of 6a for variant chapters. Also used for composite chapters with context. The template adds an outer loop over context axis values, rendering grouped rows inside a vertical container frame. Each row group has a row label and a horizontal instance row.

Replace `CONTEXT_AXIS_NAME`, `CONTEXT_OPTIONS`, and `CONTEXT_DEFAULT` with the context axis data from the exhibit plan. Replace all other placeholders as in 6a:

```javascript
const FRAME_ID = '__FRAME_ID__';
const COMP_SET_ID = '__COMP_SET_NODE_ID__';
const PROPERTY_NAME = '__PROPERTY_NAME__';
const OPTIONS = __OPTIONS_JSON__;
const DEFAULT_VALUE = '__DEFAULT_VALUE__';
const DEFAULT_PROPS = __DEFAULT_PROPS_JSON__;
const CONTEXT_AXIS_NAME = '__CONTEXT_AXIS_NAME__';
const CONTEXT_OPTIONS = __CONTEXT_OPTIONS_JSON__;
const CONTEXT_DEFAULT = '__CONTEXT_DEFAULT__';
const FONT_FAMILY = '__FONT_FAMILY__';

const frame = await figma.getNodeByIdAsync(FRAME_ID);
const chapterTemplate = frame.findOne(n => n.name === '#anatomy-section');

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

const chapter = chapterTemplate.clone();
chapterTemplate.parent.appendChild(chapter);
chapter.name = PROPERTY_NAME;
chapter.visible = true;

try {

await loadAllFonts(chapter);

const sectionName = chapter.findOne(n => n.name === '#section-name');
if (sectionName) {
  const t = sectionName.findOne(n => n.type === 'TEXT');
  if (t) t.characters = PROPERTY_NAME;
}

const sectionDesc = chapter.findOne(n => n.name === '#optional-section-description');
if (sectionDesc) {
  const t = sectionDesc.findOne(n => n.type === 'TEXT');
  if (t) t.characters = OPTIONS.length + ' options across ' + CONTEXT_OPTIONS.length + ' ' + CONTEXT_AXIS_NAME + 's. Default: ' + DEFAULT_VALUE;
}

const assetPlaceholder = chapter.findOne(n => n.name === '#preview');
while (assetPlaceholder.children.length > 0) {
  assetPlaceholder.children[0].remove();
}

const compSet = await figma.getNodeByIdAsync(COMP_SET_ID);
const LABEL_FONT = await loadFontWithFallback(FONT_FAMILY, 'Medium');
const ROW_LABEL_FONT = await loadFontWithFallback(FONT_FAMILY, 'Bold');

const contextContainer = figma.createFrame();
contextContainer.name = 'context-groups';
contextContainer.layoutMode = 'VERTICAL';
contextContainer.itemSpacing = 32;
contextContainer.fills = [];
contextContainer.primaryAxisSizingMode = 'AUTO';
contextContainer.counterAxisSizingMode = 'FILL';
assetPlaceholder.appendChild(contextContainer);

for (const ctxValue of CONTEXT_OPTIONS) {
  const rowGroup = figma.createFrame();
  rowGroup.name = ctxValue;
  rowGroup.layoutMode = 'VERTICAL';
  rowGroup.itemSpacing = 16;
  rowGroup.fills = [];
  rowGroup.primaryAxisSizingMode = 'AUTO';
  rowGroup.counterAxisSizingMode = 'FILL';
  contextContainer.appendChild(rowGroup);

  const rowLabel = figma.createText();
  rowLabel.fontName = ROW_LABEL_FONT;
  rowLabel.characters = ctxValue === CONTEXT_DEFAULT ? ctxValue + ' (default)' : ctxValue;
  rowLabel.fontSize = 12;
  rowLabel.fills = [{ type: 'SOLID', color: { r: 0.45, g: 0.45, b: 0.45 } }];
  rowGroup.appendChild(rowLabel);

  const instanceRow = figma.createFrame();
  instanceRow.name = ctxValue + '-instances';
  instanceRow.layoutMode = 'HORIZONTAL';
  instanceRow.layoutWrap = 'WRAP';
  instanceRow.itemSpacing = 24;
  instanceRow.counterAxisSpacing = 24;
  instanceRow.fills = [];
  instanceRow.primaryAxisSizingMode = 'AUTO';
  instanceRow.counterAxisSizingMode = 'AUTO';
  rowGroup.appendChild(instanceRow);

  for (const option of OPTIONS) {
    const variantProps = { ...DEFAULT_PROPS };
    variantProps[PROPERTY_NAME] = option;
    variantProps[CONTEXT_AXIS_NAME] = ctxValue;

    let targetVariant = null;
    let bestFallback = null;
    let bestFallbackScore = -1;
    for (const child of compSet.children) {
      const vp = child.variantProperties || {};
      if (vp[PROPERTY_NAME] !== option) continue;
      if (vp[CONTEXT_AXIS_NAME] !== ctxValue) continue;
      let score = 0;
      let exactMatch = true;
      for (const [k, v] of Object.entries(variantProps)) {
        if (vp[k] === v) { score++; } else { exactMatch = false; }
      }
      if (exactMatch) { targetVariant = child; break; }
      if (score > bestFallbackScore) { bestFallbackScore = score; bestFallback = child; }
    }
    if (!targetVariant) targetVariant = bestFallback;

    const wrapper = figma.createFrame();
    wrapper.name = option;
    wrapper.layoutMode = 'VERTICAL';
    wrapper.primaryAxisAlignItems = 'CENTER';
    wrapper.counterAxisAlignItems = 'CENTER';
    wrapper.itemSpacing = 12;
    wrapper.fills = [];
    wrapper.primaryAxisSizingMode = 'AUTO';
    wrapper.counterAxisSizingMode = 'AUTO';
    instanceRow.appendChild(wrapper);

    if (targetVariant) {
      const inst = targetVariant.createInstance();
      await loadAllFonts(inst);
      wrapper.appendChild(inst);
    } else {
      const placeholder = figma.createText();
      await figma.loadFontAsync({ family: 'Inter', style: 'Regular' });
      placeholder.characters = 'N/A';
      placeholder.fontSize = 12;
      placeholder.fills = [{ type: 'SOLID', color: { r: 0.6, g: 0.6, b: 0.6 } }];
      wrapper.appendChild(placeholder);
    }

    const label = figma.createText();
    label.fontName = LABEL_FONT;
    label.characters = option === DEFAULT_VALUE ? option + ' (default)' : option;
    label.fontSize = 14;
    label.fills = [{ type: 'SOLID', color: { r: 0.29, g: 0.29, b: 0.29 } }];
    wrapper.appendChild(label);
  }
}

return { success: true, property: PROPERTY_NAME };

} catch (e) {
  chapter.remove();
  return { error: e.message, rolledBack: true };
}
```

**Key differences from 6a:**
- Outer loop over `CONTEXT_OPTIONS` creates row groups with labels
- A `contextContainer` frame inside `#preview` handles vertical stacking (avoids modifying `#preview` properties)
- `variantProps` sets both `PROPERTY_NAME` and `CONTEXT_AXIS_NAME` for each instance
- Variant lookup requires both the property AND context axis to match, with fallback scoring
- Row labels use Bold/12px to distinguish from option labels (Medium/14px)
- N/A placeholders appear when a context × option combination doesn't exist

**Composite chapters with context:** When a composite chapter (variant axis + related booleans) needs context rendering, use the same 6a-ctx structure. The `OPTIONS` loop creates instances with custom property combinations (as in the standard composite approach), and the outer `CONTEXT_OPTIONS` loop wraps everything in context rows. For each composite option, set the variant properties AND the boolean properties on the instance, then also set `CONTEXT_AXIS_NAME = ctxValue`.

#### 6a-matrix: For a SPARSE VARIANT MATRIX chapter

When the exhibit plan (Step 4e) identified a sparse axis pair, render a matrix chapter **plus standalone chapters for both axes**. The matrix's primary axis forms the rows, the secondary axis forms the columns. Missing combinations get "N/A" placeholders that occupy the same cell space as real instances for visual alignment. The standalone chapters (6a) give engineers a dedicated reference for each axis in isolation; the matrix shows which cross-product combinations exist.

**Grid layout technique**: The matrix uses **absolute positioning** inside a non-auto-layout child frame, nested within the template's `#preview` frame. This prevents auto-layout from collapsing or misaligning cells when "N/A" placeholders are smaller than real instances.

```javascript
const FRAME_ID = '__FRAME_ID__';
const COMP_SET_ID = '__COMP_SET_NODE_ID__';
const PRIMARY_AXIS = '__PRIMARY_AXIS_NAME__';   // e.g., 'variant' (rows)
const SECONDARY_AXIS = '__SECONDARY_AXIS_NAME__'; // e.g., 'color' (columns)
const PRIMARY_OPTIONS = __PRIMARY_OPTIONS_JSON__;
const SECONDARY_OPTIONS = __SECONDARY_OPTIONS_JSON__;
const DEFAULT_PROPS = __DEFAULT_PROPS_JSON__;
const FONT_FAMILY = '__FONT_FAMILY__';
const CHAPTER_NAME = '__CHAPTER_NAME__';
const DESCRIPTION = '__DESCRIPTION__';

const frame = await figma.getNodeByIdAsync(FRAME_ID);
const chapterTemplate = frame.findOne(n => n.name === '#anatomy-section');

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
  if (familyFonts.length === 0) return { family: 'Inter', style: fallbackStyle };
  const pref = familyFonts.find(f => f.fontName.style === preferredStyle);
  if (pref) return pref.fontName;
  const fb = familyFonts.find(f => f.fontName.style === fallbackStyle);
  return fb ? fb.fontName : familyFonts[0].fontName;
}

const chapter = chapterTemplate.clone();
chapter.visible = true;
chapter.name = CHAPTER_NAME;
frame.appendChild(chapter);

try {

await loadAllFonts(chapter);
const titleNode = chapter.findOne(n => n.name === '#property-name' && n.type === 'TEXT');
if (titleNode) titleNode.characters = CHAPTER_NAME;
const descNode = chapter.findOne(n => n.name === '#property-description' && n.type === 'TEXT');
if (descNode) descNode.characters = DESCRIPTION;

const assetPlaceholder = chapter.findOne(n => n.name === '#preview');
while (assetPlaceholder.children.length > 0) assetPlaceholder.children[0].remove();

// --- Measure a sample instance to determine cell size ---
const compSet = await figma.getNodeByIdAsync(COMP_SET_ID);
const sampleVariant = compSet.children[0];
const sampleInst = sampleVariant.createInstance();
await loadAllFonts(sampleInst);
const CELL_W = Math.ceil(sampleInst.width) + 40;
const CELL_H = Math.ceil(sampleInst.height) + 40;
sampleInst.remove();

const LABEL_H = 20;
const HEADER_H = 24;
const GAP = 8;
const ROW_LABEL_W = 120;
const GRID_LEFT = ROW_LABEL_W + GAP;

const totalCols = SECONDARY_OPTIONS.length;
const totalRows = PRIMARY_OPTIONS.length;
const totalW = GRID_LEFT + totalCols * (CELL_W + GAP);
const totalH = HEADER_H + GAP + totalRows * (CELL_H + LABEL_H + GAP);

// Preserve #preview as auto-layout, create a non-auto-layout child for the grid
assetPlaceholder.layoutWrap = 'WRAP';
const gridFrame = figma.createFrame();
gridFrame.name = CHAPTER_NAME + '-grid';
gridFrame.layoutMode = 'NONE';
gridFrame.fills = [];
gridFrame.resize(totalW, totalH);
assetPlaceholder.appendChild(gridFrame);

const LABEL_FONT = await loadFontWithFallback(FONT_FAMILY, 'Medium');
const HEADER_FONT = await loadFontWithFallback(FONT_FAMILY, 'Bold');

// --- Column headers ---
for (let ci = 0; ci < SECONDARY_OPTIONS.length; ci++) {
  const header = figma.createText();
  header.fontName = HEADER_FONT;
  header.characters = SECONDARY_OPTIONS[ci];
  header.fontSize = 12;
  header.fills = [{ type: 'SOLID', color: { r: 0.4, g: 0.4, b: 0.4 } }];
  gridFrame.appendChild(header);
  header.x = GRID_LEFT + ci * (CELL_W + GAP) + CELL_W / 2 - header.width / 2;
  header.y = 0;
}

// --- Rows ---
for (let ri = 0; ri < PRIMARY_OPTIONS.length; ri++) {
  const rowY = HEADER_H + GAP + ri * (CELL_H + LABEL_H + GAP);
  const rowLabel = figma.createText();
  rowLabel.fontName = LABEL_FONT;
  rowLabel.characters = PRIMARY_OPTIONS[ri];
  rowLabel.fontSize = 14;
  rowLabel.fills = [{ type: 'SOLID', color: { r: 0.29, g: 0.29, b: 0.29 } }];
  gridFrame.appendChild(rowLabel);
  rowLabel.x = 0;
  rowLabel.y = rowY + CELL_H / 2 - rowLabel.height / 2;

  for (let ci = 0; ci < SECONDARY_OPTIONS.length; ci++) {
    const cellX = GRID_LEFT + ci * (CELL_W + GAP);
    const cellY = rowY;

    const variantProps = { ...DEFAULT_PROPS };
    variantProps[PRIMARY_AXIS] = PRIMARY_OPTIONS[ri];
    variantProps[SECONDARY_AXIS] = SECONDARY_OPTIONS[ci];

    let targetVariant = null;
    for (const child of compSet.children) {
      const vp = child.variantProperties || {};
      let match = true;
      for (const [k, v] of Object.entries(variantProps)) {
        if (vp[k] !== v) { match = false; break; }
      }
      if (match) { targetVariant = child; break; }
    }

    const wrapper = figma.createFrame();
    wrapper.layoutMode = 'VERTICAL';
    wrapper.primaryAxisAlignItems = 'CENTER';
    wrapper.counterAxisAlignItems = 'CENTER';
    wrapper.itemSpacing = 8;
    wrapper.fills = [];
    wrapper.primaryAxisSizingMode = 'AUTO';
    wrapper.counterAxisSizingMode = 'FIXED';
    wrapper.resize(CELL_W, CELL_H + LABEL_H);

    if (targetVariant) {
      const inst = targetVariant.createInstance();
      await loadAllFonts(inst);
      wrapper.appendChild(inst);
    } else {
      const naText = figma.createText();
      await figma.loadFontAsync({ family: 'Inter', style: 'Regular' });
      naText.characters = 'N/A';
      naText.fontSize = 14;
      naText.fills = [{ type: 'SOLID', color: { r: 0.7, g: 0.7, b: 0.7 } }];
      wrapper.appendChild(naText);
    }

    gridFrame.appendChild(wrapper);
    wrapper.x = cellX;
    wrapper.y = cellY;
  }
}

return { success: true, chapter: CHAPTER_NAME };

} catch (e) {
  chapter.remove();
  return { error: e.message, rolledBack: true };
}
```

**N/A placeholder rule**: Always render "N/A" text for missing combinations. Never skip the cell or leave it empty — the placeholder preserves the grid's visual scanability and lets the spec consumer immediately see which combinations don't exist.

**Cell sizing**: Measure a real instance before building the grid. Use the measured dimensions + padding as the fixed cell size. All cells (instance and N/A) use the same width to maintain column alignment.

#### 6b: Standard BOOLEAN property chapter

For exhibit plan entries with `template: "6b"` (when `contextAxis` is null).

**Skip controlling booleans**: Before rendering each parent boolean, check if its `name` appears in the `controllingBooleanNames` set built in Step 4 (matched from `render-meta.subComponents`). If so, skip it — its chapter is produced by 6e as part of the unified child component chapter.

**Handle variant-gated booleans**: Before rendering, check if the boolean has `requiredVariantOverrides` (from Step 4a). If so, the base variant for instance creation must match those overrides instead of using the default variant. Replace `VARIANT_OVERRIDES` with the required overrides object (e.g., `{"Behavior": "Interactive"}`), or `null` if the boolean is not variant-gated.

**Slot-aware descriptions**: Replace `__CONTROLS_SLOT_BOOL__` with the boolean's `controlsSlot` value (`true` or `false`). Replace `__SLOT_PREFERRED_NAMES_JSON__` with the boolean's `slotPreferredNames` array (e.g., `["Checkbox", "Radio"]`), or `[]` if empty. When a boolean controls a SLOT, the description reads "Controls slot: {name} (accepts: {preferred})" instead of "Controls layer: {name}".

For each remaining boolean property, run via `figma_execute`:

```javascript
const FRAME_ID = '__FRAME_ID__';
const COMP_SET_ID = '__COMP_SET_NODE_ID__';
const PROPERTY_NAME = '__PROPERTY_NAME__';
const DEFAULT_VALUE = __DEFAULT_BOOL_VALUE__;
const ASSOCIATED_LAYER = '__ASSOCIATED_LAYER__';
const CONTROLS_SLOT = __CONTROLS_SLOT_BOOL__;
const SLOT_PREFERRED_NAMES = __SLOT_PREFERRED_NAMES_JSON__;
const VARIANT_OVERRIDES = __VARIANT_OVERRIDES_OR_NULL__;
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

const frame = await figma.getNodeByIdAsync(FRAME_ID);
const chapterTemplate = frame.findOne(n => n.name === '#anatomy-section');

const chapter = chapterTemplate.clone();
chapterTemplate.parent.appendChild(chapter);
chapter.name = PROPERTY_NAME;
chapter.visible = true;

try {

await loadAllFonts(chapter);

const sectionName = chapter.findOne(n => n.name === '#section-name');
if (sectionName) {
  const t = sectionName.findOne(n => n.type === 'TEXT');
  if (t) t.characters = PROPERTY_NAME;
}

const sectionDesc = chapter.findOne(n => n.name === '#optional-section-description');
if (sectionDesc) {
  const t = sectionDesc.findOne(n => n.type === 'TEXT');
  const defaultStr = DEFAULT_VALUE ? 'true' : 'false';
  let layerStr = '';
  if (CONTROLS_SLOT) {
    layerStr = '. Controls slot: ' + ASSOCIATED_LAYER;
    if (SLOT_PREFERRED_NAMES.length > 0) layerStr += ' (accepts: ' + SLOT_PREFERRED_NAMES.join(', ') + ')';
  } else if (ASSOCIATED_LAYER) {
    layerStr = '. Controls layer: ' + ASSOCIATED_LAYER;
  }
  const gateStr = VARIANT_OVERRIDES ? '. Requires ' + Object.entries(VARIANT_OVERRIDES).map(([k,v]) => k + ' = ' + v).join(', ') : '';
  if (t) t.characters = 'Boolean toggle. Default: ' + defaultStr + layerStr + gateStr;
}

const assetPlaceholder = chapter.findOne(n => n.name === '#preview');
while (assetPlaceholder.children.length > 0) {
  assetPlaceholder.children[0].remove();
}
assetPlaceholder.layoutWrap = 'WRAP';
assetPlaceholder.counterAxisSpacing = assetPlaceholder.itemSpacing;

const compNode = await figma.getNodeByIdAsync(COMP_SET_ID);

let baseVariant;
if (VARIANT_OVERRIDES && compNode.type === 'COMPONENT_SET') {
  const defaultVProps = (compNode.defaultVariant || compNode.children[0]).variantProperties || {};
  const targetProps = { ...defaultVProps, ...VARIANT_OVERRIDES };
  baseVariant = null;
  let bestScore = -1;
  for (const child of compNode.children) {
    const vp = child.variantProperties || {};
    let score = 0;
    let exact = true;
    for (const [k, v] of Object.entries(targetProps)) {
      if (vp[k] === v) { score++; } else { exact = false; }
    }
    if (exact) { baseVariant = child; break; }
    if (score > bestScore) { bestScore = score; baseVariant = child; }
  }
} else {
  baseVariant = compNode.type === 'COMPONENT_SET'
    ? (compNode.defaultVariant || compNode.children[0])
    : compNode;
}

const LABEL_FONT = await loadFontWithFallback(FONT_FAMILY, 'Medium');

for (const boolVal of [true, false]) {
  const wrapper = figma.createFrame();
  wrapper.name = PROPERTY_NAME + ' = ' + boolVal;
  wrapper.layoutMode = 'VERTICAL';
  wrapper.primaryAxisAlignItems = 'CENTER';
  wrapper.counterAxisAlignItems = 'CENTER';
  wrapper.itemSpacing = 12;
  wrapper.fills = [];
  wrapper.primaryAxisSizingMode = 'AUTO';
  wrapper.counterAxisSizingMode = 'AUTO';
  assetPlaceholder.appendChild(wrapper);

  const inst = baseVariant.createInstance();
  await loadAllFonts(inst);
  wrapper.appendChild(inst);

  for (const [rawKey, val] of Object.entries(inst.componentProperties)) {
    const cleanKey = rawKey.split('#')[0];
    if (cleanKey === PROPERTY_NAME) {
      inst.setProperties({ [rawKey]: boolVal });
      await loadAllFonts(inst);
      break;
    }
  }

  const label = figma.createText();
  label.fontName = LABEL_FONT;
  const isDefault = boolVal === DEFAULT_VALUE;
  label.characters = String(boolVal) + (isDefault ? ' (default)' : '');
  label.fontSize = 14;
  label.fills = [{ type: 'SOLID', color: { r: 0.29, g: 0.29, b: 0.29 } }];
  wrapper.appendChild(label);
}

return { success: true, property: PROPERTY_NAME };

} catch (e) {
  chapter.remove();
  return { error: e.message, rolledBack: true };
}
```

#### 6b-ctx: Contextual BOOLEAN property chapter

When `contextAxis` is non-null, use this template instead of 6b for boolean chapters. It wraps the true/false toggle in context rows so the developer sees how the boolean looks across all context values.

**Skip controlling booleans and handle variant-gated booleans** using the same rules as 6b.

For each remaining boolean property, run via `figma_execute`:

```javascript
const FRAME_ID = '__FRAME_ID__';
const COMP_SET_ID = '__COMP_SET_NODE_ID__';
const PROPERTY_NAME = '__PROPERTY_NAME__';
const DEFAULT_VALUE = __DEFAULT_BOOL_VALUE__;
const ASSOCIATED_LAYER = '__ASSOCIATED_LAYER__';
const CONTROLS_SLOT = __CONTROLS_SLOT_BOOL__;
const SLOT_PREFERRED_NAMES = __SLOT_PREFERRED_NAMES_JSON__;
const VARIANT_OVERRIDES = __VARIANT_OVERRIDES_OR_NULL__;
const CONTEXT_AXIS_NAME = '__CONTEXT_AXIS_NAME__';
const CONTEXT_OPTIONS = __CONTEXT_OPTIONS_JSON__;
const CONTEXT_DEFAULT = '__CONTEXT_DEFAULT__';
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

const frame = await figma.getNodeByIdAsync(FRAME_ID);
const chapterTemplate = frame.findOne(n => n.name === '#anatomy-section');

const chapter = chapterTemplate.clone();
chapterTemplate.parent.appendChild(chapter);
chapter.name = PROPERTY_NAME;
chapter.visible = true;

try {

await loadAllFonts(chapter);

const sectionName = chapter.findOne(n => n.name === '#section-name');
if (sectionName) {
  const t = sectionName.findOne(n => n.type === 'TEXT');
  if (t) t.characters = PROPERTY_NAME;
}

const sectionDesc = chapter.findOne(n => n.name === '#optional-section-description');
if (sectionDesc) {
  const t = sectionDesc.findOne(n => n.type === 'TEXT');
  const defaultStr = DEFAULT_VALUE ? 'true' : 'false';
  let layerStr = '';
  if (CONTROLS_SLOT) {
    layerStr = '. Controls slot: ' + ASSOCIATED_LAYER;
    if (SLOT_PREFERRED_NAMES.length > 0) layerStr += ' (accepts: ' + SLOT_PREFERRED_NAMES.join(', ') + ')';
  } else if (ASSOCIATED_LAYER) {
    layerStr = '. Controls layer: ' + ASSOCIATED_LAYER;
  }
  const gateStr = VARIANT_OVERRIDES ? '. Requires ' + Object.entries(VARIANT_OVERRIDES).map(([k,v]) => k + ' = ' + v).join(', ') : '';
  if (t) t.characters = 'Boolean toggle across ' + CONTEXT_OPTIONS.length + ' ' + CONTEXT_AXIS_NAME + 's. Default: ' + defaultStr + layerStr + gateStr;
}

const assetPlaceholder = chapter.findOne(n => n.name === '#preview');
while (assetPlaceholder.children.length > 0) {
  assetPlaceholder.children[0].remove();
}

const compNode = await figma.getNodeByIdAsync(COMP_SET_ID);
const LABEL_FONT = await loadFontWithFallback(FONT_FAMILY, 'Medium');
const ROW_LABEL_FONT = await loadFontWithFallback(FONT_FAMILY, 'Bold');

const contextContainer = figma.createFrame();
contextContainer.name = 'context-groups';
contextContainer.layoutMode = 'VERTICAL';
contextContainer.itemSpacing = 32;
contextContainer.fills = [];
contextContainer.primaryAxisSizingMode = 'AUTO';
contextContainer.counterAxisSizingMode = 'FILL';
assetPlaceholder.appendChild(contextContainer);

for (const ctxValue of CONTEXT_OPTIONS) {
  const rowGroup = figma.createFrame();
  rowGroup.name = ctxValue;
  rowGroup.layoutMode = 'VERTICAL';
  rowGroup.itemSpacing = 16;
  rowGroup.fills = [];
  rowGroup.primaryAxisSizingMode = 'AUTO';
  rowGroup.counterAxisSizingMode = 'FILL';
  contextContainer.appendChild(rowGroup);

  const rowLabel = figma.createText();
  rowLabel.fontName = ROW_LABEL_FONT;
  rowLabel.characters = ctxValue === CONTEXT_DEFAULT ? ctxValue + ' (default)' : ctxValue;
  rowLabel.fontSize = 12;
  rowLabel.fills = [{ type: 'SOLID', color: { r: 0.45, g: 0.45, b: 0.45 } }];
  rowGroup.appendChild(rowLabel);

  const instanceRow = figma.createFrame();
  instanceRow.name = ctxValue + '-instances';
  instanceRow.layoutMode = 'HORIZONTAL';
  instanceRow.layoutWrap = 'WRAP';
  instanceRow.itemSpacing = 24;
  instanceRow.counterAxisSpacing = 24;
  instanceRow.fills = [];
  instanceRow.primaryAxisSizingMode = 'AUTO';
  instanceRow.counterAxisSizingMode = 'AUTO';
  rowGroup.appendChild(instanceRow);

  const defaultVProps = (compNode.defaultVariant || compNode.children[0]).variantProperties || {};
  const baseProps = VARIANT_OVERRIDES ? { ...defaultVProps, ...VARIANT_OVERRIDES } : { ...defaultVProps };
  baseProps[CONTEXT_AXIS_NAME] = ctxValue;

  let baseVariant = null;
  let bestScore = -1;
  for (const child of compNode.children) {
    const vp = child.variantProperties || {};
    let score = 0;
    let exact = true;
    for (const [k, v] of Object.entries(baseProps)) {
      if (vp[k] === v) { score++; } else { exact = false; }
    }
    if (exact) { baseVariant = child; break; }
    if (score > bestScore) { bestScore = score; baseVariant = child; }
  }

  if (!baseVariant) {
    const skipLabel = figma.createText();
    skipLabel.fontName = LABEL_FONT;
    skipLabel.characters = 'Not available for ' + ctxValue;
    skipLabel.fontSize = 12;
    skipLabel.fills = [{ type: 'SOLID', color: { r: 0.6, g: 0.6, b: 0.6 } }];
    instanceRow.appendChild(skipLabel);
    continue;
  }

  for (const boolVal of [true, false]) {
    const wrapper = figma.createFrame();
    wrapper.name = PROPERTY_NAME + ' = ' + boolVal;
    wrapper.layoutMode = 'VERTICAL';
    wrapper.primaryAxisAlignItems = 'CENTER';
    wrapper.counterAxisAlignItems = 'CENTER';
    wrapper.itemSpacing = 12;
    wrapper.fills = [];
    wrapper.primaryAxisSizingMode = 'AUTO';
    wrapper.counterAxisSizingMode = 'AUTO';
    instanceRow.appendChild(wrapper);

    const inst = baseVariant.createInstance();
    await loadAllFonts(inst);
    wrapper.appendChild(inst);

    for (const [rawKey, val] of Object.entries(inst.componentProperties)) {
      const cleanKey = rawKey.split('#')[0];
      if (cleanKey === PROPERTY_NAME) {
        inst.setProperties({ [rawKey]: boolVal });
        await loadAllFonts(inst);
        break;
      }
    }

    const label = figma.createText();
    label.fontName = LABEL_FONT;
    const isDefault = boolVal === DEFAULT_VALUE;
    label.characters = String(boolVal) + (isDefault ? ' (default)' : '');
    label.fontSize = 14;
    label.fills = [{ type: 'SOLID', color: { r: 0.29, g: 0.29, b: 0.29 } }];
    wrapper.appendChild(label);
  }
}

return { success: true, property: PROPERTY_NAME };

} catch (e) {
  chapter.remove();
  return { error: e.message, rolledBack: true };
}
```

**Key differences from 6b:**
- Outer loop over `CONTEXT_OPTIONS` creates row groups with labels
- Base variant lookup includes `CONTEXT_AXIS_NAME = ctxValue` in the target props
- When no base variant exists for a context value (sparse), the row shows "Not available for {ctxValue}" instead of failing
- Same `contextContainer` → `rowGroup` → `instanceRow` nesting as 6a-ctx

#### 6c: For each VARIABLE MODE property

If `variableModeProps` is not empty, render a visual chapter for each. Variable mode properties are controlled via Figma variable modes at the container level. To produce visual previews, create a wrapper frame for each mode option, place a component instance inside, and call `wrapper.setExplicitVariableModeForCollection(collection, modeId)` on the wrapper so the instance inherits the mode.

**Important — collection object, not string ID:** The Figma plugin API in incremental mode requires the actual collection object for `setExplicitVariableModeForCollection`, not a string ID. The script below fetches the collection object via `getLocalVariableCollectionsAsync()`.

**Important — clearing baked-in modes:** Some components have explicit variable modes set directly on their root or internal nodes. Instances created from such components inherit these baked-in modes, which override the wrapper's mode. After creating each instance, the script recursively clears explicit modes for the target collection so the instance defers to the wrapper.

For each variable mode property, run via `figma_execute`:

```javascript
const FRAME_ID = '__FRAME_ID__';
const COMP_SET_ID = '__COMP_SET_NODE_ID__';
const PROPERTY_NAME = '__PROPERTY_NAME__';
const DEFAULT_VALUE = '__DEFAULT_VALUE__';
const COLLECTION_NAME = '__COLLECTION_NAME__';
const COLLECTION_ID = '__COLLECTION_ID__';
const MODES = __MODES_JSON__;
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

const frame = await figma.getNodeByIdAsync(FRAME_ID);
const chapterTemplate = frame.findOne(n => n.name === '#anatomy-section');

const chapter = chapterTemplate.clone();
chapterTemplate.parent.appendChild(chapter);
chapter.name = PROPERTY_NAME;
chapter.visible = true;

try {

const collections = await figma.variables.getLocalVariableCollectionsAsync();
const collection = collections.find(c => c.id === COLLECTION_ID);
if (!collection) {
  chapter.remove();
  return { error: 'Variable collection not found: ' + COLLECTION_ID };
}

function clearModesRecursive(node, col) {
  try { node.clearExplicitVariableModeForCollection(col); } catch {}
  if ('children' in node) {
    for (const child of node.children) clearModesRecursive(child, col);
  }
}

await loadAllFonts(chapter);

const sectionName = chapter.findOne(n => n.name === '#section-name');
if (sectionName) {
  const t = sectionName.findOne(n => n.type === 'TEXT');
  if (t) t.characters = PROPERTY_NAME;
}

const sectionDesc = chapter.findOne(n => n.name === '#optional-section-description');
if (sectionDesc) {
  const t = sectionDesc.findOne(n => n.type === 'TEXT');
  if (t) {
    t.characters = MODES.length + ' options. Default: ' + DEFAULT_VALUE + '. Controlled via \'' + COLLECTION_NAME + '\' variable mode.';
  }
}

const assetPlaceholder = chapter.findOne(n => n.name === '#preview');
while (assetPlaceholder.children.length > 0) {
  assetPlaceholder.children[0].remove();
}
assetPlaceholder.layoutWrap = 'WRAP';
assetPlaceholder.counterAxisSpacing = assetPlaceholder.itemSpacing;

const compNode = await figma.getNodeByIdAsync(COMP_SET_ID);
const defaultVariant = compNode.type === 'COMPONENT_SET'
  ? (compNode.defaultVariant || compNode.children[0])
  : compNode;

const LABEL_FONT = await loadFontWithFallback(FONT_FAMILY, 'Medium');

for (const mode of MODES) {
  const wrapper = figma.createFrame();
  wrapper.name = mode.name;
  wrapper.layoutMode = 'VERTICAL';
  wrapper.primaryAxisAlignItems = 'CENTER';
  wrapper.counterAxisAlignItems = 'CENTER';
  wrapper.itemSpacing = 12;
  wrapper.fills = [];
  wrapper.primaryAxisSizingMode = 'AUTO';
  wrapper.counterAxisSizingMode = 'AUTO';
  assetPlaceholder.appendChild(wrapper);

  wrapper.setExplicitVariableModeForCollection(collection, mode.modeId);

  const inst = defaultVariant.createInstance();
  wrapper.appendChild(inst);
  clearModesRecursive(inst, collection);

  const label = figma.createText();
  label.fontName = LABEL_FONT;
  label.characters = mode.name === DEFAULT_VALUE ? mode.name + ' (default)' : mode.name;
  label.fontSize = 14;
  label.fills = [{ type: 'SOLID', color: { r: 0.29, g: 0.29, b: 0.29 } }];
  wrapper.appendChild(label);
}

return { success: true, property: PROPERTY_NAME };

} catch (e) {
  chapter.remove();
  return { error: e.message, rolledBack: true };
}
```

#### 6e: For each CHILD COMPONENT

If the `childComponents` array rebuilt in Step 4 (from `render-meta.subComponents`, constitutive sets only) is not empty, render chapters for each child component.

**Rendering mode selection:** The preferred approach is **in-context rendering** — creating parent component instances with the child's property varied on the nested instance. This shows the child property in the context of the full parent component, which matches the designer's experience.

However, use **blown-out rendering** (isolated sub-component instances created directly from the child's component set) when any of these conditions apply:

- The child was flagged for blown-out rendering in Step 4e (sparse variant matrix, interdependent constraints)
- `setProperties()` on a nested instance fails at runtime (fallback — catch the error, remove the broken chapter, and re-render blown-out)
- Multiple identical child instances exist in the parent (e.g., 4 buttons in a button group) — deduplicate to one blown-out child entry
- The user explicitly requests blown-out views

When blown-out rendering is used, create instances directly from the child's `mainComponentSetId` component set using `findVariant()` to locate the exact variant, rather than modifying nested instances. See **6e-iii** for the blown-out script template.

**Important**: Run **one `figma_execute` call per child component** (covering its variant axes chapter). If the child also has boolean properties, run a second call for the boolean chapters. This prevents timeouts.

##### 6e-i: Child variant axes (with optional off state)

**Skip coupled axes**: Before rendering each child variant axis, check if the axis has `coupled === true` (set in Step 4d-i). If so, skip it entirely — it mirrors the parent axis and adds no information.

For each remaining child component variant axis, run via `figma_execute`. When the child has a `controllingBooleanName`, the first preview shows the "off" state (controlling boolean = false), and subsequent previews show each variant option (controlling boolean = true, child variant swapped). When there is no controlling boolean, only the variant options are shown.

Replace placeholders with extracted data. Set `CONTROLLING_BOOL_RAW_KEY` to `null` if no controlling boolean was found.

```javascript
const FRAME_ID = '__FRAME_ID__';
const COMP_SET_ID = '__COMP_SET_NODE_ID__';
const CHILD_NAME = '__CHILD_LAYER_NAME__';
const MAIN_COMP_NAME = '__MAIN_COMPONENT_NAME__';
const CONTROLLING_BOOL_NAME = '__CONTROLLING_BOOL_NAME__';
const CONTROLLING_BOOL_RAW_KEY = __CONTROLLING_BOOL_RAW_KEY_OR_NULL__;
const VARIANT_AXES = __VARIANT_AXES_JSON__;
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

const frame = await figma.getNodeByIdAsync(FRAME_ID);
const chapterTemplate = frame.findOne(n => n.name === '#anatomy-section');

const compNode = await figma.getNodeByIdAsync(COMP_SET_ID);
const parentDefaultVariant = compNode.type === 'COMPONENT_SET'
  ? (compNode.defaultVariant || compNode.children[0])
  : compNode;

const LABEL_FONT = await loadFontWithFallback(FONT_FAMILY, 'Medium');

for (const axis of VARIANT_AXES) {

const chapter = chapterTemplate.clone();
chapterTemplate.parent.appendChild(chapter);
chapter.name = CHILD_NAME + ' – ' + axis.name;
chapter.visible = true;

try {

await loadAllFonts(chapter);

const sectionName = chapter.findOne(n => n.name === '#section-name');
if (sectionName) {
  const t = sectionName.findOne(n => n.type === 'TEXT');
  if (t) t.characters = CHILD_NAME + ' – ' + axis.name;
}

const sectionDesc = chapter.findOne(n => n.name === '#optional-section-description');
if (sectionDesc) {
  const t = sectionDesc.findOne(n => n.type === 'TEXT');
  const totalOptions = CONTROLLING_BOOL_RAW_KEY ? axis.options.length + 1 : axis.options.length;
  const offNote = CONTROLLING_BOOL_RAW_KEY ? ' (includes off state)' : '';
  if (t) t.characters = 'Sub-component: ' + MAIN_COMP_NAME + '. ' + totalOptions + ' options' + offNote + '. Default: ' + axis.defaultValue;
}

const assetPlaceholder = chapter.findOne(n => n.name === '#preview');
while (assetPlaceholder.children.length > 0) {
  assetPlaceholder.children[0].remove();
}
assetPlaceholder.layoutWrap = 'WRAP';
assetPlaceholder.counterAxisSpacing = assetPlaceholder.itemSpacing;

function findControllingBoolRawKey(inst) {
  for (const [rk, val] of Object.entries(inst.componentProperties)) {
    if (rk.split('#')[0] === CONTROLLING_BOOL_NAME) return rk;
  }
  return null;
}

function findNestedChild(parentInst, childLayerName) {
  const queue = [...parentInst.children];
  while (queue.length > 0) {
    const n = queue.shift();
    if (n.name === childLayerName) return n;
    if ('children' in n) queue.push(...n.children);
  }
  return null;
}

if (CONTROLLING_BOOL_RAW_KEY) {
  const wrapper = figma.createFrame();
  wrapper.name = 'No ' + CONTROLLING_BOOL_NAME;
  wrapper.layoutMode = 'VERTICAL';
  wrapper.primaryAxisAlignItems = 'CENTER';
  wrapper.counterAxisAlignItems = 'CENTER';
  wrapper.itemSpacing = 12;
  wrapper.fills = [];
  wrapper.primaryAxisSizingMode = 'AUTO';
  wrapper.counterAxisSizingMode = 'AUTO';
  assetPlaceholder.appendChild(wrapper);

  const inst = parentDefaultVariant.createInstance();
  await loadAllFonts(inst);
  wrapper.appendChild(inst);
  const boolRk = findControllingBoolRawKey(inst);
  if (boolRk) {
    inst.setProperties({ [boolRk]: false });
    await loadAllFonts(inst);
  }

  const label = figma.createText();
  label.fontName = LABEL_FONT;
  label.characters = 'No ' + CONTROLLING_BOOL_NAME + ' (default)';
  label.fontSize = 14;
  label.fills = [{ type: 'SOLID', color: { r: 0.29, g: 0.29, b: 0.29 } }];
  wrapper.appendChild(label);
}

for (const option of axis.options) {
  const wrapper = figma.createFrame();
  wrapper.name = option;
  wrapper.layoutMode = 'VERTICAL';
  wrapper.primaryAxisAlignItems = 'CENTER';
  wrapper.counterAxisAlignItems = 'CENTER';
  wrapper.itemSpacing = 12;
  wrapper.fills = [];
  wrapper.primaryAxisSizingMode = 'AUTO';
  wrapper.counterAxisSizingMode = 'AUTO';
  assetPlaceholder.appendChild(wrapper);

  const inst = parentDefaultVariant.createInstance();
  await loadAllFonts(inst);
  wrapper.appendChild(inst);

  if (CONTROLLING_BOOL_RAW_KEY) {
    const boolRk = findControllingBoolRawKey(inst);
    if (boolRk) {
      inst.setProperties({ [boolRk]: true });
      await loadAllFonts(inst);
    }
  }

  const nestedChild = findNestedChild(inst, CHILD_NAME);
  if (nestedChild && nestedChild.type === 'INSTANCE') {
    for (const [rk, val] of Object.entries(nestedChild.componentProperties)) {
      if (rk.split('#')[0] === axis.name) {
        nestedChild.setProperties({ [rk]: option });
        await loadAllFonts(inst);
        break;
      }
    }
  }

  const label = figma.createText();
  label.fontName = LABEL_FONT;
  label.characters = option === axis.defaultValue ? option + ' (default)' : option;
  label.fontSize = 14;
  label.fills = [{ type: 'SOLID', color: { r: 0.29, g: 0.29, b: 0.29 } }];
  wrapper.appendChild(label);
}

} catch (e) {
  chapter.remove();
  return { error: e.message, rolledBack: true };
}
}

return { success: true, childComponent: CHILD_NAME };
```

Replace `__COMP_SET_NODE_ID__` with the **parent** component's `compSetNodeId` (`render-meta.component.compSetNodeId`), not the child's. Set `__CONTROLLING_BOOL_RAW_KEY_OR_NULL__` to the quoted raw key string if a controlling boolean was found (e.g., `'Trailing content#6051:1'`), or `null` if none.

##### 6e-ii: Child boolean properties (in parent context)

**Skip unified sub-booleans**: Before rendering each child boolean, check if its `name` appears in the `unifiedSubBooleanNames` set built in Step 4d-iii. If so, skip it — its chapter is produced by 6f as part of a unified slot chapter.

For each remaining child boolean property, run via `figma_execute`. Each preview is a parent instance with the controlling boolean enabled and the child's boolean toggled.

```javascript
const FRAME_ID = '__FRAME_ID__';
const COMP_SET_ID = '__COMP_SET_NODE_ID__';
const CHILD_NAME = '__CHILD_LAYER_NAME__';
const MAIN_COMP_NAME = '__MAIN_COMPONENT_NAME__';
const CONTROLLING_BOOL_NAME = '__CONTROLLING_BOOL_NAME__';
const CONTROLLING_BOOL_RAW_KEY = __CONTROLLING_BOOL_RAW_KEY_OR_NULL__;
const BOOLEAN_PROPS = __BOOLEAN_PROPS_JSON__;
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

const frame = await figma.getNodeByIdAsync(FRAME_ID);
const chapterTemplate = frame.findOne(n => n.name === '#anatomy-section');

const compNode = await figma.getNodeByIdAsync(COMP_SET_ID);
const parentDefaultVariant = compNode.type === 'COMPONENT_SET'
  ? (compNode.defaultVariant || compNode.children[0])
  : compNode;

const LABEL_FONT = await loadFontWithFallback(FONT_FAMILY, 'Medium');

function findControllingBoolRawKey(inst) {
  for (const [rk, val] of Object.entries(inst.componentProperties)) {
    if (rk.split('#')[0] === CONTROLLING_BOOL_NAME) return rk;
  }
  return null;
}

function findNestedChild(parentInst, childLayerName) {
  const queue = [...parentInst.children];
  while (queue.length > 0) {
    const n = queue.shift();
    if (n.name === childLayerName) return n;
    if ('children' in n) queue.push(...n.children);
  }
  return null;
}

for (const boolProp of BOOLEAN_PROPS) {

const chapter = chapterTemplate.clone();
chapterTemplate.parent.appendChild(chapter);
chapter.name = CHILD_NAME + ' – ' + boolProp.name;
chapter.visible = true;

try {

await loadAllFonts(chapter);

const sectionName = chapter.findOne(n => n.name === '#section-name');
if (sectionName) {
  const t = sectionName.findOne(n => n.type === 'TEXT');
  if (t) t.characters = CHILD_NAME + ' – ' + boolProp.name;
}

const sectionDesc = chapter.findOne(n => n.name === '#optional-section-description');
if (sectionDesc) {
  const t = sectionDesc.findOne(n => n.type === 'TEXT');
  const defaultStr = boolProp.defaultValue ? 'true' : 'false';
  if (t) t.characters = 'Sub-component: ' + MAIN_COMP_NAME + '. Boolean toggle. Default: ' + defaultStr;
}

const assetPlaceholder = chapter.findOne(n => n.name === '#preview');
while (assetPlaceholder.children.length > 0) {
  assetPlaceholder.children[0].remove();
}
assetPlaceholder.layoutWrap = 'WRAP';
assetPlaceholder.counterAxisSpacing = assetPlaceholder.itemSpacing;

for (const boolVal of [true, false]) {
  const wrapper = figma.createFrame();
  wrapper.name = boolProp.name + ' = ' + boolVal;
  wrapper.layoutMode = 'VERTICAL';
  wrapper.primaryAxisAlignItems = 'CENTER';
  wrapper.counterAxisAlignItems = 'CENTER';
  wrapper.itemSpacing = 12;
  wrapper.fills = [];
  wrapper.primaryAxisSizingMode = 'AUTO';
  wrapper.counterAxisSizingMode = 'AUTO';
  assetPlaceholder.appendChild(wrapper);

  const inst = parentDefaultVariant.createInstance();
  await loadAllFonts(inst);
  wrapper.appendChild(inst);

  if (CONTROLLING_BOOL_RAW_KEY) {
    const boolRk = findControllingBoolRawKey(inst);
    if (boolRk) {
      inst.setProperties({ [boolRk]: true });
      await loadAllFonts(inst);
    }
  }

  const nestedChild = findNestedChild(inst, CHILD_NAME);
  if (nestedChild && nestedChild.type === 'INSTANCE') {
    for (const [rk, val] of Object.entries(nestedChild.componentProperties)) {
      if (rk.split('#')[0] === boolProp.name) {
        nestedChild.setProperties({ [rk]: boolVal });
        await loadAllFonts(inst);
        break;
      }
    }
  }

  const label = figma.createText();
  label.fontName = LABEL_FONT;
  const isDefault = boolVal === boolProp.defaultValue;
  label.characters = String(boolVal) + (isDefault ? ' (default)' : '');
  label.fontSize = 14;
  label.fills = [{ type: 'SOLID', color: { r: 0.29, g: 0.29, b: 0.29 } }];
  wrapper.appendChild(label);
}

} catch (e) {
  chapter.remove();
  return { error: e.message, rolledBack: true };
}
}

return { success: true, childComponent: CHILD_NAME };
```

Replace `__COMP_SET_NODE_ID__` with the **parent** component's `compSetNodeId`, not the child's. Set `__CONTROLLING_BOOL_RAW_KEY_OR_NULL__` to the quoted raw key string or `null`.

##### 6e-iii: Blown-out child rendering (direct sub-component instances)

When blown-out rendering is selected (per the conditions in 6e), create instances directly from the child's component set rather than modifying nested instances in a parent. This approach is immune to sparse variant matrices and nested-instance property access issues.

For each child variant axis (non-coupled), run via `figma_execute`. Replace `__SUB_COMP_SET_ID__` with the child's `mainComponentSetId`:

```javascript
const FRAME_ID = '__FRAME_ID__';
const SUB_COMP_SET_ID = '__SUB_COMP_SET_ID__';
const CHAPTER_NAME = '__CHAPTER_NAME__';
const AXIS_NAME = '__AXIS_NAME__';
const OPTIONS = __OPTIONS_JSON__;
const DEFAULT_VALUE = '__DEFAULT_VALUE__';
const BASE_PROPS = __BASE_PROPS_JSON__;
const DESCRIPTION = '__DESCRIPTION__';
const FONT_FAMILY = '__FONT_FAMILY__';

// ... page-loading block (see MCP Adapter) ...

const frame = await figma.getNodeByIdAsync(FRAME_ID);
const subCompSet = await figma.getNodeByIdAsync(SUB_COMP_SET_ID);

function findVariant(compSet, targetProps) {
  let best = null;
  let bestScore = -1;
  for (const child of compSet.children) {
    const vp = child.variantProperties || {};
    let score = 0;
    let exact = true;
    for (const [k, v] of Object.entries(targetProps)) {
      if (vp[k] === v) score++;
      else exact = false;
    }
    if (exact) return child;
    if (score > bestScore) { bestScore = score; best = child; }
  }
  return best;
}

// ... clone #anatomy-section, set section name/description, clear #preview (same pattern as 6a) ...

for (const option of OPTIONS) {
  const targetProps = { ...BASE_PROPS };
  targetProps[AXIS_NAME] = option;

  const variant = findVariant(subCompSet, targetProps);
  // ... create wrapper, create instance from variant, add label (same pattern as 6a) ...
}
```

`BASE_PROPS` should contain the default values for all OTHER variant axes of the sub-component (e.g., `{ layout: 'icon+label', size: 'medium', variant: 'primary', isDisabled: 'false', isSelected: 'true' }`). When a `constrainedBy` note exists from 3e (e.g., `isDisabled` requires `isSelected=true`), incorporate that constraint into `BASE_PROPS`.

For child **boolean** properties in blown-out mode, create an instance from the sub-component's default variant and call `inst.setProperties({ [rawKey]: boolValue })` directly on the instance (not nested). Boolean `setProperties` on a direct instance is reliable since it doesn't change the variant combination.

For **sibling boolean** combinatorial chapters in blown-out mode, follow the same pattern: create a direct instance and call `setProperties()` with the boolean raw keys for each combination.

##### 6f: Unified slot chapters (combinatorial previews)

If `unifiedSlotChapters` from Step 4d-iii is not empty, render one chapter per entry. Each chapter shows the meaningful combinations of the container boolean + its sub-booleans as a single visual exhibit.

**Blown-out adaptation**: If the child referenced by a unified slot chapter has `blownOut: true`, replace the in-context rendering pattern (parent instance + `findNestedChild` + `setProperties` on nested instance) with the blown-out pattern from 6e-iii: create instances directly from the child's `mainComponentSetId` and call `setProperties()` for the boolean combinations on the direct instance. The container boolean on/off toggle is still meaningful — for the "None" state, simply omit the instance (or show a placeholder text "Hidden").

For each unified slot chapter, run via `figma_execute`:

```javascript
const FRAME_ID = '__FRAME_ID__';
const COMP_SET_ID = '__COMP_SET_NODE_ID__';
const CHILD_NAME = '__CHILD_LAYER_NAME__';
const CHAPTER_NAME = '__CHAPTER_NAME__';
const CONTAINER_BOOL_NAME = '__CONTAINER_BOOL_NAME__';
const DEFAULT_LABEL = '__DEFAULT_LABEL__';
const PREVIEW_COMBINATIONS = __PREVIEW_COMBINATIONS_JSON__;
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

const frame = await figma.getNodeByIdAsync(FRAME_ID);
const chapterTemplate = frame.findOne(n => n.name === '#anatomy-section');

const compNode = await figma.getNodeByIdAsync(COMP_SET_ID);
const parentDefaultVariant = compNode.type === 'COMPONENT_SET'
  ? (compNode.defaultVariant || compNode.children[0])
  : compNode;

const chapter = chapterTemplate.clone();
chapterTemplate.parent.appendChild(chapter);
chapter.name = CHAPTER_NAME;
chapter.visible = true;

try {

await loadAllFonts(chapter);

const sectionName = chapter.findOne(n => n.name === '#section-name');
if (sectionName) {
  const t = sectionName.findOne(n => n.type === 'TEXT');
  if (t) t.characters = CHAPTER_NAME;
}

const sectionDesc = chapter.findOne(n => n.name === '#optional-section-description');
if (sectionDesc) {
  const t = sectionDesc.findOne(n => n.type === 'TEXT');
  if (t) t.characters = PREVIEW_COMBINATIONS.length + ' combinations. Default: ' + DEFAULT_LABEL;
}

const assetPlaceholder = chapter.findOne(n => n.name === '#preview');
while (assetPlaceholder.children.length > 0) {
  assetPlaceholder.children[0].remove();
}
assetPlaceholder.layoutWrap = 'WRAP';
assetPlaceholder.counterAxisSpacing = assetPlaceholder.itemSpacing;

function findControllingBoolRawKey(inst) {
  for (const [rk, val] of Object.entries(inst.componentProperties)) {
    if (rk.split('#')[0] === CONTAINER_BOOL_NAME) return rk;
  }
  return null;
}

function findNestedChild(parentInst, childLayerName) {
  const queue = [...parentInst.children];
  while (queue.length > 0) {
    const n = queue.shift();
    if (n.name === childLayerName) return n;
    if ('children' in n) queue.push(...n.children);
  }
  return null;
}

const LABEL_FONT = await loadFontWithFallback(FONT_FAMILY, 'Medium');

for (const combo of PREVIEW_COMBINATIONS) {
  const wrapper = figma.createFrame();
  wrapper.name = combo.label;
  wrapper.layoutMode = 'VERTICAL';
  wrapper.primaryAxisAlignItems = 'CENTER';
  wrapper.counterAxisAlignItems = 'CENTER';
  wrapper.itemSpacing = 12;
  wrapper.fills = [];
  wrapper.primaryAxisSizingMode = 'AUTO';
  wrapper.counterAxisSizingMode = 'AUTO';
  assetPlaceholder.appendChild(wrapper);

  const inst = parentDefaultVariant.createInstance();
  await loadAllFonts(inst);
  wrapper.appendChild(inst);

  const boolRk = findControllingBoolRawKey(inst);
  if (boolRk) {
    inst.setProperties({ [boolRk]: combo.containerOn });
    await loadAllFonts(inst);
  }

  if (combo.containerOn) {
    const nestedChild = findNestedChild(inst, CHILD_NAME);
    if (nestedChild && nestedChild.type === 'INSTANCE') {
      for (const [subName, subVal] of Object.entries(combo.subValues)) {
        for (const [rk, val] of Object.entries(nestedChild.componentProperties)) {
          if (rk.split('#')[0] === subName) {
            nestedChild.setProperties({ [rk]: subVal });
            break;
          }
        }
      }
      await loadAllFonts(inst);
    }
  }

  const label = figma.createText();
  label.fontName = LABEL_FONT;
  const isDefault = combo.label === DEFAULT_LABEL;
  label.characters = combo.label + (isDefault ? ' (default)' : '');
  label.fontSize = 14;
  label.fills = [{ type: 'SOLID', color: { r: 0.29, g: 0.29, b: 0.29 } }];
  wrapper.appendChild(label);
}

return { success: true, chapter: CHAPTER_NAME };

} catch (e) {
  chapter.remove();
  return { error: e.message, rolledBack: true };
}
```

Replace `__COMP_SET_NODE_ID__` with the **parent** component's `compSetNodeId`. Replace `__CHAPTER_NAME__` with the `chapterName` from the unified slot chapter entry (e.g., "Input -- Leading content"). Replace `__CHILD_LAYER_NAME__` with the child's layer `name` from the `childComponents` entry. Replace `__PREVIEW_COMBINATIONS_JSON__` with the `previewCombinations` array from the unified slot chapter entry.

##### 6g: Sibling boolean combinatorial chapters

If `siblingBoolChapters` from Step 4d-iv is not empty, render one chapter per entry. Each chapter shows the meaningful combinations of sibling booleans on the same child component as a single visual exhibit.

**Blown-out adaptation**: If the child has `blownOut: true`, use the blown-out pattern from 6e-iii: create instances directly from the child's `mainComponentSetId` and call `setProperties()` with the boolean combinations on the direct instance (no parent wrapper, no `findNestedChild`).

For each sibling boolean chapter, run via `figma_execute`:

```javascript
const FRAME_ID = '__FRAME_ID__';
const COMP_SET_ID = '__COMP_SET_NODE_ID__';
const CHILD_NAME = '__CHILD_LAYER_NAME__';
const CHAPTER_NAME = '__CHAPTER_NAME__';
const DEFAULT_LABEL = '__DEFAULT_LABEL__';
const PREVIEW_COMBINATIONS = __PREVIEW_COMBINATIONS_JSON__;
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

const frame = await figma.getNodeByIdAsync(FRAME_ID);
const chapterTemplate = frame.findOne(n => n.name === '#anatomy-section');

const compNode = await figma.getNodeByIdAsync(COMP_SET_ID);
const parentDefaultVariant = compNode.type === 'COMPONENT_SET'
  ? (compNode.defaultVariant || compNode.children[0])
  : compNode;

const chapter = chapterTemplate.clone();
chapterTemplate.parent.appendChild(chapter);
chapter.name = CHAPTER_NAME;
chapter.visible = true;

try {

await loadAllFonts(chapter);

const sectionName = chapter.findOne(n => n.name === '#section-name');
if (sectionName) {
  const t = sectionName.findOne(n => n.type === 'TEXT');
  if (t) t.characters = CHAPTER_NAME;
}

const sectionDesc = chapter.findOne(n => n.name === '#optional-section-description');
if (sectionDesc) {
  const t = sectionDesc.findOne(n => n.type === 'TEXT');
  if (t) t.characters = PREVIEW_COMBINATIONS.length + ' combinations. Default: ' + DEFAULT_LABEL;
}

const assetPlaceholder = chapter.findOne(n => n.name === '#preview');
while (assetPlaceholder.children.length > 0) {
  assetPlaceholder.children[0].remove();
}
assetPlaceholder.layoutWrap = 'WRAP';
assetPlaceholder.counterAxisSpacing = assetPlaceholder.itemSpacing;

function findNestedChild(parentInst, childLayerName) {
  const queue = [...parentInst.children];
  while (queue.length > 0) {
    const n = queue.shift();
    if (n.name === childLayerName) return n;
    if ('children' in n) queue.push(...n.children);
  }
  return null;
}

const LABEL_FONT = await loadFontWithFallback(FONT_FAMILY, 'Medium');

for (const combo of PREVIEW_COMBINATIONS) {
  const wrapper = figma.createFrame();
  wrapper.name = combo.label;
  wrapper.layoutMode = 'VERTICAL';
  wrapper.primaryAxisAlignItems = 'CENTER';
  wrapper.counterAxisAlignItems = 'CENTER';
  wrapper.itemSpacing = 12;
  wrapper.fills = [];
  wrapper.primaryAxisSizingMode = 'AUTO';
  wrapper.counterAxisSizingMode = 'AUTO';
  assetPlaceholder.appendChild(wrapper);

  const inst = parentDefaultVariant.createInstance();
  await loadAllFonts(inst);
  wrapper.appendChild(inst);

  const nestedChild = findNestedChild(inst, CHILD_NAME);
  if (nestedChild && nestedChild.type === 'INSTANCE') {
    for (const [subName, subVal] of Object.entries(combo.subValues)) {
      for (const [rk, val] of Object.entries(nestedChild.componentProperties)) {
        if (rk.split('#')[0] === subName) {
          nestedChild.setProperties({ [rk]: subVal });
          break;
        }
      }
    }
    await loadAllFonts(inst);
  }

  const label = figma.createText();
  label.fontName = LABEL_FONT;
  const isDefault = combo.label === DEFAULT_LABEL;
  label.characters = combo.label + (isDefault ? ' (default)' : '');
  label.fontSize = 14;
  label.fills = [{ type: 'SOLID', color: { r: 0.29, g: 0.29, b: 0.29 } }];
  wrapper.appendChild(label);
}

return { success: true, chapter: CHAPTER_NAME };

} catch (e) {
  chapter.remove();
  return { error: e.message, rolledBack: true };
}
```

Replace `__COMP_SET_NODE_ID__` with the **parent** component's `compSetNodeId`. Replace `__CHAPTER_NAME__` with the `chapterName` from the sibling boolean chapter entry (e.g., "Label"). Replace `__CHILD_LAYER_NAME__` with the child's layer `name`. Replace `__PREVIEW_COMBINATIONS_JSON__` with the `previewCombinations` array. Replace `__DEFAULT_LABEL__` with the `defaultLabel` value.

#### 6d: Clean up

After all properties are rendered (including child component chapters), hide the original `#anatomy-section`:

```javascript
const frame = await figma.getNodeByIdAsync('__FRAME_ID__');
const chapterTemplate = frame.findOne(n => n.name === '#anatomy-section');
if (chapterTemplate) chapterTemplate.visible = false;
return { success: true };
```

### Step 10: Visual Validation

1. `figma_take_screenshot` with the `frameId` — Capture the completed annotation
2. Verify:
   - Each variant axis has a section with instance previews for every option
   - Each boolean has a section showing on/off states (excluding controlling booleans merged into child chapters, and sibling booleans collapsed into combinatorial chapters)
   - Each variable mode property has a section with visual instance previews per mode
   - Each child component chapter shows the child property varied — either as in-context parent instances or as blown-out sub-component instances (see 6e for mode selection criteria). Verify the chosen mode matches the conditions.
   - Child chapters with a controlling boolean include an "off" state labeled "No {booleanName}" as the first preview (in-context mode only)
   - Labels indicate defaults
   - Component instances render correctly
   - Child component chapter titles use the `controllingBooleanName` (e.g., "Trailing content") rather than the raw layer name (e.g., "trailingContent v2") when a controlling boolean exists. If a title shows an internal layer name (camelCase, version suffixes like "v2"), rename the chapter and its `#section-name` text to use the controlling boolean name instead.
   - All preview items fit within the preview area without being clipped. Wrapping is always enabled, but if items are still too wide for a single row even individually, reduce `itemSpacing` or check that instances are not unexpectedly large.
   - When `contextAxis` is non-null: each illustrated chapter shows grouped rows per context value, with row labels. Row labels use the context value name, with "(default)" appended to the default value. The context axis itself has NO standalone chapter.
3. If issues are found, fix via `figma_execute` and re-capture (up to 3 iterations)

### Step 11: Completion Link

Print a clickable Figma URL to the completed spec in chat. Construct the URL from the `fileKey` (`render-meta.fileKey`) and the `frameId` (returned by Step 7), replacing `:` with `-` in the node ID. **Provenance footer:** also report the `sourceHash` recorded from `render-meta` (Step 0) so downstream readers can detect drift between this render and the `_base.json` that produced the `.md`:

```
Property spec complete: https://www.figma.com/design/{fileKey}/?node-id={frameId}
Source: {mdPath} (render-meta sourceHash: {sourceHash})
```

## Notes

- **This skill consumes the component `.md`** (the source of truth produced by the `create-component-md` skill) and rebuilds its property model from the `.md`'s `render-meta` block — `compSetNodeId`, variant axes, boolean defs, slot contents, instance-swaps, and constitutive sub-components all come from `render-meta`. It does NOT extract the property surface from Figma — see the Step 0 FORBIDDEN directive. **Asymmetry:** the `.md` has no Property body section, so this skill takes identity only from `render-meta` and still authors its own property model + exhibit plans (Steps 4–4e) with light in-memory reasoning.
- The ONLY Figma reads beyond the render scripts are the two bounded whitelisted live reads: the **variant-gated-boolean scan** (Step 4a, read #2) and the **variable-collection lookup** (Step 4b, read #1). Normalization (4d) and exhibit planning (4e) run entirely in memory.
- **Scope limit:** only constitutive sub-component-SETS (`render-meta.subComponents` entries with a non-null `subCompSetId`) get full child chapters. Deeper/non-constitutive child surfaces degrade gracefully with a note rather than being re-extracted.
- See the instruction file ([agent-property-instruction.md](../../../references/property/agent-property-instruction.md)) for implementation notes, normalization reference, rendering mode selection guidance, common mistakes, and do-not rules.
