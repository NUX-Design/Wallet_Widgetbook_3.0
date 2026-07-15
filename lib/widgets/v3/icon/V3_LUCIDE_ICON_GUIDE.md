# V3 Lucide Icon Guide

## V3LucideIcon

Adapter widget สำหรับเรียก icon จาก [Lucide](https://lucide.dev) แบบเดียวกับ Flutter `Icon` แต่ควบคุม size/stroke ผ่าน V3 dimension tokens, สืบสี/ขนาดจาก `IconTheme`/Theme V3 เท่านั้น (ไม่มี raw color parameter) และรองรับ checked-in SVG override สำหรับกรณีที่ package renderer ไม่ตรง Figma

`V3LucideIcon` เป็นไฟล์เดียวใน reusable Widget V3 catalog ที่ import `package:lucide_icons_flutter/lucide_icons.dart`/`package:flutter_svg/flutter_svg.dart` เพื่อ render icon โดยตรง — Widget V3 อื่น (`V3Navigation`, `V3MiniButton`) ต้องคง icon slot เป็น `Widget`/`Widget?` และรับ `V3LucideIcon(...)` จาก caller เท่านั้น ห้าม import package เหล่านี้เอง

ดูสถานะ implementation แบบละเอียดที่ `task/V3_LUCIDE_ICON_TASKS.md` (LI-01 ถึง LI-08) และแผนสถาปัตยกรรมที่ `docs/V3_LUCIDE_ICON_PLAN.md`

### Usage

```dart
// Package renderer (default) — inherits color/size from the nearest IconTheme.
const V3LucideIcon(
  LucideIcons.house,
  size: V3IconSize.medium,
  stroke: V3IconStroke.regular,
)

// Verified Figma-mismatch override — flutter_svg renders the checked-in
// upstream SVG instead of the package font; size/color still come from
// IconTheme.
const V3LucideIcon(
  LucideIcons.scanLine,
  size: V3IconSize.large,
  svgAsset: 'lib/assets/icons/v3/lucide/scan-line.svg',
)

// Standalone icon-only action needs a localized accessibility label.
V3LucideIcon(
  LucideIcons.search,
  semanticLabel: AppLocalizations.of(context)!.searchLabel,
)
```

### Public API

| Property | Type | Default | Description |
|---|---|---|---|
| `icon` | `IconData` | required | unsuffixed base Lucide constant, e.g. `LucideIcons.house` — never pass a weight-suffixed constant (`house100`..`house600`) directly |
| `size` | `V3IconSize?` | `null` | explicit size role; falls back to ambient `IconTheme.size`, then `V3IconSize.medium` |
| `stroke` | `V3IconStroke?` | `null` | explicit stroke role; falls back directly to `V3IconStroke.regular` (no ambient equivalent exists) |
| `svgAsset` | `String?` | `null` | checked-in Lucide SVG path under `lib/assets/icons/v3/lucide/`; when set, takes over rendering entirely and `icon`/`stroke` weight mapping is ignored |
| `semanticLabel` | `String?` | `null` | localized accessibility label for a standalone icon-only action; leave `null` when the icon is decorative inside an already-labeled parent (button, navigation destination) |

Color is intentionally **not** a constructor parameter — it always resolves from `IconTheme.of(context).color`, matching how `V3Navigation`/`V3MiniButton` already wrap their icon slots in `IconTheme`/`IconTheme.merge`.

### Token Contract

| Size role | Value | Initial usage |
|---|---:|---|
| `V3IconSize.tiny` | `V3Spacing.space12` (12px) | Mini Button icon slots |
| `V3IconSize.small` | `V3Spacing.space16` (16px) | compact controls |
| `V3IconSize.medium` | `V3Spacing.space24` (24px) | Navigation destination icons; documented V3 default |
| `V3IconSize.large` | `V3Spacing.space32` (32px) | Navigation Scan icon |

| Stroke role | Design intent | Package weight family | Verified vs. upstream |
|---|---:|---|---|
| `V3IconStroke.thin` | ~1px | `Lucide100` | approximate — no published upstream px-per-weight mapping (see LI-01 evidence) |
| `V3IconStroke.light` | ~1.5px | `Lucide300` | approximate |
| `V3IconStroke.regular` | ~2px | `Lucide` (unsuffixed base) | **verified exact match** — upstream `lucide.dev` SVGs use `stroke-width="2"` |
| `V3IconStroke.bold` | ~2.5px | `Lucide600` | approximate |

### Resolution And Render Priority

```text
Size/color resolution:  explicit property → inherited IconTheme → documented V3 default
Stroke resolution:      explicit property → documented V3 default (no IconTheme equivalent)
Render priority:        svgAsset present → flutter_svg
                         svgAsset absent  → lucide_icons_flutter package renderer
```

### Package Renderer Mechanism

`lucide_icons_flutter` (pub.dev, MIT, `^3.1.15`, SDK `^3.0.0`) exposes stroke weight as **7 separate pre-baked font families** rather than a live variable-weight parameter (the official archived `lucide-flutter` package's `Icon(weight: ...)` is confirmed broken upstream — [`lucide-icons/lucide-flutter#6`](https://github.com/lucide-icons/lucide-flutter/issues/6)). Each icon exposes one `IconData` constant per family (`house`, `house100`..`house600`), all sharing the same glyph `codePoint` but a different `fontFamily`. `V3LucideIcon` accepts only the unsuffixed base constant, keeps its `codePoint`/`fontPackage`, selects the requested weight-specific font family, and paints the glyph through `RichText` without constructing `IconData` at runtime. This preserves the simple caller API while remaining compatible with Flutter web's icon tree-shaker.

### SVG Override

Use `svgAsset` only for a **verified** Figma mismatch — do not copy the whole Lucide SVG set into the repo (see Non-Goals in `docs/V3_LUCIDE_ICON_PLAN.md`). Each checked-in file must:

- come from a **pinned upstream release tag**, not a moving branch
- be recorded in the Figma-to-Lucide mapping table below (source file, upstream name, pinned tag, license, override reason)
- render through `flutter_svg` with the same `IconTheme`-sourced size/color/semantics as the package renderer (verified by the parity tests in `test/widgets/v3/icon/v3_lucide_icon_test.dart`)

Currently checked in:

| Asset | Upstream icon | Source | Pinned version | License | Override reason |
|---|---|---|---|---|---|
| `lib/assets/icons/v3/lucide/scan-line.svg` | `scan-line` | `github.com/lucide-icons/lucide` | `1.24.0` | ISC (`Copyright (c) 2026 Lucide Icons and Contributors`) | SVG rendering pipeline proof-of-capability using the plan's own documented example; not yet tied to a confirmed Figma pixel mismatch — see LI-04 evidence in `task/V3_LUCIDE_ICON_TASKS.md`. Can be dropped without an API change once Navigation pilot verification (LI-06) confirms whether the package renderer alone is sufficient for Scan. |

### Figma-To-Lucide Mapping Template

Fill one row per Widget V3 component that adopts `V3LucideIcon`. `V3Navigation` (LI-06) is populated below; add new rows as more components adopt the adapter.

| Figma node | Component | Lucide icon | Size role | Stroke role | Renderer | Override reason |
|---|---|---|---|---|---|---|
| [`110:5384`](https://www.figma.com/design/mhUvPg9tOjlvQvEW6glQhJ/Wi-Design-System?node-id=110-5384) | `V3Navigation` Home (inactive / selected) | `LucideIcons.house` | `medium` (24px) | `regular` inactive / `bold` selected | package | — |
| [`110:5382`](https://www.figma.com/design/mhUvPg9tOjlvQvEW6glQhJ/Wi-Design-System?node-id=110-5382) | `V3Navigation` Card (inactive / selected) | `LucideIcons.creditCard` | `medium` (24px) | `regular` inactive / `bold` selected | package | — |
| [`110:5383`](https://www.figma.com/design/mhUvPg9tOjlvQvEW6glQhJ/Wi-Design-System?node-id=110-5383) | `V3Navigation` Services (inactive / selected) | `LucideIcons.layoutGrid` | `medium` (24px) | `regular` inactive / `bold` selected | package | — |
| [`110:5381`](https://www.figma.com/design/mhUvPg9tOjlvQvEW6glQhJ/Wi-Design-System?node-id=110-5381) | `V3Navigation` Menu (inactive / selected) | `LucideIcons.settings2` | `medium` (24px) | `light` (1.5px) inactive / selected | package | Exact match to Figma layer `Menu Icon` (`58:12711`): settings-2 path with 1.5px stroke; active state changes semantic color only. |
| [`110:5385`](https://www.figma.com/design/mhUvPg9tOjlvQvEW6glQhJ/Wi-Design-System?node-id=110-5385) | `V3Navigation` Scan | `LucideIcons.scanLine` | `large` (32px) | n/a (SVG override) | SVG (`scan-line.svg`) | matches the plan's own documented `svgAsset` example for this exact icon/component pairing — see the SVG Override table above; not independently re-verified against live Figma pixels in this session (no Figma tool access) |

Selected/inactive distinction: Lucide has no filled/outline icon pairs (it is a stroke-only icon set), so Home, Card, and Services currently mirror the Bold/Medium label-weight pairing by rendering the selected icon at `V3IconStroke.bold` and the inactive icon at `V3IconStroke.regular`. Menu is the verified exception: live Figma SVG node `58:12711` specifies the `settings-2` path at 1.5px, so both states use `V3IconStroke.light` and differ by semantic color only. Re-check the remaining three mappings against their live SVG nodes before treating their selected stroke change as a Figma rule.

### Accessibility

- icons in button/navigation slots are decorative by default (`semanticLabel: null`) since the parent already provides a `Semantics` node — matches `V3Navigation`'s `ExcludeSemantics`-wrapped destinations and `V3MiniButton`'s `ExcludeSemantics`-wrapped button
- a standalone icon-only action must receive a localized `semanticLabel` from the caller; no user-facing English literal is embedded in `V3LucideIcon` itself
- package and SVG renderers apply `semanticLabel` identically, verified by tests
- preview: `flutter run -t lib/widgets/v3/icon/preview_v3_lucide_icon.dart`; starts in Light and uses the toggle to switch the whole matrix (all sizes × strokes, plus the package-vs-SVG comparison) to Dark

### Token Audit Values

| Dimension token | Primitive value |
|---|---:|
| `space-12` | `12px` |
| `space-16` | `16px` |
| `space-24` | `24px` |
| `space-32` | `32px` |

## V3 Metadata

```yaml
Theme system: V3
Widget: V3LucideIcon
Category: icon
Source: lib/widgets/v3/icon/v3_lucide_icon.dart
Preview: lib/widgets/v3/icon/preview_v3_lucide_icon.dart
Test: test/widgets/v3/icon/v3_lucide_icon_test.dart
Design source: docs/V3_LUCIDE_ICON_PLAN.md (cross-cutting adapter, not a single Figma node)
Dependency: lucide_icons_flutter ^3.1.15 (MIT)
SVG override license: ISC (lucide-icons/lucide upstream)
Dimension tokens:
  - space-12
  - space-16
  - space-24
  - space-32
```
