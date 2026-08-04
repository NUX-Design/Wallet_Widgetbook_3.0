# Flutter Widget Wallet OAuth Gateway

OAuth Resource Server and fixed streaming proxy for Gemini Spark. This package
does not implement an Authorization Server and does not own MCP tool contracts.

## Local verification

```bash
npm ci
npm test
npm run check
```

Generic remote smoke verification requires a short-lived access token issued by
the configured Authorization Server. The verifier never prints the token:

```bash
OAUTH_GATEWAY_ACCESS_TOKEN="<short-lived-access-token>" npm run verify:remote
```

It verifies RFC 9728 discovery, the unauthenticated `401` challenge,
`initialize`, `tools/list`, and a representative `list_v3_categories`
`tools/call`. Override the target with `OAUTH_GATEWAY_URL`,
`OAUTH_GATEWAY_SMOKE_TOOL`, and JSON `OAUTH_GATEWAY_SMOKE_ARGUMENTS`.

Runtime configuration is documented in `.env.example`. Real secrets belong in
Render/Auth0 only. Never provide `MCP_REMOTE_PROXY_SHARED_SECRET` to this
service.

## Render staging service

- Root directory: `oauth-gateway`
- Region: Singapore
- Build command: `npm ci`
- Start command: `npm start`
- Health check: `/health`
- Instances: exactly 1 until session state is externalized
- Staging plan: Free (`$0/month`); production plan requires explicit approval
- Public URL: a new staging URL; never reuse the existing MCP URL

Set Edge Caching to disabled for all Gateway routes. Render terminates TLS and
forwards `X-Forwarded-Proto`; `GATEWAY_TRUST_PROXY=true` is therefore required.
The staging gate must verify that Render overwrites/sanitizes forwarded headers;
the application cannot prove the external load-balancer hop in local tests.

Browser `Origin` values are denied unless listed exactly in
`GATEWAY_ALLOWED_ORIGINS`. Server-side clients that omit `Origin` are allowed.
Session state is TTL/capacity bounded and intentionally process-local, so a
restart invalidates Gateway session bindings and clients must initialize again.

## Auth0 static client

- Application type: Regular Web Application / confidential third-party client
- Grant: Authorization Code
- PKCE: S256
- Allowed callback URL: the exact URI in ADR-001
- API audience/resource: exact Gateway `/mcp` URL
- Scope: `mcp:read`
- Allowed users: owner account only

Use the Auth0 authorization URL, token URL, client ID, and client secret in
Gemini Spark Advanced settings. DCR remains disabled unless staging proves it
is required.
