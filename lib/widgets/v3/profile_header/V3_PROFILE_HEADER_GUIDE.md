# V3ProfileHeader

`V3ProfileHeader` คือ header แสดงตัวตนผู้ใช้ (avatar, ชื่อ, สถานะยืนยันตัวตน) พร้อม balance แบบย่อในสถานะ scrolled และปุ่มแจ้งเตือนแบบ icon-only อ้างอิง Wi Design System Figma component set `Profile Header` (`617:235`)

## Usage

```dart
V3ProfileHeader(
  status: V3ProfileHeaderStatus.success,
  layoutState: V3ProfileHeaderLayoutState.scrolled,
  balanceVisibility: V3ProfileHeaderBalanceVisibility.visible,
  userName: profile.displayName,
  avatarInitials: profile.initials,
  balanceAmount: formattedBalance,
  notificationSemanticLabel: localizations.notifications,
  onNotificationPressed: onOpenNotifications,
)
```

## Public API

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `status` | `V3ProfileHeaderStatus` | `success` | สถานะยืนยันตัวตนถาวรของโปรไฟล์ (`pending`, `error`, `success`); กำหนดไอคอนและสี verification |
| `layoutState` | `V3ProfileHeaderLayoutState` | `defaultState` | เลือก layout ปกติ (`defaultState`, สูง 40) หรือแบบย่อตอน scroll (`scrolled`, สูง 44) |
| `balanceVisibility` | `V3ProfileHeaderBalanceVisibility` | `none` | ควบคุมแถว balance; มีผลเมื่อ `layoutState` เป็น `scrolled` เท่านั้น |
| `userName` | `String` | `'–'` | ชื่อที่แสดงในแถวข้อมูลโปรไฟล์ |
| `avatarInitials` | `String` | `'CW'` | ตัวอักษรย่อที่แสดงใน avatar เมื่อไม่มีรูป |
| `balanceAmount` | `String` | `'–'` | ข้อความ balance ที่จัด format แล้ว (localized โดย caller); ใช้เมื่อ `balanceVisibility` เป็น `visible` หรือ `obscured` |
| `notificationSemanticLabel` | `String` | required | ชื่อ action ที่ localized แล้วสำหรับปุ่มแจ้งเตือน (widget นี้ไม่ hardcode ข้อความ) |
| `onNotificationPressed` | `VoidCallback?` | `null` | Callback ของปุ่มแจ้งเตือน; `null` ทำให้ disabled |
| `notificationSemanticHint` | `String?` | `null` | Localized semantic hint เพิ่มเติมของปุ่มแจ้งเตือน |
| `notificationTooltip` | `String?` | `null` | Localized tooltip ของปุ่มแจ้งเตือน |

`balanceVisibility.obscured` มาสก์ทุกตัวเลขในสตริง `balanceAmount` ด้วย `*` โดยตรง (คงเครื่องหมายวรรคตอน/ตัวอักษรสกุลเงินไว้) เพื่อไม่ต้องเพิ่ม property ใหม่และไม่ hardcode ข้อความสกุลเงินไว้ใน widget — ตัวอย่างในเอกสาร Figma แสดงผลลัพธ์แบบย่อกว่านี้เล็กน้อย (ตัด comma ออก) ถือเป็นตัวเลือกการมาสก์ระดับ illustrative ไม่ใช่สัญญา API ที่ต้อง bit-for-bit ตรงกัน

## Structure

- Root สูง 40 (default) / 44 (scrolled) ไม่มี background/border ของตัวเอง (สืบทอดพื้นหลังจาก parent) padding แนวนอน `space-16`
- Avatar 40×40 วงกลม, ระยะห่างจาก identity stack `space-8`
- แถวชื่อ: `userName` (ellipsis 1 บรรทัด) + gap `space-8` + ไอคอนยืนยันตัวตน 24×24 โดยไอคอนวางต่อท้ายความกว้างจริงของชื่อแบบ dynamic และชื่อจะย่อด้วย ellipsis เมื่อพื้นที่ไม่พอ
- Scrolled + balance ที่ไม่ใช่ `none`: เพิ่มแถว balance ใต้แถวชื่อ ด้วย gap แนวตั้ง `space-4`
- ปุ่มแจ้งเตือน: พื้นที่ interaction 48×48 วางซ้อน (Stack + `Clip.none`) เหนือพื้นที่ visual 24×24 ที่จองไว้ในแถว เพื่อคง root height ตาม Figma (40/44) พร้อมรักษา minimum touch target ตาม accessibility

