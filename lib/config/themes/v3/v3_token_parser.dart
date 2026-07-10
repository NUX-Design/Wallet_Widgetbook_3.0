import 'dart:convert';
import 'dart:io';

import 'v3_color_token.dart';

final class V3TokenFormatException implements Exception {
  const V3TokenFormatException(this.message);

  final String message;

  @override
  String toString() => 'V3TokenFormatException: $message';
}

final class V3TokenParser {
  const V3TokenParser();

  List<V3ColorToken> parseFile(File file) {
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      return parseDocument(decoded, source: file.path);
    } on FormatException catch (error) {
      throw V3TokenFormatException(
        '${file.path}: invalid JSON: ${error.message}',
      );
    }
  }

  List<V3ColorToken> parseDocument(
    Object? document, {
    String source = 'tokens',
  }) {
    if (document is! Map<String, dynamic>) {
      throw V3TokenFormatException('$source: root must be a JSON object');
    }
    final tokens = <V3ColorToken>[];
    _visit(document, const [], null, source, tokens);
    final seen = <String, String>{};
    final properties = <String, String>{};
    for (final token in tokens) {
      final previous = seen[token.path];
      if (previous != null) {
        throw V3TokenFormatException(
          '${token.sourcePath}: duplicate normalized path "${token.path}"; also defined by $previous',
        );
      }
      seen[token.path] = token.sourcePath;
      final propertyOwner = properties[token.dartProperty];
      if (propertyOwner != null && propertyOwner != token.path) {
        throw V3TokenFormatException(
          '${token.sourcePath}: Dart property collision "${token.dartProperty}" '
          'for "$propertyOwner" and "${token.path}"',
        );
      }
      properties[token.dartProperty] = token.path;
    }
    return List.unmodifiable(tokens..sort((a, b) => a.path.compareTo(b.path)));
  }

  void _visit(
    Map<String, dynamic> node,
    List<String> segments,
    String? inheritedType,
    String source,
    List<V3ColorToken> output,
  ) {
    final type = node[r'$type'] as String? ?? inheritedType;
    if (node.containsKey(r'$value')) {
      final sourcePath = segments.join('/');
      if (sourcePath.isEmpty) {
        throw V3TokenFormatException('$source: token path cannot be empty');
      }
      if (type != 'color') {
        throw V3TokenFormatException(
          '$source:$sourcePath: expected \$type "color"',
        );
      }
      output.add(_parseToken(node, sourcePath, '$source:$sourcePath'));
      return;
    }

    for (final entry in node.entries) {
      if (entry.key.startsWith(r'$')) continue;
      if (entry.value is! Map<String, dynamic>) {
        throw V3TokenFormatException(
          '$source:${[...segments, entry.key].join('/')}: group must be an object',
        );
      }
      _visit(
        entry.value as Map<String, dynamic>,
        [...segments, entry.key],
        type,
        source,
        output,
      );
    }
  }

  V3ColorToken _parseToken(
    Map<String, dynamic> node,
    String rawPath,
    String sourcePath,
  ) {
    final path = normalizePath(rawPath);
    final value = node[r'$value'];
    String? alias;
    String? hex;
    var alpha = 1.0;

    if (value is String && value.startsWith('{') && value.endsWith('}')) {
      alias = normalizePath(value.substring(1, value.length - 1));
    } else if (value is Map<String, dynamic>) {
      final rawHex = value['hex'];
      final rawAlpha = value['alpha'];
      final colorSpace = value['colorSpace'];
      final components = value['components'];
      if (colorSpace != null && colorSpace != 'srgb') {
        throw V3TokenFormatException(
          '$sourcePath: unsupported colorSpace "$colorSpace"',
        );
      }
      if (components != null) {
        if (components is! List ||
            (components.length != 3 && components.length != 4)) {
          throw V3TokenFormatException(
            '$sourcePath: components must contain 3 or 4 numbers',
          );
        }
        for (final component in components) {
          if (component is! num || component < 0 || component > 1) {
            throw V3TokenFormatException(
              '$sourcePath: components must be numbers from 0 to 1',
            );
          }
        }
      }
      if (rawHex is! String ||
          !RegExp(r'^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$').hasMatch(rawHex)) {
        throw V3TokenFormatException(
          '$sourcePath: hex must be #RRGGBB or #RRGGBBAA',
        );
      }
      hex = rawHex.toUpperCase();
      if (rawHex.length == 9) {
        alpha = int.parse(rawHex.substring(7, 9), radix: 16) / 255;
        hex = rawHex.substring(0, 7).toUpperCase();
      }
      if (rawAlpha != null) {
        if (rawAlpha is! num || rawAlpha < 0 || rawAlpha > 1) {
          throw V3TokenFormatException(
            '$sourcePath: alpha must be a number from 0 to 1',
          );
        }
        alpha = rawAlpha.toDouble();
      }
    } else {
      throw V3TokenFormatException(
        '$sourcePath: color value must be an alias or color object',
      );
    }

    final extensions = node[r'$extensions'];
    final aliasData =
        extensions is Map<String, dynamic>
            ? extensions['com.figma.aliasData']
            : null;
    final figmaTarget =
        aliasData is Map<String, dynamic>
            ? aliasData['targetVariableName']
            : null;
    if (alias == null && figmaTarget is String && figmaTarget.isNotEmpty) {
      alias = normalizePath(figmaTarget);
    }
    if (alias == null && hex == null) {
      throw V3TokenFormatException(
        '$sourcePath: semantic token has no resolvable color',
      );
    }

    return V3ColorToken(
      sourcePath: sourcePath,
      path: path,
      dartProperty: dartPropertyFor(path),
      hex: hex,
      alpha: alpha,
      aliasPath: alias,
    );
  }

  static String normalizePath(String value) {
    final segments = value
        .replaceAll('.', '/')
        .split('/')
        .map(
          (segment) =>
              segment
                  .trim()
                  .replaceAllMapped(
                    RegExp(r'([a-z0-9])([A-Z])'),
                    (match) => '${match.group(1)}-${match.group(2)}',
                  )
                  .replaceAll(RegExp(r'\s+'), '-')
                  .toLowerCase(),
        )
        .where((segment) => segment.isNotEmpty);
    return segments.join('/');
  }

  static String dartPropertyFor(String normalizedPath) {
    final pathWithoutNamespace = normalizedPath.replaceFirst(
      RegExp(r'^(core|semantic)/'),
      '',
    );
    final words =
        pathWithoutNamespace
            .split(RegExp(r'[/_-]+'))
            .where((word) => word.isNotEmpty)
            .toList();
    if (words.isEmpty) return '';
    final property =
        words.first +
        words
            .skip(1)
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join();
    return RegExp(r'^\d').hasMatch(property) ? 'color$property' : property;
  }
}
