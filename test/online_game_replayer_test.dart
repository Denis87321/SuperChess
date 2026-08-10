import 'package:flutter_test/flutter_test.dart';
import 'package:super_chess/chess/chess_game.dart';
import 'package:super_chess/l10n/models/game_ability.dart';
import 'package:super_chess/l10n/models/piece.dart';
import 'package:super_chess/l10n/models/square.dart';
import 'package:super_chess/online/online_game_replayer.dart';

void main() {
  test('replays start abilities, a move, and clock_sync', () {
    final log = <Map<String, dynamic>>[
      {
        'type': 'start_ability',
        'color': 'white',
        'ability': gameAbilityToJson(GameAbility.modeAtomic),
        'offer': {
          'ability': 'modeAtomic',
          'applyMode': 'boardWide',
        },
      },
      {
        'type': 'start_ability',
        'color': 'black',
        'ability': gameAbilityToJson(GameAbility.boardFogOfWar),
        'offer': {
          'ability': 'boardFogOfWar',
          'applyMode': 'boardWide',
        },
      },
      {
        'type': 'move',
        'move': {
          'fromF': 4,
          'fromR': 1,
          'toF': 4,
          'toR': 3,
          'pieceIndex': 0,
        },
        'whiteMs': 295000,
        'blackMs': 300000,
        'fromColor': 'white',
      },
      {
        'type': 'clock_sync',
        'whiteMs': 294000,
        'blackMs': 300000,
      },
    ];

    final result = OnlineGameReplayer.replay(log);
    expect(result.game.isReadyToPlay, isTrue);
    expect(result.game.turn, PieceColor.black);
    expect(result.game.pieceAt(const Square(4, 3))?.type, PieceType.pawn);
    expect(result.whiteMs, 294000);
    expect(result.blackMs, 300000);
  });

  test('replays disconnect game_over', () {
    final result = OnlineGameReplayer.replay([
      {
        'type': 'game_over',
        'winner': 'white',
        'reason': 'disconnect',
      },
    ]);
    expect(result.game.isGameOver, isTrue);
    expect(result.game.winnerColor, PieceColor.white);
    expect(result.game.endReason, GameEndReason.disconnect);
  });
}
