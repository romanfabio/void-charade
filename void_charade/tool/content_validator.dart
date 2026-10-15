import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:void_charade/features/categories/word_utils.dart';

/// Limits for word entries (kept in one place; see IMPLEMENTATION_PLAN.md §7).
const defaultMinWords = 300;
const maxEntryLength = 30;
const maxEntryWords = 5;
const contentLanguages = ['en', 'it'];

final _allowedChars = RegExp(r"^[\p{L}\p{N} '\-.&!?,:/]+$", unicode: true);
final _hexColor = RegExp(r'^#[0-9A-Fa-f]{6}$');
final _snakeCase = RegExp(r'^[a-z][a-z0-9]*(?:_[a-z0-9]+)*$');

class Issue {
  const Issue(this.where, this.message);
  final String where;
  final String message;

  @override
  String toString() => '$where: $message';
}

class FileStats {
  FileStats(this.categoryId, this.language);
  final String categoryId;
  final String language;
  bool present = false;
  int count = 0;
  int errors = 0;
  int warnings = 0;
}

class ValidationReport {
  final errors = <Issue>[];
  final warnings = <Issue>[];
  final pending = <String>[];
  final stats = <FileStats>[];

  /// Valid entries per `language/categoryId`, used for the spot-check files.
  final wordsByFile = <String, List<String>>{};

  /// category id -> display name per language, for the spot-check headings.
  final categoryNames = <String, Map<String, String>>{};

  bool get ok => errors.isEmpty;
}

/// Validates `assets/categories.json` and every `assets/words/<lang>/<id>.txt`
/// under [root] (the Flutter project directory).
///
/// With [strict] false, a missing word file is reported as "pending" instead of
/// an error, so the app can ship while content is still being written.
ValidationReport validateContent(
  Directory root, {
  bool strict = false,
  int minWords = defaultMinWords,
}) {
  final report = ValidationReport();
  final sep = Platform.pathSeparator;
  final categoriesFile = File('${root.path}${sep}assets${sep}categories.json');

  if (!categoriesFile.existsSync()) {
    report.errors.add(const Issue('categories.json', 'file not found'));
    return report;
  }

  final List<dynamic> categories;
  try {
    final json = jsonDecode(categoriesFile.readAsStringSync());
    categories = (json as Map<String, dynamic>)['categories'] as List<dynamic>;
  } on Object catch (e) {
    report.errors.add(Issue('categories.json', 'invalid JSON structure: $e'));
    return report;
  }

  final ids = <String>{};
  final knownIds = <String>{};
  for (final raw in categories) {
    final c = raw as Map<String, dynamic>;
    final id = c['id'];
    final where = 'categories.json[$id]';
    if (id is! String || !_snakeCase.hasMatch(id)) {
      report.errors.add(Issue(where, 'id must be snake_case'));
      continue;
    }
    if (!ids.add(id)) report.errors.add(Issue(where, 'duplicate id'));
    knownIds.add(id);

    final name = c['name'];
    final names = <String, String>{};
    for (final lang in contentLanguages) {
      final n = name is Map ? name[lang] : null;
      if (n is! String || n.trim().isEmpty) {
        report.errors.add(Issue(where, 'missing name.$lang'));
      } else {
        names[lang] = n;
      }
    }
    report.categoryNames[id] = names;

    final color = c['color'];
    if (color is! String || !_hexColor.hasMatch(color)) {
      report.errors.add(Issue(where, 'color must be #RRGGBB'));
    }
    if (c['adult'] is! bool) {
      report.errors.add(Issue(where, '"adult" must be true or false'));
    }
    if (c['emoji'] is! String || (c['emoji'] as String).isEmpty) {
      report.errors.add(Issue(where, 'missing emoji'));
    }
  }

  // Orphan word files / unexpected language folders.
  final wordsDir = Directory('${root.path}${sep}assets${sep}words');
  if (wordsDir.existsSync()) {
    for (final entity in wordsDir.listSync()) {
      final folder = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
      if (entity is Directory) {
        if (!contentLanguages.contains(folder)) {
          report.errors.add(Issue('assets/words/$folder', 'unknown language'));
          continue;
        }
        for (final file in entity.listSync().whereType<File>()) {
          final fileName = file.uri.pathSegments.last;
          if (fileName == '.gitkeep') continue;
          final id = fileName.endsWith('.txt')
              ? fileName.substring(0, fileName.length - 4)
              : null;
          if (id == null || !knownIds.contains(id)) {
            report.errors.add(
              Issue('assets/words/$folder/$fileName', 'orphan file'),
            );
          }
        }
      }
    }
  }

  // normalised word -> category ids, per language (cross-category duplicates).
  final seenAcross = {for (final l in contentLanguages) l: <String, List<String>>{}};

  for (final id in knownIds) {
    for (final lang in contentLanguages) {
      final stats = FileStats(id, lang);
      report.stats.add(stats);
      final path = 'assets/words/$lang/$id.txt';
      final file = File('${root.path}$sep${path.replaceAll('/', sep)}');

      if (!file.existsSync()) {
        if (strict) {
          report.errors.add(Issue(path, 'missing word file'));
          stats.errors++;
        } else {
          report.pending.add('$lang/$id');
        }
        continue;
      }
      stats.present = true;
      _validateWordFile(
        file: file,
        path: path,
        categoryId: id,
        language: lang,
        categoryName: report.categoryNames[id]?[lang],
        minWords: minWords,
        report: report,
        stats: stats,
        seenAcross: seenAcross[lang]!,
      );
    }
  }

  for (final lang in contentLanguages) {
    final shared = seenAcross[lang]!.entries.where((e) => e.value.length > 1);
    if (shared.isNotEmpty) {
      final examples = shared
          .take(8)
          .map((e) => '"${e.key}" (${e.value.join(', ')})')
          .join('; ');
      report.warnings.add(
        Issue(
          'words/$lang',
          '${shared.length} entries appear in several categories: $examples',
        ),
      );
    }
  }

  return report;
}

