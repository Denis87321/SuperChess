import '../chess/move.dart';
import '../l10n/models/game_ability.dart';
import '../l10n/models/piece.dart';
import '../l10n/models/square.dart';

class OnlineMatch {
  const OnlineMatch({
    required this.gameId,
    required this.localColor,
    required this.opponentName,
    this.resumeToken,
    this.rated = false,
    this.yourRating,
    this.opponentRating,
    this.opponentLoggedIn = false,
    this.timeControlId = '5+0',
    this.initialMs = 300000,
    this.incrementMs = 0,
  });

  final String gameId;
  final PieceColor localColor;
  final String opponentName;
  final String? resumeToken;
  final bool rated;
  final int? yourRating;
  final int? opponentRating;
  final bool opponentLoggedIn;
  final String timeControlId;
  final int initialMs;
  final int incrementMs;
}

class OnlineLobbySnapshot extends OnlineEvent {
  OnlineLobbySnapshot({required this.seeks, required this.count});
  final List<Map<String, dynamic>> seeks;
  final int count;
}

class OnlineIllegalMove extends OnlineEvent {
  OnlineIllegalMove(this.message);
  final String message;
}

class OnlineIllegalAction extends OnlineEvent {
  OnlineIllegalAction(this.message, {this.action});
  final String message;
  final String? action;
}

class OnlineFairPlayAlert extends OnlineEvent {
  OnlineFairPlayAlert({
    required this.color,
    required this.matchRate,
    required this.samples,
    this.soft = true,
  });
  final String color;
  final double matchRate;
  final int samples;
  final bool soft;
}

class OnlineDmMessage extends OnlineEvent {
  OnlineDmMessage(this.message);
  final Map<String, dynamic> message;
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
  OnlineOpponentMove(this.move, {this.whiteMs, this.blackMs});

  final Move move;

  /// Authoritative remaining times frozen by the mover at send time.
  final int? whiteMs;
  final int? blackMs;
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
  OnlineGameOver({this.winner, this.reason, this.detail, this.stateHash});

  final PieceColor? winner;
  final String? reason;
  final String? detail;
  final String? stateHash;
}

class OnlineRematchOffer extends OnlineEvent {}

class OnlineRematchStart extends OnlineEvent {
  OnlineRematchStart(this.match);
  final OnlineMatch match;
}

class OnlineStateResync extends OnlineEvent {
  OnlineStateResync(this.snapshot);

  final Map<String, dynamic> snapshot;
}

class OnlineChatMessage extends OnlineEvent {
  OnlineChatMessage(this.text, {this.fromOpponent = true});

  final String text;
  final bool fromOpponent;
}

class OnlineResign extends OnlineEvent {}

class OnlineDrawOffer extends OnlineEvent {}

class OnlineDrawResponse extends OnlineEvent {
  OnlineDrawResponse({required this.accepted});
  final bool accepted;
}

class OnlineTakebackOffer extends OnlineEvent {}

class OnlineTakebackResponse extends OnlineEvent {
  OnlineTakebackResponse({required this.accepted});
  final bool accepted;
}

class OnlineClockSync extends OnlineEvent {
  OnlineClockSync({required this.whiteMs, required this.blackMs});

  final int whiteMs;
  final int blackMs;
}

/// Local WebSocket dropped; auto-resume may be in progress.
class OnlineConnectionLost extends OnlineEvent {}

/// Opponent seat disconnected; [graceMs] until forfeit.
class OnlineOpponentDisconnected extends OnlineEvent {
  OnlineOpponentDisconnected({this.graceMs = 90000});

  final int graceMs;
}

class OnlineOpponentReconnected extends OnlineEvent {}

/// Grace expired / room closed without a clean game_over.
class OnlineOpponentLeft extends OnlineEvent {}

class OnlineResumeOk extends OnlineEvent {
  OnlineResumeOk(this.match, {required this.eventLog});

  final OnlineMatch match;
  final List<Map<String, dynamic>> eventLog;
}

class OnlineResumeFailed extends OnlineEvent {
  OnlineResumeFailed(this.message);
  final String message;
}

class OnlinePrivateWaiting extends OnlineEvent {
  OnlinePrivateWaiting(this.code);
  final String code;
}

class OnlineSpectateOk extends OnlineEvent {
  OnlineSpectateOk({
    required this.gameId,
    required this.eventLog,
    this.roomCode,
    this.whiteName,
    this.blackName,
  });

  final String gameId;
  final String? roomCode;
  final String? whiteName;
  final String? blackName;
  final List<Map<String, dynamic>> eventLog;
}

class OnlineError extends OnlineEvent {
  OnlineError(this.message);
  final String message;
}

abstract class OnlineGameService {
  Stream<OnlineEvent> get events;

  Future<void> connect();

  Future<void> findGame({
    String playerName = 'Player',
    String? token,
    String timeControlId = '5+0',
    bool? rated,
  });

  void cancelSeek();

  void subscribeLobby();

  void requeue({
    String playerName = 'Player',
    String? token,
    String timeControlId = '5+0',
    bool? rated,
  });

  void presencePing(String? token);

  void sendDm({required String toUserId, required String body});

  void createPrivateRoom({String playerName = 'Player', String? token});

  void joinPrivateRoom({
    required String code,
    String playerName = 'Player',
    String? token,
  });

  void cancelPrivateRoom();

  void spectatePrivateRoom(String code);

  void leaveSpectate({String? gameId});

  void sendStartAbility(
    PieceColor color,
    GameAbility ability, {
    int? lavaRank,
    AbilityOffer? offer,
  });

  void sendMove(Move move, {int? whiteMs, int? blackMs});

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
    String? detail,
    String? stateHash,
  });

  void sendRematchOffer();

  void sendRematchAccept();

  void sendChat(String text);

  void sendResign();

  void sendDrawOffer();

  void sendDrawResponse({required bool accepted});

  void sendTakebackOffer();

  void sendTakebackResponse({required bool accepted});

  void sendClockSync({required int whiteMs, required int blackMs});

  /// Intentional leave (forfeit without grace). Cleares resume credentials.
  void sendLeaveGame();

  /// Clear stored resume credentials after a finished game.
  Future<void> clearResumeSession();

  void dispose();
}
