import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import fs from "fs";
import path from "path";
import { createStructuredLogger, measureDurationMs } from "./observability.js";
import { DEFAULT_SERVER_NAME, DEFAULT_SERVER_VERSION } from "./server_metadata.js";
import { toolDefinitions } from "./tool_contracts.js";
import {
  ToolError,
  buildPaginatedWidgetsPayload,
  ensureEnum,
  ensureNonEmptyString,
  fail,
  ok,
  parsePagination,
} from "./tool_runtime.js";
import { WidgetCatalog } from "./widget_catalog.js";

export { DEFAULT_SERVER_NAME, DEFAULT_SERVER_VERSION };

const WIDGETBOOK_PATTERNS = {
  drawer: "blurOverlay",
  navigator_bar: "scaffold",
  announce: "localization",
  input: "localization",
  card: "simple",
  button: "simple",
  visa: "simple",
  snack_bar: "simple",
  skeleton: "simple",
  loading: "simple",
  avatar: "simple",
  image_carousel: "simple",
  item_list: "simple",
  shortcut_menu: "simple",
};

const FIGMA_TO_FLUTTER_MAP = {
  Button: {
    class: "Buttons",
    import: "package:mcp_test_app/widgets/button/buttons.dart",
    category: "button",
  },
  Buttons: {
    class: "Buttons",
    import: "package:mcp_test_app/widgets/button/buttons.dart",
    category: "button",
  },
  "Card Review Transaction": {
    class: "CardReviewTransaction",
    import: "package:mcp_test_app/widgets/card/card_review_transaction.dart",
    category: "card",
  },
  CardReviewTransaction: {
    class: "CardReviewTransaction",
    import: "package:mcp_test_app/widgets/card/card_review_transaction.dart",
    category: "card",
  },
  "Drawer Review Transaction": {
    class: "DrawerReviewTransaction",
    import: "package:mcp_test_app/widgets/drawer/drawer_review_transaction.dart",
    category: "drawer",
  },
  "Drawer Balance Detail": {
    class: "DrawerBalanceDetail",
    import: "package:mcp_test_app/widgets/drawer/drawer_balance_detail.dart",
    category: "drawer",
  },
  "Drawer Deposit Channel": {
    class: "DrawerDepositChannel",
    import: "package:mcp_test_app/widgets/drawer/drawer_deposit_channel.dart",
    category: "drawer",
  },
  "Drawer Country Code": {
    class: "DrawerCountryCode",
    import: "package:mcp_test_app/widgets/drawer/drawer_country_code.dart",
    category: "drawer",
  },
  "Full Amount Input": {
    class: "FullAmountInput",
    import: "package:mcp_test_app/widgets/input/full_amount_input.dart",
    category: "input",
  },
  "Mobile Code Input": {
    class: "MobileCodeInput",
    import: "package:mcp_test_app/widgets/input/mobile_code_input.dart",
    category: "input",
  },
  "Search Input": {
    class: "SearchInput",
    import: "package:mcp_test_app/widgets/input/search_input.dart",
    category: "input",
  },
  "Navigator Bar": {
    class: "NavigatorBar",
    import: "package:mcp_test_app/widgets/navigator_bar/navigator_bar.dart",
    category: "navigator_bar",
  },
  NavigatorBar: {
    class: "NavigatorBar",
    import: "package:mcp_test_app/widgets/navigator_bar/navigator_bar.dart",
    category: "navigator_bar",
  },
  "Visa Card": {
    class: "VisaCard",
    import: "package:mcp_test_app/widgets/visa/visa_card.dart",
    category: "visa",
  },
  VisaCard: {
    class: "VisaCard",
    import: "package:mcp_test_app/widgets/visa/visa_card.dart",
    category: "visa",
  },
  "Announcement Stack": {
    class: "AnnouncementStack",
    import: "package:mcp_test_app/widgets/announce/announcement.dart",
    category: "announce",
  },
  "Announcement Warning": {
    class: "AnnouncementWarning",
    import: "package:mcp_test_app/widgets/announce/announcement_warning.dart",
    category: "announce",
  },
  "Shortcut Menu Item": {
    class: "ShortcutMenuItem",
    import: "package:mcp_test_app/widgets/shortcut_menu/shortcut_menu.dart",
    category: "shortcut_menu",
  },
  ShortcutMenuItem: {
    class: "ShortcutMenuItem",
    import: "package:mcp_test_app/widgets/shortcut_menu/shortcut_menu.dart",
    category: "shortcut_menu",
  },
  "Item List": {
    class: "ItemList",
    import: "package:mcp_test_app/widgets/item_list/item_list.dart",
    category: "item_list",
  },
  Avatar: {
    class: "Avatar",
    import: "package:mcp_test_app/widgets/avatar/avatar.dart",
    category: "avatar",
  },
  "Image Carousel": {
    class: "ImageCarousel",
    import: "package:mcp_test_app/widgets/image_carousel/image_carousel.dart",
    category: "image_carousel",
  },
  "Snack Bar": {
    class: "SnackBarWidget",
    import: "package:mcp_test_app/widgets/snack_bar/snack_bar.dart",
    category: "snack_bar",
  },
  SnackBar: {
    class: "SnackBarWidget",
    import: "package:mcp_test_app/widgets/snack_bar/snack_bar.dart",
    category: "snack_bar",
  },
  "Lottie Skeleton": {
    class: "LottieSkeleton",
    import: "package:mcp_test_app/widgets/skeleton/lottie_skeleton.dart",
    category: "skeleton",
  },
  "Pre Loading": {
    class: "PreLoading",
    import: "package:mcp_test_app/widgets/loading/pre_loading.dart",
    category: "loading",
  },
};

