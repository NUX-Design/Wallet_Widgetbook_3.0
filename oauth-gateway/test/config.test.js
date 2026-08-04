import assert from "node:assert/strict";
import test from "node:test";
import { resolveGatewayConfig } from "../src/config.js";

function env(overrides = {}) {
  return {
    GATEWAY_PUBLIC_ORIGIN: "https://gateway.example.com",
    AUTH0_ISSUER: "https://tenant.auth0.com/",
    AUTH0_AUDIENCE: "https://gateway.example.com/mcp",
    GATEWAY_ALLOWED_SUBJECTS: "auth0|owner",
    GATEWAY_ALLOWED_CLIENT_IDS: "gemini-client",
    GATEWAY_UPSTREAM_BEARER: "secret",
    ...overrides,
  };
}

test("resolves a fixed HTTPS gateway configuration", () => {
  const value = resolveGatewayConfig(env());
  assert.equal(value.resource, "https://gateway.example.com/mcp");
  assert.equal(value.upstreamUrl, "https://flutter-widget-wallet-mcp.onrender.com/mcp");
  assert.equal(value.jwksUrl, "https://tenant.auth0.com/.well-known/jwks.json");
  assert.deepEqual([...value.allowedSubjects], ["auth0|owner"]);
});

test("rejects non-HTTPS origins and non-MCP upstream paths", () => {
  assert.throws(() => resolveGatewayConfig(env({ GATEWAY_PUBLIC_ORIGIN: "http://gateway.example.com" })), /must use HTTPS/);
  assert.throws(() => resolveGatewayConfig(env({ GATEWAY_UPSTREAM_URL: "https://upstream.example.com/other" })), /fixed \/mcp path/);
});

test("requires explicit single-owner subject and client allowlists", () => {
  assert.throws(() => resolveGatewayConfig(env({ GATEWAY_ALLOWED_SUBJECTS: "" })), /required/);
  assert.throws(() => resolveGatewayConfig(env({ GATEWAY_ALLOWED_CLIENT_IDS: "" })), /required/);
});
