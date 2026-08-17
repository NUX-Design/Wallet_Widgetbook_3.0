# Jira Template: Flutter Widget V3 Component

> อ้างอิงจาก XD-167 ([V3ProfileHeader](https://witech.atlassian.net/browse/XD-167)). แทนที่ `{{...}}` ด้วยข้อมูลจริงของ component ที่กำลังทำ

## Jira fields

- **Summary**: `[Wi Design System] Create Flutter Widget V3 {{ComponentName}}`
- **Issue type**: Task
- **Labels**: `design-system`, `flutter`, `{{component-slug}}`, `widget-v3`
- **Priority**: Medium (ปรับตามงาน)

## Description body

```markdown
## Release Evidence

* Source PR: {{source_pr_url}}
* Release PR: {{release_pr_url}}
* Main / Render SHA: `{{sha}}`
* Render deploy: `{{render_deploy_id}}` — live
* GitHub Wiki: {{wiki_url}}
* Main CI: Flutter CI, Widget Sync CI และ V3 Preview Bundle ผ่าน
* Hosted MCP: {{hosted_mcp_notes}}

---

# Jira Component Implementation Brief — Flutter Widget V3 {{ComponentName}}

## Jira Summary

Implement `V3{{ComponentName}}` จาก Wi Design System ให้เป็น reusable Flutter Widget V3 พร้อม states, Light/Dark theme, accessibility, preview และ tests

## Status

* Implementation: {{Done/In Progress}}
* UI inspection: {{status}} — Light/Dark และ documented states
* Automated tests: {{status}} — {{x}}/{{x}} เมื่อ {{date}}
* Preview registry: {{status}} — `{{component_slug}}/V3{{ComponentName}}`
* Documentation: {{status}} — component spec, implementation guide และ GitHub Wiki
* Theme reconciliation: {{status}} — {{notes on any token fixes}}

## Design Reference

* Component: `{{Component Display Name}}`
* Figma node: `{{node_id}}`
* Component spec: `lib/widgets/v3/{{component_slug}}/{{component_slug}}.md`
* Base JSON: `lib/widgets/v3/{{component_slug}}/{{component_slug}}-_base.json`
* Implementation guide: `lib/widgets/v3/{{component_slug}}/V3_{{COMPONENT_SLUG_UPPER}}_GUIDE.md`
* GitHub Wiki: [{{Wiki Title}}]({{wiki_url}})

## Objective

สร้าง reusable {{component purpose}} สำหรับ{{what it displays/does}} โดยรักษา Figma geometry, Theme V3 semantic tokens, Light/Dark behavior, accessibility และ Widget V3 delivery conventions

## Problem

{{ทำไมต้องทำเป็น shared component — ความเสี่ยงถ้าแต่ละ surface ประกอบเอง}}

## Target Users

* Product Developers ที่นำ component ไปประกอบใน Flutter application
* UX/UI และ Design Systems Designers ที่ตรวจ design parity
* QA และ Accessibility Reviewers ที่ตรวจ states, themes, overflow, semantics และ interaction
* End users ที่ต้องเห็น{{...}}

## Core Use Cases

* UC-001: {{use case}}
* UC-002: {{use case}}
* UC-003: {{use case}}

## Scope

### In scope

* Status/state: {{list variants}}
* Layout: {{layout states}}
* {{data variants, e.g. balance visibility}}
* {{interaction elements}}
* Localized semantic label, optional hint และ tooltip
* Light/Dark ผ่าน Theme V3 semantic tokens
* Standalone preview {{n}} cases พร้อม divider, theme toggle และ action feedback
* Targeted widget tests และ V3 preview registry
* Component handoff set และ GitHub Wiki

### Out of scope

* {{explicitly excluded item}}
* API, navigation และ application state management
* {{other exclusions}}
* Animation ระหว่าง states (ถ้าไม่ทำ)
* Theme V3 token อื่นนอกเหนือจาก {{token}}

## Component API

\`\`\`dart
V3{{ComponentName}}(
  {{prop}}: {{value}},
  {{prop}}: {{value}},
)
\`\`\`

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `{{prop}}` | `{{Type}}` | `{{default}}` | {{description}} |

## Design Specifications

| Element | Specification |
| --- | --- |
| {{Root height}} | {{value}} |
| {{Padding}} | {{value}} |
| {{Icon size}} | {{value}} |
| {{Typography}} | `V3Typography.{{style}}` — {{size/line-height}}, weight {{weight}} |

## Theme and Status Mapping

| Element / Status | Semantic token |
| --- | --- |
| {{element}} | `{{semantic/token}}` |

ทุกสี resolve ผ่าน `V3ThemeScope`; widget ไม่ hardcode Light/Dark colors และไม่ fallback ไป legacy theme

## Interaction and Accessibility

* {{interaction behavior}}
* `{{semanticLabel prop}}` เป็น required localized input จาก caller
* Callback `null` แสดง disabled semantics
* Decorative icon ถูก exclude จาก semantics เพื่อไม่ประกาศซ้ำ
* Visual icon อยู่ภายใน interaction target ตามขนาด touch target ที่กำหนด
* {{text overflow behavior}}

## Acceptance Criteria — Completed

### Component behavior

* \[ \] {{criterion}}

### Interaction and accessibility

* \[ \] {{criterion}}

### Theme and UI inspection

- [ ] รองรับ Light mode ผ่าน Theme V3 semantic tokens
- [ ] รองรับ Dark mode ผ่าน Theme V3 semantic tokens
- [ ] Preview label รองรับ Light/Dark
- [ ] มี divider แยกแต่ละ preview case
- [ ] Inspect UI ครบทุก state
- [ ] ไม่พบ RenderFlex overflow ใน cases ที่ทดสอบ

### Delivery artifacts

* \[ \] `{{component_slug}}-_base.json`
* \[ \] `{{component_slug}}.md`
* \[ \] `v3_{{component_slug}}.dart`
* \[ \] `preview_v3_{{component_slug}}.dart`
* \[ \] `V3_{{COMPONENT_SLUG_UPPER}}_GUIDE.md`
* \[ \] Targeted widget tests
* \[ \] V3 preview registry entry `{{component_slug}}/V3{{ComponentName}}`
* \[ \] GitHub Wiki documentation

## UI Test Coverage

| Test case | Light | Dark | Interaction | Result |
| --- | --- | --- | --- | --- |
| {{case}} | Tested | Tested | {{interaction tested}} | Pass |

UI inspection ครอบคลุม theme toggle, labels, divider, {{...}} บน {{device}} Simulator

## Automated Test Evidence

ตรวจล่าสุดเมื่อ {{date}}:

\`\`\`bash
flutter test test/widgets/v3/{{component_slug}}/v3_{{component_slug}}_test.dart
# {{n}} tests passed

dart run tool/generate_v3_preview_registry.dart --check
# registry up to date; includes {{component_slug}}/V3{{ComponentName}}
\`\`\`

Automated coverage:

- [ ] {{test coverage item}}

## Deliverables

* Widget: `lib/widgets/v3/{{component_slug}}/v3_{{component_slug}}.dart`
* Preview: `lib/widgets/v3/{{component_slug}}/preview_v3_{{component_slug}}.dart`
* Base JSON: `lib/widgets/v3/{{component_slug}}/{{component_slug}}-_base.json`
* Component spec: `lib/widgets/v3/{{component_slug}}/{{component_slug}}.md`
* Guide: `lib/widgets/v3/{{component_slug}}/V3_{{COMPONENT_SLUG_UPPER}}_GUIDE.md`
* Tests: `test/widgets/v3/{{component_slug}}/v3_{{component_slug}}_test.dart`
* Wiki: {{wiki_url}}

## Follow-up

* \[ \] {{any reconciliation note}}
* \[ \] Owner: {{name}}
* \[ \] Jira labels: `design-system`, `flutter`, `{{component-slug}}`, `widget-v3`
* \[ \] Iteration ถัดไปต้องรองรับ{{next iteration scope}}

## Definition of Done

* \[ \] Implementation ตรงกับ documented component contract
* \[ \] Light/Dark UI inspection ผ่านครบทุก documented state
* \[ \] Interaction และ accessibility checks ผ่าน
* \[ \] Targeted automated tests ผ่าน {{x}}/{{x}}
* \[ \] Preview registry check ผ่าน
* \[ \] Component handoff artifacts ครบ {{n}} ไฟล์
* \[ \] GitHub Wiki publish แล้ว
* \[ \] Theme V3 tokens ตรงกับ Figma ทั้ง Light/Dark
```

## Pattern สรุป (สังเกตจาก XD-167)

1. **Summary format**: `[Wi Design System] Create Flutter Widget V3 {ComponentName}`
2. **Labels เสมอ**: `design-system`, `flutter`, `{component-name}`, `widget-v3`
3. **โครง description แบ่งเป็นบล็อกตายตัว**: Release Evidence → Status → Design Reference → Objective → Problem → Target Users → Core Use Cases → Scope (In/Out) → Component API (Dart snippet) → Design Specs table → Theme/Status Mapping table → Interaction & Accessibility → Acceptance Criteria (checkbox, แยก 4 กลุ่ม) → UI Test Coverage table → Automated Test Evidence (bash output) → Deliverables (path list) → Follow-up → Definition of Done
4. **ไฟล์ deliverable ตั้งชื่อ pattern เดียวกันเสมอ**: `lib/widgets/v3/{slug}/{slug}.md`, `{slug}-_base.json`, `v3_{slug}.dart`, `preview_v3_{slug}.dart`, `V3_{SLUG}_GUIDE.md`, `test/widgets/v3/{slug}/v3_{slug}_test.dart`
5. **ทุกสีอ้างอิง semantic token ผ่าน Theme V3 (`V3ThemeScope`)** ไม่ hardcode
6. **ปิดท้ายด้วย UI Reference Examples** (screenshot จาก Figma + simulator ทุก state ทั้ง Light/Dark)
