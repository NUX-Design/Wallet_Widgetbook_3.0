import {
  CLIENT_LABELS,
  ensureServerExists,
  parseArgs,
  resolveInstallOptions,
  resolveServerIndexPath,
  writeExampleConfigs,
  writeSettingsConfig,
} from "./installer.js";

function setup() {
  const cli = parseArgs(process.argv.slice(2));
  const options = resolveInstallOptions(cli, process.env);

  console.log("Generating MCP configuration...");

  try {
    const serverIndex = ensureServerExists(options.repoRoot);
    const exampleFiles = writeExampleConfigs(options);

    if (!options.settingsPath) {
      console.log(`✅ Wrote example configs for client target "${options.client}".`);
      for (const file of exampleFiles) {
        console.log(`- ${file.label}: ${file.path}`);
      }
      console.log("\nTo write directly into a client config file, rerun with:");
      console.log("  node install.js --client claude-code --settings /absolute/path/to/mcp.json");
      console.log("  node install.js --client codex-chatgpt-agent --settings /absolute/path/to/mcp.json");
      console.log("  node install.js --client cursor --settings /absolute/path/to/mcp.json");
      console.log("\nResolved server entry:");
      console.log(
        JSON.stringify(
          {
            command: "node",
            args: [serverIndex],
          },
          null,
          2,
        ),
      );
      return;
    }

    const writtenPath = writeSettingsConfig(options.settingsPath, options);

    console.log("\n✅ Success! MCP server configuration has been updated.");
    console.log(`🧩 Server Name: ${options.serverName}`);
    console.log(`🧩 Client Target: ${CLIENT_LABELS[options.client] ?? options.client}`);
    console.log(`📍 Repo Root: ${options.repoRoot}`);
    console.log(`📍 Server Path: ${resolveServerIndexPath(options.repoRoot)}`);
    console.log(`📄 Config Path: ${writtenPath}`);
    console.log("\nRefresh your MCP client after updating the config.");
  } catch (error) {
    console.error("❌ Failed to update configuration:", error.message);
    process.exit(1);
  }
}

setup();
