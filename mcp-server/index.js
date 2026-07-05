#!/usr/bin/env node

import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import path from "path";
import { fileURLToPath } from "url";
import { createStructuredLogger } from "./observability.js";
import {
  DEFAULT_SERVER_NAME,
  DEFAULT_SERVER_VERSION,
  createMcpServer,
} from "./app.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(__dirname, "..");
const logger = createStructuredLogger({
  level: process.env.MCP_LOG_LEVEL ?? "silent",
  baseContext: {
    serverName: DEFAULT_SERVER_NAME,
    serverVersion: DEFAULT_SERVER_VERSION,
  },
});
const { server } = createMcpServer({
  projectRoot,
  serverName: DEFAULT_SERVER_NAME,
  serverVersion: DEFAULT_SERVER_VERSION,
  logger,
});

const transport = new StdioServerTransport();
await server.connect(transport);
logger.info("server.started", {
  transport: "stdio",
  projectRoot,
});
