import fs from "node:fs";
import path from "node:path";
import { ToolError } from "../tool_runtime.js";
import { parseV3Widget } from "./widget_parser.js";

function walk(root, predicate, files = []) {
  if (!fs.existsSync(root)) return files;
  for (const entry of fs.readdirSync(root, { withFileTypes: true })) {
    const target = path.join(root, entry.name);
    if (entry.isDirectory()) walk(target, predicate, files);
    else if (predicate(entry.name)) files.push(target);
  }
  return files;
}

export class V3WidgetCatalog {
  constructor(repoRoot) { this.repoRoot = repoRoot; this.cache = null; }
  load() {
    if (this.cache) return this.cache;
    const root = path.join(this.repoRoot, "lib/widgets/v3");
    const dartFiles = walk(root, (name) => name.endsWith(".dart"));
    const widgets = [];
    for (const absolute of dartFiles.filter((file) => path.basename(file).startsWith("v3_"))) {
      const folder = path.dirname(absolute);
      const relative = path.relative(this.repoRoot, absolute).split(path.sep).join("/");
      const docFiles = walk(folder, (name) => name.endsWith(".md")).map((file) => path.relative(this.repoRoot, file).split(path.sep).join("/"));
      const previewFiles = dartFiles.filter((file) => path.dirname(file) === folder && path.basename(file).startsWith("preview_v3_")).map((file) => path.relative(this.repoRoot, file).split(path.sep).join("/"));
      widgets.push(...parseV3Widget({ repoRoot: this.repoRoot, filePath: relative, docFiles, previewFiles }));
    }
    this.cache = widgets.sort((a, b) => a.name.localeCompare(b.name));
    return this.cache;
  }
  list(category) { return this.load().filter((widget) => !category || widget.category === category.toLowerCase()); }
  search(query) {
    const terms = query.trim().toLowerCase().split(/\s+/).filter(Boolean);
    return this.load().filter((widget) => terms.every((term) => [widget.name, widget.category, widget.docsText, ...widget.semanticTokens].join(" ").toLowerCase().includes(term)));
  }
  get(name) {
    const widget = this.load().find((entry) => entry.name.toLowerCase() === name.trim().toLowerCase());
    if (widget) return widget;
    throw new ToolError("NOT_FOUND", `V3 widget "${name}" was not found.`, { hint: "Call list_v3_widgets or search_v3_widgets first.", details: { widgetName: name } });
  }
  read(relativePath) {
    const allowedRoot = path.resolve(this.repoRoot, "lib/widgets/v3");
    const target = path.resolve(this.repoRoot, relativePath);
    if (!target.startsWith(`${allowedRoot}${path.sep}`)) throw new ToolError("INVALID_ARGUMENT", "V3 widget file is outside lib/widgets/v3.");
    return fs.readFileSync(target, "utf8");
  }
  audit(widget) {
    const findings = [];
    const add = (severity, code, message) => findings.push({ severity, code, message });
    if (widget.themeVersion !== "v3") add("error", "MISSING_THEME_VERSION", "Local guide must declare Theme system: V3.");
    if (/config\/themes\/(?:theme_color|base_theme)|ThemeColors\.get\s*\(/.test(widget.sourceText)) add("error", "LEGACY_THEME_IMPORT", "V3 widget imports or calls the legacy theme API.");
    if (/\bColor\s*\(\s*0x[0-9a-f]+\s*\)/i.test(widget.sourceText)) add("error", "RAW_COLOR", "V3 widget contains a raw Color literal.");
    if (!/V3ThemeScope\.colorsOf\s*\(context\)/.test(widget.sourceText)) add("error", "MISSING_V3_THEME_SCOPE", "V3 widget must read semantic colors through V3ThemeScope.colorsOf(context).");
    if (widget.previewFiles.length === 0) add("warning", "MISSING_PREVIEW", "V3 widget has no standalone preview.");
    if (widget.docFiles.length === 0 || widget.semanticTokens.length === 0) add("warning", "MISSING_TOKEN_METADATA", "V3 widget guide has no Semantic tokens metadata.");
    return { themeVersion: "v3", widgetName: widget.name, passed: !findings.some((item) => item.severity === "error"), findings };
  }
}
