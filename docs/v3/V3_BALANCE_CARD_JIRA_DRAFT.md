# Jira Draft: Flutter Widget V3 Balance Card

> Draft อ้างอิงโครงสร้างจาก [`V3_WIDGET_JIRA_TEMPLATE.md`](./V3_WIDGET_JIRA_TEMPLATE.md) และ source-of-truth ของ `V3BalanceCard` ใน `lib/widgets/v3/card/` ยังไม่ใช่ Jira issue ที่สร้างแล้ว

## Jira fields

- **Summary**: `[Wi Design System] Create Flutter Widget V3 Balance Card`
- **Issue type**: Task
- **Labels**: `design-system`, `flutter`, `balance-card`, `widget-v3`
- **Priority**: Medium

## Description body

## Release Evidence

* Source PR: [#86](https://github.com/NUX-Design/Wallet_Widgetbook_3.0/pull/86)
* Release PR: [#89](https://github.com/NUX-Design/Wallet_Widgetbook_3.0/pull/89)
* Main / Render SHA: `f8b044c824c1c67339cc47f2f0fe7a7227775df5` / Render parity pending at draft time
* Render deploy: `0e29908cc23ca539a2ff70aa2a72cc223ea26627` — live, older than current `main`
* GitHub Wiki: TBD
* Main CI: Flutter CI และ V3 Preview Bundle ผ่านสำหรับ the Balance Card source commit; current promotion workflow may still be pending
* Hosted MCP: `/health` และ `/info` healthy; `previewBundle.fresh=true` for `0e29908cc23ca539a2ff70aa2a72cc223ea26627`, including `card/V3BalanceCard`

---

# Jira Component Implementation Brief — Flutter Widget V3 Balance Card

## Jira Summary

Implement `V3BalanceCard` จาก Wi Design System ให้เป็น reusable Flutter Widget V3 สำหรับแสดงยอดเงินในบัญชี รองรับยอดเงินแบบ masked/revealed, Light/Dark theme, info affordance, accessibility, standalone preview และ targeted tests

## Status

* Implementation: Done in source checkout
* UI inspection: Partial — standalone preview ตรวจบน iPhone 17 Pro Max; Light/Dark toggle และ visibility/info interactions มีใน preview
* Automated tests: Passed — 6/6 เมื่อ 2026-08-18
* Preview registry: Done — `card/V3BalanceCard`
* Documentation: Done locally — component spec, implementation guide และ this Jira draft; GitHub Wiki TBD
* Theme reconciliation: Done — semantic tokens ใช้ผ่าน `V3ThemeScope`; gradient/glow ที่ Figma ไม่ได้ bind token คงเป็น measured values ตาม source guide

## Design Reference

* Component: `Balance card`
* Figma node: [`613:700`](https://www.figma.com/design/mhUvPg9tOjlvQvEW6glQhJ/Wi-Design-System?node-id=613-700)
* Component spec: `lib/widgets/v3/card/balance-card.md`
* Base JSON: `lib/widgets/v3/card/balance-card-_base.json`
* Implementation guide: `lib/widgets/v3/card/V3_BALANCE_CARD_GUIDE.md`
* GitHub Wiki: TBD

## Objective

สร้าง reusable account balance summary card ที่รักษา Figma geometry, Theme V3 semantic tokens, Light/Dark behavior, masked/revealed balance interaction, accessibility semantics และ Widget V3 five-file delivery convention

## Problem

หลาย surface อาจประกอบ balance card เองจนเกิดความคลาดเคลื่อนของ gradient, watermark, spacing, typography, visibility state และ semantics การรวมเป็น shared Widget V3 ทำให้ implementation contract, theme mapping และ preview/test evidence ใช้ร่วมกันได้

## Target Users

* Product Developers ที่นำ card ไปประกอบใน Flutter application
* UX/UI และ Design Systems Designers ที่ตรวจ Figma parity
* QA และ Accessibility Reviewers ที่ตรวจ states, themes, semantics และ overflow
* End users ที่ต้องดูยอดเงินแบบเปิดเผยหรือซ่อนข้อมูลตาม privacy intent

## Core Use Cases

* UC-001: แสดง label, formatted amount และ currency ในสถานะซ่อนยอดเงินเริ่มต้น
* UC-002: ผู้ใช้กด visibility toggle เพื่อแสดงหรือซ่อนยอดเงิน โดย glyph และ semantics เปลี่ยนตาม state
* UC-003: ผู้ใช้เปิด Balance info affordance เมื่อ caller ส่ง callback และ icon มาให้
* UC-004: Product surface สลับ Light/Dark theme โดย card ใช้ semantic V3 tokens และ measured gradient ตาม theme

## Scope

### In scope

* Theme variants: Light และ Dark
* Balance variants: masked (`**.**`) และ revealed
* Optional info affordance ข้าง label
* Caller-owned localized `label`, formatted `amount` และ `currency`
* Caller-owned visibility/info `Widget` slots เพื่อไม่ผูก widget กับ icon library
* Gradient surface, radial glow, gold divider, watermark และ measured geometry จาก Figma
* Light/Dark token mapping ผ่าน `V3ThemeScope`
* Composed card semantics, state-aware visibility button semantics และ decorative exclusions
* Standalone preview พร้อม Light/Dark toggle และ action feedback
* Targeted widget tests และ generated V3 preview registry
* Component base JSON, Markdown spec, implementation, preview และ guide

### Out of scope

* API, navigation, data fetching และ application state management
* Currency/amount formatting logic และ localization source ownership
* Figma `Error=Yes` visual state ซึ่งยังไม่มีใน extracted component set
* Animation ระหว่าง masked/revealed states
* การสร้าง standalone specs สำหรับ referenced `circle-alert`, `eye` และ `eye-off`
* GitHub Wiki publication จนกว่าจะมี owner และ release evidence พร้อม

## Component API

```dart
V3BalanceCard(
  label: localizedAvailableBalanceLabel,
  amount: formattedAmount,
  currency: 'THB',
  isBalanceVisible: isBalanceVisible,
  onToggleVisibility: toggleVisibility,
  visibilityIcon: V3LucideIcon(
    isBalanceVisible ? LucideIcons.eye : LucideIcons.eyeOff,
    size: V3IconSize.medium,
  ),
  onInfoTap: onBalanceInfo,
  infoIcon: const V3LucideIcon(
    LucideIcons.circleAlert,
    size: V3IconSize.small,
  ),
)
```

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `label` | `String` | required | Localized label above the amount. |
| `amount` | `String` | required | Caller-formatted amount; masked as `**.**` when hidden. |
| `currency` | `String` | required | Currency code shown below the amount. |
| `isBalanceVisible` | `bool` | required | Maps to Figma `Show balance`; controls text and eye glyph supplied by caller. |
| `onToggleVisibility` | `VoidCallback` | required | Callback for the visibility control. |
| `visibilityIcon` | `Widget` | required | Caller-owned eye/eye-off glyph. |
| `onInfoTap` | `VoidCallback?` | `null` | Shows the info affordance only when `infoIcon` is also provided. |
| `infoIcon` | `Widget?` | `null` | Caller-owned info glyph. |
| `hasError` | `bool` | `false` | Reserved for a future Figma error variant; no visual effect currently. |

## Design Specifications

| Element | Specification |
| --- | --- |
| Card surface | Figma measured `343×147px`; runtime width fills the caller; `minHeight: 147px` prevents text clipping/overflow. |
| Overall composition | 1px gold divider above the card surface; total measured height `148px`. |
| Corner radius | `24px` via `V3Radii.rounded3xl`. |
| Content padding | `24px` via `V3Spacing.space24`. |
| Label/info gap | `4px` via `V3Spacing.space4`. |
| Label/values and content/toggle gaps | `8px` via `V3Spacing.space8`. |
| Visibility icon | `24×24px`; caller supplies eye/eye-off. |
| Info icon | `16×16px`; caller supplies circle-alert. |
| Label typography | `V3Typography.paragraphTiny`, `12px`, Regular. |
| Amount typography | `V3Typography.headingLarge`, `36px`, Bold. |
| Currency typography | `V3Typography.paragraphMedium`, `16px`, Regular. |
| Watermark | Checked-in `lib/assets/images/v3_balance_card_watermark.svg`, decorative, Figma opacity baked into SVG. |

## Theme and Status Mapping

| Element / Status | Semantic token or measured value |
| --- | --- |
| Card border | `border/primary` |
| Label, currency and info icon | `content/secondary` |
| Amount and visibility icon | `content/primary` |
| Typography | `heading/large`, `paragraph/tiny`, `paragraph/medium` |
| Shadow | `shadow/md` via `V3PrimitiveShadows.md` |
| Radius and spacing | `rounded3xl`, `space-4`, `space-8`, `space-24` |
| Light card gradient | Measured `#EFF6FF → #2563EB`; no Figma semantic binding |
| Dark card gradient | Measured `#3B82F6 → #172554`; no Figma semantic binding |
| Radial glow | Measured `#4C6EF5 → transparent`; no Figma semantic binding |
| Gold divider | Measured `#DFAD51` midpoint; transparent → gold → transparent |

ทุกสีที่มี semantic mapping resolve ผ่าน `V3ThemeScope`; widget ไม่ import legacy theme และไม่ hardcode tokened Light/Dark colors

## Interaction and Accessibility

* เมื่อ `isBalanceVisible=false` ให้แสดง `**.**` และ caller ควรส่ง `eye-off`; เมื่อ `true` ให้แสดง amount จริงและ caller ควรส่ง `eye`
* visibility callback เป็น required และมี button semantics state-aware: `Show balance` / `Hide balance`
* info affordance แสดงเมื่อ `onInfoTap` และ `infoIcon` ไม่เป็น `null` พร้อม semantics `Balance info`
* card มี composed semantics label เช่น `Available balance: Hidden` หรือ `Available balance: 10,000,000.00 THB`
* label, amount, currency และ decorative artwork ไม่ประกาศซ้ำใน semantics tree
* `label`, `amount` และ `currency` เป็น caller-owned strings ที่ต้อง localize/format ก่อนส่งเข้า widget
* รองรับ text scaling ด้วย `minHeight` แทน fixed clipping และต้องตรวจไม่ให้เกิด RenderFlex overflow

## Acceptance Criteria — Completed

### Component behavior

* [x] แสดง masked amount `**.**` ใน hidden state
* [x] แสดง formatted amount ใน revealed state
* [x] รองรับ Light/Dark และ measured gradient/glow/watermark
* [x] รองรับ optional info affordance และ caller-owned icon slots
* [x] `hasError` ถูกเก็บเป็น reserved API โดยไม่อ้างว่า error visual state ทำเสร็จแล้ว

### Interaction and accessibility

* [x] Visibility callback ทำงานและมี state-aware button semantics
* [x] Info callback ทำงานเฉพาะเมื่อ info affordance ถูก render
* [x] Card มี composed semantics และ decorative glyphs ไม่ประกาศซ้ำ
* [x] ไม่ผูก reusable widget กับ icon library โดยตรง

### Theme and UI inspection

* [x] รองรับ Light mode ผ่าน Theme V3 semantic tokens
* [x] รองรับ Dark mode ผ่าน Theme V3 semantic tokens
* [x] Preview มี Light/Dark toggle และ action feedback
* [ ] Inspect UI ครบทุก state พร้อม screenshot evidence ที่แนบใน Jira/Wiki
* [x] Targeted test ไม่พบ RenderFlex overflow ใน cases ที่ทดสอบ

### Delivery artifacts

* [x] `lib/widgets/v3/card/balance-card-_base.json`
* [x] `lib/widgets/v3/card/balance-card.md`
* [x] `lib/widgets/v3/card/v3_balance_card.dart`
* [x] `lib/widgets/v3/card/preview_v3_balance_card.dart`
* [x] `lib/widgets/v3/card/V3_BALANCE_CARD_GUIDE.md`
* [x] `test/widgets/v3/card/v3_balance_card_test.dart`
* [x] V3 preview registry entry `card/V3BalanceCard`
* [ ] GitHub Wiki documentation

## UI Test Coverage

| Test case | Light | Dark | Interaction | Result |
| --- | --- | --- | --- | --- |
| Masked balance and eye-off | Tested | Preview toggle available | Visibility glyph/state | Pass |
| Revealed balance and eye | Tested | Preview toggle available | Visibility glyph/state | Pass |
| Border/text token mapping | Tested | Tested | Theme mapping | Pass |
| Optional info affordance | Tested | Preview toggle available | Info callback | Pass |
| Card + composed semantics | Tested | Preview toggle available | Visibility/info callbacks | Pass |
| Standalone preview | Tested | Tested | Dark toggle + action feedback | Pass |

UI inspection: standalone preview ผ่าน iPhone 17 Pro Max; ต้องแนบ screenshot ของ documented Light/Dark และ masked/revealed statesก่อนปิด Jira task

## Automated Test Evidence

ตรวจล่าสุดเมื่อ 2026-08-18:

```bash
flutter test test/widgets/v3/card/v3_balance_card_test.dart
# All tests passed: 6 tests

dart run tool/generate_v3_preview_registry.dart --check
# registry up to date; includes card/V3BalanceCard
```

Automated coverage:

* [x] Masked/revealed amount behavior
* [x] Eye/eye-off icon mapping
* [x] Light/Dark semantic color and typography mapping
* [x] Optional info icon and callback behavior
* [x] Composed card, visibility and info semantics
* [x] Standalone preview rendering and Dark mode toggle

## Deliverables

* Widget: `lib/widgets/v3/card/v3_balance_card.dart`
* Preview: `lib/widgets/v3/card/preview_v3_balance_card.dart`
* Base JSON: `lib/widgets/v3/card/balance-card-_base.json`
* Component spec: `lib/widgets/v3/card/balance-card.md`
* Guide: `lib/widgets/v3/card/V3_BALANCE_CARD_GUIDE.md`
* Tests: `test/widgets/v3/card/v3_balance_card_test.dart`
* Wiki: TBD

## Follow-up

* [ ] Publish GitHub Wiki page with Figma and Simulator screenshots for all documented states
* [ ] Reconcile Render deployment SHA with current `main` before marking release evidence complete
* [ ] Create separate component specs for referenced `circle-alert`, `eye` and `eye-off` if those widgets are independently onboarded
* [ ] Owner: TBD
* [x] Jira labels: `design-system`, `flutter`, `balance-card`, `widget-v3`
* [ ] Iteration ถัดไปต้องรองรับ Figma `Error=Yes` เมื่อมี design variant และ behavior contract ที่ยืนยันแล้ว

## Definition of Done

* [x] Implementation ตรงกับ documented component contract
* [x] Light/Dark behavior และ targeted interaction tests ผ่าน
* [x] Accessibility semantics checks ผ่าน
* [x] Targeted automated tests ผ่าน 6/6
* [x] Preview registry check ผ่าน
* [x] Component handoff artifacts ครบ 5 ไฟล์ และ targeted test ครบ
* [ ] GitHub Wiki publish แล้ว
* [x] Theme V3 semantic token mapping ผ่าน; measured un-tokened gradients ถูกบันทึกเป็น known implementation constraint
* [ ] Render deployment parity กับ current `main` verified

## UI Reference Examples — Primary Evidence

ภาพด้านล่างเป็นหลักฐานหลักสำหรับแนบใน Jira description/Wiki ครอบคลุม Light/Dark, masked/revealed balance, visibility interaction และ standalone Web preview จาก `127.0.0.1:8090`:

### iOS Simulator — `serve-sim`

#### Light — revealed — `Action: Show balance`

![iOS Simulator Light revealed balance](</Users/Niwat.yah/Desktop/serve-sim-screenshot-2026-08-17T17-48-19-234.png>)

#### Dark — revealed — `Action: Show balance`

![iOS Simulator Dark revealed balance](</Users/Niwat.yah/Desktop/serve-sim-screenshot-2026-08-17T17-48-26-376.png>)

#### Light — masked — `Action: None`

![iOS Simulator Light masked balance](</Users/Niwat.yah/Desktop/serve-sim-screenshot-2026-08-17T17-48-10-731.png>)

#### Dark — masked — `Action: Hide balance`

![iOS Simulator Dark masked balance](</Users/Niwat.yah/Desktop/serve-sim-screenshot-2026-08-17T17-48-33-759.png>)

### Flutter Web Preview — `127.0.0.1:8090`

#### Light — revealed — `Action: Show balance`

![Flutter Web Light revealed balance](</Users/Niwat.yah/Downloads/127.0.0.1_8090_ (15).png>)

#### Dark — revealed — `Action: Show balance`

![Flutter Web Dark revealed balance](</Users/Niwat.yah/Downloads/127.0.0.1_8090_ (14).png>)

#### Light — revealed — wide layout — `Action: Show balance`

![Flutter Web Light revealed wide layout](</Users/Niwat.yah/Downloads/127.0.0.1_8090_ (12).png>)

#### Dark — masked — wide layout — `Action: None`

![Flutter Web Dark masked wide layout](</Users/Niwat.yah/Downloads/127.0.0.1_8090_ (10).png>)

#### Light — masked — wide layout — `Action: None`

![Flutter Web Light masked wide layout](</Users/Niwat.yah/Downloads/127.0.0.1_8090_ (13).png>)

#### Light — masked — compact layout — `Action: None`

![Flutter Web Light masked compact layout](</Users/Niwat.yah/Downloads/127.0.0.1_8090_ (11).png>)

#### Dark — masked — compact layout — `Action: None`

![Flutter Web Dark masked compact layout](</Users/Niwat.yah/Downloads/127.0.0.1_8090_ (9).png>)

#### Light — masked — compact layout with eye-off — `Action: None`

![Flutter Web Light masked eye off](</Users/Niwat.yah/Downloads/127.0.0.1_8090_ (8).png>)
