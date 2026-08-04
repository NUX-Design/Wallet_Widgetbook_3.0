# ADR-001: Gemini Spark OAuth Resource Gateway

- Status: Accepted
- Date: 2026-08-04
- Decision owner: Repository owner
- Plan: `docs/v3/V3_GEMINI_SPARK_OAUTH_GATEWAY_PLAN.md` v0.4

## Context

Gemini Spark requires an OAuth-compatible remote MCP endpoint. The existing
Render MCP endpoint uses static bearer authentication and remains the runtime,
tool catalog, and contract source of truth for existing clients.

Gemini Spark redirect URI recorded from the Custom Connected App UI:

```text
https://oauth-redirect.googleusercontent.com/r/user_bound_custom-mcp-113073092359586376293-flutter-widget-wallet-mcp_onrender_com
```

## Decision

1. Use **Auth0** as the managed Authorization Server. The repository will not
   implement `/authorize`, `/token`, consent, PKCE, or OAuth client lifecycle.
2. Host the Resource Gateway as a **separate Render Web Service in Singapore**.
   Start staging on the Free plan (`$0/month`) with the Render-assigned HTTPS
   domain; a custom domain and paid production instance are deferred until the
   production-canary budget decision.
3. Use a **single-owner identity model**. Auth0 subject and client allowlists
   are enforced by Gateway configuration.
4. Use **static client registration** with the exact Gemini redirect URI above.
   Restricted DCR is deferred unless a real staging handshake proves it is
   required.
5. Start with **one Gateway instance**. The in-memory MCP session-to-identity
   map prohibits horizontal scaling until shared state or proven affinity is
   introduced.
6. Use scope `mcp:read` and bind access tokens to the Gateway resource/audience.
7. The Gateway forwards only to the fixed existing upstream endpoint
   `https://flutter-widget-wallet-mcp.onrender.com/mcp` using a dedicated
   `GATEWAY_UPSTREAM_BEARER`.

## Responsibility Boundary

| Component | Owns | Must not own |
| --- | --- | --- |
| Auth0 | Authorization Code, PKCE S256, state/redirect validation, consent, client registration, token/JWKS lifecycle | MCP tools or upstream bearer |
| OAuth Gateway | RFC 9728 metadata, JWT validation, identity/session binding, rate limits, safe streaming proxy | `/authorize`, `/token`, tool registry, proxy shared secret |
| Existing Render MCP | MCP runtime, tool contracts, read-only enforcement, preview bundle | Gemini OAuth lifecycle |

## Consequences

- Existing bearer clients and local `stdio` configurations do not change.
- Gateway rollback is independent from the existing MCP service.
- A single instance is an explicit launch constraint.
- Production deployment still requires separate staging evidence, secret
  provisioning, and the rollout gates in the approved plan.

## Protocol Baseline For The Spike

- OAuth 2.0 Authorization Code with PKCE S256
- OAuth Protected Resource Metadata: RFC 9728
- Resource Indicators: RFC 8707
- MCP Streamable HTTP with the protocol version negotiated by `initialize`
- JWT access-token verification through Auth0 issuer metadata/JWKS

No production secret is permitted in discovery or handshake evidence.
