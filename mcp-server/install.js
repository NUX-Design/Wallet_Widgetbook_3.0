import fs from 'fs';
import path from 'path';
import os from 'os';
import { fileURLToPath } from 'url';

// Helper to get __dirname in ESM
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * Setup script for Wi_Wallet Design System MCP Server
 * This script automatically registers the server in Antigravity settings.
 */

// 1. Path to the MCP server entry point
const mcpIndex = path.resolve(__dirname, 'index.js');

// 2. Path to Antigravity's MCP settings
const settingsPath = path.join(
    os.homedir(),
    'Library/Application Support/Antigravity/User/globalStorage/kilocode.kilo-code/settings/mcp_settings.json'
);

function setup() {
    console.log('🚀 Starting MCP Server automated setup...');

    // Check if index.js exists
    if (!fs.existsSync(mcpIndex)) {
        console.error(`❌ Error: Could not find MCP server at ${mcpIndex}`);
        process.exit(1);
    }

    // Check if settings file exists
    if (!fs.existsSync(settingsPath)) {
        console.error(`❌ Error: Antigravity settings file not found at: ${settingsPath}`);
        console.log('💡 Please ensure Antigravity is installed and you have opened it at least once.');
        process.exit(1);
    }

    try {
        const config = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));

        // Initialize mcpServers if it doesn't exist
        if (!config.mcpServers) {
            config.mcpServers = {};
        }

        // Register/Update the server
        config.mcpServers["wi-wallet-design-system"] = {
            command: "node",
            args: [mcpIndex]
        };

        // Write back
        fs.writeFileSync(settingsPath, JSON.stringify(config, null, 2), 'utf8');

        console.log('\n✅ Success! MCP Server has been registered.');
        console.log(`📍 Server Path: ${mcpIndex}`);
        console.log('\n💡 Please restart your IDE or refresh MCP servers to see the changes.');

    } catch (err) {
        console.error('❌ Failed to update configuration:', err.message);
        process.exit(1);
    }
}

setup();
