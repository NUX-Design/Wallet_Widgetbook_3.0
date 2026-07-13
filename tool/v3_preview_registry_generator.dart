import 'dart:io';

/// One discovered `lib/widgets/v3/<category>/preview_v3_<widget>.dart` entry.
class V3PreviewGeneratorEntry {
  const V3PreviewGeneratorEntry({
    required this.category,
    required this.widgetClassName,
    required this.previewClassName,
    required this.relativeImportPath,
    required this.sourcePath,
  });

  final String category;
  final String widgetClassName;
  final String previewClassName;

  /// Import path relative to `lib/`, e.g. `widgets/v3/button/preview_v3_mini_button.dart`.
  final String relativeImportPath;

  /// Absolute (or test-fixture-relative) path to the source preview file, kept
  /// only for actionable error messages.
  final String sourcePath;

  String get slug => '$category/$widgetClassName';
}

class V3PreviewGeneratorException implements Exception {
  V3PreviewGeneratorException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Converts a snake_case widget filename fragment (e.g. `v3_mini_button`) into
/// its PascalCase class name (e.g. `V3MiniButton`), matching the repo's
/// `preview_v3_<widget>.dart` -> `V3<Widget>` naming convention.
String v3ClassNameFromSnakeCase(String snake) {
  return snake
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join();
}

String _basename(String path) => path.split('/').last;

String _dirname(String path) {
  final segments = path.split('/');
  return segments.length > 1
      ? segments.sublist(0, segments.length - 1).join('/')
      : '.';
}

/// Recursively finds every `preview_v3_*.dart` file under [widgetsV3Dir] and
/// derives its category, widget class name, and expected preview class name
/// from the filesystem convention `<category>/preview_v3_<widget>.dart` ->
/// `class V3<Widget>Preview`. Throws [V3PreviewGeneratorException] with an
/// actionable message when a preview class is missing or a slug repeats.
///
/// Entries are returned sorted deterministically by slug so regenerated
/// output only changes when the underlying preview set actually changes.
List<V3PreviewGeneratorEntry> discoverV3PreviewEntries(Directory widgetsV3Dir) {
  if (!widgetsV3Dir.existsSync()) {
    throw V3PreviewGeneratorException(
      'Widget V3 directory not found: ${widgetsV3Dir.path}',
    );
  }

  final previewFiles =
      widgetsV3Dir.listSync(recursive: true).whereType<File>().where((file) {
          final name = _basename(
            file.path.replaceAll(Platform.pathSeparator, '/'),
          );
          return name.startsWith('preview_v3_') && name.endsWith('.dart');
        }).toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  final entries = <V3PreviewGeneratorEntry>[];
  final seenSlugs = <String, String>{};

  for (final file in previewFiles) {
    final normalizedPath = file.path.replaceAll(Platform.pathSeparator, '/');
    final category = _basename(_dirname(normalizedPath));
    final fileName = _basename(normalizedPath).replaceAll('.dart', '');
    final snakeWidgetName = fileName.substring('preview_'.length);
    final widgetClassName = v3ClassNameFromSnakeCase(snakeWidgetName);
    final previewClassName = '${widgetClassName}Preview';

    final source = file.readAsStringSync();
    if (!RegExp('class\\s+$previewClassName\\b').hasMatch(source)) {
      throw V3PreviewGeneratorException(
        'Missing preview builder: expected "class $previewClassName" in $normalizedPath '
        '(derived from filename convention preview_v3_<widget>.dart -> <WidgetClass>Preview).',
      );
    }

    final widgetsV3Path = widgetsV3Dir.path.replaceAll(
      Platform.pathSeparator,
      '/',
    );
    final relativeToWidgetsV3 = normalizedPath
        .substring(widgetsV3Path.length)
        .replaceFirst(RegExp('^/'), '');

    final entry = V3PreviewGeneratorEntry(
      category: category,
      widgetClassName: widgetClassName,
      previewClassName: previewClassName,
      relativeImportPath: 'widgets/v3/$relativeToWidgetsV3',
      sourcePath: normalizedPath,
    );

    final existingSourcePath = seenSlugs[entry.slug];
    if (existingSourcePath != null) {
      throw V3PreviewGeneratorException(
        'Duplicate V3 preview slug "${entry.slug}": already defined by $existingSourcePath, also found in $normalizedPath.',
      );
    }
    seenSlugs[entry.slug] = normalizedPath;
    entries.add(entry);
  }

  entries.sort((a, b) => a.slug.compareTo(b.slug));
  return entries;
}

/// Renders the deterministic generated Dart source for [entries]. Each entry
/// gets its own aliased import (`p0`, `p1`, ...) so preview classes never
/// collide even if two categories happen to reuse a class name.
String generateV3PreviewRegistrySource(
  List<V3PreviewGeneratorEntry> entries, {
  required String packageName,
}) {
  final buffer =
      StringBuffer()
        ..writeln('// GENERATED FILE - DO NOT EDIT BY HAND.')
        ..writeln('//')
        ..writeln(
          '// Produced by: dart run tool/generate_v3_preview_registry.dart',
        )
        ..writeln(
          '// Regenerate whenever lib/widgets/v3/**/preview_v3_*.dart changes.',
        )
        ..writeln()
        ..writeln("import 'preview_definition.dart';");

  for (var i = 0; i < entries.length; i++) {
    buffer.writeln(
      "import 'package:$packageName/${entries[i].relativeImportPath}' as p$i;",
    );
  }

  buffer
    ..writeln()
    ..writeln('final List<V3PreviewDefinition> generatedV3PreviewEntries = [');

  for (var i = 0; i < entries.length; i++) {
    final entry = entries[i];
    buffer
      ..writeln('  V3PreviewDefinition(')
      ..writeln("    category: '${entry.category}',")
      ..writeln("    widgetName: '${entry.widgetClassName}',")
      ..writeln(
        '    builder: (context) => const p$i.${entry.previewClassName}(),',
      )
      ..writeln('  ),');
  }

  buffer.writeln('];');
  return buffer.toString();
}
