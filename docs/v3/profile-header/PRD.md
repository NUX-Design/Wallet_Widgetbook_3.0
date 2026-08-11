# PRD: Flutter Widget V3 — Profile Header (PRD-ID: PRD--001)

- เวอร์ชัน: 1.0
- สถานะ: Draft
- Owner: Design Systems Team
- อัปเดตล่าสุด: 2026-08-11
- Design source: Wi Design System Figma component set `Profile Header` (`617:235`)

## 1. Product Context

`V3ProfileHeader` คือ reusable Flutter widget ใน Wi Design System V3 สำหรับแสดงตัวตนผู้ใช้ สถานะการยืนยันตัวตน balance แบบย่อในบริบทที่ scroll แล้ว และ action สำหรับเปิดการแจ้งเตือน โดยใช้ semantic tokens และ component conventions เดียวกับ Widget V3 อื่นในระบบ

งานนี้เกิดขึ้นเพื่อแปลง Figma component set ให้เป็น implementation ที่ทีมผลิตภัณฑ์นำกลับไปใช้ได้อย่างสม่ำเสมอ รองรับ Light/Dark, accessibility, preview และ automated tests โดยไม่ผูกข้อความหรือสีไว้ใน widget

## 2. Problem Statement

- ทีมผลิตภัณฑ์ต้องการ profile identity header ที่มีโครงสร้างและ state ตรงกับ Design System โดยไม่ต้องประกอบ avatar, ชื่อ, verification, balance และ notification action ซ้ำในแต่ละหน้าจอ
- การ implement แยกกันมีความเสี่ยงเรื่อง spacing, state mapping, Light/Dark colors, long-name overflow และ touch target ไม่ตรงกัน
- Design และ Engineering ต้องมี source/handoff artifacts และ acceptance criteria ชุดเดียวกันสำหรับตรวจสอบ Figma-to-Flutter parity

## 3. Goals & Non-goals

### Goals

- ส่งมอบ reusable `V3ProfileHeader` ที่ครอบคลุม variant axes ตาม Figma
- รักษา layout, typography, spacing และ status semantics ตาม component spec
- รองรับ Light/Dark ผ่าน Theme V3 semantic tokens
- รองรับชื่อแบบ dynamic, balance visibility และ notification action ที่ accessible
- มี preview ครบ state หลักและ targeted widget tests

### Non-goals

- ไม่รวม business logic สำหรับโหลดข้อมูล profile, balance หรือ notification
- ไม่รวม navigation, API integration หรือ state management ของแอป
- ไม่ทำให้ profile container ทั้งก้อนกดได้ เพราะ Figma extraction ยืนยันเฉพาะ notification action
- ไม่เพิ่มรูป profile จาก network; component scope ปัจจุบันใช้ fallback initials
- ไม่แก้ Theme V3 token อื่นนอกเหนือจาก `State/error`

## 4. Target Users / Personas

- Product Developer: ต้องการนำ profile header ไปใช้โดยกำหนด state และ callback ผ่าน public API ที่ชัดเจน
- UX/UI Designer / Design Systems Designer: ต้องการตรวจสอบว่า Flutter implementation รักษา variants, tokens และ geometry ตาม Figma
- QA / Accessibility Reviewer: ต้องการตรวจ state, Light/Dark, overflow, semantics และ interaction จาก preview/test ที่ทำซ้ำได้
- End User: ต้องการเห็นตัวตน สถานะการยืนยัน และ balance อย่างอ่านง่าย พร้อมเข้าถึงการแจ้งเตือน

## 5. Use Cases / Jobs To Be Done

