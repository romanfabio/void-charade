// Validates the bundled categories and word lists.
//
//   dart run tool/validate_words.dart            # missing word files = pending
//   dart run tool/validate_words.dart --strict   # missing word files = error
//   dart run tool/validate_words.dart --seed 42  # reproducible spot-check files
//
// Exit code 1 when any error is found. Spot-check files are written to
// build/spot_check_<lang>.md.
import 'dart:io';

import 'content_validator.dart';

void main(List<String> args) {
  final strict = args.contains('--strict');
  final seedIndex = args.indexOf('--seed');
  final seed = seedIndex >= 0 && seedIndex + 1 < args.length
      ? int.tryParse(args[seedIndex + 1])
      : null;

  final root = Directory.current;
  final report = validateContent(root, strict: strict);

  stdout.writeln('Word lists (valid entries per category)');
  stdout.writeln('${'category'.padRight(24)} ${'en'.padLeft(5)} ${'it'.padLeft(5)}  issues');
  final ids = report.stats.map((s) => s.categoryId).toSet();
  for (final id in ids) {
    final en = report.stats.firstWhere((s) => s.categoryId == id && s.language == 'en');
    final it = report.stats.firstWhere((s) => s.categoryId == id && s.language == 'it');
    String cell(FileStats s) => s.present ? '${s.count}' : '-';
    final errors = en.errors + it.errors;
    final warnings = en.warnings + it.warnings;
    final issues = [
      if (errors > 0) '$errors error(s)',
      if (warnings > 0) '$warnings warning(s)',
    ].join(', ');
    stdout.writeln(
      '${id.padRight(24)} ${cell(en).padLeft(5)} ${cell(it).padLeft(5)}  $issues',
    );
  }

  if (report.pending.isNotEmpty) {
    stdout.writeln('\nPending (no file yet): ${report.pending.length} of ${ids.length * 2}');
  }

  for (final w in report.warnings.take(40)) {
    stdout.writeln('WARNING $w');
  }
  if (report.warnings.length > 40) {
    stdout.writeln('... ${report.warnings.length - 40} more warnings');
  }
  for (final e in report.errors.take(80)) {
    stderr.writeln('ERROR   $e');
  }
  if (report.errors.length > 80) {
    stderr.writeln('... ${report.errors.length - 80} more errors');
  }

  writeSpotChecks(report, Directory('build'), seed: seed);
  stdout.writeln('\nSpot-check files: build/spot_check_en.md, build/spot_check_it.md');

  stdout.writeln(
    report.ok
        ? 'OK: ${report.warnings.length} warning(s), no errors.'
        : 'FAILED: ${report.errors.length} error(s), ${report.warnings.length} warning(s).',
  );
  exit(report.ok ? 0 : 1);
}
