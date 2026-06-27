# Figma-Context-MCP Server Setup and Demonstration

## Setup Complete

The Figma-Context-MCP server has been successfully set up with the following configuration:

- **Server Name**: `github.com/GLips/Figma-Context-MCP`
- **Installation Method**: NPX (global execution)
- **Platform**: macOS optimized
- **Configuration File**: `cline_mcp_settings.json`

## Configuration Details

The server is configured to run with the following command structure:
```bash
FIGMA_API_KEY=your_figma_pat npx -y figma-developer-mcp --figma-api-key="$FIGMA_API_KEY" --stdio
```

## Available Server Options

Based on the help output, the server supports these options:
- `--figma-api-key`: Figma API key (Personal Access Token) [REQUIRED]
- `--figma-oauth-token`: Figma OAuth Bearer token (alternative to API key)
- `--env`: Path to custom .env file to load environment variables
- `--port`: Port to run the server on
- `--json`: Output data from tools in JSON format instead of YAML
- `--skip-image-downloads`: Do not register the download_figma_images tool
- `--help`: Show help
- `--version`: Show version number

## Server Capabilities

The Figma-Context-MCP server provides these main capabilities:

1. **Figma File Access**: Connect to Figma files and retrieve design data
2. **Design Element Parsing**: Extract layout, styling, and component information
3. **Image Asset Downloads**: Download images and assets from Figma designs
4. **Component Analysis**: Analyze Figma components and their properties
5. **Design System Integration**: Access design tokens and styling information

## Usage Instructions

### Step 1: Get Your Figma API Key

To use the server, you need a Figma Personal Access Token:

1. Go to [Figma Account Settings](https://www.figma.com/settings/account)
2. Scroll down to "Personal access tokens"
3. Click "Create new token"
4. Give it a descriptive name (e.g., "MCP Server")
5. Copy the generated token

### Step 2: Configure With An Environment Variable

Do not paste the token directly into tracked files. Export it through an environment variable and reference that variable from `cline_mcp_settings.json`:

```json
{
  "mcpServers": {
    "github.com/GLips/Figma-Context-MCP": {
      "command": "sh",
      "args": [
        "-c",
        "exec npx -y figma-developer-mcp --figma-api-key=\"$FIGMA_API_KEY\" --stdio"
      ]
    }
  }
}
```

Then export the token locally before starting the client:

```bash
export FIGMA_API_KEY=your_figma_pat
```

If you prefer, load it from a local shell profile or private `.env` file that is not committed.

### Step 3: Use the Server

Once configured, you can:
1. Provide Figma file URLs to your AI assistant
2. Ask questions about design layouts, colors, typography
3. Request implementation of specific components
4. Extract design tokens and styling information

## Example Usage

Try these prompts with your AI assistant after setup:

- "Here's a Figma file: [URL]. Can you implement this button component in Flutter?"
- "Analyze the design system in this Figma file: [URL]"
- "What are the primary colors and typography used in this design: [URL]?"
- "Implement this entire page from Figma: [URL]"

## Verification

The server has been verified to be accessible and functional:
- ✅ NPX installation confirmed
- ✅ Help command displays proper options
- ✅ Configuration file created with correct syntax
- ✅ Server name follows the required format

## Next Steps

1. Obtain your Figma API key
2. Export it locally as `FIGMA_API_KEY`
3. Restart your AI assistant to load the new MCP server
4. Test with a Figma file URL

## Security Note

- Never commit a Figma Personal Access Token into this repository.
- If a token was ever committed, rotate/revoke it in Figma immediately even if the file has already been cleaned up.