- UC-001: ในฐานะผู้ใช้ ฉันต้องการเห็น avatar initials และชื่อ เพื่อยืนยันว่ากำลังใช้งาน profile ที่ถูกต้อง
- UC-002: ในฐานะผู้ใช้ ฉันต้องการเห็นสถานะ `pending`, `error` หรือ `success` เพื่อเข้าใจสถานะการยืนยันตัวตน
- UC-003: ในฐานะผู้ใช้ ฉันต้องการเห็นหรือซ่อน balance ใน scrolled layout เพื่อรักษาบริบทและความเป็นส่วนตัว
- UC-004: ในฐานะผู้ใช้ ฉันต้องการกด notification action เพื่อให้แอปเรียก workflow การแจ้งเตือน
- UC-005: ในฐานะ developer/designer ฉันต้องการ preview ทุก state ใน Light/Dark เพื่อ review component ได้อย่างสม่ำเสมอ

## 6. Assumptions / Constraints / Dependencies

- ใช้ Theme V3 ผ่าน `V3ThemeScope`; ห้าม hardcode design colors หรือ fallback ไป legacy theme
- ใช้ `V3LucideIcon` สำหรับ verification และ notification icons
- Caller รับผิดชอบการ format/localize `userName`, `balanceAmount`, semantic label, hint และ tooltip
- `balanceVisibility` มีผลเฉพาะเมื่อ `layoutState == scrolled`
- Figma component source คือ node `617:235`; local component markdown และ guide เป็น handoff source ใกล้ implementation ที่สุด
- `State/error` ใช้ semantic token กลางที่ reconcile จาก Figma แล้ว: Light `Red/600` และ Dark `Red/500`

## 7. Functional Requirements

### FR--001: แสดงข้อมูลตัวตน

- Widget ต้องแสดง avatar initials และ `userName`
- Use cases ที่เกี่ยวข้อง: [UC-001]
- Problems ที่เกี่ยวข้อง: การประกอบ profile identity ซ้ำและ layout ไม่สม่ำเสมอ
- ผู้ใช้งานหลัก / actor หลัก: End User, Product Developer
- Triggers / inputs: `avatarInitials`, `userName`
- ผลลัพธ์ที่คาดหวัง: identity content แสดงใน leading zone โดยชื่อไม่ดัน notification action ออกจากจอ

### FR--002: แสดง verification status

- Widget ต้องรองรับ `pending`, `error`, `success` และแสดง icon/color ที่ตรงกับ semantic state
- Use cases ที่เกี่ยวข้อง: [UC-002]
- Problems ที่เกี่ยวข้อง: status mapping ไม่สม่ำเสมอระหว่างหน้าจอ
- ผู้ใช้งานหลัก / actor หลัก: End User, Design Systems Team
- Triggers / inputs: `status`
- ผลลัพธ์ที่คาดหวัง: icon ตามสถานะวางต่อจากความกว้างจริงของชื่อด้วย gap 8px

### FR--003: รองรับ Default และ Scrolled layout

- Widget ต้องรองรับ default height 40px และ scrolled height 44px พร้อม horizontal padding 16px
- Use cases ที่เกี่ยวข้อง: [UC-001, UC-003]
- Problems ที่เกี่ยวข้อง: geometry ไม่ตรง Design System
- ผู้ใช้งานหลัก / actor หลัก: Product Developer, End User
- Triggers / inputs: `layoutState`
- ผลลัพธ์ที่คาดหวัง: layout เปลี่ยนโดยยังรักษา identity และ notification zones

### FR--004: จัดการ balance visibility

- ใน scrolled layout widget ต้องรองรับ `none`, `visible`, `obscured`
- เมื่อ `obscured` ต้องแทนตัวเลขทุกตัวใน formatted `balanceAmount` ด้วย `*` และคง punctuation/currency copy เดิม
- Use cases ที่เกี่ยวข้อง: [UC-003]
- Problems ที่เกี่ยวข้อง: balance privacy behavior ไม่สม่ำเสมอ
- ผู้ใช้งานหลัก / actor หลัก: End User, Product Developer
- Triggers / inputs: `layoutState`, `balanceVisibility`, `balanceAmount`
- ผลลัพธ์ที่คาดหวัง: balance row แสดงเฉพาะ combination ที่กำหนด

### FR--005: รองรับ notification action

