import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/v3_preview_registry_generator.dart';

void main() {
  late Directory tempRoot;
  late Directory widgetsV3Dir;

  setUp(() {
    tempRoot = Directory.systemTemp.createTempSync(
      'v3_preview_registry_generator_test_',
    );
    widgetsV3Dir = Directory('${tempRoot.path}/widgets_v3')
      ..createSync(recursive: true);
  });

  tearDown(() {
    tempRoot.deleteSync(recursive: true);
  });

  void writePreview(String category, String fileName, String classBody) {
    final dir = Directory('${widgetsV3Dir.path}/$category')
      ..createSync(recursive: true);
    File('${dir.path}/$fileName').writeAsStringSync(classBody);
  }

  group('v3ClassNameFromSnakeCase', () {
    test('converts snake_case fragments to PascalCase', () {
      expect(v3ClassNameFromSnakeCase('v3_mini_button'), 'V3MiniButton');
      expect(v3ClassNameFromSnakeCase('v3_icon_badge'), 'V3IconBadge');
      expect(v3ClassNameFromSnakeCase('v3_button'), 'V3Button');
    });
  });

  group('discoverV3PreviewEntries', () {
    test(
      'scales past one entry: discovers multiple previews across categories, sorted by slug',
      () {
        writePreview(
          'button',
          'preview_v3_mini_button.dart',
          "class V3MiniButtonPreview {}\n",
        );
        writePreview(
          'badge',
          'preview_v3_icon_badge.dart',
          "class V3IconBadgePreview {}\n",
        );

        final entries = discoverV3PreviewEntries(widgetsV3Dir);

        expect(entries, hasLength(2));
        // Sorted by slug: "badge/V3IconBadge" < "button/V3MiniButton".
        expect(entries[0].slug, 'badge/V3IconBadge');
        expect(entries[0].category, 'badge');
        expect(entries[0].widgetClassName, 'V3IconBadge');
        expect(entries[0].previewClassName, 'V3IconBadgePreview');
        expect(
          entries[0].relativeImportPath,
          'widgets/v3/badge/preview_v3_icon_badge.dart',
        );

        expect(entries[1].slug, 'button/V3MiniButton');
        expect(entries[1].category, 'button');
        expect(entries[1].widgetClassName, 'V3MiniButton');
        expect(entries[1].previewClassName, 'V3MiniButtonPreview');
      },
    );

    test('ignores non-preview Dart files in the same directory', () {
      writePreview(
        'button',
        'preview_v3_mini_button.dart',
        'class V3MiniButtonPreview {}\n',
      );
      writePreview('button', 'v3_mini_button.dart', 'class V3MiniButton {}\n');

      final entries = discoverV3PreviewEntries(widgetsV3Dir);

      expect(entries, hasLength(1));
      expect(entries.single.slug, 'button/V3MiniButton');
    });

    test(
      'throws an actionable error when the expected preview class is missing',
      () {
        writePreview(
          'button',
          'preview_v3_mini_button.dart',
          'class SomethingElse {}\n',
        );

        expect(
          () => discoverV3PreviewEntries(widgetsV3Dir),
          throwsA(
            isA<V3PreviewGeneratorException>().having(
              (e) => e.message,
              'message',
              allOf(
                contains('V3MiniButtonPreview'),
                contains('preview_v3_mini_button.dart'),
              ),
            ),
          ),
        );
      },
    );

    test(
      'throws an actionable error naming both files on a duplicate slug',
      () {
        // Same leaf category name ("button") reached through two different
        // subtrees, both producing the same widgetName -> same slug.
        writePreview(
          'button',
          'preview_v3_mini_button.dart',
          'class V3MiniButtonPreview {}\n',
        );
        final nestedDuplicateDir = Directory(
          '${widgetsV3Dir.path}/legacy_copy/button',
        )..createSync(recursive: true);
        File(
          '${nestedDuplicateDir.path}/preview_v3_mini_button.dart',
        ).writeAsStringSync('class V3MiniButtonPreview {}\n');

        expect(
          () => discoverV3PreviewEntries(widgetsV3Dir),
          throwsA(
            isA<V3PreviewGeneratorException>().having(
              (e) => e.message,
              'message',
              allOf(
                contains('Duplicate V3 preview slug'),
                contains('button/preview_v3_mini_button.dart'),
                contains('legacy_copy/button/preview_v3_mini_button.dart'),
              ),
            ),
          ),
        );
      },
    );

    test('throws when the Widget V3 directory does not exist', () {
      expect(
        () => discoverV3PreviewEntries(
          Directory('${tempRoot.path}/does_not_exist'),
        ),
        throwsA(isA<V3PreviewGeneratorException>()),
      );
    });
  });

  group('generateV3PreviewRegistrySource', () {
    test('renders a deterministic, aliased-import source for multiple entries', () {
      writePreview(
        'button',
        'preview_v3_mini_button.dart',
        'class V3MiniButtonPreview {}\n',
      );
      writePreview(
        'badge',
        'preview_v3_icon_badge.dart',
        'class V3IconBadgePreview {}\n',
      );
      final entries = discoverV3PreviewEntries(widgetsV3Dir);

      final first = generateV3PreviewRegistrySource(
        entries,
        packageName: 'mcp_test_app',
      );
      final second = generateV3PreviewRegistrySource(
        entries,
        packageName: 'mcp_test_app',
      );

      expect(first, equals(second));
      expect(
        first,
        contains(
          "import 'package:mcp_test_app/widgets/v3/badge/preview_v3_icon_badge.dart' as p0;",
        ),
      );
      expect(
        first,
        contains(
          "import 'package:mcp_test_app/widgets/v3/button/preview_v3_mini_button.dart' as p1;",
        ),
      );
      expect(first, contains("category: 'badge'"));
      expect(first, contains("widgetName: 'V3IconBadge'"));
      expect(
        first,
        contains('builder: (context) => const p0.V3IconBadgePreview(),'),
      );
      expect(first, contains("category: 'button'"));
      expect(first, contains("widgetName: 'V3MiniButton'"));
      expect(
        first,
        contains('builder: (context) => const p1.V3MiniButtonPreview(),'),
      );
    });

    test('renders an empty list when there are no entries', () {
      final source = generateV3PreviewRegistrySource(
        const [],
        packageName: 'mcp_test_app',
      );
      expect(
        source,
        contains(
          'final List<V3PreviewDefinition> generatedV3PreviewEntries = [',
        ),
      );
      expect(source, isNot(contains(' as p0;')));
    });
  });
}
