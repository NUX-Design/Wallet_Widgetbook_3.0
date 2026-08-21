# V3 Currency Card

Reusable Flutter Widget V3 สำหรับแสดง flag, currency code และยอดเงินแบบ compact ตาม Wi Design System

## Design reference

- Figma component: [`Currency Card`](https://www.figma.com/design/mhUvPg9tOjlvQvEW6glQhJ/Wi-Design-System?node-id=849-3263)
- Figma node: `849:3263`
- Default variant: `Property=Show` (`852:138`)
- Local component spec: [`currency-card.md`](https://github.com/NUX-Design/Wallet_Widgetbook_3.0/blob/main/lib/widgets/v3/current_card/currency-card.md)
- Implementation guide: [`V3_CURRENCY_CARD_GUIDE.md`](https://github.com/NUX-Design/Wallet_Widgetbook_3.0/blob/main/lib/widgets/v3/current_card/V3_CURRENCY_CARD_GUIDE.md)
- UI test report: [`V3_CURRENCY_CARD_UI_TEST_REPORT.md`](https://github.com/NUX-Design/Wallet_Widgetbook_3.0/blob/main/lib/widgets/v3/current_card/V3_CURRENCY_CARD_UI_TEST_REPORT.md)

## Component contract

```dart
V3CurrencyCard(
  flag: '🇬🇧',
  currencyCode: 'GBP',
  integerPart: '9,999',
  decimalPart: '.99',
  variant: CurrencyCardVariant.show,
  onTap: () {},
)
```

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `flag` | `String` | required | Flag หรือ locale marker |
| `currencyCode` | `String` | required | ISO 4217 code เช่น `GBP`, `USD`, `CNY`, `EUR` |
| `integerPart` | `String` | `9,999` | จำนวนเต็มใน `show` |
| `decimalPart` | `String` | `.99` | ทศนิยม; runtime normalize ให้แสดง 2 ตำแหน่งเสมอ |
| `variant` | `CurrencyCardVariant` | `show` | `show`, `hide` หรือ `error` |
| `onTap` | `VoidCallback?` | `null` | ทำให้ card เป็น interactive พร้อม button semantics |

## Layout and states

- Card ใช้ HUG ตามเนื้อหา และมี `minWidth: 74px` ในทุก state
- Padding `12px`, radius `12px`, border `1px`
- Flag กับ currency code มี gap `4px`; flag row กับ amount row มี gap `8px`
- `show`: แสดงจำนวนเต็มและทศนิยม 2 ตำแหน่ง
- `hide`: แสดง `*` และ `.**`
- `error`: แสดง `-`
- รองรับ Light/Dark ผ่าน Theme V3 semantic tokens; widget ไม่ hardcode สี Light/Dark

## Interaction model

ตัว preview แยกบทบาทของ card ออกเป็นสองส่วน:

1. Display card ด้านบนเป็น display-only และไม่มี `onTap`
2. Card ใน `Multiple currencies` รับ tap ทุกใบ (`GBP`, `USD`, `CNY`, `EUR`)
3. เมื่อกด card ด้านล่าง จะอัปเดตข้อมูลบน display card และแสดง `Tapped currency: <CODE>`
4. การกด card ด้านล่างไม่มี visual effect หรือ state mutation กับ card ใบอื่น นอกจากข้อมูล display card ที่ตั้งใจให้เชื่อมกัน

## Accessibility

- Interactive card ประกาศเป็น button พร้อม label `<CODE> currency card`
- Display card หลักเป็น static content และไม่เป็น tap target
- ใช้ explicit semantics container เพื่อให้แต่ละ currency card เป็น target แยกกันสำหรับ assistive technology และ UI automation
- ลำดับการอ่านคือ flag, currency code และ amount
- `hide` ไม่เปิดเผยยอดเงินจริง

## Source and preview

| Artifact | Path |
| --- | --- |
| Base JSON | `lib/widgets/v3/current_card/currency-card-_base.json` |
| Component spec | `lib/widgets/v3/current_card/currency-card.md` |
| Widget | `lib/widgets/v3/current_card/v3_currency_card.dart` |
| Preview | `lib/widgets/v3/current_card/preview_v3_currency_card.dart` |
| Guide | `lib/widgets/v3/current_card/V3_CURRENCY_CARD_GUIDE.md` |
| UI test report | `lib/widgets/v3/current_card/V3_CURRENCY_CARD_UI_TEST_REPORT.md` |
| Targeted tests | `test/widgets/v3/current_card/v3_currency_card_test.dart` |
| Preview slug | `current_card/V3CurrencyCard` |

Run the standalone preview:

```bash
flutter run -t lib/widgets/v3/current_card/preview_v3_currency_card.dart
```

Regenerate/check the V3 preview registry:

```bash
dart run tool/generate_v3_preview_registry.dart --check
```

## Verification evidence

ตรวจบน iPhone 17 Pro Max Simulator, iOS 26.5 ด้วย Maestro MCP:

- Light/Dark × Show/Hide/Error × GBP/USD/CNY/EUR ครบ `24 cases`
- Maestro flow สำเร็จ `59 commands`
- `flutter analyze` ผ่าน
- targeted Flutter tests ผ่าน `5 tests`
- ตรวจ accessibility targets ของ GBP, USD, CNY และ EUR แยกกันได้

รายละเอียดอยู่ใน [UI test report](https://github.com/NUX-Design/Wallet_Widgetbook_3.0/blob/main/lib/widgets/v3/current_card/V3_CURRENCY_CARD_UI_TEST_REPORT.md)

## Delivery status

สถานะการ publish GitHub Wiki, merge เข้า branch release และ Render preview จะเติมด้วย commit SHA และ workflow evidence หลัง external release workflow ทำงานสำเร็จ ห้ามถือเอกสารนี้เป็นหลักฐานว่า deploy แล้วก่อนตรวจ `/health`, `/info` และ preview-bundle source SHA ให้ตรงกัน
