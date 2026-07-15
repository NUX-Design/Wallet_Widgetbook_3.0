import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { v3ToolDefinitions } from "../mcp-server/v3/tool_contracts.js";
import { REMOTE_READ_ONLY_TOOL_NAMES } from "../mcp-server/remote_support.js";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const skillNames = [
  "flutter-widget-v3-beginner",
  "flutter-widget-v3-search",
  "flutter-widget-v3-install",
  "flutter-widget-v3-adapt",
  "flutter-widget-v3-preview",
  "flutter-widget-v3-figma-to-code",
  "flutter-widget-v3-audit",
  "flutter-widget-v3-upgrade",
];
const packs = [
  { name: "codex", root: "skills-v3/codex/.codex/skills", openAiMetadata: true },
  { name: "claude-code", root: "skills-v3/claude-code/.claude/skills", readme: true },
  { name: "kiro", root: "skills-v3/kiro/.kiro/skills", readme: true },
];
const localOnlyTools = new Set([
  "generate_v3_widget_code",
  "generate_v3_widgetbook_use_case",
]);
const knownTools = new Set(v3ToolDefinitions.map((tool) => tool.name));
const violations = [];

function read(relativePath) {
  const absolutePath = path.join(repoRoot, relativePath);
  if (!fs.existsSync(absolutePath)) {
    violations.push(`${relativePath}: missing required file`);
    return "";
  }
  return fs.readFileSync(absolutePath, "utf8");
}

function toolNames(source) {
  const section = source.match(/## MCP Tools\s+([\s\S]*?)(?=\n## |$)/)?.[1] ?? "";
  return [...section.matchAll(/^- `([^`]+)`/gm)].map((match) => match[1]);
}

for (const pack of packs) {
  const packRoot = path.join(repoRoot, pack.root);
  const actualSkills = fs.existsSync(packRoot)
    ? fs.readdirSync(packRoot, { withFileTypes: true })
        .filter((entry) => entry.isDirectory())
        .map((entry) => entry.name)
        .sort()
    : [];
  if (JSON.stringify(actualSkills) !== JSON.stringify([...skillNames].sort())) {
    violations.push(`${pack.root}: expected exactly 8 canonical Skills V3 folders`);
  }
  if (pack.readme) {
    const readme = read(`${pack.root}/README.md`);
    if (!readme.includes("Remote-safe fallback")) {
      violations.push(`${pack.root}/README.md: missing Remote-safe fallback guidance`);
    }
    for (const marker of [
      "## Setup local live preview",
      "MCP_REMOTE_BEARER_TOKEN",
      "reused: true",
      "--stop-all",
      "STALE_BUNDLE",
    ]) {
      if (!readme.includes(marker)) {
        violations.push(`${pack.root}/README.md: missing preview setup marker ${marker}`);
      }
    }
    if (pack.name === "claude-code" && !readme.includes("permission mode `default`")) {
      violations.push(`${pack.root}/README.md: missing Claude Code default permission guidance`);
    }
    if (pack.name === "kiro" && !readme.includes(".kiro/settings/mcp.json")) {
      violations.push(`${pack.root}/README.md: missing Kiro MCP configuration path`);
    }
  }
  for (const skillName of skillNames) {
    const relativeSkill = `${pack.root}/${skillName}/SKILL.md`;
    const source = read(relativeSkill);
    const frontmatter = source.match(/^---\n([\s\S]*?)\n---/i)?.[1] ?? "";
    if (!frontmatter.includes(`name: ${skillName}`) || !/^description:\s*.+/m.test(frontmatter)) {
      violations.push(`${relativeSkill}: invalid name/description frontmatter`);
    }
    if (!source.includes("lib/widgets/v3/**") && !source.includes("Widget V3")) {
      violations.push(`${relativeSkill}: missing explicit Widget V3 scope`);
    }
    if (!/legacy|ThemeColors\.get\(\)/i.test(source)) {
      violations.push(`${relativeSkill}: missing legacy isolation guardrail`);
    }
    const tools = toolNames(source);
    for (const toolName of tools) {
      if (!knownTools.has(toolName)) violations.push(`${relativeSkill}: unknown MCP tool ${toolName}`);
      if (!toolName.includes("v3")) violations.push(`${relativeSkill}: legacy/ambiguous MCP tool ${toolName}`);
    }
    if (tools.some((toolName) => localOnlyTools.has(toolName)) && !source.includes("## Remote-Safe Fallback")) {
      violations.push(`${relativeSkill}: local-only generation tool lacks Remote-Safe Fallback`);
    }
    if (skillName === "flutter-widget-v3-beginner") {
      for (const step of ["Ask discovery questions", "Scan the workspace", "Summarize", "confirmation", "Execute only"]) {
        if (!source.includes(step)) violations.push(`${relativeSkill}: missing beginner flow marker ${step}`);
      }
      for (const marker of [
        "flutter create --project-name",
        "get_v3_theme_foundation",
        "lib/main.dart",
        "flutter analyze",
        "flutter test",
        "Never present bare labels",
        "existing-v3-foundation",
        "existing-flutter-no-v3",
        "no-flutter-yet",
        "additive-only` — recommended",
        "allow-structure-setup",
        "ask-before-overwrite",
        "organization identifier",
        "scan-only, auto-detect, auto, additive-only",
      ]) {
        if (!source.includes(marker)) violations.push(`${relativeSkill}: missing bootstrap-new marker ${marker}`);
      }
      if (/bootstrap-new[^\n]*stop here/i.test(source)) {
        violations.push(`${relativeSkill}: bootstrap-new still stops instead of creating a Flutter app`);
      }
    }
    if (skillName === "flutter-widget-v3-preview") {
      for (const marker of [
        "## Mode Selection — Run This First",
        "lib/preview_v3/",
        "scripts/serve-v3-preview.sh",
        "dart run tool/generate_v3_preview_registry.dart",
        "preview_registry.g.dart",
        "source-development mode automatically",
        "do not request a bearer token",
        "Never ask the user to paste, type, or reveal a token in chat",
        "one standalone Bash tool call",
        "Do not create `/tmp/delivery.json`",
        "do not prefix it with `node`",
        "use `default` mode",
        "--detach",
        "never respond with \"still waiting\"",
      ]) {
        if (!source.includes(marker)) violations.push(`${relativeSkill}: missing source-first preview marker ${marker}`);
      }
      if (source.includes("Choose published consumer mode by default")) {
        violations.push(`${relativeSkill}: still defaults to consumer mode inside the source repo`);
      }
      if (/ask the user for the hosted MCP bearer token/i.test(source)) {
        violations.push(`${relativeSkill}: still asks users to disclose bearer tokens in chat`);
      }
    }
    if (pack.openAiMetadata) {
      const metadataPath = `${pack.root}/${skillName}/agents/openai.yaml`;
      const metadata = read(metadataPath);
      if (!metadata.includes("display_name:") || !metadata.includes(`$${skillName}`)) {
        violations.push(`${metadataPath}: metadata does not match ${skillName}`);
      }
    }
  }
}

for (const toolName of localOnlyTools) {
  if (REMOTE_READ_ONLY_TOOL_NAMES.has(toolName)) {
    violations.push(`${toolName}: generation tool must remain excluded from remote registry`);
  }
}

if (violations.length > 0) {
  console.error("Skills V3 validation failed:");
  for (const violation of violations) console.error(`- ${violation}`);
  process.exitCode = 1;
} else {
  console.log(
    `Skills V3 validation passed (${packs.length} packs, ${skillNames.length} skills each, ` +
      `${knownTools.size} known V3 tools).`,
  );
}
