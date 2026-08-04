# Gemini Spark Gateway Credential Runbook

This runbook applies only to the dedicated Gateway upstream bearer. It must
never remove or rotate existing user bearer tokens.

## Initial Provisioning

1. Generate a cryptographically random bearer outside Git and terminal logs.
2. In the existing MCP Render service, append it to
   `MCP_REMOTE_BEARER_TOKENS`; preserve every existing value.
3. Verify both an existing user bearer and the new bearer against the deployed
   read-only MCP contracts.
4. Store the new value as `GATEWAY_UPSTREAM_BEARER` in the Gateway Render
   service only.
5. Confirm the Gateway environment does not contain
   `MCP_REMOTE_PROXY_SHARED_SECRET`.

## Rotation

1. Generate a replacement Gateway-only bearer.
2. Append it to the existing MCP bearer list without removing the active one.
3. Verify the replacement directly against upstream.
4. Switch `GATEWAY_UPSTREAM_BEARER` and deploy/restart the Gateway.
5. Observe authentication failures, tool calls, streams, and reconnects.
6. Remove only the superseded Gateway bearer after the overlap window.
7. Re-run legacy direct-bearer regression checks.

## Emergency Revoke

1. Disable the Gateway OAuth client or Gateway route to stop new sessions.
2. Remove only the compromised Gateway bearer from the existing MCP bearer
   list.
3. Rotate to a new Gateway bearer if service restoration is required.
4. Verify existing direct bearer clients and local `stdio` remain operational.
5. Archive redacted incident evidence; never paste token values into issues,
   commits, PRs, or chat.
