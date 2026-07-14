import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const canonical = fs.readFileSync(path.join(repoRoot, "scripts/v3-preview-bundle/launch-v3-preview.mjs"), "utf8");

const packCopies = [
  "skills-v3/codex/.codex/skills/flutter-widget-v3-preview/assets/launch-v3-preview.mjs",
  "skills-v3/claude-code/.claude/skills/flutter-widget-v3-preview/assets/launch-v3-preview.mjs",
  "skills-v3/kiro/.kiro/skills/flutter-widget-v3-preview/assets/launch-v3-preview.mjs",
];

test("each skill pack ships a launcher identical to the canonical source", () => {
  for (const rel of packCopies) {
    const copy = fs.readFileSync(path.join(repoRoot, rel), "utf8");
    assert.equal(copy, canonical, `${rel} drifted from scripts/v3-preview-bundle/launch-v3-preview.mjs; re-copy it.`);
  }
});
