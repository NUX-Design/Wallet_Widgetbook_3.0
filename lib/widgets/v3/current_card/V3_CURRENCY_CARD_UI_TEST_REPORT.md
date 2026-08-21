# Currency Card — UI Test Report

วันที่ทดสอบ: `2026-08-22`

## Scope

ตรวจ UI ของ `V3CurrencyCard` จาก preview จริงบน iOS Simulator ครอบคลุม:

- Theme: `Light`, `Dark`
- Display state: `Show`, `Hide`, `Error`
- Multiple currencies: `GBP`, `USD`, `CNY`, `EUR`
- Tap action ของ currency cards
- การอัปเดต display card และข้อความสถานะ
- Accessibility hierarchy และ tap targets

## Test Environment

| รายการ | ค่า |
|---|---|
| Automation | Maestro MCP |
| Device | iPhone 17 Pro Max |
| iOS | 26.5 |
| Device ID | `D471C549-DED4-42CF-A194-A881E22A0E72` |
| App ID | `com.example.mcpTestApp` |
| Preview | `preview_v3_currency_card.dart` |

## Test Matrix

| Theme | Show | Hide | Error |
|---|---:|---:|---:|
| Light | GBP/USD/CNY/EUR ผ่าน | GBP/USD/CNY/EUR ผ่าน | GBP/USD/CNY/EUR ผ่าน |
| Dark | GBP/USD/CNY/EUR ผ่าน | GBP/USD/CNY/EUR ผ่าน | GBP/USD/CNY/EUR ผ่าน |

รวมการตรวจ action ทั้งหมด `2 × 3 × 4 = 24 cases` และ flow รวม `59 commands` — **ผ่านทั้งหมด**

## Verified Behaviors

- กด currency card ใน `Multiple currencies` ได้ครบทั้ง 4 ใบ
- เมื่อกด card แล้วแสดงข้อความ `Tapped currency: <currency>` ถูกต้อง
- เมื่อกด card ด้านล่าง ข้อมูลจะอัปเดตขึ้น display card ด้านบน
- Display card ด้านบนเป็น display-only และไม่เป็น tap target
- `Show` แสดงจำนวนเงินพร้อมทศนิยม 2 ตำแหน่ง
- `Hide` แสดง `*` และ `.**`
- `Error` แสดง `-`
- Light/Dark เปลี่ยน theme ได้และยังคงใช้งาน tap action ได้
- Maestro สามารถแยก accessibility target ของ GBP/USD/CNY/EUR ได้หลังเพิ่ม explicit semantics container

## Maestro Inspection Evidence

จาก `inspect_screen` พบ tap targets:

- `Light`, `Dark`
- `Show`, `Hide`, `Error`
- `GBP currency card`
- `USD currency card`
- `CNY currency card`
- `EUR currency card`

Display card หลักมี `enabled: false` และไม่ปรากฏเป็น tap target ซึ่งตรงตาม behavior ที่กำหนด

## Additional Verification

```text
flutter analyze: No issues found
flutter test test/widgets/v3/current_card/v3_currency_card_test.dart: 5 tests passed
Maestro flow: success, 59 commands executed
```

Maestro Viewer ระหว่างตรวจ: <http://127.0.0.1:10001/>

## Source Files

- `v3_currency_card.dart` — reusable widget และ `onTap`/semantics
- `preview_v3_currency_card.dart` — Light/Dark, state matrix และ interaction preview
- `v3_currency_card_test.dart` — targeted widget tests
- `currency-card.md` — generated component specification
