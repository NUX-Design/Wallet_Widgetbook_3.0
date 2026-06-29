import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mcp_test_app/widgets/shortcut_menu/shortcut_menu.dart';

void main() {
  const String rawSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24">
  <path d="M4 12h16" stroke="#F2C564" stroke-width="2"/>
  <path d="M4 16h16" stroke="white" stroke-width="2"/>
</svg>
''';

  const String assetKey = 'lib/assets/images/arrow-data-transfer-horizontal.svg';

  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    binding.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (ByteData? message) async {
        final requestedKey = utf8.decode(message!.buffer.asUint8List());
        if (requestedKey == assetKey) {
          return ByteData.view(Uint8List.fromList(utf8.encode(rawSvg)).buffer);
        }
        return null;
      },
    );
  });

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      null,
    );
  });

  group('ShortcutMenuItem', () {
    testWidgets('loads the svg asset and replaces both stroke colors', (
      WidgetTester tester,
    ) async {
      final topColor = const Color(0xFF2196F3);
      final bottomColor = const Color(0xFF4CAF50);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShortcutMenuItem(
              label: 'Transfer',
              topArrowColor: topColor,
              bottomArrowColor: bottomColor,
            ),
          ),
        ),
      );

      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      });
      await tester.pump();
      await tester.pump();

      final svgPicture = tester.widget<SvgPicture>(find.byType(SvgPicture));
      final svgLoader = svgPicture.bytesLoader as SvgStringLoader;
      expect(
        svgLoader,
        equals(
          SvgStringLoader(
            _expectedSvg(
              topArrowHex: _colorToHex(topColor),
              bottomArrowHex: _colorToHex(bottomColor),
            ),
          ),
        ),
      );
    });

    testWidgets('renders the custom icon when provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShortcutMenuItem(
              label: 'Settings',
              icon: SizedBox(key: Key('custom_icon')),
            ),
          ),
        ),
      );

      final item = tester.widget<ShortcutMenuItem>(
        find.byType(ShortcutMenuItem),
      );
      expect(item.icon, isA<SizedBox>());
      expect((item.icon as SizedBox).key, const Key('custom_icon'));
    });

    testWidgets('shows loading overlay when isLoading is true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShortcutMenuItem(label: 'Transfer', isLoading: true),
          ),
        ),
      );

      final item = tester.widget<ShortcutMenuItem>(
        find.byType(ShortcutMenuItem),
      );
      expect(item.isLoading, isTrue);
      expect(item.label, 'Transfer');
    });
  });
}

String _expectedSvg({
  required String topArrowHex,
  required String bottomArrowHex,
}) {
  return '''
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24">
  <path d="M4 12h16" stroke="#$topArrowHex" stroke-width="2"/>
  <path d="M4 16h16" stroke="#$bottomArrowHex" stroke-width="2"/>
</svg>
''';
}

String _colorToHex(Color color) {
  return color.toARGB32().toRadixString(16).substring(2);
}
