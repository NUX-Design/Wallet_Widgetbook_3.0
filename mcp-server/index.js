#!/usr/bin/env node

/**
 * mcp-server/index.js
 * Wi Wallet Design System MCP Server v2.0
 *
 * Tools:
 *  [Original]
 *   - get_design_system_info
 *   - list_widgets
 *   - get_widget_details
 *  [New — Figma-to-Flutter + Widgetbook]
 *   - get_color_token
 *   - get_flutter_widget_template
 *   - get_codebase_patterns
 *   - get_figma_to_flutter_mapping
 *   - generate_widget_code
 *   - generate_widgetbook_use_case
 */

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PROJECT_ROOT = path.resolve(__dirname, "..");

// ─── File paths ───────────────────────────────────────────────────────────────
const SCHEMA_PATH = path.join(PROJECT_ROOT, "docs", "schema.json");
const THEME_JSON_PATH = path.join(PROJECT_ROOT, "lib", "config", "themes", "theme.json");
const CODEBASE_CONTEXT_PATH = path.join(PROJECT_ROOT, "CODEBASE_CONTEXT.md");
const WIDGETS_GUIDE_PATH = path.join(PROJECT_ROOT, "WIDGETS_GUIDE.md");

// ─── Loaders ──────────────────────────────────────────────────────────────────
function loadJSON(filePath) {
  try {
    if (fs.existsSync(filePath)) {
      return JSON.parse(fs.readFileSync(filePath, "utf-8"));
    }
    return null;
  } catch (e) {
    console.error(`Error loading ${filePath}:`, e.message);
    return null;
  }
}

function loadText(filePath) {
  try {
    if (fs.existsSync(filePath)) return fs.readFileSync(filePath, "utf-8");
    return null;
  } catch (e) {
    return null;
  }
}

// ─── Theme JSON helpers ───────────────────────────────────────────────────────
/**
 * Build a flat token map from theme.json.
 * Returns: { light: { "primary/400": { value, var, rootAlias } }, dark: {...} }
 */
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

// ─── Widget → Widgetbook pattern map ─────────────────────────────────────────
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

// ─── Figma component → Flutter widget mapping ─────────────────────────────────
const FIGMA_TO_FLUTTER_MAP = {
  // Buttons
  "Button": { class: "Buttons", import: "package:mcp_test_app/widgets/button/buttons.dart", category: "button" },
  "Buttons": { class: "Buttons", import: "package:mcp_test_app/widgets/button/buttons.dart", category: "button" },
  // Cards
  "Card Review Transaction": { class: "CardReviewTransaction", import: "package:mcp_test_app/widgets/card/card_review_transaction.dart", category: "card" },
  "CardReviewTransaction": { class: "CardReviewTransaction", import: "package:mcp_test_app/widgets/card/card_review_transaction.dart", category: "card" },
  // Drawers
  "Drawer Review Transaction": { class: "DrawerReviewTransaction", import: "package:mcp_test_app/widgets/drawer/drawer_review_transaction.dart", category: "drawer" },
  "Drawer Balance Detail": { class: "DrawerBalanceDetail", import: "package:mcp_test_app/widgets/drawer/drawer_balance_detail.dart", category: "drawer" },
  "Drawer Deposit Channel": { class: "DrawerDepositChannel", import: "package:mcp_test_app/widgets/drawer/drawer_deposit_channel.dart", category: "drawer" },
  "Drawer Country Code": { class: "DrawerCountryCode", import: "package:mcp_test_app/widgets/drawer/drawer_country_code.dart", category: "drawer" },
  // Inputs
  "Full Amount Input": { class: "FullAmountInput", import: "package:mcp_test_app/widgets/input/full_amount_input.dart", category: "input" },
  "Mobile Code Input": { class: "MobileCodeInput", import: "package:mcp_test_app/widgets/input/mobile_code_input.dart", category: "input" },
  "Search Input": { class: "SearchInput", import: "package:mcp_test_app/widgets/input/search_input.dart", category: "input" },
  // Navigation
  "Navigator Bar": { class: "NavigatorBar", import: "package:mcp_test_app/widgets/navigator_bar/navigator_bar.dart", category: "navigator_bar" },
  "NavigatorBar": { class: "NavigatorBar", import: "package:mcp_test_app/widgets/navigator_bar/navigator_bar.dart", category: "navigator_bar" },
  // Visa
  "Visa Card": { class: "VisaCard", import: "package:mcp_test_app/widgets/visa/visa_card.dart", category: "visa" },
  "VisaCard": { class: "VisaCard", import: "package:mcp_test_app/widgets/visa/visa_card.dart", category: "visa" },
  // Announce
  "Announcement Stack": { class: "AnnouncementStack", import: "package:mcp_test_app/widgets/announce/announcement.dart", category: "announce" },
  "Announcement Warning": { class: "AnnouncementWarning", import: "package:mcp_test_app/widgets/announce/announcement_warning.dart", category: "announce" },
  // Others
  "Shortcut Menu Item": { class: "ShortcutMenuItem", import: "package:mcp_test_app/widgets/shortcut_menu/shortcut_menu.dart", category: "shortcut_menu" },
  "ShortcutMenuItem": { class: "ShortcutMenuItem", import: "package:mcp_test_app/widgets/shortcut_menu/shortcut_menu.dart", category: "shortcut_menu" },
  "Item List": { class: "ItemList", import: "package:mcp_test_app/widgets/item_list/item_list.dart", category: "item_list" },
  "Avatar": { class: "Avatar", import: "package:mcp_test_app/widgets/avatar/avatar.dart", category: "avatar" },
  "Image Carousel": { class: "ImageCarousel", import: "package:mcp_test_app/widgets/image_carousel/image_carousel.dart", category: "image_carousel" },
  "Snack Bar": { class: "SnackBarWidget", import: "package:mcp_test_app/widgets/snack_bar/snack_bar.dart", category: "snack_bar" },
  "SnackBar": { class: "SnackBarWidget", import: "package:mcp_test_app/widgets/snack_bar/snack_bar.dart", category: "snack_bar" },
  "Lottie Skeleton": { class: "LottieSkeleton", import: "package:mcp_test_app/widgets/skeleton/lottie_skeleton.dart", category: "skeleton" },
  "Pre Loading": { class: "PreLoading", import: "package:mcp_test_app/widgets/loading/pre_loading.dart", category: "loading" },
};

