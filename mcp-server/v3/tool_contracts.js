const readOnly = { readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: false };
const objectOutput = { type: "object", additionalProperties: true };
const offset = { type: "number", minimum: 0 };

export const v3ToolDefinitions = [
  {
    name: "get_v3_design_system_info", title: "Get V3 Design System Info", description: "Return Theme/Widget V3 project, token, widget, or implementation information without legacy fallback.",
    inputSchema: { type: "object", properties: { section: { type: "string", enum: ["project", "designTokens", "widgets", "implementation"] } }, required: ["section"], additionalProperties: false },
    outputSchema: objectOutput, annotations: readOnly,
  },
  {
    name: "list_v3_categories", title: "List V3 Widget Categories", description: "List categories indexed exclusively from lib/widgets/v3.",
    inputSchema: { type: "object", properties: {}, additionalProperties: false }, outputSchema: objectOutput, annotations: readOnly,
  },
  {
    name: "list_v3_color_tokens", title: "List V3 Color Tokens",
    description: "List Theme V3 semantic color tokens with Light/Dark values, aliases, and Dart metadata.",
    inputSchema: { type: "object", properties: { mode: { type: "string", enum: ["light", "dark", "both"] }, limit: { type: "number", minimum: 1, maximum: 200 }, offset }, additionalProperties: false },
    outputSchema: objectOutput, annotations: readOnly,
  },
  {
    name: "search_v3_color_tokens", title: "Search V3 Color Tokens",
    description: "Search Theme V3 semantic tokens by path, Dart property, or primitive alias.",
    inputSchema: { type: "object", properties: { query: { type: "string" }, limit: { type: "number", minimum: 1, maximum: 100 }, offset }, required: ["query"], additionalProperties: false },
    outputSchema: objectOutput, annotations: readOnly,
  },
  {
    name: "get_v3_color_token", title: "Get V3 Color Token",
    description: "Get one Theme V3 semantic token with Light/Dark values, primitive aliases, and V3ThemeScope usage.",
    inputSchema: { type: "object", properties: { tokenName: { type: "string" }, mode: { type: "string", enum: ["light", "dark", "both"] } }, required: ["tokenName"], additionalProperties: false },
    outputSchema: objectOutput, annotations: readOnly,
  },
  {
    name: "list_v3_widgets", title: "List V3 Widgets", description: "List widgets indexed exclusively from lib/widgets/v3.",
    inputSchema: { type: "object", properties: { category: { type: "string" }, limit: { type: "number", minimum: 1, maximum: 200 }, offset }, additionalProperties: false },
    outputSchema: objectOutput, annotations: readOnly,
  },
  {
    name: "search_v3_widgets", title: "Search V3 Widgets", description: "Search V3 widgets across names, categories, local docs, and semantic token metadata.",
    inputSchema: { type: "object", properties: { query: { type: "string" }, limit: { type: "number", minimum: 1, maximum: 100 }, offset }, required: ["query"], additionalProperties: false },
    outputSchema: objectOutput, annotations: readOnly,
  },
  ...[
    ["get_v3_widget_details", "Get V3 Widget Details", "Backward-compatible V3 alias returning the same isolated metadata as get_v3_widget_metadata."],
    ["get_v3_widget_metadata", "Get V3 Widget Metadata", "Return V3 widget paths, API metadata, theme version, Figma nodes, and token dependencies."],
    ["get_v3_widget_code", "Get V3 Widget Code", "Return Dart source exclusively from a V3 widget implementation."],
    ["get_v3_widget_preview", "Get V3 Widget Preview", "Return standalone preview source files exclusively from lib/widgets/v3."],
    ["audit_v3_widget", "Audit V3 Widget", "Audit a V3 widget for legacy theme imports, raw colors, V3ThemeScope usage, preview, and token metadata."],
  ].map(([name, title, description]) => ({ name, title, description, inputSchema: { type: "object", properties: { widgetName: { type: "string" } }, required: ["widgetName"], additionalProperties: false }, outputSchema: objectOutput, annotations: readOnly })),
  {
    name: "get_v3_flutter_widget_template", title: "Get V3 Flutter Widget Template", description: "Return V3-prefixed Flutter boilerplate using V3ThemeScope and V3 paths.",
    inputSchema: { type: "object", properties: { widgetType: { type: "string", enum: ["stateless", "stateful"] }, widgetName: { type: "string" }, category: { type: "string" } }, required: ["widgetType", "widgetName", "category"], additionalProperties: false },
    outputSchema: objectOutput, annotations: readOnly,
  },
  {
    name: "get_v3_codebase_patterns", title: "Get V3 Codebase Patterns", description: "Return Widget V3 implementation, theme, naming, state, typography, and accessibility rules.",
    inputSchema: { type: "object", properties: { pattern: { type: "string", enum: ["imports", "theme", "fonts", "state", "naming", "accessibility", "all"] } }, required: ["pattern"], additionalProperties: false },
    outputSchema: objectOutput, annotations: readOnly,
  },
  {
    name: "get_v3_figma_to_flutter_mapping", title: "Get V3 Figma To Flutter Mapping", description: "Map a Figma component name only to indexed Widget V3 implementations and metadata.",
    inputSchema: { type: "object", properties: { figmaComponentName: { type: "string" } }, required: ["figmaComponentName"], additionalProperties: false },
    outputSchema: objectOutput, annotations: readOnly,
  },
  {
    name: "generate_v3_widget_code", title: "Generate V3 Widget Code", description: "Return V3 widget source boilerplate constrained to V3 paths and semantic tokens; does not write files.",
    inputSchema: { type: "object", properties: { componentName: { type: "string" }, category: { type: "string" }, figmaDescription: { type: "string" }, widgetType: { type: "string", enum: ["stateless", "stateful"] }, semanticTokens: { type: "array", items: { type: "string" } } }, required: ["componentName", "category", "figmaDescription", "widgetType"], additionalProperties: false },
    outputSchema: objectOutput, annotations: readOnly,
  },
  {
    name: "generate_v3_widgetbook_use_case", title: "Generate V3 Widgetbook Use Case", description: "Return V3 standalone preview/Widgetbook use-case code without writing files.",
    inputSchema: { type: "object", properties: { widgetName: { type: "string" }, importPath: { type: "string" }, category: { type: "string" } }, required: ["widgetName", "importPath", "category"], additionalProperties: false },
    outputSchema: objectOutput, annotations: readOnly,
  },
];
