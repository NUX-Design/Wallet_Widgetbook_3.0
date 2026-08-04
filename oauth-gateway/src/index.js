#!/usr/bin/env node

import { resolveGatewayConfig } from "./config.js";
import { createGatewayServer } from "./server.js";
import { createTokenVerifier } from "./token-verifier.js";

const config = resolveGatewayConfig();
const server = createGatewayServer({ config, verifyToken: createTokenVerifier(config) });

server.listen(config.port, config.host, () => {
  process.stderr.write(`${JSON.stringify({ event: "gateway.started", host: config.host, port: config.port, resource: config.resource })}\n`);
});

function shutdown(signal) {
  process.stderr.write(`${JSON.stringify({ event: "gateway.stopping", signal })}\n`);
  server.close(() => process.exit(0));
  setTimeout(() => process.exit(1), 30_000).unref();
}

process.once("SIGTERM", () => shutdown("SIGTERM"));
process.once("SIGINT", () => shutdown("SIGINT"));
