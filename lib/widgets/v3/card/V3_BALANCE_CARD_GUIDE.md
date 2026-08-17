# V3 Balance Card

Account balance summary card ตาม Figma component set `Balance card` (`613:700`) แสดง label, จำนวนเงินที่ซ่อน/เปิดเผยได้, currency, ลายน้ำแบรนด์แบบ decorative และปุ่มสลับการมองเห็นยอดเงิน

## Figma Source Of Truth

- Component set: [`Balance card` `613:700`](https://www.figma.com/design/mhUvPg9tOjlvQvEW6glQhJ/Wi-Design-System?node-id=613-700)
- Variant axes: `Theme` (Light/Dark), `Show balance` (False/True), `Error` (No — ยังไม่มี variant สำหรับ error state จริง)
- Card surface: กว้าง 343px (Figma-measured; runtime เต็มความกว้างของ parent), สูงคงที่ 147px, corner radius 24px
- Gold divider: สูง 1px เต็มความกว้าง gradient transparent → gold (`#DFAD51`) → transparent
- Content padding 24px, label↔icon gap 4px, label↔values gap 8px, amount↔currency gap 4px, balance-info↔visibility-toggle gap 8px
- Typography: label = Paragraph/tiny (12 Regular), amount = Heading/large (36 Bold), currency = Paragraph/medium (16 Regular) — ทั้งหมด match ค่า V3 semantic typography แบบ exact ไม่ต้อง override ขนาด
- Border ใช้ `Border/Primary`, ข้อความ label/currency ใช้ `Content/Secondary`, ข้อความ amount และไอคอนสลับการมองเห็นใช้ `Content/Primary`
- Gradient พื้นผิวการ์ดและ glow ไม่ได้ bind กับ semantic token ใน Figma (`boundVariableId: null`) จึงเก็บเป็นค่า hex คงที่ตามที่ตรวจสอบจริง — ไฟล์ base JSON ระบุ `angleDegrees: 9` แต่ Flutter ใช้ `Alignment.topLeft → Alignment.bottomRight` (45°) เป็นค่าประมาณเพราะ `LinearGradient` ควบคุมมุมแบบขั้นบันไดกว่า Figma
- Icon ที่อ้างอิง (referenced): `circle-alert` (info) และ `eye`/`eye-off` (visibility toggle ตาม `Show balance` axis) — ตรวจสอบผ่าน Figma `download_assets` แล้วว่าเป็น Lucide icon เป๊ะ ๆ (`stroke-width` เท่ากันตามสัดส่วน) จึง render ผ่าน `V3LucideIcon(LucideIcons.circleAlert/eye/eyeOff)` ที่ caller ส่งเข้ามา (ดู Usage); ยังไม่มี component `.md` spec แยกของตัวเอง ดู `balance-card.md` > Known gaps
- Watermark (`water_mark_logo`, `613:385`): export SVG จริงจาก Figma เก็บไว้ที่ `lib/assets/images/v3_balance_card_watermark.svg`, opacity 10% ถูก bake ไว้ในไฟล์ SVG เองแล้ว (ไม่ต้องครอบ `Opacity` เพิ่ม)

รายละเอียดเต็มอยู่ใน [`balance-card.md`](./balance-card.md)

## Usage

```dart
V3BalanceCard(
  label: localizedAvailableBalanceLabel,
  amount: formattedAmount,
  currency: 'THB',
  isBalanceVisible: isBalanceVisible,
  onToggleVisibility: () => setState(() => isBalanceVisible = !isBalanceVisible),
  visibilityIcon: V3LucideIcon(
    isBalanceVisible ? LucideIcons.eye : LucideIcons.eyeOff,
    size: V3IconSize.medium,
  ),
  onInfoTap: () => showBalanceInfoSheet(context),
  infoIcon: const V3LucideIcon(LucideIcons.circleAlert, size: V3IconSize.small),
)
```

`visibilityIcon` เป็น `Widget` ที่ caller ต้องส่งเสมอ (widget เองไม่ import icon library ตาม convention เดียวกับ `V3Header`/`V3Navigation`/`V3IconButton`) — caller เป็นเจ้าของ `isBalanceVisible` อยู่แล้วจึงสลับ glyph ได้ตรงไปตรงมา ถ้าไม่ต้องการไอคอน info ให้ละ `onInfoTap`/`infoIcon` (หรือส่ง `null`) แถวไอคอนและช่องว่างจะไม่ถูก render:

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
)
```

## Public API

### `V3BalanceCard`

| Property | Type | Description |
|---|---|---|
| `label` | `String` | ข้อความ label เหนือยอดเงิน (caller-owned, ต้อง localize) |
| `amount` | `String` | ยอดเงินที่ format แล้ว; ถูก mask เป็น `"**.**"` เมื่อ `isBalanceVisible == false` |
| `currency` | `String` | รหัสสกุลเงิน เช่น `"THB"` |
| `isBalanceVisible` | `bool` | map ตรงกับ Figma `Show balance` axis; คุมทั้งข้อความ mask และ glyph eye/eye-off |
| `onToggleVisibility` | `VoidCallback` | callback เมื่อกดปุ่มสลับการมองเห็น |
| `visibilityIcon` | `Widget` | glyph ของปุ่มสลับการมองเห็น (caller-owned, ต้องส่งเสมอ) — caller สลับ `V3LucideIcon(LucideIcons.eye/eyeOff)` ตาม `isBalanceVisible` เอง |
| `onInfoTap` | `VoidCallback?` | เมื่อไม่เป็น `null` (และ `infoIcon` ไม่เป็น `null` ด้วย) จะแสดงไอคอน info ข้าง label |
| `infoIcon` | `Widget?` | glyph ของไอคอน info (caller-owned) เช่น `V3LucideIcon(LucideIcons.circleAlert)` |
| `hasError` | `bool` | สำรองไว้สำหรับ Figma `Error` variant ในอนาคต; ปัจจุบันยังไม่มีผลต่อ visual (ดู Known gaps ใน `balance-card.md`) |

## Variants And Behavior

- รองรับ 4 measured compositions จาก Figma: Theme×Show-balance (Light/Dark × Hidden/Revealed); `Error` มีแค่ค่า `No` ในข้อมูลที่ extract มา
- ความสูงคงที่ 147px (ไม่รวม gold divider 1px ด้านบน); ความกว้างขึ้นกับ parent ไม่ fix ตาม Figma 343px
- Amount ถูก mask เป็น `"**.**"` เมื่อ `isBalanceVisible == false`; glyph ของปุ่มสลับสอดคล้องกับ Figma `eye-off`/`eye` เป๊ะ ๆ
- ไอคอน info เป็น optional slot: แสดงเมื่อ `onInfoTap != null` เท่านั้น พร้อมช่องว่าง 4px จาก label
- `Semantics` composed label เดียวสำหรับทั้ง card ("`label`: `amount currency`" หรือ "Hidden"); ปุ่มสลับการมองเห็นมี semantics ของตัวเองแยกออกมาและซ่อน glyph ภายในจาก accessibility tree
- สีทั้งหมด (border, ข้อความ) ผ่าน `V3ThemeScope.colorsOf(context)`; gradient พื้นผิว/glow เป็นค่า hex คงที่ (ยังไม่มี semantic token ผูกอยู่ใน Figma)
- component ไม่ hardcode ข้อความ; caller เป็นเจ้าของ localized `label`/`amount`/`currency`
- component ไม่ import icon library เอง; ไอคอน info และ visibility เป็น injectable `Widget` slot (`infoIcon`/`visibilityIcon`) ตาม convention เดียวกับ `V3Header`/`V3Navigation`/`V3IconButton` — caller ส่ง `V3LucideIcon(LucideIcons.circleAlert/eye/eyeOff)` ที่ตรวจสอบแล้วว่าตรงกับ glyph จริงใน Figma

## Token Audit

| Token | Usage |
|---|---|
| `border/primary` | Card border stroke (Light `#DDE8FB` / Dark `#334155`) |
| `content/primary` | Amount text และ visibility toggle icon |
| `content/secondary` | Label และ currency text, info icon |
| `heading/large` | Amount typography (36/Bold — exact match, ไม่ override ขนาด) |
| `paragraph/tiny` | Label typography (12/Regular — exact match) |
| `paragraph/medium` | Currency typography (16/Regular — exact match) |
| `shadow/md` (`V3PrimitiveShadows.md`) | Card drop shadow (2-layer, ตรงกับ Figma เป๊ะทั้ง offset/blur/spread/สี) |
| `rounded3xl` (`V3Radii.rounded3xl`) | Card corner radius (24px) |
| `space-4` | Label↔info-icon gap, amount↔currency gap |
| `space-8` | Label-row↔values-column gap, balance-info↔visibility-toggle gap |
| `space-24` | Card content padding |

