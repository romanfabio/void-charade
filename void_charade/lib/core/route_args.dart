import '../features/categories/category.dart';
import '../features/categories/round_setup.dart';
import '../features/results/round_result.dart';

/// Passed to the game screen as the route `extra`.
class GameArgs {
  const GameArgs({required this.selection, required this.round});

  /// What to replay on "Play again". A random pick is stored as the category it
  /// resolved to, so replaying keeps the same category.
  final RoundSelection selection;
  final PreparedRound round;
}

/// Passed to the results screen as the route `extra`.
class ResultsArgs {
  const ResultsArgs({
    required this.result,
    required this.selection,
    required this.category,
  });

  final RoundResult result;
  final RoundSelection selection;

  /// Null for "Mix all".
  final Category? category;
}
