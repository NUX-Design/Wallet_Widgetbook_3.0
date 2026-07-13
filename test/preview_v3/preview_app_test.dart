import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_test_app/preview_v3/preview_app.dart';
import 'package:mcp_test_app/preview_v3/preview_not_found.dart';
import 'package:mcp_test_app/widgets/v3/button/preview_v3_mini_button.dart';

void main() {
  group('V3PreviewRoute', () {
    testWidgets('renders the matching preview for a known slug', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: V3PreviewRoute(rawSlug: 'button/V3MiniButton')),
      );

      expect(find.byType(V3MiniButtonPreview), findsOneWidget);
      expect(find.byType(V3PreviewNotFound), findsNothing);
    });

    testWidgets(
      'normalizes a fragment with a leading slash and surrounding whitespace',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: V3PreviewRoute(rawSlug: '/button/V3MiniButton '),
          ),
        );

        expect(find.byType(V3MiniButtonPreview), findsOneWidget);
      },
    );

    testWidgets(
      'redirects an empty root fragment to the first registered preview',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: V3PreviewRoute(rawSlug: '')),
        );

        expect(find.byType(V3MiniButtonPreview), findsOneWidget);
      },
    );

    testWidgets(
      'shows an actionable Not Found for an unknown slug without crashing',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: V3PreviewRoute(rawSlug: 'button/DoesNotExist'),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(V3PreviewNotFound), findsOneWidget);
        expect(find.textContaining('button/DoesNotExist'), findsOneWidget);
        expect(find.textContaining('#/button/V3MiniButton'), findsOneWidget);
      },
    );

    testWidgets('Not Found stays overflow-free at a narrow viewport', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 480));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(home: V3PreviewRoute(rawSlug: 'button/DoesNotExist')),
      );

      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('V3PreviewApp wires MaterialApp around the resolved route', (
    tester,
  ) async {
    await tester.pumpWidget(const V3PreviewApp(rawSlug: 'button/V3MiniButton'));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(V3MiniButtonPreview), findsOneWidget);
  });
}
