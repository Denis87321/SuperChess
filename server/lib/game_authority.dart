import 'package:super_chess_engine/super_chess_engine.dart';

/// Result of an authoritative gameplay action.
class AuthorityResult {
  const AuthorityResult({
    this.error,
    this.broadcast,
    this.gameOver = false,
    this.winner,
    this.reason,
    this.detail,
  });

  final String? error;
  final Map<String, dynamic>? broadcast;
  final bool gameOver;
  final String? winner; // white | black | null draw
  final String? reason;
  final String? detail;

  bool get ok => error == null;

  static AuthorityResult fail(String error) => AuthorityResult(error: error);
}

/// Server-side game + clock authority for one online room.
class GameAuthority {
  GameAuthority({required this.tc})
      : game = ChessGame(),
        clock = ServerClock(tc);

  final TimeControl tc;
  final ChessGame game;
  final ServerClock clock;
  final List<String> sans = [];
  bool started = false;
  bool finalized = false;

  String? get winnerColorName {
    final w = game.winnerColor;
    if (w == null && game.isGameOver) return null;
    if (w == PieceColor.white) return 'white';
    if (w == PieceColor.black) return 'black';
    return null;
  }

  String? get endReasonName => game.endReason?.name;

  void onBothReady() {
    if (started) return;
    started = true;
    clock.start('white');
  }

  String? fenBeforeMove() => tryBuildFen(game);

  String currentStateHash() => game.stateHash;

  Map<String, dynamic> clockSnapshot() => clock.snapshot();

  /// Apply a client move JSON. Returns error message or null on success.
  String? applyMove({
    required String fromColor,
    required Map<String, dynamic> moveJson,
  }) {
    if (game.isGameOver) return 'game_over';
    final expected = game.turn == PieceColor.white ? 'white' : 'black';
    if (fromColor != expected) return 'not_your_turn';

    // Auto-skip start abilities if still pending (server cannot UI-pick).
    if (!game.isReadyToPlay) {
      if (game.isAwaitingStartChoice(PieceColor.white)) {
        game.skipStartAbility(PieceColor.white);
      }
      if (game.isAwaitingStartChoice(PieceColor.black)) {
        game.skipStartAbility(PieceColor.black);
      }
    }
    if (!started && game.isReadyToPlay) onBothReady();

    final move = MoveCodec.fromJson(moveJson);
    final legal = game.getLegalMoves(from: move.from);
    final matched = legal.cast<Move?>().firstWhere(
      (m) =>
          m!.to == move.to &&
          m.promotion == move.promotion &&
          m.pieceIndex == move.pieceIndex,
      orElse: () => null,
    );
    if (matched == null) {
      final any = legal.cast<Move?>().firstWhere(
        (m) => m!.to == move.to && m.pieceIndex == move.pieceIndex,
        orElse: () => null,
      );
      if (any == null) return 'illegal_move';
      final result = game.makeMove(any);
      if (result == null) return 'illegal_move';
      sans.add(_san(any));
    } else {
      final result = game.makeMove(matched);
      if (result == null) return 'illegal_move';
      sans.add(_san(matched));
    }
    clock.afterMove(fromColor);
    return null;
  }

  AuthorityResult applyStartAbility({
    required String fromColor,
    required String color,
    required String abilityName,
    int? lavaRank,
    Map<String, dynamic>? offerJson,
  }) {
    if (game.isGameOver) return AuthorityResult.fail('game_over');
    if (color != fromColor) return AuthorityResult.fail('not_your_seat');
    final pieceColor =
        color == 'white' ? PieceColor.white : PieceColor.black;
    if (!game.isAwaitingStartChoice(pieceColor)) {
      return AuthorityResult.fail('not_awaiting_start');
    }
    final ability = _parseAbility(abilityName);
    if (ability == null) return AuthorityResult.fail('bad_ability');
    AbilityOffer? offer;
    if (offerJson != null) {
      try {
        offer = AbilityOffer.fromJson(offerJson);
      } catch (_) {
        return AuthorityResult.fail('bad_offer');
      }
    }
    try {
      game.applyRemoteStartAbility(
        pieceColor,
        ability,
        lavaRank: lavaRank ?? offer?.lavaRank,
        offer: offer,
      );
    } catch (_) {
      return AuthorityResult.fail('apply_failed');
    }
    if (!started && game.isReadyToPlay) onBothReady();
    return AuthorityResult(
      broadcast: {
        'type': 'start_ability',
        'color': color,
        'ability': ability.name,
        'lavaRank': lavaRank ?? offer?.lavaRank,
        if (offer != null) 'offer': offer.toJson(),
        'stateHash': game.stateHash,
      },
    );
  }

