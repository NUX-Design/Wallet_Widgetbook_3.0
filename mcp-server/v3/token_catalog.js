import path from "node:path";
import { ToolError } from "../tool_runtime.js";
import { parseTokenFile, normalizeTokenPath } from "./token_parser.js";
import { resolveV3Tokens } from "./token_resolver.js";

export class V3TokenCatalog {
  constructor(repoRoot) { this.repoRoot = repoRoot; this.cache = null; }
  load() {
    if (this.cache) return this.cache;
    const root = path.join(this.repoRoot, "lib/config/themes/v3/tokens");
    this.cache = resolveV3Tokens(
      parseTokenFile(path.join(root, "primitive.tokens.json")),
      parseTokenFile(path.join(root, "semantic/light.tokens.json")),
      parseTokenFile(path.join(root, "semantic/dark.tokens.json")),
    );
    return this.cache;
  }
  list() { return this.load(); }
  search(query) {
    const terms = query.trim().toLowerCase().split(/\s+/).filter(Boolean);
    return this.load().filter((token) => terms.every((term) =>
      [token.tokenName, token.dartProperty, token.lightPrimitiveAlias, token.darkPrimitiveAlias].join(" ").toLowerCase().includes(term),
    ));
  }
  get(name) {
    const normalized = normalizeTokenPath(name.replace(/^semantic[/.]/i, "").split(/[/.]/));
    const token = this.load().find((entry) => entry.tokenName === normalized || entry.dartProperty.toLowerCase() === name.toLowerCase());
    if (token) return token;
    const suggestions = this.search(name.split("/")[0] ?? name).slice(0, 10).map((entry) => entry.tokenName);
    throw new ToolError("NOT_FOUND", `V3 color token "${name}" was not found.`, {
      hint: suggestions.length ? `Try one of these V3 tokens: ${suggestions.join(", ")}` : "Call list_v3_color_tokens or search_v3_color_tokens first.",
      details: { tokenName: name, suggestions },
    });
  }
}
