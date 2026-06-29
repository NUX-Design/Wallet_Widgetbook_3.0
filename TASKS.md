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

- [ ] ตรวจ render เริ่มต้น
- [ ] ทดสอบ input รับตัวเลขและจุดทศนิยม
- [ ] ทดสอบ clear button และ `onChanged`
- [ ] ทดสอบ focus/error/success/disabled state

Depends on: S-01, S-02

### W-02: `MobileCodeInput`

- [ ] ตรวจ render country code, flag, placeholder, counter
- [ ] ทดสอบ digit-only input และ `maxLength`
- [ ] ทดสอบ clear button, `onCountryCodeTap`, error state
- [ ] ทดสอบ focus state และ callback `onChanged`

Depends on: S-01, S-02

### W-03: `SearchInput`

- [ ] ตรวจ placeholder และ icon state
- [ ] ทดสอบ focus border change
- [ ] ทดสอบ clear button และ `onChanged`
- [ ] ทดสอบ controller sync

Depends on: S-01, S-02

### W-04: `HorizontalTabs`

- [ ] ตรวจ selected tab, pressed state, และ `showDot`
- [ ] ทดสอบ tap แล้ว `onTabChanged`
- [ ] ทดสอบ 2-tab / 3-tab layout

Depends on: S-01

## Lane B: Navigation / Shell / Status

### W-05: `NavigatorBar`

- [ ] ตรวจ render menu ครบ 5 item
- [ ] ทดสอบ scan button ตรงกลาง
- [ ] ทดสอบ theme light/dark
- [ ] ทดสอบ locale label และ safe area/padding
- [ ] ทดสอบ opacity behavior

Depends on: S-01, S-02

### W-06: `Avatar`

- [ ] ตรวจ fallback icon เมื่อไม่มีรูป
- [ ] ทดสอบ asset image vs network image precedence
- [ ] ทดสอบ status badge `none/danger/warning`
- [ ] ทดสอบ loading skeleton และ radius scaling

Depends on: S-01, S-02

### W-07: `SnackBarWidget`

- [ ] ขยาย UI test ครบทุก type
- [ ] ตรวจ `show()` integration path
- [ ] ทดสอบ floating behavior และ text/icon/color mapping

Depends on: S-01, S-02

## Lane C: Announcement / Feedback Components

### W-08: `AnnouncementStack`

- [ ] ทดสอบ render 1/2/3 message
- [ ] ทดสอบ close rotation logic และ `onClose`
- [ ] ทดสอบ close button เมื่อเหลือ message เดียว
- [ ] ทดสอบ `didUpdateWidget` และ loading state

Depends on: S-01, S-02

### W-09: `AnnouncementWarning`

- [ ] ทดสอบ warning และ danger state
- [ ] ทดสอบ title optional
- [ ] ทดสอบ `descriptionSpans` เป็น RichText

Depends on: S-01

### W-10: `AnnouncementDanger`

- [ ] ทดสอบสีและ icon override ของ danger state
- [ ] ทดสอบ title optional
- [ ] ทดสอบ `descriptionSpans`

Depends on: S-01

## Lane D: Transaction / Financial Summary

### W-11: `Buttons`

- [ ] ขยาย test ครบทุก `ButtonType`
- [ ] ทดสอบ enabled/disabled style ทั้ง light/dark
- [ ] ทดสอบ pressed animation และ callback
- [ ] ทดสอบ amount text normalization

Depends on: S-01

### W-12: `ItemList`

- [ ] ทดสอบ common item + `iconPath`
- [ ] ทดสอบ selected/unselected radio
- [ ] ทดสอบ transaction in/out icon mapping
- [ ] ทดสอบ trailing text vs amount precedence
- [ ] ทดสอบ `onTap` และ ellipsis/overflow

Depends on: S-01, S-02

### W-13: `CardReviewTransaction`

- [ ] ทดสอบ total, fee, detail rows, divider spacing
- [ ] ทดสอบ long value handling
- [ ] ทดสอบ light/dark token match

Depends on: S-01

### W-14: `DrawerBalanceDetail`

- [ ] ขยาย coverage loading state และ `showButton = false`
- [ ] ทดสอบ warning parsing, safe area, custom callback
- [ ] ทดสอบ `show()` helper path

Depends on: S-01, S-02

### W-15: `DrawerDepositChannel`

- [ ] ขยาย coverage `show()` helper, close callback, safe area
- [ ] ทดสอบ bank order, labels, logo mapping

Depends on: S-01, S-02

### W-16: `DrawerReviewTransaction`

- [ ] ทดสอบ warning section, transaction card, object section
- [ ] ทดสอบ confirm button และ close button
- [ ] ทดสอบ `show()` helper

Depends on: S-01, S-02

### W-17: `DrawerCountryCode`

- [ ] ทดสอบ search filter by name/code
- [ ] ทดสอบ empty state
- [ ] ทดสอบ tap country -> callback + pop
- [ ] ทดสอบ close button และ `show()` helper

Depends on: S-01, S-02

## Lane E: Visual / Media / Complex Layout

### W-18: `ImageCarousel`

- [ ] ขยาย test autoPlay, indicator state, size
- [ ] ทดสอบ single page / empty pages guard ถ้าจะรองรับ
- [ ] ทดสอบ timer cleanup ตอน dispose

Depends on: S-01, S-02

### W-19: `LottieSkeleton`

- [ ] ทดสอบ `isLoading = false` คืน child ตรงๆ
- [ ] ทดสอบ loading overlay, borderRadius, custom asset

Depends on: S-01, S-02

### W-20: `PreLoading`

- [ ] ทดสอบ blur overlay และ centered animation
- [ ] ทดสอบ asset path render

Depends on: S-01, S-02

### W-21: `ShortcutMenuItem`

- [ ] ทดสอบ async SVG load แล้ว render
- [ ] ทดสอบ custom icon override
- [ ] ทดสอบ top/bottom arrow color replacement
- [ ] ทดสอบ loading state

Depends on: S-01, S-02

### W-22: `VisaCard`

- [ ] สร้าง golden baseline
- [ ] ทดสอบ logo, expiry date, masked number, gradient card

Depends on: S-01, S-02

### W-23: `ReceiptComponent`

- [ ] สร้าง golden baseline
- [ ] ทดสอบ section rendering, optional asset fallback, long text
- [ ] ทดสอบ `transactionDetailRowCount`

Depends on: S-01, S-02

### W-24: `ReceiptImageComponent`

- [ ] สร้าง golden baseline
- [ ] ทดสอบ header logo fallback, background fallback, long text
- [ ] ทดสอบ transaction detail layout

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
