import 'dart:math' as math;

class Elo {
  /// Classic Elo. [score] is 1 win, 0 loss, 0.5 draw.
  static int kFactor(int gamesPlayed) => gamesPlayed < 30 ? 40 : 32;

  static double expected(int rating, int opponentRating) {
    return 1.0 /
        (1.0 + math.pow(10, (opponentRating - rating) / 400.0));
  }

  static int nextRating({
    required int rating,
    required int opponentRating,
    required double score,
    required int gamesPlayed,
  }) {
    final k = kFactor(gamesPlayed);
    final exp = expected(rating, opponentRating);
    return (rating + k * (score - exp)).round();
  }
}