- Widget ต้องเปิดให้ caller ส่ง callback, localized semantic label, optional hint และ optional tooltip
- Callback `null` ต้องทำให้ control อยู่ใน disabled semantics
- Use cases ที่เกี่ยวข้อง: [UC-004]
- Problems ที่เกี่ยวข้อง: icon-only action ไม่มี event contract หรือ accessible name ที่สม่ำเสมอ
- ผู้ใช้งานหลัก / actor หลัก: End User, Product Developer
- Triggers / inputs: `onNotificationPressed`, `notificationSemanticLabel`, `notificationSemanticHint`, `notificationTooltip`
- ผลลัพธ์ที่คาดหวัง: action มี visual icon 24px, interaction target 48×48px และเรียก callback ได้

### FR--006: มี preview และ test coverage

- Preview ต้องแสดง Default × Success/Pending/Error และ Scrolled × visible/obscured/none
- Preview ต้อง toggle Light/Dark, มี divider แยกแต่ละ case และแสดง feedback เมื่อกด notification action
- Tests ต้องตรวจ geometry, state colors, Light/Dark, balance masking, semantics, callback, long name และ dynamic 8px verification gap
- Use cases ที่เกี่ยวข้อง: [UC-005]
- Problems ที่เกี่ยวข้อง: review และ regression verification ทำซ้ำไม่ได้
- ผู้ใช้งานหลัก / actor หลัก: Design Systems Team, QA
- Triggers / inputs: standalone preview และ widget test suite
- ผลลัพธ์ที่คาดหวัง: ทุก state หลักตรวจได้ทั้งเชิง visual และ automated

## 8. Non-functional Requirements

- Performance: component ต้องเป็น stateless reusable widget และไม่ทำ network/data work ภายใน
- Reliability: state mapping และ layout ต้อง deterministic จาก public properties
- Security / privacy: obscured balance ต้องไม่ต้องรับ pre-masked copy; อย่างไรก็ตาม caller ยังเป็นผู้ถือค่าจริงใน memory ของแอป
- UX / accessibility: notification control ต้องมี localized accessible name, button semantics และ minimum target 48×48px; decorative icon ไม่ประกาศซ้ำ
- Theming: ทุกสีต้องมาจาก Theme V3 semantic tokens และรองรับ Light/Dark
- Responsive behavior: ชื่อต้อง ellipsize 1 บรรทัดเมื่อพื้นที่ไม่พอ และ notification action ต้องไม่หลุดจอ

## 9. Business Rules

- BR--001: `balanceVisibility` ถูกประเมินเฉพาะใน `scrolled` layout
- BR--002: `visible` แสดง formatted `balanceAmount` ตามที่ caller ส่งมา
- BR--003: `obscured` มาสก์ digit ทุกตัวและคง non-digit characters
- BR--004: notification bell เป็น independently focusable control เพียงจุดเดียวใน component scope ที่ยืนยันจาก design extraction
- BR--005: user-facing และ accessibility copy ต้อง localized โดย caller
- BR--006: shared semantic tokens มีอำนาจเหนือการ hardcode component-specific color workaround

## 10. User Flows (High-level)

- FLOW--001: Caller ส่ง profile data และ state → widget resolve Theme V3 → แสดง avatar/name/status → แสดง balance ตาม layout/visibility
- FLOW--002: ผู้ใช้ focus/tap notification control → widget เรียก `onNotificationPressed` → caller จัดการ navigation/action และ feedback
- FLOW--003: Reviewer เปิด preview → ตรวจ 6 cases ใน Light → toggle Dark → ตรวจซ้ำและกด notification ในแต่ละ case

## 11. Edge Cases & Error Scenarios

- ชื่อยาว: ellipsis โดยต้องรักษา verification icon gap 8px และพื้นที่ notification
- `scrolled + none`: ไม่สร้าง balance row
- `default + visible/obscured`: ไม่แสดง balance เพราะ visibility ไม่มีผลใน default layout
- `onNotificationPressed == null`: control disabled แต่ semantic label ยังคงอยู่
- `balanceAmount` มีหลายรูปแบบ locale/currency: มาสก์เฉพาะ digit และรักษา copy อื่น
- text scaling สูง: ชื่อยังจำกัด 1 บรรทัดตาม component contract
- Dark error color: ใช้ shared `state/error` ซึ่ง resolve เป็น Figma `Red/500`

