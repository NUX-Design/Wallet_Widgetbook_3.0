/// Parsed and normalized representation of one Theme V3 color token.
final class V3ColorToken {
  const V3ColorToken({
    required this.sourcePath,
    required this.path,
    required this.dartProperty,
    this.hex,
    this.alpha = 1,
    this.aliasPath,
  });

  final String sourcePath;
  final String path;
  final String dartProperty;
  final String? hex;
  final double alpha;
  final String? aliasPath;

  bool get isAlias => aliasPath != null;
}

/// A semantic token together with its fully resolved primitive value.
final class V3ResolvedColorToken {
  const V3ResolvedColorToken({required this.token, required this.primitive});

  final V3ColorToken token;
  final V3ColorToken primitive;
}
