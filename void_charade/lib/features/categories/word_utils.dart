// Pure Dart (no Flutter imports) so the content validator in `tool/` can reuse
// exactly the same normalisation the app uses to de-duplicate words.

const _articlesByLanguage = <String, Set<String>>{
  'it': {'il', 'lo', 'la', 'i', 'gli', 'le', 'un', 'uno', 'una'},
  'en': {'the', 'a', 'an'},
};

const _accentFolds = <String, String>{
  'àáâäãåā': 'a',
  'èéêëē': 'e',
  'ìíîïī': 'i',
  'òóôöõøō': 'o',
  'ùúûüū': 'u',
  'ç': 'c',
  'ñ': 'n',
  'ß': 'ss',
};

final _foldTable = <String, String>{
  for (final entry in _accentFolds.entries)
    for (final rune in entry.key.runes) String.fromCharCode(rune): entry.value,
};

/// Splits the raw content of a word file into entries, tolerating CRLF, a BOM
/// and stray blank lines (the validator is the one that rejects those).
List<String> parseWordFile(String raw) {
  final text = raw.startsWith('﻿') ? raw.substring(1) : raw;
  return [
    for (final line in text.split('\n'))
      if (line.trim().isNotEmpty) line.trim(),
  ];
}

/// Canonical form used to detect duplicates: lower-case, no accents, no leading
/// article, no punctuation, single spaces. "L'Orso", "orso" and "Un orso" all
/// normalise to "orso".
String normalizeWord(String word, String languageCode) {
  var s = word.toLowerCase().replaceAll('’', "'");
  s = s.split('').map((c) => _foldTable[c] ?? c).join();

  // Elided articles glued to the noun: l'orso, un'ape.
  s = s.replaceFirst(RegExp(r"^(?:l|un)'\s*"), '');

  s = s.replaceAll(RegExp(r'[^a-z0-9À-￿]+'), ' ').trim();
  final tokens = s.isEmpty ? <String>[] : s.split(RegExp(r'\s+'));

  final articles = _articlesByLanguage[languageCode] ?? const <String>{};
  if (tokens.length > 1 && articles.contains(tokens.first)) {
    tokens.removeAt(0);
  }
  return tokens.join(' ');
}

/// Removes duplicates (by [normalizeWord]) keeping the first occurrence.
List<String> dedupeWords(Iterable<String> words, String languageCode) {
  final seen = <String>{};
  return [
    for (final w in words)
      if (seen.add(normalizeWord(w, languageCode))) w,
  ];
}
