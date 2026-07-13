import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_test_app/preview_v3/preview_definition.dart';

void main() {
  group('V3PreviewDefinition', () {
    test(
      'slug combines category and widgetName as <category>/<WidgetClass>',
      () {
        final definition = V3PreviewDefinition(
          category: 'button',
          widgetName: 'V3MiniButton',
          builder: (context) => const SizedBox.shrink(),
        );

        expect(definition.slug, 'button/V3MiniButton');
      },
    );

    test('rejects an empty category', () {
      expect(
        () => V3PreviewDefinition(
          category: '',
          widgetName: 'V3MiniButton',
          builder: (context) => const SizedBox.shrink(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects an empty widgetName', () {
      expect(
        () => V3PreviewDefinition(
          category: 'button',
          widgetName: '',
          builder: (context) => const SizedBox.shrink(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('normalizeV3PreviewSlug', () {
    test('strips leading and trailing slashes', () {
      expect(
        normalizeV3PreviewSlug('/button/V3MiniButton/'),
        'button/V3MiniButton',
      );
    });

    test('strips surrounding whitespace', () {
      expect(
        normalizeV3PreviewSlug('  button/V3MiniButton  '),
        'button/V3MiniButton',
      );
    });

    test('collapses to empty for a bare slash or empty string', () {
      expect(normalizeV3PreviewSlug('/'), '');
      expect(normalizeV3PreviewSlug(''), '');
    });

    test('leaves an already-canonical slug unchanged', () {
      expect(
        normalizeV3PreviewSlug('button/V3MiniButton'),
        'button/V3MiniButton',
      );
    });
  });

  group('ensureUniqueV3PreviewSlugs', () {
    V3PreviewDefinition definitionFor(String category, String widgetName) {
      return V3PreviewDefinition(
        category: category,
        widgetName: widgetName,
        builder: (context) => const SizedBox.shrink(),
      );
    }

    test('returns the same list when every slug is unique', () {
      final entries = [
        definitionFor('button', 'V3MiniButton'),
        definitionFor('button', 'V3OtherButton'),
      ];

      expect(ensureUniqueV3PreviewSlugs(entries), same(entries));
    });

    test('throws a StateError naming the duplicate slug', () {
      final entries = [
        definitionFor('button', 'V3MiniButton'),
        definitionFor('button', 'V3MiniButton'),
      ];

      expect(
        () => ensureUniqueV3PreviewSlugs(entries),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('button/V3MiniButton'),
          ),
        ),
      );
    });
  });
}