  AuthorityResult applyAbility({
    required String fromColor,
    required String abilityName,
    Map<String, dynamic>? offerJson,
  }) {
    if (game.isGameOver) return AuthorityResult.fail('game_over');
    final pending = game.pendingSkillColor;
    if (pending == null) return AuthorityResult.fail('no_pending_skill');
    final pendingName =
        pending == PieceColor.white ? 'white' : 'black';
    if (pendingName != fromColor) return AuthorityResult.fail('not_your_turn');
    final ability = _parseAbility(abilityName);
    if (ability == null) return AuthorityResult.fail('bad_ability');
    AbilityOffer? offer;
    if (offerJson != null) {
      try {
        offer = AbilityOffer.fromJson(offerJson);
      } catch (_) {
        return AuthorityResult.fail('bad_offer');
      }
    }
    try {
      game.applyRemoteAbility(ability, offer: offer);
    } catch (_) {
      return AuthorityResult.fail('apply_failed');
    }
    return _okAbilityBroadcast(
      type: 'ability',
      extra: {
        'ability': ability.name,
        if (offer != null) 'offer': offer.toJson(),
      },
    );
  }

  AuthorityResult applyAbilityTarget({
    required String fromColor,
    String? pieceId,
    Map<String, dynamic>? squareJson,
    int index = 0,
    String? removeAbilityName,
  }) {
    if (game.isGameOver) return AuthorityResult.fail('game_over');
    if (!game.isAwaitingAbilityTarget) {
      return AuthorityResult.fail('not_awaiting_target');
    }
    final pending = game.pendingSkillColor;
    if (pending != null) {
      final pendingName =
          pending == PieceColor.white ? 'white' : 'black';
      if (pendingName != fromColor) {
        return AuthorityResult.fail('not_your_turn');
      }
    }
    var ok = false;
    if (removeAbilityName != null) {
      final ability = _parseAbility(removeAbilityName);
      if (ability == null) return AuthorityResult.fail('bad_ability');
      ok = game.chooseAbilityToRemove(ability);
    } else {
      Square? square;
      if (squareJson != null) {
        final f = squareJson['f'] ?? squareJson['file'];
        final r = squareJson['r'] ?? squareJson['rank'];
        if (f is int && r is int) square = Square(f, r);
      }
      ok = game.chooseAbilityTarget(
        pieceId: pieceId,
        square: square,
        index: index,
      );
    }
    if (!ok) return AuthorityResult.fail('illegal_target');
    return _okAbilityBroadcast(
      type: 'ability_target',
      extra: {
        if (pieceId != null) 'pieceId': pieceId,
        if (squareJson != null) 'square': squareJson,
        'index': index,
        if (removeAbilityName != null) 'removeAbility': removeAbilityName,
      },
    );
  }

  AuthorityResult applyReaction({
    required String fromColor,
    required bool accepted,
    String? abilityName,
  }) {
    if (game.isGameOver) return AuthorityResult.fail('game_over');
    if (!game.isAwaitingReaction) {
      return AuthorityResult.fail('not_awaiting_reaction');
    }
    if (accepted) {
      final ability = _parseAbility(abilityName ?? '');
      if (ability == null) return AuthorityResult.fail('bad_ability');
      if (!game.acceptRansom(ability)) {
        return AuthorityResult.fail('illegal_reaction');
      }
      return _okAbilityBroadcast(
        type: 'reaction',
        extra: {'accepted': true, 'ability': ability.name},
      );
    }
    final result = game.declineRansom();
    if (result == null) return AuthorityResult.fail('illegal_reaction');
    return _okAbilityBroadcast(
      type: 'reaction',
      extra: {'accepted': false},
      checkGameOver: true,
    );
  }

  AuthorityResult applyReroll({
    required String fromColor,
    required String color,
  }) {
    if (game.isGameOver) return AuthorityResult.fail('game_over');
    if (color != fromColor) return AuthorityResult.fail('not_your_seat');
    final pieceColor =
        color == 'white' ? PieceColor.white : PieceColor.black;
    if (!game.canRerollPendingOffers(pieceColor)) {
      return AuthorityResult.fail('cannot_reroll');
    }
    if (!game.rerollPendingOffers(pieceColor)) {
      return AuthorityResult.fail('reroll_failed');
    }
    return _okAbilityBroadcast(
      type: 'reroll',
      extra: {'color': color},
    );
  }

