import 'package:flutter_test/flutter_test.dart';
import 'package:void_charade/features/categories/word_utils.dart';

void main() {
  group('normalizeWord', () {
    test('ignores case, accents and punctuation', () {
      expect(normalizeWord('Caffè', 'it'), normalizeWord('caffe', 'it'));
      expect(normalizeWord('Rock-n-Roll!', 'en'), 'rock n roll');
    });

    test('strips leading Italian articles, including elided ones', () {
      for (final w in ['Il gatto', 'Un gatto', "L'orso", "Un'ape", 'Gli orsi']) {
        expect(normalizeWord(w, 'it').contains(' '), isFalse, reason: w);
      }
      expect(normalizeWord("L'orso", 'it'), 'orso');
      expect(normalizeWord("Un'ape", 'it'), 'ape');
      expect(normalizeWord('Il gatto', 'it'), normalizeWord('Gatto', 'it'));
    });

    test('strips leading English articles only for English', () {
      expect(normalizeWord('The Beatles', 'en'), 'beatles');
      expect(normalizeWord('A dog', 'en'), 'dog');
      // "la" is not an English article.
      expect(normalizeWord('La Scala', 'en'), 'la scala');
    });

    test('keeps a single-word entry even if it is an article', () {
      expect(normalizeWord('The', 'en'), 'the');
      expect(normalizeWord('La', 'it'), 'la');
    });

    test('treats curly apostrophes like straight ones', () {
      expect(normalizeWord('L’orso', 'it'), 'orso');
    });
  });

  group('parseWordFile', () {
    test('handles CRLF, BOM, blank lines and padding', () {
      expect(
        parseWordFile('﻿Cane\r\n\r\n  Gatto \r\nPesce\r\n'),
        ['Cane', 'Gatto', 'Pesce'],
      );
    });
  });

  group('dedupeWords', () {
    test('keeps the first spelling of near-duplicates', () {
      expect(
        dedupeWords(['Il gatto', 'Cane', 'Gatto', 'cane'], 'it'),
        ['Il gatto', 'Cane'],
      );
    });
  });
}
