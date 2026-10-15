import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/content_validator.dart';

const _categoriesJson = '''
{
  "version": 1,
  "categories": [
    { "id": "animals", "emoji": "x", "color": "#112233", "adult": false,
      "name": { "en": "Animals", "it": "Animali" } },
    { "id": "spicy", "emoji": "x", "color": "#445566", "adult": true,
      "name": { "en": "Spicy", "it": "Piccante" } }
  ]
}
''';

/// A throwaway project folder with the given word files.
Directory _project(
  Map<String, String> words, {
  String categories = _categoriesJson,
}) {
  final root = Directory.systemTemp.createTempSync('charade_validator_');
  addTearDown(() => root.deleteSync(recursive: true));
  File('${root.path}/assets/categories.json')
    ..createSync(recursive: true)
    ..writeAsStringSync(categories);
  words.forEach((path, content) {
    File('${root.path}/assets/words/$path')
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
  });
  return root;
}

Map<String, String> _validFiles() => {
      'en/animals.txt': 'Dog\nCat\nHorse\n',
      'it/animals.txt': 'Cane\nGatto\nCavallo\n',
      'en/spicy.txt': 'Kiss\nWink\nDate\n',
      'it/spicy.txt': 'Bacio\nOcchiolino\nAppuntamento\n',
    };

ValidationReport _run(Map<String, String> words, {bool strict = false}) =>
    validateContent(_project(words), strict: strict, minWords: 3);

bool _hasError(ValidationReport r, String fragment) =>
    r.errors.any((e) => e.toString().contains(fragment));

void main() {
  test('accepts well-formed content', () {
    final r = _run(_validFiles());
    expect(r.errors, isEmpty);
    expect(r.stats.where((s) => s.present).length, 4);
    expect(r.wordsByFile['en/animals'], ['Dog', 'Cat', 'Horse']);
  });

  test('missing word files are pending, or errors in strict mode', () {
    final files = _validFiles()..remove('it/spicy.txt');
    expect(_run(files).errors, isEmpty);
    expect(_run(files).pending, ['it/spicy']);
    expect(_hasError(_run(files, strict: true), 'missing word file'), isTrue);
  });

  test('rejects duplicates, including article and accent variants', () {
    final files = _validFiles()
      ..['it/animals.txt'] = "Gatto\nIl gatto\nCavallo\nL'orso\nOrso\n";
    final r = _run(files);
    expect(_hasError(r, 'line 2: duplicate of line 1'), isTrue);
    expect(_hasError(r, 'line 5: duplicate of line 4'), isTrue);
  });

  test('rejects formatting problems', () {
    final cases = <String, String>{
      'BOM': '﻿Dog\nCat\nHorse\n',
      'CRLF': 'Dog\r\nCat\r\nHorse\r\n',
      'empty line': 'Dog\n\nCat\nHorse\n',
      'leading/trailing space': 'Dog \nCat\nHorse\n',
      'double space': 'Big  dog\nCat\nHorse\n',
      'disallowed character': 'Dog\nCat@\nHorse\n',
      'more than 5 words': 'Dog\nA very very very big dog\nHorse\n',
      'longer than 30 characters': 'Dog\nSupercalifragilisticexpialidocious\nHorse\n',
    };
    cases.forEach((fragment, content) {
      final files = _validFiles()..['en/animals.txt'] = content;
      expect(
        _hasError(_run(files), fragment),
        isTrue,
        reason: 'expected an error containing "$fragment"',
      );
    });
  });

  test('rejects invalid UTF-8', () {
    final root = _project(_validFiles());
    File('${root.path}/assets/words/en/animals.txt')
        .writeAsBytesSync([0x44, 0xFF, 0xFE, 0x0A]);
    final r = validateContent(root, minWords: 3);
    expect(_hasError(r, 'not valid UTF-8'), isTrue);
  });

  test('enforces the minimum number of entries', () {
    final files = _validFiles()..['en/animals.txt'] = 'Dog\nCat\n';
    expect(_hasError(_run(files), 'only 2 valid entries'), isTrue);
  });

  test('flags orphan files and unknown language folders', () {
    final files = _validFiles()
      ..['en/ghost.txt'] = 'Boo\n'
      ..['fr/animals.txt'] = 'Chien\n';
    final r = _run(files);
    expect(_hasError(r, 'orphan file'), isTrue);
    expect(_hasError(r, 'unknown language'), isTrue);
  });

  test('warns about entries shared by several categories', () {
    final files = _validFiles()..['en/spicy.txt'] = 'Kiss\nDog\nDate\n';
    final r = _run(files);
    expect(r.errors, isEmpty);
    expect(r.warnings.any((w) => w.message.contains('several categories')), isTrue);
  });

  test('warns when an entry contains the category name', () {
    final files = _validFiles()
      ..['en/animals.txt'] = 'Dog\nFarm animals\nHorse\n';
    final r = _run(files);
    expect(r.warnings.any((w) => w.message.contains('category name')), isTrue);
  });

  test('validates categories.json', () {
    final bad = jsonEncode({
      'categories': [
        {'id': 'Bad-Id', 'emoji': 'x', 'color': 'red', 'adult': 'no',
         'name': {'en': 'X'}},
      ],
    });
    final r = validateContent(_project({}, categories: bad), minWords: 3);
    expect(_hasError(r, 'snake_case'), isTrue);

    final bad2 = jsonEncode({
      'categories': [
        {'id': 'ok', 'emoji': 'x', 'color': 'red', 'adult': 'no',
         'name': {'en': 'X'}},
      ],
    });
    final r2 = validateContent(_project({}, categories: bad2), minWords: 3);
    expect(_hasError(r2, 'color must be #RRGGBB'), isTrue);
    expect(_hasError(r2, '"adult" must be true or false'), isTrue);
    expect(_hasError(r2, 'missing name.it'), isTrue);
  });

  test('writes spot-check files with the requested number of words', () {
    final root = _project(_validFiles());
    final r = validateContent(root, minWords: 3);
    final out = Directory('${root.path}/out');
    writeSpotChecks(r, out, perCategory: 2, seed: 1);
    final en = File('${out.path}/spot_check_en.md').readAsStringSync();
    expect(en, contains('## Animals'));
    expect(RegExp(r'^- ', multiLine: true).allMatches(en).length, 4);
  });
}
