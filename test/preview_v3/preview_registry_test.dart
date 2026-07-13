import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_test_app/preview_v3/preview_registry.dart';
import 'package:mcp_test_app/widgets/v3/button/preview_v3_mini_button.dart';

void main() {
  group('V3PreviewRegistry.resolve', () {
    test('finds the registered pilot slug', () {
      final definition = V3PreviewRegistry.resolve('button/V3MiniButton');

      expect(definition, isNotNull);
      expect(definition!.slug, 'button/V3MiniButton');
      expect(definition.category, 'button');
      expect(definition.widgetName, 'V3MiniButton');
    });

    test('normalizes leading/trailing slashes before matching', () {
      expect(V3PreviewRegistry.resolve('/button/V3MiniButton/'), isNotNull);
      expect(V3PreviewRegistry.resolve('  button/V3MiniButton  '), isNotNull);
    });

    test('returns null for an unknown slug', () {
      expect(V3PreviewRegistry.resolve('button/DoesNotExist'), isNull);
    });

    test('returns null for an empty slug', () {
      expect(V3PreviewRegistry.resolve(''), isNull);
      expect(V3PreviewRegistry.resolve('/'), isNull);
    });
  });

  test('all() exposes an unmodifiable list containing the pilot entry', () {
    final entries = V3PreviewRegistry.all();

    expect(entries.map((entry) => entry.slug), contains('button/V3MiniButton'));
    expect(() => entries.add(entries.first), throwsUnsupportedError);
  });

  testWidgets('resolved builder lazily renders the pilot preview widget', (
    tester,
  ) async {
    final definition = V3PreviewRegistry.resolve('button/V3MiniButton')!;

    await tester.pumpWidget(
      MaterialApp(home: Builder(builder: definition.builder)),
    );

    expect(find.byType(V3MiniButtonPreview), findsOneWidget);
  });
}