## Typography

| Element | Token | Notes |
| --- | --- | --- |
| `userName` | `V3Typography.labelSmall` (14/20, weight 500) | ตรงกับ Figma `Label/Base` |
| balance text | `V3Typography.labelTiny` (12/16, weight 500) | ตรงกับ Figma `Label/Tiny` |
| avatar initials | `V3Typography.labelSmall` | Figma ไม่ได้ระบุ typography ของ avatar initials แยกไว้ (documented เป็น decorative child); เลือกใช้ scale เดียวกับ `userName` เพื่อความสมดุลของ 40px avatar |

## Color mapping

| Element | Semantic token | Notes |
| --- | --- | --- |
| Avatar background | `background/blue` | ตรงกับ Figma Light `Blue/100` / Dark `Slate/700` |
| Avatar initials, user name, notification icon, balance text | `content/primary` | ตรงกับ Figma Light `Slate/900` / Dark `White` |
| Verification icon — pending | `state/warning` | ตรงกับ Figma Light `Yellow/600` / Dark `Yellow/200` |
| Verification icon — success | `state/success` | ตรงกับ Figma Light `Green/600` / Dark `Green/300` |
| Verification icon — error | `state/error` | ตรงกับ Figma Light `Red/600` / Dark `Red/500` |

`State/error` ได้รับการ reconcile จาก Figma page `Header` (`351:3000`) แล้ว: Light alias ไป `Red/600` และ Dark alias ไป `Red/500` ผ่าน semantic token กลาง จึงมีผลสม่ำเสมอกับ Widget V3 ทุกตัวที่ใช้ `state/error`

## Icons

- Verification: `LucideIcons.shieldAlert` (pending) / `LucideIcons.shieldBan` (error) / `LucideIcons.shieldCheck` (success) ผ่าน `V3LucideIcon` ขนาด `V3IconSize.medium` (24)
- แจ้งเตือน: `LucideIcons.bell` ผ่าน `V3LucideIcon` ขนาด `V3IconSize.medium` (24) ภายในปุ่ม icon-only

## Accessibility

- ปุ่มแจ้งเตือนเป็นจุด focus แบบ interactive เพียงจุดเดียวที่ยืนยันได้จาก extraction; icon ถูก `ExcludeSemantics` เพื่อไม่ประกาศซ้ำชื่อปุ่ม
- `notificationSemanticLabel` ต้อง localized โดย caller เสมอ — widget ไม่ hardcode ข้อความ "Notifications"
- พื้นที่ interaction ของปุ่มแจ้งเตือนคงที่ 48×48 แม้ root height ของ header จะเป็น 40/44 ตาม Figma
- ชื่อผู้ใช้ตัด overflow ด้วย ellipsis บรรทัดเดียวเสมอ ป้องกันปุ่มแจ้งเตือนหลุดจอเมื่อชื่อยาวหรือ text scale สูง

## Preview annotation

Standalone preview (`preview_v3_profile_header.dart`) แสดงทุก variant หลักที่ md ระบุไว้: Default × (Success/Pending/Error), Scrolled × (Balance visible/obscured/none) พร้อม Divider คั่นแต่ละ variant, toggle Light/Dark และปุ่มแจ้งเตือนที่กดได้ทุก variant โดย feedback ด้านล่างจะแสดงชื่อ variant ล่าสุดกับจำนวน action events สำหรับ manual verification

## V3 Metadata

```yaml
Theme system: V3
Widget: V3ProfileHeader
Category: profile_header
Source: lib/widgets/v3/profile_header/v3_profile_header.dart
Preview: lib/widgets/v3/profile_header/preview_v3_profile_header.dart
Test: test/widgets/v3/profile_header/v3_profile_header_test.dart
Semantic tokens:
  - background/blue
  - content/primary
  - state/warning
  - state/success
  - state/error
```
