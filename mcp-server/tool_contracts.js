import { v3ToolDefinitions } from "./v3/tool_contracts.js";

const readOnly = {
  readOnlyHint: true,
  destructiveHint: false,
  idempotentHint: true,
  openWorldHint: false,
};

const genericObjectSchema = {
  type: "object",
  additionalProperties: true,
};

const widgetSummarySchema = {
  type: "object",
  properties: {
    name: { type: "string" },
    category: { type: "string" },
    widgetFile: { type: "string" },
    previewFiles: { type: "array", items: { type: "string" } },
    tags: { type: "array", items: { type: "string" } },
    updatedAt: { type: "string" },
  },
  required: ["name", "category", "widgetFile", "previewFiles", "tags", "updatedAt"],
  additionalProperties: false,
};

const widgetPropSchema = {
  type: "object",
  properties: {
    name: { type: "string" },
    type: { type: "string" },
    required: { type: "boolean" },
    defaultValue: { type: "string" },
    description: { type: "string" },
    source: { type: "string", enum: ["code", "docs"] },
  },
  required: ["name", "type", "required", "source"],
  additionalProperties: false,
};

const widgetMetadataSchema = {
  type: "object",
  properties: {
    name: { type: "string" },
    category: { type: "string" },
    widgetFile: { type: "string" },
    previewFiles: { type: "array", items: { type: "string" } },
    docFiles: { type: "array", items: { type: "string" } },
    props: { type: "array", items: widgetPropSchema },
    dependencies: { type: "array", items: { type: "string" } },
    internalImports: { type: "array", items: { type: "string" } },
    assets: { type: "array", items: { type: "string" } },
    tags: { type: "array", items: { type: "string" } },
    figmaLinks: { type: "array", items: { type: "string" } },
    updatedAt: { type: "string" },
    metadataSources: {
      type: "object",
      properties: {
        props: { type: "string" },
        dependencies: { type: "string" },
        previews: { type: "string" },
        docs: { type: "string" },
        figmaLinks: { type: "string" },
        updatedAt: { type: "string" },
      },
      required: ["props", "dependencies", "previews", "docs", "figmaLinks", "updatedAt"],
      additionalProperties: false,
    },
    metadataConfidence: {
      type: "object",
      properties: {
        props: { type: "string", enum: ["low", "medium", "high"] },
        previews: { type: "string", enum: ["low", "medium", "high"] },
        docs: { type: "string", enum: ["low", "medium", "high"] },
        figmaLinks: { type: "string", enum: ["low", "medium", "high"] },
        overall: { type: "string", enum: ["low", "medium", "high"] },
      },
      required: ["props", "previews", "docs", "figmaLinks", "overall"],
      additionalProperties: false,
    },
    warnings: { type: "array", items: { type: "string" } },
  },
  required: [
    "name",
    "category",
    "widgetFile",
    "previewFiles",
    "docFiles",
    "props",
    "dependencies",
    "internalImports",
    "assets",
    "tags",
    "figmaLinks",
    "updatedAt",
    "metadataSources",
    "metadataConfidence",
    "warnings",
  ],
  additionalProperties: false,
};

const paginatedWidgetsOutputSchema = (contextProperties, requiredContextFields) => ({
  type: "object",
  properties: {
    ...contextProperties,
    total: { type: "number" },
    count: { type: "number" },
    limit: { type: "number" },
    offset: { type: "number" },
    hasMore: { type: "boolean" },
    widgets: { type: "array", items: widgetSummarySchema },
  },
  required: [
    ...requiredContextFields,
    "total",
    "count",
    "limit",
    "offset",
    "hasMore",
    "widgets",
  ],
  additionalProperties: false,
});

