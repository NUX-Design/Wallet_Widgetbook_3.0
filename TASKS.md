# Widget Test Tasks

เอกสารนี้แตกจาก [WIDGET_TEST_PLAN.md](WIDGET_TEST_PLAN.md) เป็น task backlog ที่รันงานแบบ parallel ได้

## วิธีใช้ไฟล์นี้

- `Lane A-D` คือกลุ่มงานที่ทำพร้อมกันได้
- `Depends on` คือ task ที่ควรปิดก่อน ถ้า task นั้นมีผลกับ harness หรือ asset/shared helper
- ทุก task ควรจบด้วย test file ที่ชัดเจน และระบุ case ที่ครอบคลุม light/dark หรือ locale ที่เกี่ยวข้อง

## Shared Setup

### S-01: สร้าง test harness กลาง

- [x] ทำ `pumpWidget` helper สำหรับ `MaterialApp`, `Scaffold`, theme light/dark, และ localization
- [x] ทำ helper สำหรับ modal bottom sheet / snackbar / async settle
- [x] ทำ helper สำหรับ golden snapshot ถ้าจะเริ่มส่วน visual regression

Depends on: ไม่มี

Lane: Shared

### S-02: จัด asset-heavy widget helper

- [x] สร้าง helper สำหรับ mock/pump widget ที่พึ่ง `SvgPicture`, `Image.asset`, `Lottie.asset`
- [x] ระบุ strategy ว่าจะใช้ asset จริงหรือ placeholder ใน test

หมายเหตุ: ใช้ asset จริงเป็นค่าเริ่มต้น และมี `PlaceholderAssetBundle` สำหรับเคสที่ต้องการ isolation หรือ asset-aware smoke test.

Depends on: S-01

Lane: Shared

## Lane A: Core Form Widgets

### W-01: `FullAmountInput`

- [x] ตรวจ render เริ่มต้น
- [x] ทดสอบ input รับตัวเลขและจุดทศนิยม
- [x] ทดสอบ clear button และ `onChanged`
- [x] ทดสอบ focus/error/success/disabled state

Depends on: S-01, S-02

### W-02: `MobileCodeInput`

- [x] ตรวจ render country code, flag, placeholder, counter
- [x] ทดสอบ digit-only input และ `maxLength`
- [x] ทดสอบ clear button, `onCountryCodeTap`, error state
- [x] ทดสอบ focus state และ callback `onChanged`

Depends on: S-01, S-02

### W-03: `SearchInput`

- [x] ตรวจ placeholder และ icon state
- [x] ทดสอบ focus border change
- [x] ทดสอบ clear button และ `onChanged`
- [x] ทดสอบ controller sync

Depends on: S-01, S-02

### W-04: `HorizontalTabs`

- [x] ตรวจ selected tab, pressed state, และ `showDot`
- [x] ทดสอบ tap แล้ว `onTabChanged`
- [x] ทดสอบ 2-tab / 3-tab layout

Depends on: S-01

## Lane B: Navigation / Shell / Status

### W-05: `NavigatorBar`

- [x] ตรวจ render menu ครบ 5 item
- [x] ทดสอบ scan button ตรงกลาง
- [x] ทดสอบ theme light/dark
- [x] ทดสอบ locale label และ safe area/padding
- [x] ทดสอบ opacity behavior

Depends on: S-01, S-02

### W-06: `Avatar`

- [x] ตรวจ fallback icon เมื่อไม่มีรูป
- [x] ทดสอบ asset image vs network image precedence
- [x] ทดสอบ status badge `none/danger/warning`
- [x] ทดสอบ loading skeleton และ radius scaling

Depends on: S-01, S-02

### W-07: `SnackBarWidget`

- [x] ขยาย UI test ครบทุก type
- [x] ตรวจ `show()` integration path
- [x] ทดสอบ floating behavior และ text/icon/color mapping

Depends on: S-01, S-02

## Lane C: Announcement / Feedback Components

### W-08: `AnnouncementStack`

- [x] ทดสอบ render 1/2/3 message
- [x] ทดสอบ close rotation logic และ `onClose`
- [x] ทดสอบ close button เมื่อเหลือ message เดียว
- [x] ทดสอบ `didUpdateWidget` และ loading state

Depends on: S-01, S-02

### W-09: `AnnouncementWarning`

- [x] ทดสอบ warning และ danger state
- [x] ทดสอบ title optional
- [x] ทดสอบ `descriptionSpans` เป็น RichText

Depends on: S-01

### W-10: `AnnouncementDanger`

- [x] ทดสอบสีและ icon override ของ danger state
- [x] ทดสอบ title optional
- [x] ทดสอบ `descriptionSpans`

Depends on: S-01

## Lane D: Transaction / Financial Summary

### W-11: `Buttons`

- [x] ขยาย test ครบทุก `ButtonType`
- [x] ทดสอบ enabled/disabled style ทั้ง light/dark
- [x] ทดสอบ pressed animation และ callback
- [x] ทดสอบ amount text normalization