// ─── Widgetbook use-case builder ──────────────────────────────────────────────
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

// ─── MCP Server ───────────────────────────────────────────────────────────────
const server = new Server(
  { name: "wi-wallet-design-system", version: "2.0.0" },
  { capabilities: { tools: {} } }
);

// ─── Tool definitions ─────────────────────────────────────────────────────────
server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    // ── Original tools ──
    {
      name: "get_design_system_info",
      description:
        "Get high-level Wi_Wallet Design System information (project info, design tokens, widgets, implementation). Use to understand project structure.",
      inputSchema: {
        type: "object",
        properties: {
          section: {
            type: "string",
            enum: ["project", "designTokens", "widgets", "implementation"],
          },
        },
        required: ["section"],
      },
    },
    {
      name: "list_widgets",
      description: "List all available widgets in the design system, optionally filtered by category.",
      inputSchema: {
        type: "object",
        properties: {
          category: { type: "string", description: "Filter by category (e.g. 'input', 'card', 'drawer'). Omit for all." },
        },
      },
    },
    {
      name: "get_widget_details",
      description: "Get detailed information about a specific widget including properties and usage examples.",
      inputSchema: {
        type: "object",
        properties: {
          widgetName: { type: "string", description: "Exact widget name (e.g. 'FullAmountInput', 'Buttons')." },
        },
        required: ["widgetName"],
      },
    },

    // ── New v2.0 tools ──
    {
      name: "get_color_token",
      description:
        "Look up a design token from theme.json by its token name (as used in Figma variables). Returns the hex value for both Light and Dark modes, alias chain, and the correct Dart code to use in Flutter widgets. Token name format: 'primary/400', 'text/base/success', 'stroke/base/200'. Figma variable names like 'Color Theme/primary/400' are also accepted (prefix is stripped automatically).",
      inputSchema: {
        type: "object",
        properties: {
          tokenName: {
            type: "string",
            description: "Token name from Figma, e.g. 'primary/400', 'text/base/success', or 'Color Theme/fill/base/300'.",
          },
          mode: {
            type: "string",
            enum: ["light", "dark", "both"],
            description: "Which mode to return. Defaults to 'both'.",
          },
        },
        required: ["tokenName"],
      },
    },
    {
      name: "get_flutter_widget_template",
      description:
        "Get a correct Flutter widget boilerplate using the codebase conventions: ThemeColors.get(), GoogleFonts.notoSansThai(), Provider pattern, and proper imports.",
      inputSchema: {
        type: "object",
        properties: {
          widgetType: {
            type: "string",
            enum: ["stateless", "stateful"],
            description: "Whether the widget needs internal state.",
          },
          widgetName: { type: "string", description: "PascalCase class name, e.g. 'PaymentCard'." },
          category: { type: "string", description: "Widget category folder, e.g. 'card', 'drawer', 'input'." },
        },
        required: ["widgetType", "widgetName"],
      },
    },
    {
      name: "get_codebase_patterns",
      description:
        "Get coding conventions and patterns used in this project. Use BEFORE writing any Flutter code to ensure consistency.",
      inputSchema: {
        type: "object",
        properties: {
          pattern: {
            type: "string",
            enum: ["imports", "theme", "fonts", "state", "naming", "all"],
            description: "Which pattern category to return.",
          },
        },
        required: ["pattern"],
      },
    },
    {
      name: "get_figma_to_flutter_mapping",
      description:
        "Map a Figma component name to the corresponding Flutter widget class, import path, and category. Use when you know the Figma component name and need the correct Flutter implementation details.",
      inputSchema: {
        type: "object",
        properties: {
          figmaComponentName: {
            type: "string",
            description: "Figma component name, e.g. 'Button', 'Card Review Transaction', 'Drawer Balance Detail'.",
          },
        },
        required: ["figmaComponentName"],
      },
    },
    {
      name: "generate_widget_code",
      description:
        "Generate complete Flutter widget Dart code from a Figma component description. Produces a production-ready widget file using ThemeColors, GoogleFonts.notoSansThai(), and proper codebase patterns.",
      inputSchema: {
        type: "object",
        properties: {
          componentName: { type: "string", description: "PascalCase widget class name." },
          category: { type: "string", description: "Category folder, e.g. 'card', 'button'." },
          figmaDescription: { type: "string", description: "Description of the component from Figma (visual/functional)." },
          widgetType: { type: "string", enum: ["stateless", "stateful"], description: "State requirement." },
          properties: {
            type: "array",
            description: "List of widget properties.",
            items: {
              type: "object",
              properties: {
                name: { type: "string" },
                type: { type: "string" },
                required: { type: "boolean" },
                defaultValue: { type: "string" },
                description: { type: "string" },
              },
              required: ["name", "type"],
            },
          },
          hasTheme: { type: "boolean", description: "Widget uses ThemeColors for theming." },
          hasLocalization: { type: "boolean", description: "Widget uses AppLocalizations." },
          colorTokens: {
            type: "array",
            description: "Color tokens used (from Figma variables), e.g. ['primary/400', 'text/base/600'].",
            items: { type: "string" },
          },
        },
        required: ["componentName", "category", "figmaDescription", "widgetType"],
      },
    },
    {
      name: "generate_widgetbook_use_case",
      description:
        "Generate Widgetbook use case code (@widgetbook.UseCase annotations) for a widget. Run this AFTER generate_widget_code to get the matching Widgetbook entry. Returns code to append to lib/widgetbook_use_cases.dart.",
      inputSchema: {
        type: "object",
        properties: {
          widgetName: { type: "string", description: "PascalCase widget class name." },
          importPath: { type: "string", description: "Dart import path, e.g. 'package:mcp_test_app/widgets/card/my_card.dart'." },
          category: { type: "string", description: "Category folder used to determine wrapper pattern." },
          useCases: {
            type: "array",
            description: "Use cases to generate. Each has a name and optional sample props.",
            items: {
              type: "object",
              properties: {
                name: { type: "string", description: "Use case name, e.g. 'Default', 'Loading', 'Error'." },
                sampleProps: { type: "string", description: "Dart property assignments as a multiline string, e.g. \"amount: '5,000.00',\\n  currency: 'THB',\"" },
              },
              required: ["name"],
            },
          },
        },
        required: ["widgetName", "importPath", "category", "useCases"],
      },
    },
  ],
}));