  AuthorityResult applySkipTurn({required String fromColor}) {
    if (game.isGameOver) return AuthorityResult.fail('game_over');
    final expected = game.turn == PieceColor.white ? 'white' : 'black';
    if (fromColor != expected) return AuthorityResult.fail('not_your_turn');
    if (!game.canSkipTurn) return AuthorityResult.fail('cannot_skip');
    if (!game.skipTurn()) return AuthorityResult.fail('skip_failed');
    clock.afterMove(fromColor);
    return _okAbilityBroadcast(type: 'skip_turn', checkGameOver: true);
  }

  AuthorityResult applyResign({required String fromColor}) {
    if (game.isGameOver) return AuthorityResult.fail('game_over');
    final color =
        fromColor == 'white' ? PieceColor.white : PieceColor.black;
    game.resign(color);
    return _endResult(reason: 'resign');
  }

  AuthorityResult applyTimeout({required String flaggedColor}) {
    if (game.isGameOver) return AuthorityResult.fail('game_over');
    final color =
        flaggedColor == 'white' ? PieceColor.white : PieceColor.black;
    game.flagTimeout(color);
    return _endResult(reason: 'timeout');
  }

  AuthorityResult applyDisconnectForfeit({
    required String disconnectedColor,
    String? detail,
  }) {
    if (game.isGameOver) return AuthorityResult.fail('game_over');
    final color = disconnectedColor == 'white'
        ? PieceColor.white
        : PieceColor.black;
    game.resign(color); // opponent wins
    return _endResult(reason: 'disconnect', detail: detail);
  }

  AuthorityResult applyDrawAgreed() {
    if (game.isGameOver) return AuthorityResult.fail('game_over');
    game.agreeDraw();
    return _endResult(reason: 'draw');
  }

  /// Client-reported end: accept only if engine already over.
  AuthorityResult confirmClientGameOver({
    String? winner,
    String? reason,
    String? detail,
  }) {
    if (finalized) return const AuthorityResult();
    if (!game.isGameOver) {
      return AuthorityResult.fail('game_not_over');
    }
    return _endResult(
      reason: reason ?? endReasonName ?? 'ended',
      detail: detail,
    );
  }

  AuthorityResult _okAbilityBroadcast({
    required String type,
    Map<String, dynamic> extra = const {},
    bool checkGameOver = false,
  }) {
    final payload = <String, dynamic>{
      'type': type,
      ...extra,
      'stateHash': game.stateHash,
      ...clock.snapshot().map((k, v) => MapEntry(k.toString(), v)),
    };
    if (checkGameOver && game.isGameOver) {
      return AuthorityResult(
        broadcast: payload,
        gameOver: true,
        winner: winnerColorName,
        reason: endReasonName,
      );
    }
    return AuthorityResult(broadcast: payload);
  }

  AuthorityResult _endResult({required String reason, String? detail}) {
    clock.pause();
    return AuthorityResult(
      broadcast: {
        'type': 'game_over',
        'winner': winnerColorName,
        'reason': reason,
        if (detail != null) 'detail': detail,
        'stateHash': game.stateHash,
        'fromColor': 'server',
      },
      gameOver: true,
      winner: winnerColorName,
      reason: reason,
      detail: detail,
    );
  }

  GameAbility? _parseAbility(String name) {
    if (name.isEmpty) return null;
    try {
      return GameAbility.values.byName(name);
    } catch (_) {
      return null;
    }
  }

  String _san(Move m) {
    final from = squareLabel(m.from);
    final to = squareLabel(m.to);
    final promo = m.promotion != null
        ? '=${m.promotion!.name[0].toUpperCase()}'
        : '';
    return '$from$to$promo';
  }

  String toPgn({
    required String white,
    required String black,
    String? whiteElo,
    String? blackElo,
    String result = '*',
  }) {
    return buildPgn(
      headers: {
        'White': white,
        'Black': black,
        'TimeControl': '${tc.initialSec}+${tc.incrementSec}',
        if (whiteElo != null) 'WhiteElo': whiteElo,
        if (blackElo != null) 'BlackElo': blackElo,
        'Result': result,
      },
      sans: sans,
      result: result,
    );
  }
}