Depends on: S-01

### W-12: `ItemList`

- [x] ทดสอบ common item + `iconPath`
- [x] ทดสอบ selected/unselected radio
- [x] ทดสอบ transaction in/out icon mapping
- [x] ทดสอบ trailing text vs amount precedence
- [x] ทดสอบ `onTap` และ ellipsis/overflow

Depends on: S-01, S-02

### W-13: `CardReviewTransaction`

- [x] ทดสอบ total, fee, detail rows, divider spacing
- [x] ทดสอบ long value handling
- [x] ทดสอบ light/dark token match

Depends on: S-01

### W-14: `DrawerBalanceDetail`

- [x] ขยาย coverage loading state และ `showButton = false`
- [x] ทดสอบ warning parsing, safe area, custom callback
- [x] ทดสอบ `show()` helper path

Depends on: S-01, S-02

### W-15: `DrawerDepositChannel`

- [x] ขยาย coverage `show()` helper, close callback, safe area
- [x] ทดสอบ bank order, labels, logo mapping

Depends on: S-01, S-02

### W-16: `DrawerReviewTransaction`

- [x] ทดสอบ warning section, transaction card, object section
- [x] ทดสอบ confirm button และ close button
- [x] ทดสอบ `show()` helper

Depends on: S-01, S-02

### W-17: `DrawerCountryCode`

- [x] ทดสอบ search filter by name/code
- [x] ทดสอบ empty state
- [x] ทดสอบ tap country -> callback + pop
- [x] ทดสอบ close button และ `show()` helper

Depends on: S-01, S-02

## Lane E: Visual / Media / Complex Layout

### W-18: `ImageCarousel`

- [x] สร้าง golden baseline light/dark
- [x] ขยาย test autoPlay, indicator state, size
- [x] ทดสอบ single page / empty pages guard ถ้าจะรองรับ
- [x] ทดสอบ timer cleanup ตอน dispose

Depends on: S-01, S-02

### W-19: `LottieSkeleton`

- [x] ทดสอบ `isLoading = false` คืน child ตรงๆ
- [x] ทดสอบ loading overlay, borderRadius, custom asset

Depends on: S-01, S-02

### W-20: `PreLoading`

- [x] ทดสอบ blur overlay และ centered animation
- [x] ทดสอบ asset path render

Depends on: S-01, S-02

### W-21: `ShortcutMenuItem`

- [x] ทดสอบ async SVG load แล้ว render
- [x] ทดสอบ custom icon override
- [x] ทดสอบ top/bottom arrow color replacement
- [x] ทดสอบ loading state

Depends on: S-01, S-02

### W-22: `VisaCard`

- [x] สร้าง golden baseline light/dark
- [x] ทดสอบ logo, expiry date, masked number, gradient card

Depends on: S-01, S-02

### W-23: `ReceiptComponent`

- [x] สร้าง golden baseline light
- [x] ทดสอบ section rendering, optional asset fallback, long text
- [x] ทดสอบ `transactionDetailRowCount`

Depends on: S-01, S-02

### W-24: `ReceiptImageComponent`

- [x] สร้าง golden baseline light
- [x] ทดสอบ header logo fallback, background fallback, long text
- [x] ทดสอบ transaction detail layout

Depends on: S-01, S-02

## Parallel Execution Map

### Batch 1: เริ่มพร้อมกันได้ทันทีหลัง Shared Setup

- `W-01 FullAmountInput`
- `W-02 MobileCodeInput`
- `W-03 SearchInput`
- `W-04 HorizontalTabs`
- `W-05 NavigatorBar`
- `W-06 Avatar`
- `W-07 SnackBarWidget`

### Batch 2: Announcement / Transaction / Drawer

- `W-08 AnnouncementStack`
- `W-09 AnnouncementWarning`
- `W-10 AnnouncementDanger`
- `W-11 Buttons`
- `W-12 ItemList`
- `W-13 CardReviewTransaction`
- `W-14 DrawerBalanceDetail`
- `W-15 DrawerDepositChannel`
- `W-16 DrawerReviewTransaction`
- `W-17 DrawerCountryCode`

### Batch 3: Visual Regression

- `W-18 ImageCarousel`
- `W-19 LottieSkeleton`
- `W-20 PreLoading`
- `W-21 ShortcutMenuItem`
- `W-22 VisaCard`
- `W-23 ReceiptComponent`
- `W-24 ReceiptImageComponent`

## แนะนำลำดับลงมือทำ

1. ปิด `S-01` และ `S-02`
2. เริ่ม Batch 1 และ Batch 2 พร้อมกัน
3. ปิด widget ที่เหลือใน Batch 3 หลังจาก harness สำหรับ golden/test asset พร้อม
4. อัปเดต `WIDGET_TEST_PLAN.md` ถ้าเจอข้อจำกัดใหม่ของ fixture หรือ asset
