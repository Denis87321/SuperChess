import '../chess/chess_game.dart';
import '../chess/move_codec.dart';
import '../l10n/models/game_ability.dart';
import '../l10n/models/piece.dart';
import '../l10n/models/square.dart';

class OnlineReplayResult {
  const OnlineReplayResult({
    required this.game,
    this.whiteMs,
    this.blackMs,
  });

  final ChessGame game;
  final int? whiteMs;
  final int? blackMs;
}

/// Silently rebuilds a [ChessGame] from the server event log after resume.
class OnlineGameReplayer {
  static OnlineReplayResult replay(List<Map<String, dynamic>> eventLog) {
    final game = ChessGame();
    int? whiteMs;
    int? blackMs;

    for (final event in eventLog) {
      final type = event['type'] as String?;
      if (type == null) continue;
      switch (type) {
        case 'start_ability':
          AbilityOffer? offer;
          final offerJson = event['offer'];
          if (offerJson is Map<String, dynamic>) {
            offer = AbilityOffer.fromJson(offerJson);
          } else if (offerJson is Map) {
            offer = AbilityOffer.fromJson(Map<String, dynamic>.from(offerJson));
          }
          final color = event['color'] == 'white'
              ? PieceColor.white
              : PieceColor.black;
          game.applyRemoteStartAbility(
            color,
            gameAbilityFromJson(event['ability'] as String),
            lavaRank: event['lavaRank'] as int? ?? offer?.lavaRank,
            offer: offer,
          );
        case 'move':
          final moveJson = event['move'];
          if (moveJson is Map<String, dynamic>) {
            game.applyRemoteMove(MoveCodec.fromJson(moveJson));
          } else if (moveJson is Map) {
            game.applyRemoteMove(
              MoveCodec.fromJson(Map<String, dynamic>.from(moveJson)),
            );
          }
          final w = event['whiteMs'] as int?;
          final b = event['blackMs'] as int?;
          if (w != null) whiteMs = w;
          if (b != null) blackMs = b;
        case 'ability':
          AbilityOffer? offer;
          final offerJson = event['offer'];
          if (offerJson is Map<String, dynamic>) {
            offer = AbilityOffer.fromJson(offerJson);
          } else if (offerJson is Map) {
            offer = AbilityOffer.fromJson(Map<String, dynamic>.from(offerJson));
          }
          game.applyRemoteAbility(
            gameAbilityFromJson(event['ability'] as String),
            offer: offer,
          );
        case 'ability_target':
          final squareJson = event['square'];
          Square? square;
          if (squareJson is Map) {
            final f = squareJson['f'] ?? squareJson['file'];
            final r = squareJson['r'] ?? squareJson['rank'];
            if (f is int && r is int) {
              square = Square(f, r);
            }
          }
          final removeRaw = event['removeAbility'] as String?;
          if (removeRaw != null) {
            game.chooseAbilityToRemove(gameAbilityFromJson(removeRaw));
          } else {
            game.chooseAbilityTarget(
              pieceId: event['pieceId'] as String?,
              square: square,
              index: event['index'] as int? ?? 0,
            );
          }
        case 'reaction':
          final accepted = event['accepted'] as bool? ?? false;
          final abilityRaw = event['ability'] as String?;
          if (accepted && abilityRaw != null) {
            game.acceptRansom(gameAbilityFromJson(abilityRaw));
          } else if (!accepted) {
            game.declineRansom();
          }
        case 'reroll':
          final color = event['color'] == 'white'
              ? PieceColor.white
              : PieceColor.black;
          game.rerollPendingOffers(color);
        case 'skip_turn':
          game.skipTurn();
        case 'resign':
          final from = event['fromColor'] as String?;
          if (from == 'white') {
            game.resign(PieceColor.white);
          } else if (from == 'black') {
            game.resign(PieceColor.black);
          }
        case 'takeback_response':
          if (event['accepted'] == true) {
            game.takeback();
          }
        case 'clock_sync':
          whiteMs = event['whiteMs'] as int? ?? whiteMs;
          blackMs = event['blackMs'] as int? ?? blackMs;
        case 'game_over':
          final winnerRaw = event['winner'] as String?;
          PieceColor? winner;
          if (winnerRaw == 'white') {
            winner = PieceColor.white;
          } else if (winnerRaw == 'black') {
            winner = PieceColor.black;
          }
          GameEndReason? reason;
          final raw = event['reason'] as String?;
          if (raw != null) {
            for (final value in GameEndReason.values) {
              if (value.name == raw) {
                reason = value;
                break;
              }
            }
          }
          game.applyRemoteEnd(
            winner: winner,
            reason: reason,
            detail: event['detail'] as String? ?? raw,
          );
        default:
          break;
      }
    }

    return OnlineReplayResult(
      game: game,
      whiteMs: whiteMs,
      blackMs: blackMs,
    );
  }
}
