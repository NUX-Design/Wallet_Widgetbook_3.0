# Jira Component Implementation Brief — Flutter Widget V3 Profile Header

## Jira Summary

Implement `V3ProfileHeader` จาก Wi Design System ให้เป็น reusable Flutter Widget V3 พร้อม states, Light/Dark theme, accessibility, preview และ tests

## Status

- Implementation: Done
- UI inspection: Done — Light/Dark และ documented states
- Automated tests: Passed — 11/11 เมื่อ 2026-08-11
- Preview registry: Passed — `profile_header/V3ProfileHeader`
- Documentation: Done — component spec, implementation guide และ GitHub Wiki
- Theme reconciliation: Done — `State/error` ใช้ Light `Red/600` / Dark `Red/500` ตรงกับ Figma

## Design Reference

- Component: `Profile Header`
- Figma node: [`617:235`](https://www.figma.com/design/mhUvPg9tOjlvQvEW6glQhJ/?node-id=617-235)
- Component spec: `lib/widgets/v3/profile_header/profile-header.md`
- Base JSON: `lib/widgets/v3/profile_header/profile-header-_base.json`
- Implementation guide: `lib/widgets/v3/profile_header/V3_PROFILE_HEADER_GUIDE.md`
- GitHub Wiki: [V3 Profile Header](https://github.com/NUX-Design/Wallet_Widgetbook_3.0/wiki/V3-Profile-Header)

## Objective

สร้าง reusable profile identity header สำหรับแสดง avatar initials, user name, verification status, optional balance และ notification action โดยรักษา Figma geometry, Theme V3 semantic tokens, Light/Dark behavior, accessibility และ Widget V3 delivery conventions

## Problem

การประกอบ profile header แยกในแต่ละ product surface มีความเสี่ยงที่ spacing, status mapping, theme colors, long-name behavior, balance privacy และ notification accessibility จะไม่สม่ำเสมอ จึงต้องมี component contract และ implementation กลางที่ Design, Engineering และ QA ตรวจสอบร่วมกันได้

## Target Users

- Product Developers ที่นำ component ไปประกอบใน Flutter application
- UX/UI และ Design Systems Designers ที่ตรวจ design parity
- QA และ Accessibility Reviewers ที่ตรวจ states, themes, overflow, semantics และ interaction
- End users ที่ต้องเห็น profile identity, verification, balance และ notification action อย่างชัดเจน

## Core Use Cases

- UC-001: แสดง avatar initials และชื่อของ profile ปัจจุบัน
- UC-002: แสดง verification status แบบ `pending`, `error` หรือ `success`
- UC-003: แสดง, ซ่อน หรือไม่แสดง balance ใน scrolled layout
- UC-004: เรียก notification action ผ่าน callback ที่ caller จัดการต่อ
- UC-005: ตรวจทุก documented state ใน Light/Dark จาก standalone preview

## Scope

### In scope

- Status: `pending`, `error`, `success`
- Layout: `defaultState`, `scrolled`
- Balance: `none`, `visible`, `obscured`
- Dynamic user name พร้อม one-line ellipsis
- Verification icon วางต่อจากความกว้างจริงของชื่อด้วย gap 8px
- Notification action พร้อม callback และ disabled state
- Localized semantic label, optional hint และ tooltip
- Light/Dark ผ่าน Theme V3 semantic tokens
- Standalone preview 6 cases พร้อม divider, theme toggle และ action feedback
- Targeted widget tests และ V3 preview registry
- Component handoff set และ GitHub Wiki

### Out of scope

- Profile image loading จาก network
- API, navigation และ application state management
- Notification badge/count
- Balance formatting, currency conversion หรือ permission logic
- Animation ระหว่าง default/scrolled
- Theme V3 token อื่นนอกเหนือจาก `State/error`

## Component API

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

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `status` | `V3ProfileHeaderStatus` | `success` | เลือก verification icon และ semantic state color |
| `layoutState` | `V3ProfileHeaderLayoutState` | `defaultState` | เลือก default หรือ scrolled layout |
| `balanceVisibility` | `V3ProfileHeaderBalanceVisibility` | `none` | ควบคุม balance row ใน scrolled layout |
| `userName` | `String` | `'–'` | ชื่อผู้ใช้; ellipsize เมื่อพื้นที่ไม่พอ |
| `avatarInitials` | `String` | `'CW'` | fallback initials ใน avatar |
| `balanceAmount` | `String` | `'–'` | formatted/localized balance จาก caller |
| `notificationSemanticLabel` | `String` | required | localized accessible name |
| `onNotificationPressed` | `VoidCallback?` | `null` | callback; `null` ทำให้ control disabled |
| `notificationSemanticHint` | `String?` | `null` | optional localized semantic hint |
| `notificationTooltip` | `String?` | `null` | optional localized tooltip |

## Design Specifications

| Element | Specification |
| --- | --- |
| Default root height | 40px |
| Scrolled root height | 44px |
| Horizontal padding | 16px |
| Avatar | 40×40px |
| Avatar-to-identity gap | 8px |
| Name-to-verification gap | 8px แบบ dynamic |
| Verification icon | 24×24px |
| Notification visual icon | 24×24px |
| Notification interaction target | 48×48px |
| User name typography | `V3Typography.labelSmall` — 14/20, weight 500 |
| Balance typography | `V3Typography.labelTiny` — 12/16, weight 500 |
| Balance vertical gap | 4px |

## Theme and Status Mapping

| Element / Status | Semantic token |
| --- | --- |
| Avatar background | `background/blue` |
| Avatar initials, name, balance, notification | `content/primary` |
| Pending verification | `state/warning` |
| Error verification | `state/error` |
| Success verification | `state/success` |

ทุกสี resolve ผ่าน `V3ThemeScope`; widget ไม่ hardcode Light/Dark colors และไม่ fallback ไป legacy theme

## Interaction and Accessibility

- Notification button เรียก `onNotificationPressed` เมื่อ enabled
- `notificationSemanticLabel` เป็น required localized input จาก caller
- Callback `null` แสดง disabled semantics
- Decorative bell icon ถูก exclude จาก semantics เพื่อไม่ประกาศซ้ำ
- Visual icon 24px อยู่ภายใน interaction target 48×48px
- ชื่อยาว ellipsize หนึ่งบรรทัดโดยไม่ดัน verification หรือ notification action ออกจาก viewport
- Profile container, avatar และ verification glyph ไม่ถูก infer ให้เป็น interactive controls

## Acceptance Criteria — Completed

### Component behavior

- [x] Default layout สูง 40px และไม่มี balance row
- [x] Scrolled layout สูง 44px
- [x] Root ใช้ horizontal padding 16px
- [x] Avatar มีขนาด 40×40px
- [x] รองรับ status `pending`, `error`, `success`
- [x] Verification icon และ semantic state color เปลี่ยนตาม status
- [x] Verification icon อยู่ห่างจากความกว้างจริงของชื่อ 8px ทั้งชื่อสั้นและชื่อยาว
- [x] ชื่อยาวใช้ ellipsis และไม่ดัน notification action ออกจากจอ
- [x] `visible` แสดง formatted `balanceAmount`
- [x] `obscured` มาสก์ digit ทุกตัวและคง punctuation/currency copy
- [x] `none` ไม่สร้าง balance row
- [x] Balance visibility ไม่มีผลใน default layout

### Interaction and accessibility

- [x] Notification action กดแล้วเรียก callback ได้
- [x] Notification interaction target มีขนาด 48×48px
- [x] รองรับ localized semantic label
- [x] Callback `null` แสดง disabled semantics
- [x] Decorative icon ไม่สร้าง semantic announcement ซ้ำ

### Theme and UI inspection

- [x] รองรับ Light mode ผ่าน Theme V3 semantic tokens
- [x] รองรับ Dark mode ผ่าน Theme V3 semantic tokens
- [x] Preview label รองรับ Light/Dark
- [x] มี divider แยกแต่ละ preview case
- [x] Inspect UI ครบ Default · Success/Pending/Error
- [x] Inspect UI ครบ Scrolled · Balance visible/obscured/none
- [x] ทดสอบกด notification action ใน preview และแสดงชื่อ state/จำนวน event
- [x] ไม่พบ RenderFlex overflow ใน cases ที่ทดสอบ

### Delivery artifacts

- [x] `profile-header-_base.json`
- [x] `profile-header.md`
- [x] `v3_profile_header.dart`
- [x] `preview_v3_profile_header.dart`
- [x] `V3_PROFILE_HEADER_GUIDE.md`
- [x] Targeted widget tests
- [x] V3 preview registry entry `profile_header/V3ProfileHeader`
- [x] GitHub Wiki documentation

## UI Test Coverage

| Test case | Light | Dark | Interaction | Result |
| --- | --- | --- | --- | --- |
| Default · Success | Tested | Tested | Notification tested | Pass |
| Default · Pending | Tested | Tested | Notification tested | Pass |
| Default · Error | Tested | Tested | Notification tested | Pass |
| Scrolled · Balance visible | Tested | Tested | Notification tested | Pass |
| Scrolled · Balance obscured | Tested | Tested | Notification tested | Pass |
| Scrolled · No balance row | Tested | Tested | Notification tested | Pass |

UI inspection ครอบคลุม theme toggle, labels, divider, dynamic name/status spacing, balance states และ notification action feedback บน iPhone 17 Pro Max Simulator

## Automated Test Evidence

ตรวจล่าสุดเมื่อ 2026-08-11:

```bash
flutter test test/widgets/v3/profile_header/v3_profile_header_test.dart
# 11 tests passed

dart run tool/generate_v3_preview_registry.dart --check
# registry up to date; includes profile_header/V3ProfileHeader
```

Automated coverage:

- [x] Default geometry และ no-balance behavior
- [x] Scrolled geometry และ visible balance
- [x] Scrolled + none behavior
- [x] Obscured balance digit masking
- [x] Status-to-semantic-color mapping
- [x] Dark theme avatar/name/notification color resolution
- [x] Notification semantics และ callback
- [x] Disabled notification semantics
- [x] Long-name ellipsis และ bell visibility
- [x] Dynamic name-to-verification gap 8px
- [x] Preview 6 variants, notification feedback และ Dark toggle

## Deliverables

- Widget: `lib/widgets/v3/profile_header/v3_profile_header.dart`
- Preview: `lib/widgets/v3/profile_header/preview_v3_profile_header.dart`
- Base JSON: `lib/widgets/v3/profile_header/profile-header-_base.json`
- Component spec: `lib/widgets/v3/profile_header/profile-header.md`
- Guide: `lib/widgets/v3/profile_header/V3_PROFILE_HEADER_GUIDE.md`
- Tests: `test/widgets/v3/profile_header/v3_profile_header_test.dart`
- Jira detail reference: `docs/v3/profile-header/PRD.md`
- Wiki: https://github.com/NUX-Design/Wallet_Widgetbook_3.0/wiki/V3-Profile-Header

## Follow-up

- [x] Reconcile Theme V3 `State/error` จาก Figma: Light `Red/600` / Dark `Red/500`
- [ ] [TO CONFIRM] กำหนด owner, Jira labels และ Jira component
- [ ] [TO CONFIRM] Product ต้องการ avatar image source หรือ notification badge ใน iteration ถัดไปหรือไม่

## Definition of Done

- [x] Implementation ตรงกับ documented component contract
- [x] Light/Dark UI inspection ผ่านครบทุก documented state
- [x] Interaction และ accessibility checks ผ่าน
- [x] Targeted automated tests ผ่าน 11/11
- [x] Preview registry check ผ่าน
- [x] Component handoff artifacts ครบ 5 ไฟล์
- [x] GitHub Wiki publish แล้ว
- [x] Theme V3 `State/error` ตรงกับ Figma ทั้ง Light/Dark
