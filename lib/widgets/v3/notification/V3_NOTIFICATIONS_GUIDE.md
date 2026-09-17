# V3 Notifications

Notification row สำหรับแสดงเหตุการณ์ในแอป เช่น top-up สำเร็จ โดยแปลงจาก React `NotifyUnread` และยึด Figma component set `Notifications` (`1140:2402`) เป็น source ของ geometry และ state colors

## Usage

```dart
V3Notifications(
  state: V3NotificationState.unread,
  title: 'Top-up successful',
  message: '1,000.00 THB successfully added to your wallet',
  timestamp: '2026-05-12 00:00',
  onPressed: openNotificationDetails,
)
```

Widget ใช้ `V3LucideCreditCardPlusIcon` และ `V3LucideChevronRightIcon` ภายในตาม composition ของเอกสาร โดยไม่เปิด icon slots เพราะเอกสาร Figma ไม่ได้ประกาศเป็น configurable properties ทั้งสอง adapter render จาก SVG asset ที่ export จาก Figma และเก็บไว้ที่ `lib/assets/icons/v3/lucide/`

## API

| Property | Type | Default | Description |
|---|---|---|---|
| `state` | `V3NotificationState` | `unread` | เลือกสีของ notification ระหว่าง `unread` และ `read` |
| `title` | `String` | required | หัวข้อหลัก ควรเป็น localized string |
| `message` | `String` | required | รายละเอียด notification ควรเป็น localized string |
| `timestamp` | `String` | required | เวลา/metadata ที่ format แล้ว |
| `onPressed` | `VoidCallback?` | `null` | callback เปิดรายละเอียด; `null` ทำให้ row ไม่ active |
| `semanticLabel` | `String?` | `title` | accessible name ของ row |
| `semanticHint` | `String?` | `Opens notification details` | คำแนะนำเมื่อ activate row |
| `tooltip` | `String?` | `null` | tooltip เพิ่มเติมเมื่อ caller ต้องการ |

## Geometry

- Root: 343×100px, padding 12px vertical / 16px horizontal, border 1px, radius 20px
- Inner row: 311×76px, gap 8px ระหว่าง content กับ chevron
- Notification body: gap 16px ระหว่าง icon bubble กับ text stack
- Text stack: gap 4px; title 14px/500, message และ timestamp 12px/400
- Icon bubble: 44×44px, circular; glyphs: 24×24px; `Unread` opacity 100%, `Read` opacity 50%

## Theme V3 tokens

| Role | Token |
|---|---|
| Unread surface | `backgroundWhite` |
| Read surface | `backgroundPrimary` |
| Icon bubble | `backgroundBlue` |
| Border | `borderPrimary` |
| Unread title | `contentPrimary` |
| Read title / message | `contentSecondary` |
| Timestamp | `contentNeutral` |
| Icon stroke | `contentBlue` |
| Unread chevron | `contentPrimary` |
| Read chevron | `contentSecondary` |
| Title typography | `labelSmall` |
| Message/timestamp typography | `paragraphTiny` |
| Spacing | `space-4`, `space-8`, `space-12`, `space-16` |

Figma asset provenance:

- `credit-card-plus.svg`: Figma node `1139:2375` (`Icon decoration`)
- `chevron-right.svg`: Figma component node `13:67`

The measured Figma radius is 20px; it is retained as component geometry because the current semantic radius set exposes 16px and 24px but not 20px.

## Accessibility

- รวม title, message, timestamp และ read state เป็น focus stop เดียว
- `CreditCardPlus` และ `ChevronRight` ถูกซ่อนจาก semantics เพื่อไม่ให้เกิด focus stop ซ้ำ
- เมื่อมี `onPressed` จะ expose เป็น button; `semanticLabel` ใช้ title เป็นค่าเริ่มต้น
- `message`, `timestamp` และ `Unread`/`Read` ถูกส่งเป็น semantics value
- caller ควรส่ง `semanticHint` ที่สอดคล้องกับ destination จริงเมื่อไม่ได้เปิดรายละเอียด notification

## Preview / Test

```bash
flutter run -t lib/widgets/v3/notification/preview_v3_notifications.dart
flutter test test/widgets/v3/notification/v3_notifications_test.dart
```

## Source metadata

```yaml
Theme system: V3
Widget: V3Notifications
Category: notification
Source: lib/widgets/v3/notification/v3_notifications.dart
Preview: lib/widgets/v3/notification/preview_v3_notifications.dart
Test: test/widgets/v3/notification/v3_notifications_test.dart
Base JSON: lib/widgets/v3/notification/notifications-_base.json
Design source: Figma
Figma file key: mhUvPg9tOjlvQvEW6glQhJ
Figma node: '1140:2402'
Variants: State=Unread, State=Read
```
