import { ToolError } from "../tool_runtime.js";

export function resolveV3Tokens(primitives, lightTokens, darkTokens) {
  const primitiveMap = new Map(primitives.map((token) => [token.path, token]));
  const resolvePrimitive = (path, chain = []) => {
    if (chain.includes(path)) {
      throw new ToolError("INVALID_RESOURCE", `V3 token alias cycle: ${[...chain, path].join(" -> ")}.`);
    }
    const token = primitiveMap.get(path);
    if (!token) throw new ToolError("INVALID_RESOURCE", `Missing V3 primitive alias target "${path}".`);
    return token.alias ? resolvePrimitive(token.alias, [...chain, path]) : token;
  };
  const lightMap = new Map(lightTokens.map((token) => [token.path, token]));
  const darkMap = new Map(darkTokens.map((token) => [token.path, token]));
  const resolveModeToken = (modeMap, path, chain = []) => {
    if (chain.includes(path)) throw new ToolError("INVALID_RESOURCE", `V3 semantic alias cycle: ${[...chain, path].join(" -> ")}.`);
    const semantic = modeMap.get(path);
    if (semantic) {
      if (semantic.aliasPrimitive) return resolvePrimitive(semantic.alias, [...chain, path]);
      if (semantic.alias) return resolveModeToken(modeMap, semantic.alias, [...chain, path]);
      if (semantic.value) return semantic;
    }
    return resolvePrimitive(path, chain);
  };
  const paths = [...new Set([...lightMap.keys(), ...darkMap.keys()])].sort();
  const mismatch = paths.filter((path) => !lightMap.has(path) || !darkMap.has(path));
  if (mismatch.length) throw new ToolError("INVALID_RESOURCE", `V3 Light/Dark token parity failed: ${mismatch.join(", ")}.`);
  return paths.map((path) => {
    const light = lightMap.get(path);
    const dark = darkMap.get(path);
    const lightPrimitive = light.aliasPrimitive ? resolvePrimitive(light.alias, [path]) : light.alias ? resolveModeToken(lightMap, light.alias, [path]) : light;
    const darkPrimitive = dark.aliasPrimitive ? resolvePrimitive(dark.alias, [path]) : dark.alias ? resolveModeToken(darkMap, dark.alias, [path]) : dark;
    return {
      themeVersion: "v3",
      tokenName: path,
      dartProperty: light.dartProperty,
      lightValue: lightPrimitive.value,
      darkValue: darkPrimitive.value,
      lightPrimitiveAlias: lightPrimitive.path,
      darkPrimitiveAlias: darkPrimitive.path,
      lightAlpha: lightPrimitive.alpha ?? 1,
      darkAlpha: darkPrimitive.alpha ?? 1,
      dartUsage: `V3ThemeScope.colorsOf(context).${light.dartProperty}`,
    };
  });
}
