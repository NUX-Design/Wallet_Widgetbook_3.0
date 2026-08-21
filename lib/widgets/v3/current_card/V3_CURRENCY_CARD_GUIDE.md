# V3 Currency Card

Currency Card สำหรับแสดงธง/ตัวระบุสกุลเงินและยอดเงินแบบ compact รองรับ 3 display states: `show`, `hide` และ `error` ตาม Figma component set `Currency Card` (`849:3263`)

## Purpose And Scope

- แสดง flag marker, currency code และยอดเงินใน card ขนาดกะทัดรัด
- รองรับ Light/Dark ผ่าน `V3ThemeScope.colorsOf(context)`
- `show` แสดง integer และ decimal ที่ caller ส่งเข้ามา
- `hide` แสดงค่าปกปิดตาม behavior ปัจจุบันของ implementation (`*` และ `.**`)
- `error` แสดง `-` เป็นค่าความผิดพลาดแบบสั้น
- รองรับ optional `onTap` สำหรับ caller ที่ต้องการให้ card เป็น interactive; navigation และ business logic ยังเป็นความรับผิดชอบของ caller
- ไม่ hardcode user-facing label เพิ่มเติม; caller เป็นเจ้าของค่า flag และ currency code

## Figma Source Of Truth

- Component set: [`Currency Card`](https://www.figma.com/design/mhUvPg9tOjlvQvEW6glQhJ/Wi-Design-System?node-id=849-3263)
- Figma file: Wi Design System
- Figma file key: `mhUvPg9tOjlvQvEW6glQhJ`
- Component node: `849:3263`
- Default variant: `Property=Show` (`852:138`)
- Extracted source: [`currency-card.md`](./currency-card.md)
- Base handoff: [`currency-card-_base.json`](./currency-card-_base.json)

รายละเอียดจาก extraction ระบุ card padding `12`, outer item spacing `8`, corner radius `12`, border `1` และ gap ระหว่าง flag กับ currency code `4` (`space-4`). Runtime sizing ใช้ HUG ตามเนื้อหา โดยมี `minWidth: 74` เป็นค่าขั้นต่ำร่วมกันทุก state; เมื่อเนื้อหายาวกว่าจะขยายเกิน 74 ได้

## Usage

```dart
const V3CurrencyCard(
  flag: '🇹🇭',
  currencyCode: 'THB',
  integerPart: '12,345',
  decimalPart: '.67',
  variant: CurrencyCardVariant.show,
)
```

```dart
const V3CurrencyCard(
  flag: '🇬🇧',
  currencyCode: 'GBP',
  variant: CurrencyCardVariant.hide,
)
```

```dart
const V3CurrencyCard(
  flag: '🇬🇧',
  currencyCode: 'GBP',
  variant: CurrencyCardVariant.error,
)
```

## Public API

### `V3CurrencyCard`

| Property | Type | Required | Default | Description |
|---|---|---:|---|---|
| `flag` | `String` | yes | — | Flag emoji หรือ locale marker เช่น `🇬🇧` |
| `currencyCode` | `String` | yes | — | ISO 4217 currency code เช่น `GBP` หรือ `THB` |
| `integerPart` | `String` | no | `9,999` | ส่วนจำนวนเต็มของยอดเงินใน `show` |
| `decimalPart` | `String` | no | `.99` | ส่วนทศนิยมของยอดเงินใน `show` |
| `variant` | `CurrencyCardVariant` | no | `show` | ควบคุมการแสดงยอดเงิน |
| `onTap` | `VoidCallback?` | no | `null` | callback เมื่อกด card; เมื่อกำหนดจะ expose เป็น button semantics |

### `CurrencyCardVariant`

| Value | Behavior |
|---|---|
| `show` | แสดง `integerPart` และ `decimalPart` ที่ caller ส่งเข้ามา |
| `hide` | แสดง `*` และ `.**`; ปัจจุบันไม่ใช้ค่าจริงจาก `integerPart`/`decimalPart` |
| `error` | แสดง `-` และไม่แสดงยอดเงินจริง |

## Layout And Behavior

- Outer card ใช้ `Container` พร้อม padding `12` และ border `1px`
- Outer card ใช้ `BorderRadius.circular(12)`
- เนื้อหาจัดเรียงแนวตั้งด้วย `Column` และ gap `8`
- `Flag Row` จัด flag กับ currency code ในแนวนอนด้วย gap `4`
- flag ใช้ขนาดตัวอักษร `20`
- currency code ใช้ `Noto Sans`, `12px`, `Medium`, line height `16`
- integer amount ใช้ `Noto Sans`, `14px`, `Regular`, line height `20`
- decimal amount ใช้ `Noto Sans`, `12px`, `Regular`, line height `16`
- เมื่อกำหนด `onTap` outer card จะรับ tap และประกาศเป็น button semantics
- preview ใช้ card หลักเป็น display-only และให้ card ใน `Multiple currencies` รับ tap เพื่ออัปเดตข้อมูลของ card หลัก พร้อมข้อความสถานะที่บอกสกุลเงินที่กด
- implementation ปัจจุบันใช้ `mainAxisSize: MainAxisSize.min` และไม่กำหนด fixed width/height

## Variant Matrix

| Variant | Flag row | Amount content | Captured Figma geometry | Current Flutter behavior |
|---|---|---|---|---|
| `show` | แสดง | `integerPart` + `decimalPart` | HUG × HUG, min width 74 | HUG ตามเนื้อหา โดยไม่ต่ำกว่า 74 |
| `hide` | แสดง | `*` + `.**` | HUG × HUG, min width 74 | HUG ตามเนื้อหา โดยไม่ต่ำกว่า 74 |
| `error` | แสดง | `-` | HUG × HUG, min width 74 | HUG ตามเนื้อหา โดยไม่ต่ำกว่า 74 |

## Theme And Token Mapping

สี functional ทั้งหมดอ่านจาก `V3ThemeScope.colorsOf(context)`:

| UI element | Runtime API | Semantic intent |
|---|---|---|
| Card surface | `backgroundWhite` | `background/white` / primary surface |
| Card border | `borderPrimary` | `border/primary` |
| Currency code | `contentSecondary` | `content/secondary` |
| Integer amount | `contentPrimary` | `content/primary` |
| Decimal amount | `contentSecondary` ใน design extraction; implementation ปัจจุบันใช้ `contentPrimary` | ต้อง reconcile หากต้อง match Figma แบบ exact |

Dimension and typography evidence จาก extraction:

| Token / value | Usage |
|---|---|
| `space-4` (`4px`) | Gap ระหว่าง flag กับ currency code |
| `space-8` (`8px`) | Gap ระหว่าง flag row กับ value row |
| `rounded-xl` / radius `12px` | Outer card radius |
| `12px` | Outer card padding |
| `Noto Sans` | Currency code และ amount text ใน implementation |

ข้อสังเกต: source implementation import `v3_typography.dart` และ `v3_dimensions.dart` แต่ยังใช้ `TextStyle` และ numeric spacing inline อยู่ จึงควร migrate ไป semantic V3 typography/dimension APIs ในงาน implementation แยกต่างหาก

## Accessibility

- หากไม่กำหนด `onTap` component เป็น static informational content
- หากกำหนด `onTap` outer card จะเป็น interactive button และต้องมี action ที่คาดเดาได้
- ลำดับการอ่านที่แนะนำคือ flag → currency code → amount
- `hide` ไม่ควรประกาศยอดเงินจริงให้ assistive technology; หาก product ต้องการ accessible state label ให้ caller/integration layer เป็นผู้กำหนดตาม localization policy
- `error` ปัจจุบันมีเพียง `-` และไม่มี error message หรือ live region ใน source; ห้ามสร้างข้อความ error ขึ้นเองใน widget โดยไม่มี product copy
- ตรวจ contrast ของ `contentPrimary`, `contentSecondary`, `borderPrimary` ใน Light/Dark จาก generated V3 palette ก่อน release
- รองรับ text scaling โดยหลีกเลี่ยงการเพิ่ม fixed height ใน implementation; หากเพิ่ม fixed Figma geometry ต้องทดสอบ overflow และ large text เพิ่ม

## Preview

Source preview:

```bash
flutter run -t lib/widgets/v3/current_card/preview_v3_currency_card.dart
```

Preview ปัจจุบันมี matrix สำหรับ `show`, `hide`, `error`, multiple currencies 4 ใบ และ tap เพื่อเลือกข้อมูลไปแสดงใน card หลัก โดย discoverable ผ่าน V3 preview registry

## Tests

Targeted test อยู่ที่ `test/widgets/v3/current_card/v3_currency_card_test.dart` และครอบคลุม:

- Light/Dark semantic color mapping
- ค่า default และ behavior ของทั้ง 3 variants
- hide/error ไม่เผยยอดเงินจริง
- tap card ใน `Multiple currencies` แล้วอัปเดต card หลักและแสดงข้อความสกุลเงินที่กด; card หลักไม่รับ tap เอง
- text scaling และ overflow
- static semantics และ reading order

## Known Gaps

1. Figma ระบุ sizing baseline ที่ผู้ใช้ยืนยันเป็น `min-width: 74px` ทุก state; Flutter implementation จึงใช้ HUG พร้อม `BoxConstraints(minWidth: 74)` แทน fixed width
2. Decimal color ใน component Markdown ระบุ `content/secondary` แต่ implementation ปัจจุบันใช้ `contentPrimary`
3. Typography และ dimensions บางส่วนยังเป็น inline values แทน generated semantic V3 APIs
4. Preview เป็น standalone V3 preview และใช้ generated registry แล้ว

## V3 Metadata

```yaml
Theme system: V3
Widget: V3CurrencyCard
Category: current_card
Source: lib/widgets/v3/current_card/v3_currency_card.dart
Preview: lib/widgets/v3/current_card/preview_v3_currency_card.dart
Test: test/widgets/v3/current_card/v3_currency_card_test.dart
Design source: Figma
Figma file: Wi Design System
Figma file key: mhUvPg9tOjlvQvEW6glQhJ
Figma nodes:
  - "849:3263"
  - "852:138"
Semantic tokens:
  - background/white
  - border/primary
  - content/primary
  - content/secondary
Dimension tokens:
  - space-4
  - space-8
  - rounded-xl
```