function loadJSON(filePath) {
  try {
    if (fs.existsSync(filePath)) {
      return JSON.parse(fs.readFileSync(filePath, "utf-8"));
    }
    return null;
  } catch (error) {
    throw new ToolError("INTERNAL_ERROR", `Failed to load JSON from "${filePath}".`, {
      hint: "Validate that the JSON file exists and is not malformed.",
      details: { path: filePath, cause: error.message },
    });
  }
}

function buildTokenMap(themeJson) {
  const map = { light: {}, dark: {} };
  if (!Array.isArray(themeJson)) return map;

  for (const theme of themeJson) {
    for (const modeEntry of theme.values ?? []) {
      const modeName = modeEntry.mode?.name?.toLowerCase() ?? "light";
      const key = modeName === "dark" ? "dark" : "light";
      for (const token of modeEntry.color ?? []) {
        map[key][token.name] = {
          value: token.value,
          var: token.var ?? "",
          rootAlias: token.rootAlias ?? "",
        };
      }
    }
  }

  return map;
}

function buildBlurOverlayUseCase(widgetName, functionName, props) {
  return `@widgetbook.UseCase(name: 'Default', type: ${widgetName})
Widget ${functionName}(BuildContext context) {
  return Stack(
    children: [
      Positioned.fill(
        child: GestureDetector(
          onTap: () {},
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withValues(alpha: 0.5)),
          ),
        ),
      ),
      const Align(
        alignment: Alignment.bottomCenter,
        child: ${widgetName}(
${props}
        ),
      ),
    ],
  );
}`;
}

function buildLocalizationUseCase(widgetName, functionName, props) {
  return `@widgetbook.UseCase(name: 'Default', type: ${widgetName})
Widget ${functionName}(BuildContext context) {
  return Localizations(
    delegates: AppLocalizations.localizationsDelegates,
    locale: const Locale('en'),
    child: Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: ${widgetName}(
${props}
        ),
      ),
    ),
  );
}`;
}

function buildSimpleUseCase(widgetName, functionName, props) {
  return `@widgetbook.UseCase(name: 'Default', type: ${widgetName})
Widget ${functionName}(BuildContext context) {
  return const Padding(
    padding: EdgeInsets.all(16.0),
    child: ${widgetName}(
${props}
    ),
  );
}`;
}

