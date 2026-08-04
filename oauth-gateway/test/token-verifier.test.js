import assert from "node:assert/strict";
import test from "node:test";
import { createLocalJWKSet, exportJWK, generateKeyPair, SignJWT } from "jose";
import { createTokenVerifier } from "../src/token-verifier.js";

const issuer = "https://tenant.auth0.com/";
const audience = "https://gateway.example.com/mcp";

async function fixture() {
  const { privateKey, publicKey } = await generateKeyPair("RS256");
  const publicJwk = await exportJWK(publicKey);
  publicJwk.kid = "test-key";
  publicJwk.alg = "RS256";
  publicJwk.use = "sig";
  const config = {
    issuer,
    audience,
    jwksUrl: `${issuer}.well-known/jwks.json`,
    requiredScope: "mcp:read",
    maxTokenAgeSeconds: 86_400,
    allowedSubjects: new Set(["auth0|owner"]),
    allowedClients: new Set(["gemini-client"]),
    revokedJtis: new Set(["revoked-token-id"]),
  };
  const verify = createTokenVerifier(config, createLocalJWKSet({ keys: [publicJwk] }));

  async function token(claims = {}, options = {}) {
    const now = Math.floor(Date.now() / 1000);
    let builder = new SignJWT({
      scope: "mcp:read",
      client_id: "gemini-client",
      ...claims,
    })
      .setProtectedHeader({ alg: "RS256", kid: "test-key" })
      .setIssuer(options.issuer ?? issuer)
      .setAudience(options.audience ?? audience)
      .setSubject(options.subject ?? "auth0|owner");
    if (!options.omitIssuedAt) builder = builder.setIssuedAt(options.issuedAt ?? now);
    if (!options.omitExpiration) builder = builder.setExpirationTime(options.expiration ?? now + 300);
    if (!options.omitNotBefore) builder = builder.setNotBefore(options.notBefore ?? now - 1);
    return builder.sign(options.privateKey ?? privateKey);
  }

  return { verify, token };
}

test("accepts an RS256 token with exact issuer, audience, scope, subject, and client", async () => {
  const { verify, token } = await fixture();
  assert.deepEqual(await verify(`Bearer ${await token()}`), {
    issuer,
    subject: "auth0|owner",
    clientId: "gemini-client",
  });
});

test("rejects wrong issuer/audience, expiration, revocation, scope, subject, and client", async () => {
  const { verify, token } = await fixture();
  await assert.rejects(verify(`Bearer ${await token({}, { issuer: "https://other.auth0.com/" })}`), /unexpected "iss" claim value/);
  await assert.rejects(verify(`Bearer ${await token({}, { audience: "https://other.example.com/mcp" })}`), /unexpected "aud" claim value/);
  await assert.rejects(verify(`Bearer ${await token({}, { expiration: Math.floor(Date.now() / 1000) - 10 })}`), /"exp" claim timestamp check failed/);
  await assert.rejects(verify(`Bearer ${await token({ jti: "revoked-token-id" })}`), /revoked_token/);
  await assert.rejects(verify(`Bearer ${await token({ scope: "other" })}`), /insufficient_scope/);
  await assert.rejects(verify(`Bearer ${await token({}, { subject: "auth0|other" })}`), /invalid_subject/);
  await assert.rejects(verify(`Bearer ${await token({ client_id: "other-client" })}`), /invalid_client/);
});

test("rejects missing bearer and invalid signatures", async () => {
  const { verify, token } = await fixture();
  assert.rejects(verify(""), /missing_token/);
  const { privateKey: foreignKey } = await generateKeyPair("RS256");
  await assert.rejects(verify(`Bearer ${await token({}, { privateKey: foreignKey })}`), /signature verification failed/);
});

test("requires temporal claims and rejects future or excessive token lifetimes", async () => {
  const { verify, token } = await fixture();
  const now = Math.floor(Date.now() / 1000);
  await assert.rejects(verify(`Bearer ${await token({}, { omitExpiration: true })}`), /missing required "exp" claim/);
  await assert.rejects(verify(`Bearer ${await token({}, { omitIssuedAt: true })}`), /missing required "iat" claim/);
  await assert.rejects(verify(`Bearer ${await token({}, { notBefore: now + 300 })}`), /"nbf" claim timestamp check failed/);
  await assert.rejects(verify(`Bearer ${await token({}, { issuedAt: now - 90_000, expiration: now + 300 })}`), /token_lifetime_exceeded|"iat" claim timestamp check failed/);
});