Gradient/glow ต่อไปนี้ **ไม่ผ่าน token** เพราะ Figma ไม่ได้ bind semantic variable ให้ (measured hex เท่านั้น):

| Element | Light | Dark |
|---|---|---|
| Card gradient start | `#EFF6FF` | `#3B82F6` |
| Card gradient end | `#2563EB` | `#172554` |
| Radial glow | `#4C6EF5` → transparent | เหมือน Light |
| Gold divider mid-stop | `#DFAD51` | เหมือน Light |

Preview:

```bash
flutter run -t lib/widgets/v3/card/preview_v3_balance_card.dart
```

Preview ใช้ `background/primary`, สลับ Light/Dark แบบเต็มความกว้าง และแสดง `Action: …` เมื่อกด visibility toggle หรือ info icon เท่านั้น ตามรูปแบบเดียวกับ `V3Header` preview

## V3 Metadata

```yaml
Theme system: V3
Widget: V3BalanceCard
Category: card
Source: lib/widgets/v3/card/v3_balance_card.dart
Preview: lib/widgets/v3/card/preview_v3_balance_card.dart
Test: test/widgets/v3/card/v3_balance_card_test.dart
Design source: Figma
Figma file: Wi Design System
Figma file key: mhUvPg9tOjlvQvEW6glQhJ
Figma nodes:
  - "613:700"
Semantic tokens:
  - border/primary
  - content/primary
  - content/secondary
Dimension tokens:
  - space-4
  - space-8
  - space-24
  - rounded3xl
Typography tokens:
  - heading/large
  - paragraph/tiny
  - paragraph/medium
Effect tokens:
  - shadow/md
```
