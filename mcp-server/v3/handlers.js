import { ToolError, buildPaginatedWidgetsPayload, ensureEnum, ensureNonEmptyString, ok, parsePagination } from "../tool_runtime.js";

// Matches scripts/serve-v3-preview.sh's default host/port and env var names so the
// URL this metadata advertises lines up with the local preview host contributors
// actually run. Override with the same V3_PREVIEW_HOST/V3_PREVIEW_PORT env vars.
const V3_LOCAL_PREVIEW_HOST = process.env.V3_PREVIEW_HOST || "127.0.0.1";
const V3_LOCAL_PREVIEW_PORT = process.env.V3_PREVIEW_PORT || "8090";

// Single source of truth for the `<category>/<WidgetClass>` slug and the local
// preview URL derived from it; every handler that surfaces preview routing spreads
// this in rather than recomputing the slug/URL itself.
function v3PreviewRouteMetadata(widget) {
  const previewSlug = `${widget.category}/${widget.name}`;
  return { previewSlug, localPreviewUrl: `http://${V3_LOCAL_PREVIEW_HOST}:${V3_LOCAL_PREVIEW_PORT}/#/${previewSlug}` };
}

const tokenSummary = ({ tokenName, dartProperty, lightValue, darkValue, lightPrimitiveAlias, darkPrimitiveAlias }) => ({ tokenName, dartProperty, lightValue, darkValue, lightPrimitiveAlias, darkPrimitiveAlias });
const widgetSummary = ({ name, category, widgetFile, previewFiles, semanticTokens }) => ({ name, category, themeVersion: "v3", widgetFile, previewFiles, semanticTokens });
const widgetMetadata = (widget) => ({ name: widget.name, category: widget.category, themeVersion: "v3", widgetFile: widget.widgetFile, previewFiles: widget.previewFiles, docFiles: widget.docFiles, props: widget.props, dependencies: widget.dependencies, internalImports: widget.internalImports, semanticTokens: widget.semanticTokens, tokenProperties: widget.tokenProperties, figmaNodes: widget.figmaNodes, ...v3PreviewRouteMetadata(widget) });

function toSnakeCase(value) {
  return value.replace(/([a-z0-9])([A-Z])/g, "$1_$2").replace(/[\s-]+/g, "_").toLowerCase();
}

function ensureV3WidgetName(value, fieldName = "widgetName") {
  const name = ensureNonEmptyString(value, fieldName);
  if (!name.startsWith("V3")) {
    throw new ToolError("INVALID_ARGUMENT", `Field "${fieldName}" must start with V3.`, {
      hint: `Use a V3-prefixed class name such as "V3${name}".`,
      details: { field: fieldName, received: name },
    });
  }
  return name;
}

function buildV3Template({ widgetName, category, stateful = false }) {
  const fileName = toSnakeCase(widgetName);
  const filePath = `lib/widgets/v3/${category}/${fileName}.dart`;
  const classBody = stateful
    ? `class ${widgetName} extends StatefulWidget {
  const ${widgetName}({super.key, required this.label});

  final String label;

  @override
  State<${widgetName}> createState() => _${widgetName}State();
}

class _${widgetName}State extends State<${widgetName}> {
  @override
  Widget build(BuildContext context) {
    final colors = V3ThemeScope.colorsOf(context);
    return Text(widget.label, style: TextStyle(color: colors.contentPrimary));
  }
}`
    : `class ${widgetName} extends StatelessWidget {
  const ${widgetName}({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = V3ThemeScope.colorsOf(context);
    return Text(label, style: TextStyle(color: colors.contentPrimary));
  }
}`;
  return {
    themeVersion: "v3",
    filePath,
    code: `import 'package:flutter/material.dart';
import 'package:mcp_test_app/config/themes/v3/v3_theme_scope.dart';

${classBody}
`,
    instructions: [
      `Create ${filePath}.`,
      "Replace the placeholder body using semantic colors from V3ThemeScope.colorsOf(context).",
      "Add preview_v3_<widget>.dart, V3_<WIDGET>_GUIDE.md, and a targeted test.",
      "Never import ThemeColors or a legacy widget into Widget V3.",
    ],
  };
}

