import { createRemoteJWKSet, jwtVerify } from "jose";

function tokenFromHeader(header = "") {
  const match = /^Bearer\s+([^\s]+)$/i.exec(String(header).trim());
  return match?.[1] ?? "";
}

function clientIdFromClaims(payload) {
  return String(payload.client_id ?? payload.azp ?? "").trim();
}

export function createTokenVerifier(config, jwks = createRemoteJWKSet(new URL(config.jwksUrl))) {

  return async (authorizationHeader) => {
    const token = tokenFromHeader(authorizationHeader);
    if (!token) throw new Error("missing_token");

    const { payload } = await jwtVerify(token, jwks, {
      issuer: config.issuer,
      audience: config.audience,
      algorithms: ["RS256"],
      requiredClaims: ["exp", "iat", "sub"],
      maxTokenAge: `${config.maxTokenAgeSeconds}s`,
      clockTolerance: 5,
    });

    const subject = String(payload.sub ?? "").trim();
    const clientId = clientIdFromClaims(payload);
    const scopes = new Set(String(payload.scope ?? "").split(/\s+/).filter(Boolean));
    const jti = String(payload.jti ?? "").trim();

    if (payload.exp - payload.iat > config.maxTokenAgeSeconds) throw new Error("token_lifetime_exceeded");
    if (jti && config.revokedJtis?.has(jti)) throw new Error("revoked_token");
    if (!subject || !config.allowedSubjects.has(subject)) throw new Error("invalid_subject");
    if (!clientId || !config.allowedClients.has(clientId)) throw new Error("invalid_client");
    if (!scopes.has(config.requiredScope)) throw new Error("insufficient_scope");

    return { issuer: config.issuer, subject, clientId };
  };
}
