enum WordOutcome { guessed, skipped, notPlayed }

class PlayedWord {
  const PlayedWord(this.text, this.outcome);
  final String text;
  final WordOutcome outcome;
}

/// The outcome of a finished round.
class RoundResult {
  const RoundResult({required this.words, required this.skipPenalty});

  /// In play order.
  final List<PlayedWord> words;

  /// Whether each skipped word costs one point (setting at round start).
  final bool skipPenalty;

  int get guessed => _count(WordOutcome.guessed);
  int get skipped => _count(WordOutcome.skipped);
  int get notPlayed => _count(WordOutcome.notPlayed);

  /// Not-played words never count. Can be negative with [skipPenalty].
  int get score => guessed - (skipPenalty ? skipped : 0);

  int _count(WordOutcome o) => words.where((w) => w.outcome == o).length;
}
