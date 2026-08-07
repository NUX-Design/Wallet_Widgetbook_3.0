# V3 Splash Animation

## What this is

`V3SplashAnimation` is an asset preview wrapper around `Lottie.asset`, used to
play the splash/intro Lottie export inside the local Widget V3 preview host.
It is **not** a Figma-sourced design-system primitive.

## Deviation from the standard five-file component set

`lib/widgets/v3/V3_WIDGETS_CONTEXT.md` requires every component folder under
`lib/widgets/v3/<category>/` to have a matching `<component>-_base.json` +
`<component>.md` Figma extraction pair. This folder intentionally omits that
pair: the animation previewed here (`wi_splash.json`) is a standalone Lottie
file supplied directly by the user, not extracted from a uSpec/Figma node.
There is no Figma node to extract a base JSON from.

If this widget later gets a real Figma-sourced spec (e.g. an official splash
screen component), add the base JSON / component Markdown pair at that point
and reconcile this guide with it.

## Asset

- `lib/assets/lottie/wi_splash.json` — production export with real vector
  paths for the "W" mark and the wi wallet logo (60fps, 181 frames). This is
  the same content as the user-supplied `wi splash.lottie` (a zipped
  dotLottie container of the identical Main Scene JSON) — only the JSON form
  was checked in, since `Lottie.asset` in this repo consumes raw Lottie JSON.

An earlier revision also previewed a second file, `wi-wallet-animation.json`,
supplied by the user for comparison. It was a placeholder/mock build using
rectangle shapes instead of real vector paths (30fps, 90 frames) and did not
render real artwork. The user confirmed it was not a usable animation, so its
preview (`preview_v3_splash_animation_mock.dart`), its copied asset
(`lib/assets/lottie/wi_wallet_animation_mock.json`), and its tests were
removed. Only the production `wi_splash.json` export remains.

This lives under `lib/assets/lottie/`, which is already declared as an asset
directory in `pubspec.yaml`, so no pubspec change was needed.

## API

```dart
V3SplashAnimation(
  assetPath: 'lib/assets/lottie/wi_splash.json',
  autoPlay: true,          // plays once on load when true
  repeat: false,           // loops when true
  onControllerReady: (controller) {}, // exposes AnimationController for replay
  onCompleted: () {},      // fires once when the forward playback finishes
)
```

- Fills the full available space with `SizedBox.expand` + `Lottie.asset(fit:
  BoxFit.cover)` — no fixed aspect ratio box. This is intentional: an earlier
  revision centered the animation inside a fixed `AspectRatio(375/852)` +
  `BoxFit.contain`, which showed `colors.backgroundPrimary` as visible white
  margins on any device whose screen ratio wasn't exactly 375:852. `cover`
  scales the composition to fill the screen on any mobile device size,
  cropping evenly from the center instead of letterboxing.
- `colors.backgroundPrimary` (via `V3ThemeScope.colorsOf(context)`) still
  backs the `ColoredBox`, but with `cover` fill it should never actually
  show through — it's a safety fallback for the brief frame before the
  Lottie composition loads.
- `onControllerReady` exposes the underlying `AnimationController` to a
  caller that wants to drive replay/seek itself (used directly by
  `test/widgets/v3/splash/v3_splash_animation_test.dart`); the preview below
  does not use it, since a real splash screen has no on-screen controls.
- `onCompleted` fires from an `AnimationStatus` listener when the animation
  reaches `completed` and `repeat` is false. It does not fire while looping.

## Preview

- `preview_v3_splash_animation.dart` → `V3SplashAnimationPreview` — plays
  `wi_splash.json` completely full-bleed, with **no overlay chrome at all**:
  no title bar, no replay button, no Light/Dark toggle. A real app splash
  screen shows only the animation, so the preview intentionally matches
  that — this was a deliberate simplification from an earlier revision that
  had a translucent title + replay bar. Takes an optional `onCompleted`
  callback that passes straight through to `V3SplashAnimation`.

Auto-discovered by `dart run tool/generate_v3_preview_registry.dart` at:

- `http://127.0.0.1:8090/#/splash/V3SplashAnimation`

## Consumer: native Simulator splash-loop flow

`lib/preview_v3/main_simulator.dart` uses `onCompleted` to drive a
splash-then-destination-then-loop demo: it always shows this splash first,
then redirects to whichever preview `V3_PREVIEW_SLUG` resolves to, which
shows a CTA button that loops back to the splash. See
`docs/v3/V3_SIMULATOR_DEBUG_PREVIEW.md` for the operational details — that
behavior lives entirely in `main_simulator.dart` and does not change this
widget/preview's own API contract beyond the `onCompleted` parameter.

## Tests

`test/widgets/v3/splash/v3_splash_animation_test.dart` pumps the widget with
`PlaceholderAssetBundle` (per `test/support/widget_test_harness.dart`) and
asserts a `Lottie` widget renders with the given asset path, without using
`pumpAndSettle()` on the animation (per the repeating-Lottie test note in
`MEMORY.md`).
