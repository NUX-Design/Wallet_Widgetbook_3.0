import 'v3_color_token.dart';
import 'v3_token_parser.dart';

final class V3TokenResolver {
  const V3TokenResolver();

  List<V3ResolvedColorToken> resolve({
    required List<V3ColorToken> primitives,
    required List<V3ColorToken> semantics,
  }) {
    final primitiveByPath = {for (final token in primitives) token.path: token};
    final semanticByPath = {for (final token in semantics) token.path: token};
    final resolved = <V3ResolvedColorToken>[];
    for (final semantic in semantics) {
      final alias = semantic.aliasPath;
      if (alias == null) {
        throw V3TokenFormatException(
          '${semantic.sourcePath}: semantic token must alias a primitive token',
        );
      }
      final primitive = _resolveAlias(
        alias,
        primitiveByPath,
        semanticByPath,
        <String>[semantic.path],
      );
      resolved.add(V3ResolvedColorToken(token: semantic, primitive: primitive));
    }
    return List.unmodifiable(
      resolved..sort((a, b) => a.token.path.compareTo(b.token.path)),
    );
  }

  V3ColorToken _resolveAlias(
    String path,
    Map<String, V3ColorToken> primitives,
    Map<String, V3ColorToken> semantics,
    List<String> chain,
  ) {
    if (chain.contains(path)) {
      throw V3TokenFormatException(
        'alias cycle: ${[...chain, path].join(' -> ')}',
      );
    }
    if (primitives.containsKey(path)) {
      return _resolvePrimitive(path, primitives, chain);
    }
    final semantic = semantics[path];
    if (semantic == null) {
      throw V3TokenFormatException('missing primitive target "$path"');
    }
    final alias = semantic.aliasPath;
    if (alias == null) {
      throw V3TokenFormatException(
        '${semantic.sourcePath}: semantic alias has no target',
      );
    }
    return _resolveAlias(alias, primitives, semantics, [...chain, path]);
  }

  V3ColorToken _resolvePrimitive(
    String path,
    Map<String, V3ColorToken> primitives,
    List<String> chain,
  ) {
    if (chain.contains(path)) {
      throw V3TokenFormatException(
        'alias cycle: ${[...chain, path].join(' -> ')}',
      );
    }
    final token = primitives[path];
    if (token == null) {
      throw V3TokenFormatException('missing primitive target "$path"');
    }
    if (token.aliasPath case final alias?) {
      return _resolvePrimitive(alias, primitives, [...chain, path]);
    }
    if (token.hex == null) {
      throw V3TokenFormatException(
        '${token.sourcePath}: primitive has no resolved color',
      );
    }
    return token;
  }

  void validateModeParity(List<V3ColorToken> light, List<V3ColorToken> dark) {
    final lightPaths = light.map((token) => token.path).toSet();
    final darkPaths = dark.map((token) => token.path).toSet();
    final missingInDark = lightPaths.difference(darkPaths).toList()..sort();
    final missingInLight = darkPaths.difference(lightPaths).toList()..sort();
    if (missingInDark.isNotEmpty || missingInLight.isNotEmpty) {
      throw V3TokenFormatException(
        'Light/Dark path parity failed; missing in dark: $missingInDark; '
        'missing in light: $missingInLight',
      );
    }
  }
}