void _validateWordFile({
  required File file,
  required String path,
  required String categoryId,
  required String language,
  required String? categoryName,
  required int minWords,
  required ValidationReport report,
  required FileStats stats,
  required Map<String, List<String>> seenAcross,
}) {
  void error(String msg) {
    report.errors.add(Issue(path, msg));
    stats.errors++;
  }

  void warn(String msg) {
    report.warnings.add(Issue(path, msg));
    stats.warnings++;
  }

  final bytes = file.readAsBytesSync();
  if (bytes.length >= 3 &&
      bytes[0] == 0xEF &&
      bytes[1] == 0xBB &&
      bytes[2] == 0xBF) {
    error('starts with a UTF-8 BOM');
  }

  final String text;
  try {
    text = utf8.decode(bytes, allowMalformed: false);
  } on FormatException {
    error('not valid UTF-8');
    return;
  }

  if (text.contains('\r')) error('uses CRLF line endings (expected LF)');
  if (text.isNotEmpty && !text.endsWith('\n')) {
    warn('missing trailing newline');
  }

  final lines = text.replaceAll('\r', '').split('\n');
  if (lines.isNotEmpty && lines.last.isEmpty) lines.removeLast();

  final normalisedSeenAt = <String, int>{};
  final normalisedName =
      categoryName == null ? null : normalizeWord(categoryName, language);
  final valid = <String>[];

  for (var i = 0; i < lines.length; i++) {
    final lineNo = i + 1;
    final word = lines[i].replaceFirst('﻿', '');

    if (word.trim().isEmpty) {
      error('line $lineNo: empty line');
      continue;
    }
    var lineOk = true;
    if (word != word.trim()) {
      error('line $lineNo: leading/trailing space ("$word")');
      lineOk = false;
    }
    if (word.contains('  ')) {
      error('line $lineNo: double space ("$word")');
      lineOk = false;
    }
    if (word.runes.length > maxEntryLength) {
      error('line $lineNo: longer than $maxEntryLength characters ("$word")');
      lineOk = false;
    }
    if (word.trim().split(RegExp(r'\s+')).length > maxEntryWords) {
      error('line $lineNo: more than $maxEntryWords words ("$word")');
      lineOk = false;
    }
    if (!_allowedChars.hasMatch(word)) {
      error('line $lineNo: disallowed character ("$word")');
      lineOk = false;
    }

    final normalised = normalizeWord(word, language);
    if (normalised.isEmpty) {
      error('line $lineNo: nothing left after normalisation ("$word")');
      continue;
    }
    final firstSeen = normalisedSeenAt[normalised];
    if (firstSeen != null) {
      error('line $lineNo: duplicate of line $firstSeen ("$word")');
      lineOk = false;
    } else {
      normalisedSeenAt[normalised] = lineNo;
    }

    if (normalisedName != null &&
        normalisedName.isNotEmpty &&
        normalised.split(' ').contains(normalisedName)) {
      warn('line $lineNo: contains the category name ("$word")');
    }

    if (lineOk) {
      valid.add(word);
      (seenAcross[normalised] ??= []).add(categoryId);
    }
  }

  stats.count = valid.length;
  report.wordsByFile['$language/$categoryId'] = valid;
  if (valid.length < minWords) {
    error('only ${valid.length} valid entries (minimum $minWords)');
  }
}

/// Writes `spot_check_<lang>.md` files with [perCategory] random entries per
/// category, so a human can review the content quickly.
void writeSpotChecks(
  ValidationReport report,
  Directory outDir, {
  int perCategory = 20,
  int? seed,
}) {
  outDir.createSync(recursive: true);
  final random = Random(seed);

  for (final lang in contentLanguages) {
    final buf = StringBuffer('# Spot check ($lang)\n\n');
    for (final entry in report.wordsByFile.entries) {
      if (!entry.key.startsWith('$lang/')) continue;
      final id = entry.key.substring(lang.length + 1);
      final words = [...entry.value]..shuffle(random);
      final name = report.categoryNames[id]?[lang] ?? id;
      buf
        ..writeln('## $name (`$id`, ${entry.value.length} words)')
        ..writeln()
        ..writeln(words.take(perCategory).map((w) => '- $w').join('\n'))
        ..writeln();
    }
    File('${outDir.path}${Platform.pathSeparator}spot_check_$lang.md')
        .writeAsStringSync(buf.toString());
  }
}
