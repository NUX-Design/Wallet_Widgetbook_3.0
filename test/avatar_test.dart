import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mcp_test_app/widgets/avatar/avatar.dart';
import 'package:mcp_test_app/widgets/skeleton/lottie_skeleton.dart';

import 'support/widget_test_harness.dart';

Finder _svgAsset(String assetPath) {
  return find.byWidgetPredicate((widget) {
    return widget is SvgPicture &&
        widget.bytesLoader is SvgAssetLoader &&
        (widget.bytesLoader as SvgAssetLoader).assetName == assetPath;
  });
}

void main() {
  testWidgets('Avatar renders the fallback icon when no image is provided', (
    WidgetTester tester,
  ) async {
    await pumpTestApp(tester, const Avatar(name: 'New User', handle: 'Handle'));

    expect(find.text('New User'), findsOneWidget);
    expect(find.text('Handle'), findsOneWidget);
    expect(_svgAsset('lib/assets/images/user-add-01.svg'), findsOneWidget);
  });

  testWidgets('Avatar prefers network image over asset image', (
    WidgetTester tester,
  ) async {
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception is NetworkImageLoadException) {
        return;
      }
      previousOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousOnError);

    await pumpTestApp(
      tester,
      const Avatar(
        imageUrl: 'https://example.com/avatar.png',
        assetPath: 'lib/assets/images/avatar-demo.png',
        name: 'Tony Stark',
        handle: '@ironman',
      ),
    );

    final circleAvatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));

    expect(circleAvatar.backgroundImage, isA<NetworkImage>());
    expect(find.text('Tony Stark'), findsOneWidget);
    expect(find.text('@ironman'), findsOneWidget);
  });

  testWidgets('Avatar uses asset image and status badge correctly', (
    WidgetTester tester,
  ) async {
    await pumpTestApp(
      tester,
      const Avatar(
        assetPath: 'lib/assets/images/avatar-demo.png',
        name: 'Tony Stark',
        handle: '@ironman',
        status: AvatarStatus.warning,
      ),
    );

    final circleAvatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));

    expect(circleAvatar.backgroundImage, isA<AssetImage>());
    expect(find.text('Tony Stark'), findsOneWidget);
    expect(find.text('@ironman'), findsOneWidget);
    expect(_svgAsset('lib/assets/images/statuswarning.svg'), findsOneWidget);
  });

  testWidgets('Avatar renders the danger status badge', (
    WidgetTester tester,
  ) async {
    await pumpTestApp(
      tester,
      const Avatar(
        assetPath: 'lib/assets/images/avatar-demo.png',
        name: 'Tony Stark',
        handle: '@ironman',
        status: AvatarStatus.danger,
      ),
    );

    expect(_svgAsset('lib/assets/images/statusdanger.svg'), findsOneWidget);
  });

  testWidgets('Avatar loading state keeps radius and skeleton layout intact', (
    WidgetTester tester,
  ) async {
    await pumpTestApp(
      tester,
      const Avatar(
        radius: 32,
        isLoading: true,
        name: 'Loading...',
        handle: '@loading',
      ),
    );

    final circleAvatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));

    expect(circleAvatar.radius, 32);
    expect(find.byType(LottieSkeleton), findsNWidgets(3));
  });
}