function buildScaffoldUseCase(widgetName, functionName) {
  return `@widgetbook.UseCase(name: 'Default', type: ${widgetName})
Widget ${functionName}(BuildContext context) {
  return Localizations(
    delegates: AppLocalizations.localizationsDelegates,
    locale: const Locale('en'),
    child: Builder(
      builder: (context) => const Scaffold(
        extendBody: true,
        body: Center(child: Text('${widgetName} Preview')),
        bottomNavigationBar: ${widgetName}(),
      ),
    ),
  );
}`;
}

function summarizeWidget(widget) {
  return {
    name: widget.name,
    category: widget.category,
    widgetFile: widget.widgetFile,
    previewFiles: widget.previewFiles,
    tags: widget.tags,
    updatedAt: widget.updatedAt,
  };
}

function buildWidgetMetadata(widget) {
  return {
    name: widget.name,
    category: widget.category,
    widgetFile: widget.widgetFile,
    previewFiles: widget.previewFiles,
    docFiles: widget.docFiles,
    props: widget.props,
    dependencies: widget.dependencies,
    internalImports: widget.internalImports,
    assets: widget.assets,
    tags: widget.tags,
    figmaLinks: widget.figmaLinks,
    updatedAt: widget.updatedAt,
    metadataSources: widget.metadataSources,
    metadataConfidence: widget.metadataConfidence,
    warnings: widget.warnings,
  };
}

function summarizeArgsForLog(args) {
  const summary = {
    argKeys: Object.keys(args ?? {}).sort(),
  };

  if (typeof args.widgetName === "string") summary.widgetName = args.widgetName;
  if (typeof args.category === "string") summary.category = args.category;
  if (typeof args.query === "string") summary.query = args.query.slice(0, 120);
  if (args.limit !== undefined) summary.limit = args.limit;
  if (args.offset !== undefined) summary.offset = args.offset;
  if (typeof args.section === "string") summary.section = args.section;
  if (typeof args.tokenName === "string") summary.tokenName = args.tokenName;
  if (typeof args.widgetType === "string") summary.widgetType = args.widgetType;

  return summary;
}

