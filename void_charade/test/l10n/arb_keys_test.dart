import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _load(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

Set<String> _messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

Set<String> _placeholders(String message) => {
      for (final m in RegExp(r'\{(\w+)\}').allMatches(message)) m.group(1)!,
    };

void main() {
  final en = _load('lib/l10n/app_en.arb');
  final it = _load('lib/l10n/app_it.arb');

  test('Italian and English define the same message keys', () {
    expect(_messageKeys(it), _messageKeys(en));
  });

  test('Italian and English use the same placeholders in every message', () {
    for (final key in _messageKeys(en).difference({'@@locale'})) {
      expect(
        _placeholders(it[key] as String),
        _placeholders(en[key] as String),
        reason: 'placeholder mismatch in "$key"',
      );
    }
  });
}
