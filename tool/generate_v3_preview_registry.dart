// ignore_for_file: avoid_print
import 'dart:io';

import 'v3_preview_registry_generator.dart';

const _outputPath = 'lib/preview_v3/preview_registry.g.dart';
const _widgetsV3Dir = 'lib/widgets/v3';

String _packageName() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final match = RegExp(r'^name:\s*(\S+)', multiLine: true).firstMatch(pubspec);
  if (match == null) {
    throw StateError('Could not read "name:" from pubspec.yaml.');
  }
  return match.group(1)!;
}

String _formatWithDart(String source) {
  final tempFile = File(
    '${Directory.systemTemp.path}/v3_preview_registry_check_${DateTime.now().microsecondsSinceEpoch}.dart',
  );
  tempFile.writeAsStringSync(source);
  try {
    final result = Process.runSync('dart', ['format', tempFile.path]);
    if (result.exitCode != 0) {
      throw StateError(
        'dart format failed on generated output:\n${result.stderr}',
      );
    }
    return tempFile.readAsStringSync();
  } finally {
    if (tempFile.existsSync()) tempFile.deleteSync();
  }
}

void main(List<String> args) {
  final checkOnly = args.contains('--check');

  final List<V3PreviewGeneratorEntry> entries;
  try {
    entries = discoverV3PreviewEntries(Directory(_widgetsV3Dir));
  } on V3PreviewGeneratorException catch (error) {
    stderr.writeln('Error: $error');
    exitCode = 1;
    return;
  }

  final rawSource = generateV3PreviewRegistrySource(
    entries,
    packageName: _packageName(),
  );
  final formattedSource = _formatWithDart(rawSource);

  final outputFile = File(_outputPath);
  final currentSource =
      outputFile.existsSync() ? outputFile.readAsStringSync() : null;

  if (checkOnly) {
    if (currentSource == formattedSource) {
      print(
        '$_outputPath is up to date (${entries.length} preview(s): ${entries.map((e) => e.slug).join(', ')}).',
      );
      return;
    }
    stderr.writeln(
      '$_outputPath is stale. Run "dart run tool/generate_v3_preview_registry.dart" to regenerate it.',
    );
    exitCode = 1;
    return;
  }

  if (currentSource == formattedSource) {
    print(
      '$_outputPath already up to date (${entries.length} preview(s): ${entries.map((e) => e.slug).join(', ')}).',
    );
    return;
  }

  outputFile.parent.createSync(recursive: true);
  outputFile.writeAsStringSync(formattedSource);
  print(
    'Wrote $_outputPath (${entries.length} preview(s): ${entries.map((e) => e.slug).join(', ')}).',
  );
}
