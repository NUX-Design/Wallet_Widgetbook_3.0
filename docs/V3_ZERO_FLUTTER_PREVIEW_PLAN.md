# Widget V3 Zero-Flutter Consumer Preview Plan

สร้างเมื่อ: `2026-07-14 15:11:16 +0700`

## Goal

เปิด interactive local preview ของ Flutter Widget V3 จาก source repo นี้ได้ใน browser ของผู้ใช้ โดย **repo ปลายทางไม่ต้องเป็น Flutter project, ไม่ต้องติดตั้ง Flutter SDK, ไม่ต้องรับ widget source และไม่ต้องมีไฟล์ Flutter ใด ๆ**

แผนนี้ต่อยอดจาก local preview host ที่เสร็จแล้วใน [`V3_WEB_PREVIEW_PLAN.md`](./V3_WEB_PREVIEW_PLAN.md) และไม่ย้อนกลับไปแก้ migration VP-01–VP-10 ซึ่งเป็น verified baseline

Execution checklist อยู่ที่ [`task/V3_ZERO_FLUTTER_PREVIEW_TASKS.md`](../task/V3_ZERO_FLUTTER_PREVIEW_TASKS.md)

## Requirement Contract

เมื่อเรียก `flutter-widget-v3-preview` จาก repo ปลายทางใด ๆ:

1. Skill resolve widget และ source commit ผ่าน hosted MCP
2. ดาวน์โหลด Flutter Web preview bundle ที่ build จาก source repo commit นั้น
3. verify checksum ก่อนใช้งาน
4. แตก bundle ลง user cache นอก repo ปลายทาง
5. เปิด lightweight HTTP server ที่ `127.0.0.1`
6. รอ readiness ผ่านแล้วจึงส่ง deep link `http://127.0.0.1:<port>/#/<slug>`

หลังจบ flow `git status` ของ repo ปลายทางต้องไม่เปลี่ยน และไม่ต้องมี `pubspec.yaml`, `lib/`, `.dart_tool/`, Flutter SDK หรือ Dart SDK

## Research Findings

- Flutter widget source รันใน browser ตรง ๆ ไม่ได้; ต้อง compile เป็น web bundle ก่อน จุด build จึงยังต้องมี Flutter SDK
- `flutter build web` สร้าง static deployment bundle ใต้ `build/web` ซึ่ง serve จาก HTTP server ทั่วไปได้ หลัง compile แล้วเครื่อง consumer ไม่ต้องมี Flutter
- Flutter hot reload ต้องทำงานผ่าน debug session ของ `flutter run`; จึงไม่สามารถให้ repo ปลายทางที่ไม่มี Flutter hot reload Dart source ได้
- GitHub Actions artifacts ดาวน์โหลดข้าม workflow/repository ได้ แต่มี retention และ private-repo token considerations จึงไม่เหมาะเป็น public/stable consumer contract โดยตรง
- สถาปัตยกรรมที่ตรง requirement ที่สุดคือ build-on-source + immutable bundle distribution + local cache/server ฝั่ง consumer

Primary references:

