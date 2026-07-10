import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_test_app/config/themes/v3/v3_theme_generator.dart';
import 'package:mcp_test_app/config/themes/v3/v3_token_parser.dart';
import 'package:mcp_test_app/config/themes/v3/v3_token_resolver.dart';

void main() {
  final repoRoot = Directory.current;
  final themeRoot = Directory('${repoRoot.path}/lib/config/themes/v3');

  test('source token counts and Light/Dark parity match the contract', () {
    const parser = V3TokenParser();
    const resolver = V3TokenResolver();
    final primitives = parser.parseFile(
      File('${themeRoot.path}/tokens/primitive.tokens.json'),
    );
    final light = parser.parseFile(
      File('${themeRoot.path}/tokens/semantic/light.tokens.json'),
    );
    final dark = parser.parseFile(
      File('${themeRoot.path}/tokens/semantic/dark.tokens.json'),
    );

    expect(primitives, hasLength(145));
    expect(light, hasLength(55));
    expect(dark, hasLength(55));
    expect(() => resolver.validateModeParity(light, dark), returnsNormally);
    expect(
      resolver.resolve(primitives: primitives, semantics: light),
      hasLength(55),
    );
    expect(
      resolver.resolve(primitives: primitives, semantics: dark),
      hasLength(55),
    );
  });

  test('checked-in generated files match the generator snapshot', () {
    const parser = V3TokenParser();
    const resolver = V3TokenResolver();
    final generator = V3ThemeGenerator(repoRoot: repoRoot);
    final primitives = parser.parseFile(
      File('${themeRoot.path}/tokens/primitive.tokens.json'),
    );
    final light = parser.parseFile(
      File('${themeRoot.path}/tokens/semantic/light.tokens.json'),
    );
    final dark = parser.parseFile(
      File('${themeRoot.path}/tokens/semantic/dark.tokens.json'),
    );

    expect(
      File(
        '${themeRoot.path}/generated/v3_primitive_colors.g.dart',
      ).readAsStringSync(),
      generator.buildPrimitiveSource(primitives),
    );
    expect(
      File(
        '${themeRoot.path}/generated/v3_semantic_colors.g.dart',
      ).readAsStringSync(),
      generator.buildSemanticSource(
        resolver.resolve(primitives: primitives, semantics: light),
        resolver.resolve(primitives: primitives, semantics: dark),
      ),
    );
  });

  test('second generation is deterministic and produces no writes', () {
    final first = V3ThemeGenerator(repoRoot: repoRoot).generate();
    final second = V3ThemeGenerator(repoRoot: repoRoot).generate();

    expect(first.changedFiles, 0);
    expect(second.changedFiles, 0);
    expect(first.primitiveCount, 145);
    expect(first.lightCount, 55);
    expect(first.darkCount, 55);
  });
}
