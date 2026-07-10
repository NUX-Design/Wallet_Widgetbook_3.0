import assert from "node:assert/strict";
import test from "node:test";

import { inspectChangedPaths, inspectDartBoundary } from "./check-v3-boundaries.js";

test("rejects legacy theme imports and ThemeColors.get inside V3 theme code", () => {
  const violations = inspectDartBoundary(
    "lib/config/themes/v3/v3_theme_scope.dart",
    `
      import '../theme_color.dart';
      final color = ThemeColors.get('light', 'fill/base/300');
    `,
  );

  assert.equal(violations.length, 2);
  assert.match(violations[0], /must not import legacy theme_color\.dart/);
  assert.match(violations[1], /not ThemeColors\.get/);
});

test("allows V3 theme code to import another V3 module", () => {
  const violations = inspectDartBoundary(
    "lib/config/themes/v3/v3_theme_scope.dart",
    "import 'v3_color_palette.dart';",
  );

  assert.deepEqual(violations, []);
});

test("rejects package and relative V3 imports from legacy widgets", () => {
  const packageViolations = inspectDartBoundary(
    "lib/widgets/input/search_input.dart",
    "import 'package:mcp_test_app/config/themes/v3/v3_theme_scope.dart';",
  );
  const relativeViolations = inspectDartBoundary(
    "lib/widgets/input/search_input.dart",
    "import '../v3/buttons/v3_button.dart';",
  );

  assert.equal(packageViolations.length, 1);
  assert.equal(relativeViolations.length, 1);
});

test("allows V3 imports inside V3 widgets", () => {
  const violations = inspectDartBoundary(
    "lib/widgets/v3/buttons/v3_button.dart",
    "import 'package:mcp_test_app/config/themes/v3/v3_theme_scope.dart';",
  );

  assert.deepEqual(violations, []);
});

test("rejects legacy skill changes when the diff contains V3 work", () => {
  const violations = inspectChangedPaths([
    "lib/config/themes/v3/v3_theme_scope.dart",
    "skills/flutter-widget-search/SKILL.md",
  ]);

  assert.equal(violations.length, 1);
  assert.match(violations[0], /legacy skills must remain unchanged/);
});

test("allows skills-v3 changes and ignores legacy skill changes outside V3 work", () => {
  assert.deepEqual(
    inspectChangedPaths([
      "skills-v3/codex/.codex/skills/flutter-widget-v3-search/SKILL.md",
    ]),
    [],
  );
  assert.deepEqual(
    inspectChangedPaths(["skills/flutter-widget-search/SKILL.md", "README.md"]),
    [],
  );
});