export const toolDefinitions = [
  {
    name: "get_design_system_info",
    title: "Get Design System Info",
    description:
      "Get high-level design-system information from schema/docs, scoped to one section.",
    inputSchema: {
      type: "object",
      properties: {
        section: {
          type: "string",
          enum: ["project", "designTokens", "widgets", "implementation"],
        },
      },
      required: ["section"],
      additionalProperties: false,
    },
    outputSchema: {
      type: "object",
      properties: {
        section: { type: "string" },
        data: genericObjectSchema,
      },
      required: ["section", "data"],
      additionalProperties: false,
    },
    annotations: readOnly,
  },
  {
    name: "list_categories",
    title: "List Widget Categories",
    description: "Return all widget categories available in the Flutter widget library.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false,
    },
    outputSchema: {
      type: "object",
      properties: {
        categories: { type: "array", items: { type: "string" } },
      },
      required: ["categories"],
      additionalProperties: false,
    },
    annotations: readOnly,
  },
  {
    name: "list_widgets",
    title: "List Widgets",
    description:
      "List widgets from the Flutter widget library, optionally filtered by category and paginated.",
    inputSchema: {
      type: "object",
      properties: {
        category: {
          type: "string",
          description: "Optional category such as input, avatar, drawer, or button.",
        },
        limit: { type: "number", minimum: 1, maximum: 200 },
        offset: { type: "number", minimum: 0 },
      },
      additionalProperties: false,
    },
    outputSchema: paginatedWidgetsOutputSchema(
      { category: { type: ["string", "null"] } },
      ["category"],
    ),
    annotations: readOnly,
  },
  {
    name: "search_widgets",
    title: "Search Widgets",
    description:
      "Search widgets by keyword across widget names, categories, tags, docs, and source text.",
    inputSchema: {
      type: "object",
      properties: {
        query: { type: "string" },
        limit: { type: "number", minimum: 1, maximum: 100 },
        offset: { type: "number", minimum: 0 },
      },
      required: ["query"],
      additionalProperties: false,
    },
    outputSchema: paginatedWidgetsOutputSchema(
      { query: { type: "string" } },
      ["query"],
    ),
    annotations: readOnly,
  },
  {
    name: "get_widget_details",
    title: "Get Widget Details",
    description:
      "Backward-compatible detailed metadata for a widget including props, dependencies, assets, docs, previews, and Figma links.",
    inputSchema: {
      type: "object",
      properties: {
        widgetName: { type: "string" },
      },
      required: ["widgetName"],
      additionalProperties: false,
    },
    outputSchema: widgetMetadataSchema,
    annotations: readOnly,
  },
  {
    name: "get_widget_metadata",
    title: "Get Widget Metadata",
    description:
      "Return widget metadata including props, dependencies, internal imports, assets, preview paths, docs, Figma links, tags, and last updated time.",
    inputSchema: {
      type: "object",
      properties: {
        widgetName: { type: "string" },
      },
      required: ["widgetName"],
      additionalProperties: false,
    },
    outputSchema: widgetMetadataSchema,
    annotations: readOnly,
  },
  {
    name: "get_widget_code",
    title: "Get Widget Code",
    description: "Return the full Dart source code for a widget base implementation file.",
    inputSchema: {
      type: "object",
      properties: {
        widgetName: { type: "string" },
      },
      required: ["widgetName"],
      additionalProperties: false,
    },
    outputSchema: {
      type: "object",
      properties: {
        widgetName: { type: "string" },
        widgetFile: { type: "string" },
        code: { type: "string" },
      },
      required: ["widgetName", "widgetFile", "code"],
      additionalProperties: false,
    },
    annotations: readOnly,
  },
  {
    name: "get_widget_preview",
    title: "Get Widget Preview",
    description: "Return the preview/demo Dart source files associated with a widget.",
    inputSchema: {
      type: "object",
      properties: {
        widgetName: { type: "string" },
      },
      required: ["widgetName"],
      additionalProperties: false,
    },
    outputSchema: {
      type: "object",
      properties: {
        widgetName: { type: "string" },
        previews: {
          type: "array",
          items: {
            type: "object",
            properties: {
              file: { type: "string" },
              code: { type: "string" },
            },
            required: ["file", "code"],
            additionalProperties: false,
          },
        },
      },
      required: ["widgetName", "previews"],
      additionalProperties: false,
    },
    annotations: readOnly,
  },
  {
    name: "get_color_token",
    title: "Get Color Token",
    description:
      "Look up a color token from theme.json and return light/dark values plus the correct Dart usage.",
    inputSchema: {
      type: "object",
      properties: {
        tokenName: { type: "string" },
        mode: { type: "string", enum: ["light", "dark", "both"] },
      },
      required: ["tokenName"],
      additionalProperties: false,
    },
    outputSchema: {
      type: "object",
      properties: {
        tokenName: { type: "string" },
        lightValue: { type: "string" },
        darkValue: { type: "string" },
        var: { type: "string" },
        rootAlias: { type: "string" },
        dartUsage: { type: "string" },
        note: { type: "string" },
      },
      required: ["tokenName", "var", "rootAlias", "dartUsage", "note"],
      additionalProperties: false,
    },
    annotations: readOnly,
  },
  {
    name: "get_flutter_widget_template",
    title: "Get Flutter Widget Template",
    description:
      "Get a Flutter widget boilerplate that follows the repo's codebase conventions.",
    inputSchema: {
      type: "object",
      properties: {
        widgetType: { type: "string", enum: ["stateless", "stateful"] },
        widgetName: { type: "string" },
        category: { type: "string" },
      },
      required: ["widgetType", "widgetName"],
      additionalProperties: false,
    },
    outputSchema: {
      type: "object",
      properties: {
        filePath: { type: "string" },
        code: { type: "string" },
        instructions: { type: "array", items: { type: "string" } },
      },
      required: ["filePath", "code", "instructions"],
      additionalProperties: false,
    },
    annotations: readOnly,
  },
  {
    name: "get_codebase_patterns",
    title: "Get Codebase Patterns",
    description:
      "Return coding conventions and implementation patterns used in this Flutter widget library.",
    inputSchema: {
      type: "object",
      properties: {
        pattern: {
          type: "string",
          enum: ["imports", "theme", "fonts", "state", "naming", "all"],
        },
      },
      required: ["pattern"],
      additionalProperties: false,
    },
    outputSchema: {
      type: "object",
      properties: {
        pattern: { type: "string" },
        data: genericObjectSchema,
      },
      required: ["pattern", "data"],
      additionalProperties: false,
    },
    annotations: readOnly,
  },
  {
    name: "get_figma_to_flutter_mapping",
    title: "Get Figma To Flutter Mapping",
    description:
      "Map a Figma component name to a Flutter widget class, import path, category, and Widgetbook pattern.",
    inputSchema: {
      type: "object",
      properties: {
        figmaComponentName: { type: "string" },
      },
      required: ["figmaComponentName"],
      additionalProperties: false,
    },
    outputSchema: genericObjectSchema,
    annotations: readOnly,
  },
  {
    name: "generate_widget_code",
    title: "Generate Widget Code",
    description:
      "Generate Flutter widget Dart code from a Figma component description using repo patterns and theme tokens.",
    inputSchema: {
      type: "object",
      properties: {
        componentName: { type: "string" },
        category: { type: "string" },
        figmaDescription: { type: "string" },
        widgetType: { type: "string", enum: ["stateless", "stateful"] },
        properties: {
          type: "array",
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
            additionalProperties: false,
          },
        },
        hasTheme: { type: "boolean" },
        hasLocalization: { type: "boolean" },
        colorTokens: { type: "array", items: { type: "string" } },
      },
      required: ["componentName", "category", "figmaDescription", "widgetType"],
      additionalProperties: false,
    },
    outputSchema: genericObjectSchema,
    annotations: readOnly,
  },
  {
    name: "generate_widgetbook_use_case",
    title: "Generate Widgetbook Use Case",
    description:
      "Generate Widgetbook use-case code for a widget and return import snippets plus append instructions.",
    inputSchema: {
      type: "object",
      properties: {
        widgetName: { type: "string" },
        importPath: { type: "string" },
        category: { type: "string" },
        useCases: {
          type: "array",
          items: {
            type: "object",
            properties: {
              name: { type: "string" },
              sampleProps: { type: "string" },
            },
            required: ["name"],
            additionalProperties: false,
          },
        },
      },
      required: ["widgetName", "importPath", "category", "useCases"],
      additionalProperties: false,
    },
    outputSchema: genericObjectSchema,
    annotations: readOnly,
  },
  ...v3ToolDefinitions,
];
