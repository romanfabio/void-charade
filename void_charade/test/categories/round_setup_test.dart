import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_charade/features/categories/category.dart';
import 'package:void_charade/features/categories/round_setup.dart';
import 'package:void_charade/features/categories/word_repository.dart';

class _FakeBundle extends AssetBundle {
  _FakeBundle(this.files);
  final Map<String, String> files;

  @override
  Future<ByteData> load(String key) async {
    final content = files[key];
    if (content == null) throw FlutterError('Unable to load asset: "$key"');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(content)));
  }
}

Category _cat(String id, {bool adult = false}) => Category(
      id: id,
      emoji: '🙂',
      color: const Color(0xFF123456),
      adult: adult,
      names: {'en': id, 'it': id},
    );

const _animals = ['Dog', 'Cat', 'Horse', 'Cow', 'Pig', 'Duck', 'Frog', 'Owl'];

void main() {
  late WordRepository words;

  setUp(() {
    words = WordRepository(
      bundle: _FakeBundle({
        'assets/words/en/animals.txt': '${_animals.join('\n')}\n',
        'assets/words/en/farm.txt': 'Cow\nPig\nTractor\nBarn\n',
        'assets/words/it/animals.txt': 'Cane\nGatto\n',
      }),
    );
  });

  RoundSetupService service(int seed) =>
      RoundSetupService(words, random: Random(seed));

  group('category selection', () {
    test('contains every word exactly once, shuffled', () async {
      final round = await service(1).prepare(
        CategorySelection(_cat('animals')),
        playable: const [],
        languageCode: 'en',
      );
      expect(round.category?.id, 'animals');
      expect(round.words.toSet(), _animals.toSet());
      expect(round.words.length, _animals.length);
      expect(round.words, isNot(_animals));
    });

    test('does not corrupt the cached list between rounds', () async {
      await service(1).prepare(
        CategorySelection(_cat('animals')),
        playable: const [],
        languageCode: 'en',
      );
      expect(await words.load('animals', 'en'), _animals);
    });

    test('uses the requested word language', () async {
      final round = await service(1).prepare(
        CategorySelection(_cat('animals')),
        playable: const [],
        languageCode: 'it',
      );
      expect(round.words.toSet(), {'Cane', 'Gatto'});
    });

    test('a missing word file gives an empty round', () async {
      final round = await service(1).prepare(
        CategorySelection(_cat('nope')),
        playable: const [],
        languageCode: 'en',
      );
      expect(round.words, isEmpty);
    });
  });

  group('mix all', () {
    test('merges only the playable categories without duplicates', () async {
      final round = await service(3).prepare(
        const MixAllSelection(),
        playable: [_cat('animals'), _cat('farm')],
        languageCode: 'en',
      );
      expect(round.isMix, isTrue);
      expect(round.words.length, _animals.length + 2); // Cow, Pig shared
      expect(round.words.toSet(), {..._animals, 'Tractor', 'Barn'});
    });
  });

  group('random category', () {
    test('picks one of the playable categories', () async {
      final playable = [_cat('animals'), _cat('farm')];
      final picked = <String>{};
      for (var seed = 0; seed < 30; seed++) {
        final round = await service(seed).prepare(
          const RandomCategorySelection(),
          playable: playable,
          languageCode: 'en',
        );
        picked.add(round.category!.id);
      }
      expect(picked, {'animals', 'farm'});
    });

    test('with nothing playable gives an empty round', () async {
      final round = await service(1).prepare(
        const RandomCategorySelection(),
        playable: const [],
        languageCode: 'en',
      );
      expect(round.words, isEmpty);
    });
  });

  group('playableCategories', () {
    final all = [
      _cat('animals'),
      _cat('farm'),
      _cat('spicy', adult: true),
      _cat('movies'),
    ];
    const assets = {
      'assets/words/en/animals.txt',
      'assets/words/en/spicy.txt',
      'assets/words/it/animals.txt',
      'assets/words/it/movies.txt',
    };

    List<String> ids(String lang, bool showAdult) => playableCategories(
          all: all,
          assetPaths: assets,
          languageCode: lang,
          showAdult: showAdult,
        ).map((c) => c.id).toList();

    test('requires a word file for the current word language', () {
      expect(ids('en', true), ['animals', 'spicy']);
      expect(ids('it', true), ['animals', 'movies']);
    });

    test('hides 18+ categories when asked', () {
      expect(ids('en', false), ['animals']);
    });
  });
}
