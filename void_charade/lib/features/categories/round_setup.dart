import 'dart:math';

import 'category.dart';
import 'word_repository.dart';

/// What the player picked on the home screen.
sealed class RoundSelection {
  const RoundSelection();
}

class CategorySelection extends RoundSelection {
  const CategorySelection(this.category);
  final Category category;
}

class RandomCategorySelection extends RoundSelection {
  const RandomCategorySelection();
}

class MixAllSelection extends RoundSelection {
  const MixAllSelection();
}

/// A round ready to play: the words are already shuffled, so consuming them in
/// order gives a random sequence with no repeats.
class PreparedRound {
  const PreparedRound({required this.category, required this.words});

  /// The category being played, or null for "Mix all".
  final Category? category;
  final List<String> words;

  bool get isMix => category == null;
}

class RoundSetupService {
  RoundSetupService(this._words, {Random? random})
      : _random = random ?? Random();

  final WordRepository _words;
  final Random _random;

  /// [playable] must already be filtered (18+ setting, word files present).
  Future<PreparedRound> prepare(
    RoundSelection selection, {
    required List<Category> playable,
    required String languageCode,
  }) async {
    switch (selection) {
      case CategorySelection(:final category):
        return _forCategory(category, languageCode);
      case RandomCategorySelection():
        if (playable.isEmpty) {
          return const PreparedRound(category: null, words: []);
        }
        return _forCategory(
          playable[_random.nextInt(playable.length)],
          languageCode,
        );
      case MixAllSelection():
        final words = await _words.loadMixed(
          [for (final c in playable) c.id],
          languageCode,
        );
        return PreparedRound(category: null, words: _shuffled(words));
    }
  }

  Future<PreparedRound> _forCategory(Category category, String lang) async {
    final words = await _words.load(category.id, lang);
    return PreparedRound(category: category, words: _shuffled(words));
  }

  List<String> _shuffled(List<String> words) => [...words]..shuffle(_random);
}

/// Categories the player can actually choose: not hidden by the 18+ setting
/// and with a word file for [languageCode] bundled in the app.
List<Category> playableCategories({
  required List<Category> all,
  required Set<String> assetPaths,
  required String languageCode,
  required bool showAdult,
}) {
  return [
    for (final c in all)
      if ((showAdult || !c.adult) &&
          assetPaths.contains(WordRepository.assetPath(c.id, languageCode)))
        c,
  ];
}