// ─── Tool handlers ────────────────────────────────────────────────────────────
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    // ══════════════════════════════════════════════════
    // Original tools
    // ══════════════════════════════════════════════════

    if (name === "get_design_system_info") {
      const schema = loadJSON(SCHEMA_PATH);
      if (!schema) return err("Schema not found. Generate docs/schema.json first.");
      const { section } = args;
      let result;
      if (section === "project") result = schema.project;
      else if (section === "designTokens") result = schema.designTokens;
      else if (section === "implementation") result = schema.implementation;
      else if (section === "widgets")
        result = { count: schema.widgets?.total, categories: Object.keys(schema.widgets?.byCategory ?? {}) };
      else result = { availableSections: ["project", "designTokens", "widgets", "implementation"] };
      return ok(result);
    }

    if (name === "list_widgets") {
      const schema = loadJSON(SCHEMA_PATH);
      if (!schema) return err("Schema not found.");
      const category = args?.category;
      const widgets = category
        ? schema.widgets?.byCategory?.[category] ?? []
        : schema.widgets?.all ?? [];
      return ok(widgets.map((w) => ({ name: w.name, description: w.description, category: w.category })));
    }

    if (name === "get_widget_details") {
      const schema = loadJSON(SCHEMA_PATH);
      if (!schema) return err("Schema not found.");
      const widget = schema.widgets?.all?.find((w) => w.name === args.widgetName);
      if (!widget) return err(`Widget '${args.widgetName}' not found.`);
      return ok(widget);
    }

    // ══════════════════════════════════════════════════
    // New v2.0 tools
    // ══════════════════════════════════════════════════

    // ── get_color_token ──────────────────────────────
    if (name === "get_color_token") {
      const themeJson = loadJSON(THEME_JSON_PATH);
      if (!themeJson) return err("theme.json not found at lib/config/themes/theme.json");

      const tokenMap = buildTokenMap(themeJson);
      // Strip Figma prefix like "Color Theme/"
      let tokenName = (args.tokenName ?? "").trim();
      const prefixMatch = tokenName.match(/^[^/]+Theme\//i);
      if (prefixMatch) tokenName = tokenName.slice(prefixMatch[0].length);

      const mode = args.mode ?? "both";
      const lightEntry = tokenMap.light[tokenName];
      const darkEntry = tokenMap.dark[tokenName];

      if (!lightEntry && !darkEntry) {
        // Try partial match
        const allTokens = Object.keys(tokenMap.light);
        const suggestions = allTokens.filter((k) => k.includes(tokenName.split("/")[0])).slice(0, 10);
        return err(
          `Token '${tokenName}' not found in theme.json.\nDid you mean one of:\n${suggestions.map((s) => `  - ${s}`).join("\n")}`
        );
      }

      const entry = lightEntry ?? darkEntry;
      const result = {
        tokenName,
        lightValue: lightEntry?.value ?? "N/A",
        darkValue: darkEntry?.value ?? (lightEntry?.value ?? "N/A"),
        var: entry.var || "(none — primitive token)",
        rootAlias: entry.rootAlias || "(none — primitive token)",
        dartUsage: `ThemeColors.get(brightnessKey, '${tokenName}')`,
        note:
          lightEntry?.value === darkEntry?.value || !darkEntry
            ? "Same value in Light and Dark modes."
            : "Values differ between Light and Dark modes.",
      };

      if (mode === "light") delete result.darkValue;
      if (mode === "dark") delete result.lightValue;

      return ok(result);
    }

    // ── get_flutter_widget_template ──────────────────
    if (name === "get_flutter_widget_template") {
      const { widgetType, widgetName, category } = args;
      const categoryFolder = category ? `widgets/${category}/` : "widgets/";
      const fileName = widgetName
        .replace(/([a-z])([A-Z])/g, "$1_$2")
        .toLowerCase();

      if (widgetType === "stateless") {
        return ok({
          filePath: `lib/${categoryFolder}${fileName}.dart`,
          code: `import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mcp_test_app/config/themes/theme_color.dart';

class ${widgetName} extends StatelessWidget {
  // TODO: Add required properties here
  const ${widgetName}({super.key});

  @override
  Widget build(BuildContext context) {
    final brightnessKey =
        Theme.of(context).brightness == Brightness.light ? 'light' : 'dark';

    return Container(
      // TODO: Implement widget using ThemeColors and design tokens
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
            "1. Add this file to lib/${categoryFolder}${fileName}.dart",
            "2. Replace the placeholder properties and build() body with your implementation",
            "3. Always use ThemeColors.get(brightnessKey, 'token/name') for colors",
            "4. Always use GoogleFonts.notoSansThai() for text styles",
            "5. Run generate_widgetbook_use_case after to create the Widgetbook entry",
          ],
        });
      }

      // stateful
      return ok({
        filePath: `lib/${categoryFolder}${fileName}.dart`,
        code: `import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mcp_test_app/config/themes/theme_color.dart';

class ${widgetName} extends StatefulWidget {
  // TODO: Add required properties here
  const ${widgetName}({super.key});

  @override
  State<${widgetName}> createState() => _${widgetName}State();
}

class _${widgetName}State extends State<${widgetName}> {
  // TODO: Add state variables here

  @override
  Widget build(BuildContext context) {
    final brightnessKey =
        Theme.of(context).brightness == Brightness.light ? 'light' : 'dark';

    return Container(
      // TODO: Implement widget
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
          "1. Add this file to lib/${categoryFolder}${fileName}.dart",
          "2. Add properties to the StatefulWidget class (immutable)",
          "3. Add mutable state to _${widgetName}State",
          "4. Always use ThemeColors.get(brightnessKey, 'token/name') for colors",
          "5. Always use GoogleFonts.notoSansThai() for text styles",
        ],
      });
    }

    // ── get_codebase_patterns ─────────────────────────
    if (name === "get_codebase_patterns") {
      const { pattern } = args;
      const allPatterns = {
        imports: {
          title: "Import conventions",
          rules: [
            "Use package imports: 'package:mcp_test_app/...' (never relative for cross-module)",
            "Relative imports only within the same feature folder",
            "Import order: flutter/material.dart → google_fonts → mcp_test_app packages",
          ],
          examples: [
            "import 'package:flutter/material.dart';",
            "import 'package:google_fonts/google_fonts.dart';",
            "import 'package:mcp_test_app/config/themes/theme_color.dart';",
            "import 'package:mcp_test_app/widgets/button/buttons.dart';",
          ],
        },
        theme: {
          title: "Theme & Color token usage",
          rules: [
            "ALWAYS use ThemeColors.get() — never hardcode hex colors",
            "Detect brightness at the top of build(): final brightnessKey = Theme.of(context).brightness == Brightness.light ? 'light' : 'dark';",
            "Token format: '{category}/{variant}/{intensity}' e.g. 'primary/400', 'text/base/600', 'fill/contrast/600'",
          ],
          examples: [
            "final brightnessKey = Theme.of(context).brightness == Brightness.light ? 'light' : 'dark';",
            "color: ThemeColors.get(brightnessKey, 'primary/400'),",
            "color: ThemeColors.get(brightnessKey, 'text/base/600'),",
            "color: ThemeColors.get(brightnessKey, 'fill/base/100'),",
            "color: ThemeColors.get(brightnessKey, 'stroke/base/200'),",
            "color: ThemeColors.get(brightnessKey, 'text/base/success'),",
            "color: ThemeColors.get(brightnessKey, 'text/base/danger'),",
          ],
        },
        fonts: {
          title: "Typography conventions",
          rules: [
            "ALWAYS use GoogleFonts.notoSansThai() for all text styles",
            "Standard font sizes: 12 (caption), 14 (body), 15 (body medium), 16 (subtitle), 18 (title), 20 (heading)",
            "Standard line heights (height): 1.33 for body, 1.25 for headings",
            "Font weights: w400 (regular), w500 (medium), w600 (semibold), w700 (bold)",
          ],
          examples: [
            "style: GoogleFonts.notoSansThai(fontSize: 14, fontWeight: FontWeight.w400, color: ThemeColors.get(brightnessKey, 'text/base/600')),",
            "style: GoogleFonts.notoSansThai(fontSize: 15, fontWeight: FontWeight.w700, color: ThemeColors.get(brightnessKey, 'primary/400')),",
            "style: GoogleFonts.notoSansThai(fontSize: 16, fontWeight: FontWeight.w600, color: ThemeColors.get(brightnessKey, 'text/base/600')),",
          ],
        },
        state: {
          title: "State management patterns",
          rules: [
            "StatelessWidget for purely presentational components",
            "StatefulWidget for components with animations, toggles, or local interaction state",
            "Use Provider (via context.watch / Consumer) for app-level state (theme, locale)",
            "No setState for theme switching — use ThemeProvider via Provider",
          ],
          examples: [
            "// Read theme from Provider:\nfinal themeProvider = Provider.of<ThemeProvider>(context);",
            "// StatefulWidget for press animation:\nbool _isPressed = false;\nonTapDown: (_) => setState(() => _isPressed = true),",
          ],
        },
        naming: {
          title: "Naming conventions",
          rules: [
            "Widget files: snake_case.dart (e.g. card_review_transaction.dart)",
            "Widget classes: PascalCase (e.g. CardReviewTransaction)",
            "Preview files: preview_{widget}.dart (for standalone testing)",
            "Guide docs: {WIDGET}_GUIDE.md",
            "Widgetbook use cases: build{WidgetName}{UseCase}(BuildContext context)",
            "Folder structure: lib/widgets/{category}/{widget_name}.dart",
          ],
          examples: [
            "lib/widgets/card/card_review_transaction.dart → class CardReviewTransaction",
            "lib/widgets/card/preview_card_review_transaction.dart → preview widget",
            "test function: Widget buildCardReviewTransaction(BuildContext context)",
          ],
        },
      };

      const result = pattern === "all" ? allPatterns : { [pattern]: allPatterns[pattern] };
      return ok(result);
    }

    // ── get_figma_to_flutter_mapping ─────────────────
    if (name === "get_figma_to_flutter_mapping") {
      const { figmaComponentName } = args;
      const mapping = FIGMA_TO_FLUTTER_MAP[figmaComponentName];

      if (!mapping) {
        const suggestions = Object.keys(FIGMA_TO_FLUTTER_MAP).filter((k) =>
          k.toLowerCase().includes(figmaComponentName.toLowerCase().split(" ")[0])
        );
        return ok({
          found: false,
          message: `No mapping found for '${figmaComponentName}'. This may be a new widget that needs to be created.`,
          suggestions: suggestions.length ? suggestions : Object.keys(FIGMA_TO_FLUTTER_MAP),
          createNewWidget: {
            step1: "Call get_flutter_widget_template to get the widget boilerplate",
            step2: "Call generate_widget_code to generate the full implementation",
            step3: "Call generate_widgetbook_use_case for the Widgetbook entry",
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
    }

    // ── generate_widget_code ─────────────────────────
    if (name === "generate_widget_code") {
      const {
        componentName,
        category,
        figmaDescription,
        widgetType,
        properties = [],
        hasTheme = true,
        hasLocalization = false,
        colorTokens = [],
      } = args;

      const fileName = componentName.replace(/([a-z])([A-Z])/g, "$1_$2").toLowerCase();
      const filePath = `lib/widgets/${category}/${fileName}.dart`;

      // Build props declarations
      const propsDecl = properties
        .map((p) => {
          const nullable = !p.required ? "?" : "";
          const defaultVal = p.defaultValue ? ` = ${p.defaultValue}` : "";
          return `  final ${p.type}${nullable} ${p.name};`;
        })
        .join("\n");

      const constructorParams = properties
        .map((p) => {
          const prefix = p.required ? "required " : "";
          return `    ${prefix}this.${p.name},`;
        })
        .join("\n");

      // Build color token usage comments
      const tokenComments = colorTokens.length
        ? colorTokens.map((t) => `    // ThemeColors.get(brightnessKey, '${t}')`).join("\n")
        : "    // ThemeColors.get(brightnessKey, 'fill/base/100')";

      const imports = [
        "import 'package:flutter/material.dart';",
        "import 'package:google_fonts/google_fonts.dart';",
        "import 'package:mcp_test_app/config/themes/theme_color.dart';",
        ...(hasLocalization
          ? ["import 'package:mcp_test_app/generated/intl/app_localizations.dart';"]
          : []),
      ].join("\n");

      let classCode;
      if (widgetType === "stateless") {
        classCode = `class ${componentName} extends StatelessWidget {
${propsDecl ? propsDecl + "\n" : ""}
  const ${componentName}({
    super.key,
${constructorParams}
  });

  @override
  Widget build(BuildContext context) {
    final brightnessKey =
        Theme.of(context).brightness == Brightness.light ? 'light' : 'dark';
    ${hasLocalization ? "// final l10n = AppLocalizations.of(context)!;" : ""}

    // TODO: Implement ${componentName} based on Figma design:
    // ${figmaDescription}
    //
    // Color tokens to use:
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
}`;
      } else {
        classCode = `class ${componentName} extends StatefulWidget {
${propsDecl ? propsDecl + "\n" : ""}
  const ${componentName}({
    super.key,
${constructorParams}
  });

  @override
  State<${componentName}> createState() => _${componentName}State();
}

class _${componentName}State extends State<${componentName}> {
  // TODO: Add state variables

  @override
  Widget build(BuildContext context) {
    final brightnessKey =
        Theme.of(context).brightness == Brightness.light ? 'light' : 'dark';
    ${hasLocalization ? "// final l10n = AppLocalizations.of(context)!;" : ""}

    // TODO: Implement ${componentName} based on Figma design:
    // ${figmaDescription}
    //
    // Color tokens to use:
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
      }

      return ok({
        filePath,
        code: `${imports}\n\n${classCode}\n`,
        nextStep: `Run generate_widgetbook_use_case with widgetName="${componentName}", importPath="package:mcp_test_app/${filePath.replace("lib/", "")}", category="${category}"`,
        tokenResolution: colorTokens.length
          ? `Run get_color_token for each of: ${colorTokens.join(", ")} to get exact values`
          : "No specific tokens specified — check Figma variables for the correct tokens",
      });
    }

    // ── generate_widgetbook_use_case ─────────────────
    if (name === "generate_widgetbook_use_case") {
      const { widgetName, importPath, category, useCases } = args;
      const pattern = WIDGETBOOK_PATTERNS[category] ?? "simple";

      const useCaseBlocks = useCases.map((uc) => {
        const safeName = uc.name.replace(/\s+/g, "");
        const functionName = `build${widgetName}${safeName === "Default" ? "" : safeName}`;
        const props = uc.sampleProps ? `          ${uc.sampleProps}` : "";

        let block;
        if (uc.name !== "Default") {
          // Secondary use cases always use simple pattern
          block = `@widgetbook.UseCase(name: '${uc.name}', type: ${widgetName})
Widget ${functionName}(BuildContext context) {
  return const Padding(
    padding: EdgeInsets.all(16.0),
    child: ${widgetName}(
${props}
    ),
  );
}`;
        } else {
          switch (pattern) {
            case "blurOverlay":
              block = buildBlurOverlayUseCase(widgetName, functionName, props);
              break;
            case "localization":
              block = buildLocalizationUseCase(widgetName, functionName, props);
              break;
            case "scaffold":
              block = buildScaffoldUseCase(widgetName, functionName);
              break;
            default:
              block = buildSimpleUseCase(widgetName, functionName, props);
          }
        }
        return block;
      });

      // Build required imports
      const needsBlur = pattern === "blurOverlay";
      const needsLocale = pattern === "localization" || pattern === "scaffold";
      const extraImports = [
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
        importsToAdd: extraImports,
        codeToAppend: `\n// ${widgetName}\n${useCaseBlocks.join("\n\n")}\n`,
        instructions: [
          `1. Add the import(s) to the imports section of lib/widgetbook_use_cases.dart`,
          `2. Append the use case code to the bottom of lib/widgetbook_use_cases.dart`,
          `3. Run: flutter pub run build_runner build --delete-conflicting-outputs`,
          `4. Verify with: flutter run -d chrome -t lib/widgetbook.dart`,
        ],
      });
    }

    return err(`Unknown tool: ${name}`);
  } catch (e) {
    return err(`Error in tool '${name}': ${e.message}`);
  }
});

// ─── Response helpers ─────────────────────────────────────────────────────────
function ok(data) {
  return { content: [{ type: "text", text: JSON.stringify(data, null, 2) }] };
}
function err(msg) {
  return { content: [{ type: "text", text: msg }], isError: true };
}

// ─── Start ────────────────────────────────────────────────────────────────────
const transport = new StdioServerTransport();
await server.connect(transport);
console.error("Wi Wallet MCP Server v2.0 started.");