- Flutter: [Build and release a web app](https://docs.flutter.dev/deployment/web)
- Flutter: [Building a web application](https://docs.flutter.dev/platform-integration/web/building)
- Flutter: [Hot reload](https://docs.flutter.dev/tools/hot-reload)
- GitHub: [Workflow artifacts](https://docs.github.com/en/actions/concepts/workflows-and-actions/workflow-artifacts)

## Definitions

- **Source repo**: repository นี้ ซึ่งเป็น source of truth ของ Widget V3, preview source และ Theme V3
- **Consumer/target repo**: repo ที่ agent/user กำลังทำงานและต้องการดู preview โดยไม่ติดตั้ง Flutter
- **Live local preview**: interactive Flutter Web UI ที่ browser เปิดจาก `127.0.0.1` และ route/state/theme ใช้งานได้จริง
- **Published freshness**: preview ตรงกับ immutable source commit ที่ MCP รายงาน ไม่ได้หมายถึง hot reload ของ uncommitted Dart edits
- **Source-development mode**: flow เดิม `scripts/serve-v3-preview.sh` สำหรับผู้พัฒนา source repo ที่ต้องการ build ล่าสุดหรือ hot iteration และมี Flutter SDK

## Assumptions And Decisions

- ใช้ source repo นี้เป็น single source of truth; consumer repo ไม่ copy Flutter source
- คง local-only browser URL; ไม่เปลี่ยน product requirement เป็น hosted preview URL
- build bundle ใน source CI จาก `lib/preview_v3/main.dart` และ generated registry เดิม
- bundle ต้อง immutable ตาม commit SHA และมี SHA-256 manifest
- consumer cache อยู่ใต้ platform user cache เช่น `${XDG_CACHE_HOME:-~/.cache}/flutter-widget-wallet/v3-preview/<commit>/` ไม่อยู่ใน repo ปลายทาง
- launcher ใช้ runtime ทั่วไปที่ไม่เกี่ยวกับ Flutter: รองรับ Python 3 เป็น baseline และ Node.js เป็น fallback; ต้อง preflight แล้วแจ้งข้อผิดพลาดตรง ๆ ถ้าไม่มีทั้งคู่
- hosted MCP ยังคงเป็น service เดิม ไม่สร้าง Render service ตัวที่สอง
- bearer token ใช้เฉพาะตอน resolve/download; ห้ามใส่ token ใน URL, cache manifest, log หรือ browser history
- bundle distribution endpoint ต้องรองรับ streaming binary/static asset โดยไม่ยัด archive แบบ base64 ลง MCP JSON response
- `localPreviewUrl` ปัจจุบันเป็น misleading สำหรับ remote consumers และต้องเปลี่ยนแบบ additive/deprecated ไม่ reinterpret field เดิมแบบเงียบ ๆ

## Non-Goals

- ทำให้ Flutter/Dart source รันใน browser โดยไม่ compile
- hot reload uncommitted source จากเครื่องที่ไม่มี Flutter SDK
- เขียน Flutter files หรือ generated preview host ลง consumer repo
- online public preview page หรือ Render service ใหม่
- iframe/HTML approximation, screenshot-only preview หรือการ reimplement widget เป็น React
- ลบ source-development flow เดิม

## Target Architecture

```text
Source repo
  Widget/Theme/Preview sources
          │
          ├─ registry generation + Flutter tests
          ▼
  flutter build web --release -t lib/preview_v3/main.dart
          │
          ├─ preview-bundle.tar.gz
          └─ manifest.json { commit, checksum, schemaVersion, slugs }
                         │
                         ▼
            Existing hosted MCP/service
              metadata + bundle download
                         │
                         ▼
Consumer agent/skill (from any repo)
  resolve → download → verify → user cache → local static server
                                             │
                                             ▼
                          http://127.0.0.1:<port>/#/<slug>
```

## Two Supported Modes

| Mode | ใช้เมื่อ | Flutter อยู่ที่ไหน | Freshness |
|---|---|---|---|
| Published consumer mode (default) | เรียกจาก repo ปลายทางทั่วไป | Source CI เท่านั้น | commit ที่ MCP/manifest ระบุ |
| Source-development mode | แก้ widget ใน source repo | เครื่อง source developer | working tree ล่าสุด; รองรับ iteration ผ่าน Flutter tooling |

Skill ต้องเลือก published consumer mode เป็น default เสมอเมื่อ current workspace ไม่มี preview host source และห้ามติดตั้ง Flutter หรือ bootstrap Flutter project เพื่อเปิด preview

## Public Contract

Hosted MCP preview response เพิ่มข้อมูลแบบ additive:

```json
{
  "widgetName": "V3MiniButton",
  "previewSlug": "button/V3MiniButton",
  "previewDelivery": {
    "mode": "bundle",
    "schemaVersion": 1,
    "sourceCommit": "<full-sha>",
    "bundleUrl": "<authenticated-download-url>",
    "sha256": "<hex>",
    "entryPath": "index.html"
  }
}
```

Contract rules:

- `sourceCommit` ต้องตรงกับ catalog freshness commit
- `bundleUrl` ต้องไม่ฝัง secret และต้องมี error ที่แยก `NOT_BUILT`, `STALE_BUNDLE`, `UNAUTHORIZED` ได้
- `sha256` verify ก่อน extract และใช้ archive path traversal protection
- `localPreviewUrl` เดิมคงไว้ชั่วคราวเพื่อ backward compatibility แต่ mark deprecated; consumer skill สร้าง localhost URL หลัง launcher เลือก port สำเร็จเท่านั้น
- bundle หนึ่งชุดครอบคลุมทุก registered slug เพื่อไม่ build ซ้ำต่อ widget

## Execution Plan

### Phase ZP-1 — Freeze Contract And Prove Artifact Portability

สร้าง fixture bundle จาก pipeline ปัจจุบัน พร้อม manifest/checksum แล้วทดสอบใน temporary non-Flutter directory โดยซ่อน `flutter`/`dart` จาก `PATH`

Expected result: browser/curl เปิด bundleได้, route ทำงาน, temp consumer directory ไม่ถูกแก้ และพิสูจน์ว่า runtime ไม่พึ่ง Flutter หลัง build

### Phase ZP-2 — Build Immutable Bundle In Source CI

เพิ่ม CI job ที่รัน registry check, targeted tests และ release web build จาก source commit จากนั้น pack deterministic archive + manifest + checksum และ publish เฉพาะเมื่อ gates ผ่าน

ควรเริ่มด้วย GitHub Release asset หรือ versioned object endpoint ที่ไม่หมดอายุ; Actions artifact ใช้เป็น CI evidence/cache ได้ แต่ไม่เป็น stable delivery contract

Expected result: ทุก publishable commit มี bundle ที่ trace กลับ source SHA ได้ และ build failure ไม่เลื่อน latest pointer

### Phase ZP-3 — Expose Delivery Metadata From Existing MCP Service

เพิ่ม bundle catalog/provider แยกจาก widget catalog, เพิ่ม `previewDelivery` ใน `get_v3_widget_preview` และ metadata handlers, รวม health/freshness status โดยไม่โหลด archive เข้า memory ทั้งก้อน

Expected result: remote MCP ระบุ exact bundle, commit และ checksum ของ widget ได้; legacy contracts/tests ยังผ่าน

### Phase ZP-4 — Build Repo-Independent Local Launcher

เพิ่ม launcher ที่:

- รับ delivery manifest + slug
- เลือก free loopback port หรือ reuse server ที่ commit/checksum ตรงกัน
- lock concurrent downloads
- ดาวน์โหลดไป temporary file, verify SHA-256, safe-extract แล้ว atomic rename เข้า user cache
- serve ด้วย Python 3 หรือ Node fallback โดย bind เฉพาะ `127.0.0.1`
- expose local health metadata เพื่อกัน reuse bundleผิด commit
- cleanup process ได้ แต่เก็บ immutable cache สำหรับครั้งต่อไป

Expected result: command เดียวจาก empty/non-Flutter repo ส่ง exact URL หลัง HTTP 200 และไม่เขียนอะไรลง workspace

### Phase ZP-5 — Rewrite Preview Skills For All Native Packs

ปรับ Codex, Claude Code และ Kiro ให้ flow เป็น:

1. resolve `previewDelivery`
2. ถ้าอยู่ source repo และ user ขอ working-tree preview จึงใช้ source-development mode
3. กรณีอื่นใช้ launcher เท่านั้น
4. readiness gate ก่อนส่ง URL
5. ห้ามเรียก `flutter-widget-v3-install`, ห้ามสร้าง preview Dart file และห้ามตรวจ Flutter SDK ใน consumer mode

Expected result: prompt เดียวกันทำงานจาก repo React/Node/empty Git repo และ skills ทั้งสาม pack มี contract ตรงกัน

### Phase ZP-6 — End-To-End And Failure Verification

ทดสอบ matrix อย่างน้อย:

- empty Git repo, React repo และ plain directory ที่ไม่มี Flutter files
- `PATH` ไม่มี `flutter`/`dart`
- cold cache, warm cache, concurrent launch และ port collision
- checksum mismatch, truncated archive, unauthorized, bundle missing และ stale commit
- Light/Dark, interaction, narrow viewport, unknown slug และ reload
- source update → CI bundle ใหม่ → MCP freshness ใหม่ → consumer cache key ใหม่
- `git status --porcelain` ก่อน/หลังต้องเหมือนเดิม

Expected result: zero-Flutter consumer acceptance ผ่านจริง พร้อม evidence จาก process/browser ไม่ใช่แค่ unit test

### Phase ZP-7 — Rollout And Deprecate Old Consumer Flow

rollout แบบ additive, deploy บน Render service เดิม, verify remote endpoint จริง แล้วค่อยเปลี่ยน skills ให้ published consumer mode เป็น default หลัง bundle availability ครบ

คง `scripts/serve-v3-preview.sh` สำหรับ source-development mode และประกาศ `localPreviewUrl` เดิม deprecated หลัง native skill packs ใช้ delivery contract ใหม่ครบ

Expected result: ไม่มีช่วงที่ skill ส่ง dead URL และ rollback ได้ด้วยการ pin skill/MCP contract version ก่อนหน้า

## Validation Gates

```bash
# Source correctness
dart run tool/generate_v3_preview_registry.dart --check
flutter analyze
flutter test test/preview_v3/ test/tool/
flutter build web --release -t lib/preview_v3/main.dart

# MCP/contract regression
npm run check:v3-boundaries
npm run validate:v3-skills
cd mcp-server && npm run check:mcp-syntax && npm test

# Consumer acceptance (new harness; exact command defined in ZP-1)
env PATH="<path-without-flutter-or-dart>" node test-zero-flutter-preview.mjs
```

Release gate ต้องตรวจ checksum, source SHA parity, real HTTP readiness และ unchanged consumer worktree ทุกครั้ง

## Acceptance Criteria

- จาก repo ปลายทางที่ไม่มี Flutter ทุกชนิด ผู้ใช้เรียก skill แล้วได้ interactive local URL ที่เปิดจริง
- consumer flow ไม่เรียก `flutter`, `dart`, `flutter pub get` หรือเขียนไฟล์เข้า repo ปลายทาง
- widget, theme, assets และ preview matrix มาจาก source repo commit เดียวกัน
- URL ถูกส่งหลัง HTTP readiness ผ่านเท่านั้น
- cold start ดาวน์โหลด/verify หนึ่งครั้ง; warm start reuse cache ที่ commit/checksum ตรงกัน
- checksum mismatch หรือ stale/missing bundle fail closed พร้อม actionable error
- token ไม่ปรากฏใน URL/log/cache/browser history
- source-development preview เดิมยังใช้งานได้
- CI, MCP, Skills V3 และ browser E2E gates ผ่าน

## Highest Risk And Mitigation

ความเสี่ยงสูงสุดคือ **freshness drift**: MCP catalog ชี้ commit หนึ่ง แต่ bundle มาจากอีก commit ทำให้ preview ไม่ตรง source

ลดความเสี่ยงโดยใช้ immutable commit-addressed bundle, manifest + SHA-256, ตรวจ `sourceCommit` เทียบ MCP freshness ทุก launch, publish latest pointer แบบ atomic หลัง build/test ผ่านเท่านั้น และไม่ fallback ไป bundle เก่าแบบเงียบ ๆ

## Hard Constraint

ถ้า “live” หมายถึงเห็น uncommitted Dart source เปลี่ยนแบบ hot reload บนเครื่อง consumer ที่ไม่มี Flutter เลย requirement นั้นทำไม่ได้ด้วย Flutter runtime ปัจจุบัน เพราะ source ต้องถูก compile ผ่าน Flutter toolchain ก่อน ทางเลือกที่รองรับคือ:

- build/hot reload บน source machine ที่มี Flutter แล้ว proxy/stream preview ให้ consumer หรือ
- commit/push source เพื่อให้ CI สร้าง published bundleใหม่

แผนนี้เลือกทางที่สองเป็น default เพราะตรงเงื่อนไข zero-Flutter consumer, reproducible และปลอดภัยกว่า ส่วนทางแรกคงไว้ใน source-development mode
