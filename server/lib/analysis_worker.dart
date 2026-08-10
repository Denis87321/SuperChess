import 'db.dart';
import 'stockfish_service.dart';

/// Run Stockfish over PGN coordinate moves (classical approximation under mods).
Future<void> runAnalysisJob({
  required AuthDatabase db,
  required String jobId,
  required String gameId,
}) async {
  final pgn = await db.getGamePgn(gameId);
  if (pgn == null || pgn.isEmpty) {
    await db.setAnalysisResult(
      jobId: jobId,
      gameId: gameId,
      analysis: null,
      status: 'failed',
      error: 'no_pgn',
    );
    return;
  }
  final ok = await StockfishService.instance.ensureStarted();
  if (!ok) {
    await db.setAnalysisResult(
      jobId: jobId,
      gameId: gameId,
      analysis: null,
      status: 'failed',
      error: StockfishService.instance.lastError ?? 'stockfish_unavailable',
    );
    return;
  }

  final moves = _extractUciMoves(pgn);
  final evals = <Map<String, dynamic>>[];
  const maxPlies = 40;

  final openBest = await StockfishService.instance.goBestMoveFromMoves(
    moves: const [],
    movetimeMs: 80,
  );
  evals.add({
    'ply': 0,
    'best': openBest,
    'played': moves.isEmpty ? null : moves.first,
  });

  for (var i = 0; i < moves.length && i < maxPlies; i++) {
    final prefix = moves.sublist(0, i);
    final played = moves[i];
    final best = await StockfishService.instance.goBestMoveFromMoves(
      moves: prefix,
      movetimeMs: 60,
    );
    final matched = best != null && _uciEqual(played, best);
    evals.add({
      'ply': i + 1,
      'played': played,
      'best': best,
      'matched': matched,
      'judgment': matched
          ? 'best'
          : (best == null ? 'unknown' : 'inaccuracy'),
    });
  }

  await db.setAnalysisResult(
    jobId: jobId,
    gameId: gameId,
    analysis: {
      'approxUnderMods': true,
      'evals': evals,
      'moveCount': moves.length,
      'analyzedPlies': evals.length,
      'pgnLength': pgn.length,
      'note':
          'Classical Stockfish line replay; judgments approximate under mods',
    },
  );
}

List<String> _extractUciMoves(String pgn) {
  final body = pgn.split('\n\n').length > 1
      ? pgn.split('\n\n').sublist(1).join('\n')
      : pgn;
  final cleaned = body
      .replaceAll(RegExp(r'\{[^}]*\}'), ' ')
      .replaceAll(RegExp(r'\([^)]*\)'), ' ');
  final out = <String>[];
  for (final tok in cleaned.split(RegExp(r'\s+'))) {
    if (tok.isEmpty || tok.endsWith('.')) continue;
    if (tok == '1-0' || tok == '0-1' || tok == '1/2-1/2' || tok == '*') {
      continue;
    }
    final m = RegExp(r'^([a-h][1-8][a-h][1-8][qrbn]?)', caseSensitive: false)
        .firstMatch(tok);
    if (m != null) {
      out.add(m.group(1)!.toLowerCase());
    }
  }
  return out;
}

bool _uciEqual(String a, String b) {
  String norm(String u) {
    final t = u.toLowerCase().trim();
    if (t.length >= 5 && 'qrbn'.contains(t[4])) return t.substring(0, 5);
    return t.length >= 4 ? t.substring(0, 4) : t;
  }

  return norm(a) == norm(b);
}
