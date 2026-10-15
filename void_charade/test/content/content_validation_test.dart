import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/content_validator.dart';

/// Runs the validator on the real bundled content, so `flutter test` fails on
/// any broken word list. Categories without a word file yet are "pending".
void main() {
  test('bundled categories and word lists are valid', () {
    final report = validateContent(Directory.current);
    expect(
      report.errors,
      isEmpty,
      reason: report.errors.take(20).join('\n'),
    );
  });

  test('every category has an English and an Italian name and 50 exist', () {
    final report = validateContent(Directory.current);
    expect(report.categoryNames.length, 50);
    for (final entry in report.categoryNames.entries) {
      expect(entry.value.keys, containsAll(['en', 'it']), reason: entry.key);
    }
  });
}
