import '../chess/move.dart';
import '../models/game_ability.dart';
import '../models/piece.dart';
import '../models/square.dart';

class OnlineMatch {
  const OnlineMatch({
    required this.gameId,
    required this.localColor,
    required this.opponentName,
  });

  final String gameId;
  final PieceColor localColor;
  final String opponentName;
}

sealed class OnlineEvent {}

class OnlineSearching extends OnlineEvent {
  OnlineSearching({this.count});

  /// Сколько игроков сейчас в очереди поиска (включая себя).
  final int? count;
}

class OnlineMatched extends OnlineEvent {
  OnlineMatched(this.match);
  final OnlineMatch match;
}

class OnlineOpponentMove extends OnlineEvent {
  OnlineOpponentMove(this.move);
  final Move move;
}

class OnlineOpponentAbility extends OnlineEvent {
  OnlineOpponentAbility(this.ability, {this.offer, this.stateHash});

  final GameAbility ability;
  final AbilityOffer? offer;
  final String? stateHash;
}

class OnlineOpponentStartAbility extends OnlineEvent {
  OnlineOpponentStartAbility(
    this.color,
    this.ability, {
    this.lavaRank,
    this.offer,
  });

  final PieceColor color;
  final GameAbility ability;
  final int? lavaRank;
  final AbilityOffer? offer;
}

class OnlineOpponentAbilityTarget extends OnlineEvent {
  OnlineOpponentAbilityTarget({
    this.pieceId,
    this.square,
    this.index = 0,
    this.removeAbility,
    this.stateHash,
  });

  final String? pieceId;
  final Square? square;
  final int index;
  final GameAbility? removeAbility;
  final String? stateHash;
}

class OnlineOpponentReaction extends OnlineEvent {
  OnlineOpponentReaction({
    required this.accepted,
    this.ability,
    this.stateHash,
  });

  final bool accepted;
  final GameAbility? ability;
  final String? stateHash;
}

class OnlineOpponentReroll extends OnlineEvent {
  OnlineOpponentReroll(this.color, {this.stateHash});

  final PieceColor color;
  final String? stateHash;
}

class OnlineOpponentSkipTurn extends OnlineEvent {
  OnlineOpponentSkipTurn({this.stateHash});

  final String? stateHash;
}

class OnlineGameOver extends OnlineEvent {
  OnlineGameOver({this.winner, this.reason, this.stateHash});

  final PieceColor? winner;
  final String? reason;
  final String? stateHash;
}

class OnlineStateResync extends OnlineEvent {
  OnlineStateResync(this.snapshot);

  final Map<String, dynamic> snapshot;
}

class OnlineOpponentDisconnected extends OnlineEvent {}

class OnlineError extends OnlineEvent {
  OnlineError(this.message);
  final String message;
}

abstract class OnlineGameService {
  Stream<OnlineEvent> get events;

  Future<void> connect();

  Future<void> findGame({String playerName = 'Player'});

  void sendStartAbility(
    PieceColor color,
    GameAbility ability, {
    int? lavaRank,
    AbilityOffer? offer,
  });

  void sendMove(Move move);

  void sendAbility(
    GameAbility ability, {
    AbilityOffer? offer,
    String? stateHash,
  });

  void sendAbilityTarget({
    String? pieceId,
    Square? square,
    int index = 0,
    GameAbility? removeAbility,
    String? stateHash,
  });

  void sendReaction({
    required bool accepted,
    GameAbility? ability,
    String? stateHash,
  });

  void sendReroll(PieceColor color, {String? stateHash});

  void sendSkipTurn({String? stateHash});

  void sendGameOver({
    PieceColor? winner,
    String? reason,
    String? stateHash,
  });

  void dispose();
}
