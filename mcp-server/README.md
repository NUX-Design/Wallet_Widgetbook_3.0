# Wi_Wallet Design System - MCP Server

This directory contains the Model Context Protocol (MCP) server for the Wi_Wallet Design System. It allows AI-powered coding assistants to understand and consume our design tokens, widgets, and implementation rules.

## 🚀 Team Installation (Automated)

We have provided a script to automatically configure your local development environment. This will register the MCP server with correctly resolved absolute paths for your specific machine.

### Prerequisites

- **Node.js**: Version 18 or higher.
- **Project Cloned**: Ensure you have this project repository on your local machine.

### Installation Steps

1. **Open your terminal** and navigate to this directory:
   ```bash
   cd mcp-server
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Run the setup script**:
   ```bash
   npm run install-mcp
   ```

4. **Restart your IDE**: After the script finishes successfully, restart Antigravity (or your IDE) to activate the server.

---

## 🛠 Manual Configuration (If needed)

If you prefer to configure it manually, add the following to your `mcp_settings.json`:

```json
"wi-wallet-design-system": {
  "command": "node",
  "args": [
    "/ABSOLUTE/PATH/TO/PROJECT/mcp-server/index.js"
  ]
}
```

## 📚 Features

- **Project Info**: High-level overview of the Wi_Wallet design system.
- **Design Tokens**: Direct access to themed colors and styles.
- **Widget Catalog**: Detailed documentation and implementation examples for all widgets (e.g., `FullAmountInput`, `VisaCard`, `AnnouncementStack`).
- **Implementation Rules**: Best practices for layout, styling, and localization.

## 💻 Development

To run the server in developer mode for debugging:

```bash
node index.js
```

The server uses Standard Input/Output (stdio) for communication.
