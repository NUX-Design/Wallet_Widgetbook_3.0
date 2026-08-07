# Widget V3 Simulator Debug Preview

คู่มือนี้อธิบายวิธีเปิด Widget V3 preview registry บน iOS Simulator แบบ debug เพื่อทดสอบ native rendering, interaction และ hot reload จาก source ที่กำลังแก้ไขอยู่

## Entrypoint

- Native Simulator: `lib/preview_v3/main_simulator.dart`
- Flutter Web: `lib/preview_v3/main.dart`
- Shared app/router: `lib/preview_v3/preview_app.dart`

`main_simulator.dart` ไม่ import `flutter_web_plugins` จึง build บน iOS ได้ ส่วน `main.dart` ต้องคงเป็น Web-only เพราะเรียก `setUrlStrategy(null)` เพื่อรักษา fragment route ใน browser

## Splash-Then-Destination-Then-Loop Flow

ทุกครั้งที่รันผ่าน `main_simulator.dart` (ไม่ว่าจะส่ง `V3_PREVIEW_SLUG` หรือไม่) แอปจะเล่น flow นี้เสมอ — เป็น behavior ของ entrypoint นี้เพียงไฟล์เดียว ไม่กระทบ `main.dart` (Web) หรือ `preview_app.dart` (shared router ที่ Web ยังใช้ตรงแบบเดิม):

1. เล่น splash `V3SplashAnimationPreview` (`lib/widgets/v3/splash/preview_v3_splash_animation.dart`, asset `lib/assets/lottie/wi_splash.json`) เป็นหน้า pre-loading ก่อนเสมอ
2. เมื่อ animation เล่นจบ (`V3SplashAnimation.onCompleted` ยิงเมื่อ `AnimationStatus.completed` และไม่ได้ตั้ง `repeat`) จะ redirect ไปหน้าปลายทางที่ resolve จาก `rawSlug` เหมือนที่ `V3PreviewRoute` ทำเสมอมา (ถ้าไม่ส่ง slug จะเปิด preview แรกของ registry ตามปกติ)
3. หน้าปลายทางมีปุ่ม CTA "Loop back to splash" ลอยติดขอบล่าง (key `v3-simulator-splash-loop-cta`) กดแล้ววนกลับไปเล่น splash ใหม่ — flow นี้วนซ้ำไปเรื่อยๆ

โครงสร้าง widget: `main()` -> `V3SimulatorSplashLoopApp` -> `V3SimulatorSplashLoopHost` (คุม state `_showSplash` ด้วย `setState`, ไม่ใช้ `Navigator`) -> splash หรือ `_V3SimulatorLoopDestination` (ห่อ `V3PreviewRoute(rawSlug: rawSlug)` เดิมด้วย CTA ลอยด้านล่าง)

ทดสอบด้วย `test/preview_v3/main_simulator_test.dart` (pump ผ่าน asset load + animation duration ด้วย `pumpAndSettle`, ยืนยัน splash -> destination -> tap CTA -> splash)

## Prerequisites

- ติดตั้ง Flutter และ Xcode พร้อม iOS Simulator runtime
- รันคำสั่งจาก repository root
- generated registry ต้องเป็นปัจจุบัน:

  ```bash
  dart run tool/generate_v3_preview_registry.dart --check
  ```

ตรวจ Simulator ที่พร้อมใช้งาน:

```bash
xcrun simctl list devices available
flutter devices
```

หาก Simulator ยังไม่เปิด ให้ boot ด้วย UDID ที่เลือก:

```bash
xcrun simctl boot <simulator-udid>
xcrun simctl bootstatus <simulator-udid> -b
```

## Run A Specific V3 Preview

ส่ง slug รูปแบบ `<category>/<WidgetClass>` ผ่าน `V3_PREVIEW_SLUG`:

```bash
flutter run \
  -t lib/preview_v3/main_simulator.dart \
  -d <simulator-udid> \
  --debug \
  --dart-define=V3_PREVIEW_SLUG=header/V3Header
```

ตัวอย่างอื่น:

```bash
--dart-define=V3_PREVIEW_SLUG=button/V3DefaultButton
--dart-define=V3_PREVIEW_SLUG=button/V3MiniButton
--dart-define=V3_PREVIEW_SLUG=icon_button/V3IconButton
--dart-define=V3_PREVIEW_SLUG=navigation/V3Navigation
```

