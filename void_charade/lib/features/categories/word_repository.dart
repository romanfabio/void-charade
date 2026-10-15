import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'word_utils.dart';

class WordRepository {
  WordRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final _cache = <String, List<String>>{};

  static String assetPath(String categoryId, String languageCode) =>
      'assets/words/$languageCode/$categoryId.txt';

  /// Words of one category in one language. Returns an empty list when the
  /// file does not exist (content still being written for that language).
  Future<List<String>> load(String categoryId, String languageCode) async {
    final path = assetPath(categoryId, languageCode);
    final cached = _cache[path];
    if (cached != null) return cached;

    List<String> words;
    try {
      words = parseWordFile(await _bundle.loadString(path));
    } on FlutterError {
      words = const [];
    }
    return _cache[path] = words;
  }

  /// Merged, de-duplicated words of several categories.
  Future<List<String>> loadMixed(
    Iterable<String> categoryIds,
    String languageCode,
  ) async {
    final lists = await Future.wait(
      [for (final id in categoryIds) load(id, languageCode)],
    );
    return dedupeWords(lists.expand((l) => l), languageCode);
  }
}

final wordRepositoryProvider = Provider<WordRepository>(
  (ref) => WordRepository(),
);