## 12. Out-of-scope

- Profile image loading/caching/error fallback จาก URL
- Notification badge/count
- Profile tap action หรือ navigation
- Balance formatting, currency conversion หรือ permission logic
- Animation ระหว่าง default/scrolled
- การเปลี่ยน Theme V3 token อื่นนอกเหนือจาก `State/error`

## 13. Success Metrics

- Automated tests ของ `V3ProfileHeader` ผ่านทุก case ที่ระบุใน FR--006
- Preview แสดง 6 documented variants และ toggle Light/Dark ได้โดยไม่มี overflow/runtime error
- Design review ยืนยัน geometry, 8px dynamic gap, dividers และ semantic status mapping
- Accessibility review ยืนยัน notification button semantics และ 48×48px target
- [TO CONFIRM] adoption metric เช่นจำนวน product surfaces ที่ migrate มาใช้ component นี้

## 14. Acceptance Criteria (แยกตาม FR)

### AC--001 (สำหรับ FR--001)

GIVEN widget ได้รับชื่อสั้นหรือชื่อยาว
WHEN component render ในพื้นที่กว้าง 375px
THEN avatar มีขนาด 40×40px ชื่อแสดงหนึ่งบรรทัด และชื่อยาว ellipsize โดย notification action ยังอยู่บนจอ

### AC--002 (สำหรับ FR--002)

GIVEN status เป็น `pending`, `error` หรือ `success`
WHEN component render
THEN verification icon และ semantic state color ตรงกับแต่ละ status และ icon อยู่ห่างจากขอบขวาจริงของชื่อ 8px

### AC--003 (สำหรับ FR--003)

GIVEN layout เป็น `defaultState` หรือ `scrolled`
WHEN component render
THEN root height เท่ากับ 40px หรือ 44px ตามลำดับ และมี horizontal padding 16px

### AC--004 (สำหรับ FR--004)

GIVEN scrolled layout และ balance visibility แต่ละค่า
WHEN component render
THEN `none` ไม่มี balance row, `visible` แสดง formatted amount และ `obscured` แทน digit ทุกตัวด้วย `*`

### AC--005 (สำหรับ FR--005)

GIVEN notification callback และ localized semantic label
WHEN ผู้ใช้กด notification control
THEN callback ถูกเรียกหนึ่งครั้ง และ control ถูกประกาศเป็น enabled button ด้วย target 48×48px

### AC--006 (สำหรับ FR--005)

GIVEN notification callback เป็น `null`
WHEN accessibility tree ถูก inspect
THEN control ถูกประกาศเป็น disabled และ decorative bell icon ไม่ถูกประกาศซ้ำ

### AC--007 (สำหรับ FR--006)

GIVEN standalone preview
WHEN reviewer เปิด Light และ Dark mode
THEN พบ Default Success/Pending/Error และ Scrolled visible/obscured/none พร้อม divider และ notification action feedback ครบ

### AC--008 (สำหรับ FR--006)

GIVEN targeted widget test suite
WHEN รัน `flutter test test/widgets/v3/profile_header/v3_profile_header_test.dart`
THEN tests ผ่านโดยไม่มี exception หรือ RenderFlex overflow

## 15. Open Questions

- [TO CONFIRM] Product ต้องการรองรับ avatar image source เพิ่มเติมจาก initials ใน iteration ถัดไปหรือไม่
- [TO CONFIRM] Product ต้องการ notification badge/count เป็น component extension หรือแยก component
- [TO CONFIRM] `userName` และ verification status ควรถูกรวมเป็น semantic announcement เดียวใน product context ใดหรือไม่
- [TO CONFIRM] owner และ Jira labels/component ที่ใช้สำหรับ issue นี้

## 16. Changelog

- v1.0 — ดราฟต์จาก Figma extraction, component source, local guide, preview และ targeted tests ที่ implement แล้ว