หากไม่ส่ง `V3_PREVIEW_SLUG` `main_simulator.dart` จะเปิด `header/V3Header` เป็นค่า default เสมอ (ค่านี้ hardcode ไว้ที่ `_defaultSimulatorPreviewSlug` ใน `lib/preview_v3/main_simulator.dart` เฉพาะ entrypoint นี้เท่านั้น) — ต่างจาก `main.dart` (Web) และ `preview_app.dart` shared router ที่ยังเปิด preview แรกตามลำดับ deterministic ของ generated registry เหมือนเดิมเมื่อ slug ว่าง:

```bash
flutter run \
  -t lib/preview_v3/main_simulator.dart \
  -d <simulator-udid> \
  --debug
```

เปลี่ยน default นี้ได้โดยแก้ค่า `_defaultSimulatorPreviewSlug` ในไฟล์เดียวนั้น

## Debug Controls

เมื่อ `flutter run` เชื่อมต่อแล้ว:

- `r` — hot reload
- `R` — hot restart
- `h` — แสดงคำสั่งทั้งหมด
- `q` — ปิดแอปและจบ debug session

การเปลี่ยนค่า `V3_PREVIEW_SLUG` ต้องหยุด session แล้วรันคำสั่งใหม่ เพราะ `String.fromEnvironment` ถูกกำหนดตอน build ไม่เปลี่ยนด้วย hot reload

## Optional Browser Mirror

หากต้องการดูหรือควบคุม Simulator ผ่าน browser ให้ pin `serve-sim` ด้วย UDID เดียวกับ Flutter session:

```bash
SIM="<simulator-udid>"
cleanup_serve_sim() {
  npx --yes serve-sim@latest --kill "$SIM" >/dev/null 2>&1 || true
}
trap cleanup_serve_sim EXIT INT TERM HUP
cleanup_serve_sim
npx --yes serve-sim@latest "$SIM"
```

เปิด URL ที่ `serve-sim` แสดง เช่น `http://localhost:3200` และต้องตรวจว่ามี frame ของแอป render จริงก่อนถือว่าสำเร็จ ห้ามใช้ `serve-sim --kill` แบบไม่ระบุ UDID เพราะอาจปิด mirror ของงานอื่น

## Verification Checklist

- splash เล่นก่อนเสมอ แล้ว redirect ไป preview ที่ตรงกับ slug ที่ส่ง (หรือ preview แรกถ้าไม่ส่ง)
- ปุ่ม CTA "Loop back to splash" ที่ขอบล่างของหน้าปลายทางกดแล้ววนกลับไป splash ได้จริง
- ไม่มี exception หรือ `RenderFlex overflow` ใน Flutter debug console
- Light/Dark mode แสดง semantic tokens ถูกต้อง
- interaction และ action feedback ทำงาน
- touch targets, text scaling และ safe area ใช้งานได้บนขนาดอุปกรณ์เป้าหมาย
- hot reload สะท้อน source ล่าสุด

รัน regression ขั้นต่ำ:

```bash
flutter analyze
flutter test test/preview_v3/ test/widgets/v3/<category>/
dart run tool/generate_v3_preview_registry.dart --check
```

## Troubleshooting

### `dart:ui_web is not available on this platform`

กำลังใช้ Web entrypoint ผิดไฟล์ ให้เปลี่ยนจาก:

```bash
-t lib/preview_v3/main.dart
```

เป็น:

```bash
-t lib/preview_v3/main_simulator.dart
```

### เปิดแล้วได้ Widget คนละตัว

ตรวจ slug จาก `lib/preview_v3/preview_registry.g.dart` หรือรัน registry generator แล้วใช้ชื่อ `<category>/<WidgetClass>` ให้ตรงทุกตัวอักษร

### เพิ่มหรือ rename preview แล้วหาไม่เจอ

รัน:

```bash
dart run tool/generate_v3_preview_registry.dart
```

ห้ามแก้ `lib/preview_v3/preview_registry.g.dart` ด้วยมือ

### Simulator ไม่ปรากฏใน `flutter devices`

ยืนยันว่า Simulator boot เสร็จแล้วด้วย `xcrun simctl bootstatus <simulator-udid> -b` จากนั้นเรียก `flutter devices` ใหม่

## Scope Boundary

Simulator entrypoint ใช้เฉพาะ native debug และ hot reload ไม่แทนที่:

- Web source-development host
- release Web bundle
- published consumer preview
- hosted MCP freshness/publishing workflow

งาน publish ยังคงใช้ `lib/preview_v3/main.dart` และขั้นตอนใน `V3_WIDGET_PREVIEW_PUBLISHING_GUIDE.md`