export function createToolDispatcher({
  projectRoot,
  logger = createStructuredLogger(),
  widgetCatalog = new WidgetCatalog(projectRoot, { logger }),
}) {
  const schemaPath = path.join(projectRoot, "docs", "schema.json");
  const themeJsonPath = path.join(projectRoot, "lib", "config", "themes", "theme.json");

  const widgetLibraryHandlers = {
    async list_categories() {
      const categories = await widgetCatalog.listCategories();
      return ok({ categories });
    },

    async list_widgets(args) {
      const category = args.category?.trim() ? args.category.trim() : null;
      const { limit, offset } = parsePagination(args, {
        defaultLimit: 50,
        maxLimit: 200,
      });
      const allWidgets = await widgetCatalog.listWidgets(category ?? undefined);
      const widgets = allWidgets.slice(offset, offset + limit).map(summarizeWidget);

      return ok(
        buildPaginatedWidgetsPayload(
          { category },
          widgets,
          allWidgets.length,
          limit,
          offset,
        ),
      );
    },

    async search_widgets(args) {
      const query = ensureNonEmptyString(args.query, "query", 'Example: query="drawer"');
      const { limit, offset } = parsePagination(args, {
        defaultLimit: 10,
        maxLimit: 100,
      });
      const allWidgets = await widgetCatalog.searchWidgets(query);
      const widgets = allWidgets.slice(offset, offset + limit).map(summarizeWidget);

      return ok(
        buildPaginatedWidgetsPayload(
          { query },
          widgets,
          allWidgets.length,
          limit,
          offset,
        ),
      );
    },

    async get_widget_details(args) {
      return this.get_widget_metadata(args);
    },

    async get_widget_metadata(args) {
      const widgetName = ensureNonEmptyString(
        args.widgetName,
        "widgetName",
        'Use "list_widgets" or "search_widgets" first to discover valid names.',
      );
      const widget = await widgetCatalog.getWidget(widgetName);
      return ok(buildWidgetMetadata(widget));
    },

    async get_widget_code(args) {
      const widgetName = ensureNonEmptyString(
        args.widgetName,
        "widgetName",
        'Use "list_widgets" or "search_widgets" first to discover valid names.',
      );
      const widget = await widgetCatalog.getWidget(widgetName);
      return ok({
        widgetName: widget.name,
        widgetFile: widget.widgetFile,
        code: widgetCatalog.readRelativeFile(widget.widgetFile),
      });
    },

    async get_widget_preview(args) {
      const widgetName = ensureNonEmptyString(
        args.widgetName,
        "widgetName",
        'Use "list_widgets" or "search_widgets" first to discover valid names.',
      );
      const widget = await widgetCatalog.getWidget(widgetName);

      if (widget.previewFiles.length === 0) {
        throw new ToolError("EMPTY_RESULT", `Widget "${widget.name}" has no preview files.`, {
          hint: "Check the widget folder for preview_*.dart or *_preview.dart files, or add one before retrying.",
          details: { widgetName: widget.name },
        });
      }

      const previews = widget.previewFiles.map((file) => ({
        file,
        code: widgetCatalog.readRelativeFile(file),
      }));

      return ok({
        widgetName: widget.name,
        previews,
      });
    },
  };

  const designSystemHandlers = {
    async get_design_system_info(args) {
      const section = ensureEnum(args.section, "section", [
        "project",
        "designTokens",
        "widgets",
        "implementation",
      ]);
      const schema = loadJSON(schemaPath);
      if (!schema) {
        throw new ToolError("MISSING_RESOURCE", "Schema not found at docs/schema.json.", {
          hint: "Run `npm run generate-schema` from the repository root before retrying.",
        });
      }

      const dataBySection = {
        project: schema.project,
        designTokens: schema.designTokens,
        implementation: schema.implementation,
        widgets: {
          count: schema.widgets?.total,
          categories: Object.keys(schema.widgets?.byCategory ?? {}),
        },
      };

      return ok({
        section,
        data: dataBySection[section],
      });
    },

    async get_color_token(args) {
      const tokenNameInput = ensureNonEmptyString(
        args.tokenName,
        "tokenName",
        'Example: tokenName="text/base/600"',
      );
      const mode = args.mode ? ensureEnum(args.mode, "mode", ["light", "dark", "both"]) : "both";
      const themeJson = loadJSON(themeJsonPath);

      if (!themeJson) {
        throw new ToolError("MISSING_RESOURCE", "theme.json not found at lib/config/themes/theme.json.", {
          hint: "Verify that the theme token export exists before calling get_color_token.",
        });
      }

      const tokenMap = buildTokenMap(themeJson);
      let tokenName = tokenNameInput;
      const prefixMatch = tokenName.match(/^[^/]+Theme\//i);
      if (prefixMatch) tokenName = tokenName.slice(prefixMatch[0].length);

      const lightEntry = tokenMap.light[tokenName];
      const darkEntry = tokenMap.dark[tokenName];

      if (!lightEntry && !darkEntry) {
        const suggestions = Object.keys(tokenMap.light)
          .filter((key) => key.includes(tokenName.split("/")[0] ?? tokenName))
          .slice(0, 10);

        throw new ToolError("NOT_FOUND", `Token "${tokenName}" was not found in theme.json.`, {
          hint: suggestions.length
            ? `Try one of these tokens: ${suggestions.join(", ")}`
            : "Inspect theme.json for the canonical token names first.",
          details: { tokenName },
        });
      }

      const entry = lightEntry ?? darkEntry;
      const result = {
        tokenName,
        var: entry.var || "(none — primitive token)",
        rootAlias: entry.rootAlias || "(none — primitive token)",
        dartUsage: `ThemeColors.get(brightnessKey, '${tokenName}')`,
        note:
          lightEntry?.value === darkEntry?.value || !darkEntry
            ? "Same value in Light and Dark modes."
            : "Values differ between Light and Dark modes.",
      };

      if (mode !== "dark") result.lightValue = lightEntry?.value ?? "N/A";
      if (mode !== "light") result.darkValue = darkEntry?.value ?? lightEntry?.value ?? "N/A";

      return ok(result);
    },

    async get_flutter_widget_template(args) {
      const widgetType = ensureEnum(args.widgetType, "widgetType", ["stateless", "stateful"]);
      const widgetName = ensureNonEmptyString(args.widgetName, "widgetName");
      const category =
        typeof args.category === "string" && args.category.trim() ? args.category.trim() : null;
      const categoryFolder = category ? `widgets/${category}/` : "widgets/";
      const fileName = widgetName.replace(/([a-z])([A-Z])/g, "$1_$2").toLowerCase();

      if (widgetType === "stateless") {
        return ok({
          filePath: `lib/${categoryFolder}${fileName}.dart`,
          code: `import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mcp_test_app/config/themes/theme_color.dart';

class ${widgetName} extends StatelessWidget {
  const ${widgetName}({super.key});

  @override
  Widget build(BuildContext context) {
    final brightnessKey =
        Theme.of(context).brightness == Brightness.light ? 'light' : 'dark';

    return Container(
      decoration: BoxDecoration(
        color: ThemeColors.get(brightnessKey, 'fill/base/100'),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ThemeColors.get(brightnessKey, 'stroke/base/200'),
          width: 1,
        ),
      ),
      child: Text(
        '${widgetName}',
        style: GoogleFonts.notoSansThai(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: ThemeColors.get(brightnessKey, 'text/base/600'),
        ),
      ),
    );
  }
}
`,
          instructions: [
            `Add this file to lib/${categoryFolder}${fileName}.dart`,
            "Replace placeholder properties and the build() body with the actual implementation.",
            "Use ThemeColors.get(brightnessKey, 'token/name') for colors.",
            "Use GoogleFonts.notoSansThai() for text styles.",
            "Run generate_widgetbook_use_case after creating the widget.",
          ],
        });
      }

      return ok({
        filePath: `lib/${categoryFolder}${fileName}.dart`,
        code: `import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mcp_test_app/config/themes/theme_color.dart';

class ${widgetName} extends StatefulWidget {
  const ${widgetName}({super.key});

  @override
  State<${widgetName}> createState() => _${widgetName}State();
}

class _${widgetName}State extends State<${widgetName}> {
  @override
  Widget build(BuildContext context) {
    final brightnessKey =
        Theme.of(context).brightness == Brightness.light ? 'light' : 'dark';

    return Container(
      color: ThemeColors.get(brightnessKey, 'fill/base/100'),
      child: Text(
        '${widgetName}',
        style: GoogleFonts.notoSansThai(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: ThemeColors.get(brightnessKey, 'text/base/600'),
        ),
      ),
    );
  }
}
`,
        instructions: [
          `Add this file to lib/${categoryFolder}${fileName}.dart`,
          "Add immutable properties on the StatefulWidget and mutable state in the State class.",
          "Use ThemeColors.get(brightnessKey, 'token/name') for colors.",
          "Use GoogleFonts.notoSansThai() for text styles.",
        ],
      });
    },

    async get_codebase_patterns(args) {
      const pattern = ensureEnum(args.pattern, "pattern", [
        "imports",
        "theme",
        "fonts",
        "state",
        "naming",
        "all",
      ]);
      const allPatterns = {
        imports: {
          title: "Import conventions",
          rules: [
            "Use package imports: package:mcp_test_app/... for cross-module imports.",
            "Relative imports are acceptable only within the same feature folder.",
            "Import order: flutter/material.dart → google_fonts → mcp_test_app packages.",
          ],
        },
        theme: {
          title: "Theme & Color token usage",
          rules: [
            "Always use ThemeColors.get() instead of hardcoded hex colors.",
            "Resolve brightness once near the top of build().",
            "Follow the token pattern category/variant/intensity such as primary/400 or text/base/600.",
          ],
        },
        fonts: {
          title: "Typography conventions",
          rules: [
            "Prefer GoogleFonts.notoSansThai() for text styles in this codebase.",
            "Common sizes: 12, 14, 15, 16, 18, 20.",
            "Common weights: w400, w500, w600, w700.",
          ],
        },
        state: {
          title: "State management patterns",
          rules: [
            "Use StatelessWidget for presentational components.",
            "Use StatefulWidget for local interaction and animation state.",
            "Use Provider for app-level theme and locale state.",
          ],
        },
        naming: {
          title: "Naming conventions",
          rules: [
            "Widget files use snake_case.dart.",
            "Widget classes use PascalCase.",
            "Preview files follow preview_{widget}.dart or {widget}_preview.dart.",
            "Folder structure is lib/widgets/{category}/{widget_name}.dart.",
          ],
        },
      };

      return ok({
        pattern,
        data: pattern === "all" ? allPatterns : { [pattern]: allPatterns[pattern] },
      });
    },

    async get_figma_to_flutter_mapping(args) {
      const figmaComponentName = ensureNonEmptyString(
        args.figmaComponentName,
        "figmaComponentName",
      );
      const mapping = FIGMA_TO_FLUTTER_MAP[figmaComponentName];

      if (!mapping) {
        const suggestions = Object.keys(FIGMA_TO_FLUTTER_MAP).filter((key) =>
          key.toLowerCase().includes(figmaComponentName.toLowerCase().split(" ")[0]),
        );

        return ok({
          found: false,
          message: `No mapping found for "${figmaComponentName}".`,
          suggestions: suggestions.length ? suggestions : Object.keys(FIGMA_TO_FLUTTER_MAP),
          createNewWidget: {
            step1: "Call get_flutter_widget_template to get the widget boilerplate.",
            step2: "Call generate_widget_code to generate the full implementation.",
            step3: "Call generate_widgetbook_use_case for the Widgetbook entry.",
          },
        });
      }

      const pattern = WIDGETBOOK_PATTERNS[mapping.category] ?? "simple";
      return ok({
        found: true,
        figmaComponentName,
        flutterClass: mapping.class,
        importPath: mapping.import,
        category: mapping.category,
        widgetbookPattern: pattern,
        filePath: `lib/widgets/${mapping.category}/${mapping.class
          .replace(/([a-z])([A-Z])/g, "$1_$2")
          .toLowerCase()}.dart`,
      });
    },

    async generate_widget_code(args) {
      const componentName = ensureNonEmptyString(args.componentName, "componentName");
      const category = ensureNonEmptyString(args.category, "category");
      const figmaDescription = ensureNonEmptyString(args.figmaDescription, "figmaDescription");
      const widgetType = ensureEnum(args.widgetType, "widgetType", ["stateless", "stateful"]);
      const properties = Array.isArray(args.properties) ? args.properties : [];
      const hasLocalization = Boolean(args.hasLocalization);
      const colorTokens = Array.isArray(args.colorTokens) ? args.colorTokens : [];

      const fileName = componentName.replace(/([a-z])([A-Z])/g, "$1_$2").toLowerCase();
      const filePath = `lib/widgets/${category}/${fileName}.dart`;

      const propsDecl = properties
        .map((prop) => {
          const nullable = prop.required ? "" : "?";
          return `  final ${prop.type}${nullable} ${prop.name};`;
        })
        .join("\n");

      const constructorParams = properties
        .map((prop) => {
          const prefix = prop.required ? "required " : "";
          return `    ${prefix}this.${prop.name},`;
        })
        .join("\n");

      const tokenComments = colorTokens.length
        ? colorTokens
            .map((token) => `    // ThemeColors.get(brightnessKey, '${token}')`)
            .join("\n")
        : "    // ThemeColors.get(brightnessKey, 'fill/base/100')";

      const imports = [
        "import 'package:flutter/material.dart';",
        "import 'package:google_fonts/google_fonts.dart';",
        "import 'package:mcp_test_app/config/themes/theme_color.dart';",
        ...(hasLocalization
          ? ["import 'package:mcp_test_app/generated/intl/app_localizations.dart';"]
          : []),
      ].join("\n");

      const classCode =
        widgetType === "stateless"
          ? `class ${componentName} extends StatelessWidget {
${propsDecl ? `${propsDecl}\n` : ""}
  const ${componentName}({
    super.key,
${constructorParams}
  });

  @override
  Widget build(BuildContext context) {
    final brightnessKey =
        Theme.of(context).brightness == Brightness.light ? 'light' : 'dark';
    ${hasLocalization ? "// final l10n = AppLocalizations.of(context)!;" : ""}

    // TODO: Implement ${componentName}
    // ${figmaDescription}
${tokenComments}

    return Container(
      decoration: BoxDecoration(
        color: ThemeColors.get(brightnessKey, 'fill/base/100'),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ThemeColors.get(brightnessKey, 'stroke/base/200'),
        ),
      ),
      child: Text(
        '${componentName}',
        style: GoogleFonts.notoSansThai(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: ThemeColors.get(brightnessKey, 'text/base/600'),
        ),
      ),
    );
  }
}`
          : `class ${componentName} extends StatefulWidget {
${propsDecl ? `${propsDecl}\n` : ""}
  const ${componentName}({
    super.key,
${constructorParams}
  });

  @override
  State<${componentName}> createState() => _${componentName}State();
}

class _${componentName}State extends State<${componentName}> {
  @override
  Widget build(BuildContext context) {
    final brightnessKey =
        Theme.of(context).brightness == Brightness.light ? 'light' : 'dark';
    ${hasLocalization ? "// final l10n = AppLocalizations.of(context)!;" : ""}

    // TODO: Implement ${componentName}
    // ${figmaDescription}
${tokenComments}

    return Container(
      color: ThemeColors.get(brightnessKey, 'fill/base/100'),
      child: Text(
        '${componentName}',
        style: GoogleFonts.notoSansThai(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: ThemeColors.get(brightnessKey, 'text/base/600'),
        ),
      ),
    );
  }
}`;

      return ok({
        filePath,
        code: `${imports}\n\n${classCode}\n`,
        nextStep: `Run generate_widgetbook_use_case with widgetName="${componentName}", importPath="package:mcp_test_app/${filePath.replace("lib/", "")}", category="${category}"`,
        tokenResolution: colorTokens.length
          ? `Run get_color_token for each of: ${colorTokens.join(", ")}`
          : "No specific tokens provided.",
      });
    },

    async generate_widgetbook_use_case(args) {
      const widgetName = ensureNonEmptyString(args.widgetName, "widgetName");
      const importPath = ensureNonEmptyString(args.importPath, "importPath");
      const category = ensureNonEmptyString(args.category, "category");
      const useCases = Array.isArray(args.useCases) ? args.useCases : [];

      if (useCases.length === 0) {
        throw new ToolError(
          "INVALID_ARGUMENT",
          'Field "useCases" must contain at least one use case.',
          {
            hint: 'Pass at least one use-case object such as `{ "name": "Default" }`.',
          },
        );
      }

      const pattern = WIDGETBOOK_PATTERNS[category] ?? "simple";
      const useCaseBlocks = useCases.map((useCase) => {
        const useCaseName = ensureNonEmptyString(useCase.name, "useCases[].name");
        const safeName = useCaseName.replace(/\s+/g, "");
        const functionName = `build${widgetName}${safeName === "Default" ? "" : safeName}`;
        const props = useCase.sampleProps ? `          ${useCase.sampleProps}` : "";

        if (useCaseName !== "Default") {
          return `@widgetbook.UseCase(name: '${useCaseName}', type: ${widgetName})
Widget ${functionName}(BuildContext context) {
  return const Padding(
    padding: EdgeInsets.all(16.0),
    child: ${widgetName}(
${props}
    ),
  );
}`;
        }

        if (pattern === "blurOverlay") {
          return buildBlurOverlayUseCase(widgetName, functionName, props);
        }
        if (pattern === "localization") {
          return buildLocalizationUseCase(widgetName, functionName, props);
        }
        if (pattern === "scaffold") {
          return buildScaffoldUseCase(widgetName, functionName);
        }
        return buildSimpleUseCase(widgetName, functionName, props);
      });

      const needsBlur = pattern === "blurOverlay";
      const needsLocale = pattern === "localization" || pattern === "scaffold";
      const importsToAdd = [
        needsBlur ? "import 'dart:ui';" : null,
        needsBlur ? "import 'package:flutter/material.dart';" : null,
        needsLocale
          ? "import 'package:mcp_test_app/generated/intl/app_localizations.dart';"
          : null,
        `import '${importPath}';`,
      ]
        .filter(Boolean)
        .join("\n");

      return ok({
        pattern,
        fileToEdit: "lib/widgetbook_use_cases.dart",
        importsToAdd,
        codeToAppend: `\n// ${widgetName}\n${useCaseBlocks.join("\n\n")}\n`,
        instructions: [
          "Add the import(s) to lib/widgetbook_use_cases.dart.",
          "Append the generated use-case code.",
          "Run: dart run build_runner build --delete-conflicting-outputs",
          "Verify in Widgetbook.",
        ],
      });
    },
  };

  const toolHandlers = {
    ...designSystemHandlers,
    ...widgetLibraryHandlers,
  };

  return async function dispatchToolCall(name, args = {}) {
    const handler = toolHandlers[name];
    const startTime = performance.now();
    const argSummary = summarizeArgsForLog(args);

    if (!handler) {
      logger.warn("tool.call.error", {
        tool: name,
        durationMs: measureDurationMs(startTime),
        errorCode: "UNKNOWN_TOOL",
        ...argSummary,
      });
      return fail(
        new ToolError("UNKNOWN_TOOL", `Unknown tool "${name}".`, {
          hint: "Call tools/list to inspect the current tool registry for this server.",
        }),
      );
    }

    try {
      const result = await handler.call(toolHandlers, args);
      logger.info("tool.call.finish", {
        tool: name,
        ok: true,
        durationMs: measureDurationMs(startTime),
        structuredKeys: Object.keys(result.structuredContent ?? {}),
        ...argSummary,
      });
      return result;
    } catch (error) {
      if (error instanceof ToolError) {
        logger.warn("tool.call.error", {
          tool: name,
          ok: false,
          durationMs: measureDurationMs(startTime),
          errorCode: error.code,
          errorMessage: error.message,
          ...argSummary,
        });
        return fail(error);
      }

      logger.error("tool.call.error", {
        tool: name,
        ok: false,
        durationMs: measureDurationMs(startTime),
        errorCode: "INTERNAL_ERROR",
        errorMessage: error.message,
        ...argSummary,
      });
      return fail(
        new ToolError("INTERNAL_ERROR", `Tool "${name}" failed unexpectedly.`, {
          hint: "Retry the tool call. If the error persists, inspect the server logs.",
          details: { tool: name, cause: error.message },
        }),
      );
    }
  };
}

export function createMcpServer({
  projectRoot,
  serverName = DEFAULT_SERVER_NAME,
  serverVersion = DEFAULT_SERVER_VERSION,
  toolRegistry = toolDefinitions,
  dispatchToolCall: providedDispatchToolCall,
  widgetCatalog,
  logger = createStructuredLogger({
    baseContext: {
      serverName,
      serverVersion,
    },
  }),
}) {
  const dispatchToolCall =
    providedDispatchToolCall ?? createToolDispatcher({ projectRoot, logger, widgetCatalog });
  const server = new Server(
    { name: serverName, version: serverVersion },
    { capabilities: { tools: {} } },
  );

  server.setRequestHandler(ListToolsRequestSchema, async () => {
    const startTime = performance.now();
    const response = {
      tools: toolRegistry,
    };
    logger.debug("mcp.tools.list", {
      durationMs: measureDurationMs(startTime),
      toolCount: toolRegistry.length,
    });
    return response;
  });

  server.setRequestHandler(CallToolRequestSchema, async (request) =>
    dispatchToolCall(request.params.name, request.params.arguments ?? {}),
  );

  return { server, dispatchToolCall, logger };
}
