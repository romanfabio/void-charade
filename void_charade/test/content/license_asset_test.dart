import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the licence bundled in the app is the repository LICENSE', () {
    final bundled = File('assets/LICENSE.txt').readAsStringSync();
    final root = File('../LICENSE').readAsStringSync();
    expect(bundled, root, reason: 'copy ../LICENSE to assets/LICENSE.txt');
    expect(bundled, contains('MIT License'));
  });

  test('the version shown in the app matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version =
        RegExp(r'^version: (\d+\.\d+\.\d+)\+\d+$', multiLine: true)
            .firstMatch(pubspec)!
            .group(1);
    final screen =
        File('lib/features/settings/settings_screen.dart').readAsStringSync();
    expect(screen, contains("const _appVersion = '$version';"));
  });
}
