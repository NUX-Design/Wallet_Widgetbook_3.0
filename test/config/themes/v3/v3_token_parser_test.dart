import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_test_app/config/themes/v3/v3_token_parser.dart';
import 'package:mcp_test_app/config/themes/v3/v3_token_resolver.dart';

void main() {
  const parser = V3TokenParser();
  const resolver = V3TokenResolver();

  group('V3TokenParser', () {
    test('parses DTCG color objects, alpha, components and aliases', () {
      final tokens = parser.parseDocument({
        'Core': {
          r'$type': 'color',
          'Blue': {
            '500': {
              r'$value': {
                'hex': '#3366CC80',
                'alpha': 0.25,
                'colorSpace': 'srgb',
                'components': [0.2, 0.4, 0.8],
              },
            },
          },
          'Alias': {r'$value': '{Core.Blue.500}'},
        },
      });

      expect(tokens, hasLength(2));
      final color = tokens.singleWhere(
        (token) => token.path == 'core/blue/500',
      );
      expect(color.hex, '#3366CC');
      expect(color.alpha, 0.25);
      expect(color.dartProperty, 'blue500');
      expect(
        tokens.singleWhere((token) => token.path == 'core/alias').aliasPath,
        'core/blue/500',
      );
    });

    test('reads com.figma.aliasData target', () {
      final token =
          parser.parseDocument({
            'Semantic': {
              r'$type': 'color',
              'Content': {
                'Primary': {
                  r'$value': {
                    'hex': '#FFFFFF',
                    'colorSpace': 'srgb',
                    'components': [1, 1, 1],
                    'alpha': 1,
                  },
                  r'$extensions': {
                    'com.figma.aliasData': {'targetVariableName': 'Core/White'},
                  },
                },
              },
            },
          }).single;

      expect(token.aliasPath, 'core/white');
      expect(token.dartProperty, 'contentPrimary');
    });

    test('normalizes PascalCase segments into deterministic kebab paths', () {
      final token =
          parser.parseDocument({
            'Semantic': {
              r'$type': 'color',
              'Action': {
                'PrimaryHover': {r'$value': '{Core.Blue.700}'},
              },
            },
          }).single;

      expect(token.path, 'semantic/action/primary-hover');
      expect(token.dartProperty, 'actionPrimaryHover');
    });

    test('rejects malformed hex with token path', () {
      expect(
        () => parser.parseDocument({
          'Core': {
            r'$type': 'color',
            'Bad': {
              r'$value': {'hex': '#XYZ'},
            },
          },
        }, source: 'fixture.json'),
        throwsA(
          isA<V3TokenFormatException>().having(
            (error) => error.message,
            'message',
            allOf(contains('fixture.json:Core/Bad'), contains('hex')),
          ),
        ),
      );
    });

    test('rejects duplicate normalized paths', () {
      expect(
        () => parser.parseDocument({
          'Core': {
            r'$type': 'color',
            'Blue Gray': {
              r'$value': {'hex': '#000000'},
            },
            'blue-gray': {
              r'$value': {'hex': '#FFFFFF'},
            },
          },
        }),
        throwsA(isA<V3TokenFormatException>()),
      );
    });

    test('rejects Dart property collisions', () {
      expect(
        () => parser.parseDocument({
          'Semantic': {
            r'$type': 'color',
            'foo-bar': {r'$value': '{Core.Black}'},
            'foo': {
              'bar': {r'$value': '{Core.White}'},
            },
          },
        }),
        throwsA(
          isA<V3TokenFormatException>().having(
            (error) => error.message,
            'message',
            contains('Dart property collision'),
          ),
        ),
      );
    });
  });

  group('V3TokenResolver', () {
    test('resolves semantic aliases through primitive aliases', () {
      final primitives = parser.parseDocument({
        'Core': {
          r'$type': 'color',
          'Black': {
            r'$value': {'hex': '#000000'},
          },
          'Ink': {r'$value': '{Core.Black}'},
        },
      });
      final semantics = parser.parseDocument({
        'Semantic': {
          r'$type': 'color',
          'Content': {
            'Primary': {r'$value': '{Core.Ink}'},
          },
        },
      });

      final resolved = resolver.resolve(
        primitives: primitives,
        semantics: semantics,
      );
      expect(resolved.single.primitive.path, 'core/black');
    });

    test('resolves semantic-to-semantic aliases from Figma exports', () {
      final primitives = parser.parseDocument({
        'White': {
          r'$type': 'color',
          r'$value': {'hex': '#FFFFFF'},
        },
      });
      final semantics = parser.parseDocument({
        'Core': {
          'White': {
            r'$type': 'color',
            r'$value': {'hex': '#FFFFFF'},
            r'$extensions': {
              'com.figma.aliasData': {'targetVariableName': 'White'},
            },
          },
        },
        'Button': {
          'Content': {
            r'$type': 'color',
            r'$value': {'hex': '#FFFFFF'},
            r'$extensions': {
              'com.figma.aliasData': {'targetVariableName': 'Core/White'},
            },
          },
        },
      });

      final resolved = resolver.resolve(
        primitives: primitives,
        semantics: semantics,
      );
      expect(resolved, hasLength(2));
      expect(
        resolved
            .singleWhere((token) => token.token.path == 'button/content')
            .primitive
            .path,
        'white',
      );
    });

    test('rejects missing primitive target', () {
      final semantic = parser.parseDocument({
        'Semantic': {
          r'$type': 'color',
          'Missing': {r'$value': '{Core.Unknown}'},
        },
      });
      expect(
        () => resolver.resolve(primitives: const [], semantics: semantic),
        throwsA(
          isA<V3TokenFormatException>().having(
            (error) => error.message,
            'message',
            contains('missing primitive target'),
          ),
        ),
      );
    });

    test('rejects alias cycle', () {
      final primitives = parser.parseDocument({
        'Core': {
          r'$type': 'color',
          'A': {r'$value': '{Core.B}'},
          'B': {r'$value': '{Core.A}'},
        },
      });
      final semantics = parser.parseDocument({
        'Semantic': {
          r'$type': 'color',
          'Value': {r'$value': '{Core.A}'},
        },
      });
      expect(
        () => resolver.resolve(primitives: primitives, semantics: semantics),
        throwsA(
          isA<V3TokenFormatException>().having(
            (error) => error.message,
            'message',
            contains('alias cycle'),
          ),
        ),
      );
    });

    test('rejects Light/Dark path mismatch', () {
      final light = parser.parseDocument({
        'Semantic': {
          r'$type': 'color',
          'Content': {
            'Primary': {r'$value': '{Core.Black}'},
          },
        },
      });
      final dark = parser.parseDocument({
        'Semantic': {
          r'$type': 'color',
          'Content': {
            'Secondary': {r'$value': '{Core.White}'},
          },
        },
      });
      expect(
        () => resolver.validateModeParity(light, dark),
        throwsA(
          isA<V3TokenFormatException>().having(
            (error) => error.message,
            'message',
            contains('Light/Dark path parity failed'),
          ),
        ),
      );
    });
  });
}