export function createV3Handlers({ tokenCatalog, widgetCatalog, foundationCatalog }) {
  return {
    async get_v3_design_system_info(args) {
      const section = ensureEnum(args.section, "section", ["project", "designTokens", "widgets", "implementation"]);
      const widgets = widgetCatalog.list();
      const data = {
        project: { name: "Wi Wallet Widget V3", themeVersion: "v3", additive: true, widgetRoot: "lib/widgets/v3", themeRoot: "lib/config/themes/v3" },
        designTokens: { themeVersion: "v3", semanticTokenCount: tokenCatalog.list().length, runtimeAccessor: "V3ThemeScope.colorsOf(context)", supportsModes: ["light", "dark"] },
        widgets: { themeVersion: "v3", count: widgets.length, categories: [...new Set(widgets.map((widget) => widget.category))].sort() },
        implementation: { sourcePattern: "lib/widgets/v3/<category>/v3_<widget>.dart", previewPattern: "preview_v3_<widget>.dart", guidePattern: "V3_<WIDGET>_GUIDE.md", legacyFallback: false },
      };
      return ok({ themeVersion: "v3", section, data: data[section] });
    },
    async get_v3_theme_foundation(args) {
      if (!args.file) {
        return ok({
          themeVersion: "v3",
          profile: "runtime",
          files: foundationCatalog.manifest(),
          instructions: [
            "Create every file at the returned relative path inside the target Flutter project.",
            "Fetch each file by calling get_v3_theme_foundation with its exact manifest path.",
            "Do not modify generated files; refresh them from the Theme V3 source repository when tokens change.",
          ],
        });
      }
      const file = ensureNonEmptyString(args.file, "file");
      return ok({ themeVersion: "v3", profile: "runtime", file, code: foundationCatalog.read(file) });
    },
    async list_v3_categories() {
      return ok({ themeVersion: "v3", categories: [...new Set(widgetCatalog.list().map((widget) => widget.category))].sort() });
    },
    async list_v3_color_tokens(args) {
      const mode = args.mode ? ensureEnum(args.mode, "mode", ["light", "dark", "both"]) : "both";
      const { limit, offset } = parsePagination(args, { defaultLimit: 100, maxLimit: 200 });
      const all = tokenCatalog.list();
      return ok({ themeVersion: "v3", mode, total: all.length, count: Math.min(limit, Math.max(0, all.length - offset)), limit, offset, hasMore: offset + limit < all.length, tokens: all.slice(offset, offset + limit).map(tokenSummary) });
    },
    async search_v3_color_tokens(args) {
      const query = ensureNonEmptyString(args.query, "query");
      const { limit, offset } = parsePagination(args, { defaultLimit: 20, maxLimit: 100 });
      const all = tokenCatalog.search(query);
      return ok({ themeVersion: "v3", query, total: all.length, count: Math.min(limit, Math.max(0, all.length - offset)), limit, offset, hasMore: offset + limit < all.length, tokens: all.slice(offset, offset + limit).map(tokenSummary) });
    },
    async get_v3_color_token(args) {
      const tokenName = ensureNonEmptyString(args.tokenName, "tokenName");
      const mode = args.mode ? ensureEnum(args.mode, "mode", ["light", "dark", "both"]) : "both";
      const token = tokenCatalog.get(tokenName);
      const result = { ...token, mode };
      if (mode === "light") { delete result.darkValue; delete result.darkPrimitiveAlias; delete result.darkAlpha; }
      if (mode === "dark") { delete result.lightValue; delete result.lightPrimitiveAlias; delete result.lightAlpha; }
      return ok(result);
    },
    async list_v3_widgets(args) {
      const category = args.category?.trim() || null;
      const { limit, offset } = parsePagination(args, { defaultLimit: 50, maxLimit: 200 });
      const all = widgetCatalog.list(category);
      return ok(buildPaginatedWidgetsPayload({ themeVersion: "v3", category }, all.slice(offset, offset + limit).map(widgetSummary), all.length, limit, offset));
    },
    async search_v3_widgets(args) {
      const query = ensureNonEmptyString(args.query, "query");
      const { limit, offset } = parsePagination(args, { defaultLimit: 10, maxLimit: 100 });
      const all = widgetCatalog.search(query);
      return ok(buildPaginatedWidgetsPayload({ themeVersion: "v3", query }, all.slice(offset, offset + limit).map(widgetSummary), all.length, limit, offset));
    },
    async get_v3_widget_metadata(args) { return ok(widgetMetadata(widgetCatalog.get(ensureNonEmptyString(args.widgetName, "widgetName")))); },
    async get_v3_widget_details(args) { return ok(widgetMetadata(widgetCatalog.get(ensureNonEmptyString(args.widgetName, "widgetName")))); },
    async get_v3_widget_code(args) {
      const widget = widgetCatalog.get(ensureNonEmptyString(args.widgetName, "widgetName"));
      return ok({ themeVersion: "v3", widgetName: widget.name, widgetFile: widget.widgetFile, code: widgetCatalog.read(widget.widgetFile) });
    },
    async get_v3_widget_preview(args) {
      const widget = widgetCatalog.get(ensureNonEmptyString(args.widgetName, "widgetName"));
      if (!widget.previewFiles.length) throw new ToolError("EMPTY_RESULT", `V3 widget "${widget.name}" has no preview files.`, { hint: "Add preview_v3_<widget>.dart beside the widget." });
      return ok({ themeVersion: "v3", widgetName: widget.name, category: widget.category, ...v3PreviewRouteMetadata(widget), previews: widget.previewFiles.map((file) => ({ file, code: widgetCatalog.read(file) })) });
    },
    async audit_v3_widget(args) { return ok(widgetCatalog.audit(widgetCatalog.get(ensureNonEmptyString(args.widgetName, "widgetName")))); },
    async get_v3_flutter_widget_template(args) {
      const widgetType = ensureEnum(args.widgetType, "widgetType", ["stateless", "stateful"]);
      const widgetName = ensureV3WidgetName(args.widgetName);
      const category = ensureNonEmptyString(args.category, "category").toLowerCase();
      return ok(buildV3Template({ widgetName, category, stateful: widgetType === "stateful" }));
    },
    async get_v3_codebase_patterns(args) {
      const pattern = ensureEnum(args.pattern, "pattern", ["imports", "theme", "fonts", "state", "naming", "accessibility", "all"]);
      const patterns = {
        imports: ["Import V3ThemeScope from config/themes/v3.", "Do not import legacy theme APIs or widgets outside lib/widgets/v3."],
        theme: ["Use V3ThemeScope.colorsOf(context).", "Use semantic tokens; never silently fall back to ThemeColors.get()."],
        fonts: ["Keep typography readable and compatible with text scaling.", "Follow the verified Figma specification and existing typography dependencies."],
        state: ["Keep reusable widget state explicit and predictable.", "Disabled/loading/error behavior must not invoke callbacks incorrectly."],
        naming: ["Classes start with V3.", "Files use v3_<widget>.dart and previews use preview_v3_<widget>.dart."],
        accessibility: ["Provide semantics and keyboard focus for interactive widgets.", "Use localized labels from the caller and verify Light/Dark contrast."],
      };
      return ok({ themeVersion: "v3", pattern, data: pattern === "all" ? patterns : { [pattern]: patterns[pattern] } });
    },
    async get_v3_figma_to_flutter_mapping(args) {
      const figmaComponentName = ensureNonEmptyString(args.figmaComponentName, "figmaComponentName");
      const normalized = figmaComponentName.toLowerCase().replace(/[^a-z0-9]/g, "");
      const widget = widgetCatalog.list().find((entry) => entry.name.toLowerCase().replace(/[^a-z0-9]/g, "").includes(normalized) || normalized.includes(entry.name.toLowerCase().replace(/^v3|[^a-z0-9]/g, "")));
      if (!widget) {
        return ok({ themeVersion: "v3", found: false, figmaComponentName, suggestions: widgetCatalog.list().map((entry) => entry.name), nextStep: "Use generate_v3_widget_code only after confirming the Figma scope and semantic token mapping." });
      }
      return ok({ themeVersion: "v3", found: true, figmaComponentName, flutterClass: widget.name, category: widget.category, filePath: widget.widgetFile, previewFiles: widget.previewFiles, figmaNodes: widget.figmaNodes, semanticTokens: widget.semanticTokens });
    },
    async generate_v3_widget_code(args) {
      const componentName = ensureV3WidgetName(args.componentName, "componentName");
      const category = ensureNonEmptyString(args.category, "category").toLowerCase();
      const widgetType = ensureEnum(args.widgetType, "widgetType", ["stateless", "stateful"]);
      const tokens = Array.isArray(args.semanticTokens) ? args.semanticTokens.map((token) => tokenCatalog.get(token).tokenName) : [];
      const template = buildV3Template({ widgetName: componentName, category, stateful: widgetType === "stateful" });
      return ok({ ...template, figmaDescription: ensureNonEmptyString(args.figmaDescription, "figmaDescription"), semanticTokens: tokens.length ? tokens : ["content/primary"], note: "Generated source is returned only; this tool does not write files." });
    },
    async generate_v3_widgetbook_use_case(args) {
      const widgetName = ensureV3WidgetName(args.widgetName);
      const importPath = ensureNonEmptyString(args.importPath, "importPath");
      if (!importPath.includes("/widgets/v3/")) throw new ToolError("INVALID_ARGUMENT", "V3 Widgetbook importPath must point inside lib/widgets/v3.");
      return ok({
        themeVersion: "v3",
        fileToCreate: `lib/widgets/v3/${ensureNonEmptyString(args.category, "category")}/preview_${toSnakeCase(widgetName)}.dart`,
        code: `@widgetbook.UseCase(name: 'Default', type: ${widgetName})\nWidget build${widgetName}UseCase(BuildContext context) => const ${widgetName}(label: 'Label');`,
        importsToAdd: ["import 'package:flutter/material.dart';", "import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;", `import '${importPath}';`],
        instructions: ["Keep the preview under lib/widgets/v3.", "Add a Light/Dark toggle and important state matrix.", "Run dart run build_runner build --delete-conflicting-outputs."],
      });
    },
  };
}
