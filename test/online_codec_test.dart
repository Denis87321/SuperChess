import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:super_chess/chess/chess_game.dart';
import 'package:super_chess/chess/move.dart';
import 'package:super_chess/chess/move_codec.dart';
import 'package:super_chess/l10n/models/game_ability.dart';
import 'package:super_chess/l10n/models/piece.dart';
import 'package:super_chess/l10n/models/square.dart';
import 'package:super_chess/online/online_game_service.dart';

/// Message types the SuperChess websocket server relays to the opponent
/// (same path as `move` / `ability` / `start_ability`).
const relayMessageTypes = <String>{
  'move',
  'ability',
  'start_ability',
  'ability_target',
  'reaction',
  'reroll',
  'skip_turn',
  'game_over',
  'state_resync',
  'clock_sync',
};

void main() {
  test('MoveCodec round-trips ability-related move flags', () {
    final move = Move(
      from: const Square(1, 1),
      to: const Square(2, 3),
      promotion: PieceType.queen,
      isEnPassant: true,
      isCastle: false,
      isCastleSwap: true,
      isKnightRearSwap: true,
      isRookPush: true,
      isColorChaos: true,
      isAirborne: true,
      isInquisitorStrip: true,
      pieceIndex: 2,
    );

    final decoded = MoveCodec.fromJson(MoveCodec.toJson(move));
    expect(decoded.from, move.from);
    expect(decoded.to, move.to);
    expect(decoded.promotion, PieceType.queen);
    expect(decoded.isEnPassant, isTrue);
    expect(decoded.isCastleSwap, isTrue);
    expect(decoded.isKnightRearSwap, isTrue);
    expect(decoded.isRookPush, isTrue);
    expect(decoded.isColorChaos, isTrue);
    expect(decoded.isAirborne, isTrue);
    expect(decoded.isInquisitorStrip, isTrue);
    expect(decoded.pieceIndex, 2);
  });

  test('AbilityOffer JSON round-trips for online ability payload', () {
    const offer = AbilityOffer(
      ability: GameAbility.pawnSideways,
      applyMode: AbilityApplyMode.capturingPiece,
      lavaRank: 3,
      forColor: PieceColor.white,
    );

    final json = offer.toJson();
    expect(json['ability'], 'pawnSideways');
    expect(AbilityOffer.fromJson(json).toJson(), json);
  });

  test('ability message keeps backward-compatible ability name field', () {
    final payload = <String, dynamic>{
      'type': 'ability',
      'gameId': 'g1',
      'ability': gameAbilityToJson(GameAbility.pawnSideways),
      'offer': const AbilityOffer(
        ability: GameAbility.pawnSideways,
        applyMode: AbilityApplyMode.capturingPiece,
      ).toJson(),
      'stateHash': 'abc',
    };

    expect(payload['type'], 'ability');
    expect(payload['ability'], 'pawnSideways');
    expect(payload['offer'], isA<Map<String, dynamic>>());
    expect(payload['stateHash'], 'abc');
  });

  test('server relay set includes ability expansion types', () {
    expect(relayMessageTypes, containsAll(<String>[
      'ability_target',
      'reaction',
      'reroll',
      'skip_turn',
      'game_over',
    ]));
  });

  test('ability_target square uses compact f/r encoding', () {
    const square = Square(4, 5);
    final payload = <String, dynamic>{
      'type': 'ability_target',
      'gameId': 'g1',
      'pieceId': 'p1',
      'square': {'f': square.file, 'r': square.rank},
      'index': 0,
      'stateHash': 'h1',
    };

    final encoded = payload['square'] as Map<String, dynamic>;
    expect(encoded['f'], 4);
    expect(encoded['r'], 5);
    expect(relayMessageTypes, contains(payload['type']));
  });

  test('ChessGame.stateHash is stable for identical starting position', () {
    final a = ChessGame();
    final b = ChessGame();
    expect(a.stateHash, b.stateHash);
    expect(a.stateHash, isNotEmpty);
  });

  test('action envelope payloads round-trip ability expansion fields', () {
    final abilityTarget = <String, dynamic>{
      'type': 'ability_target',
      'gameId': 'g1',
      'pieceId': 'enemy-1',
      'square': {'f': 2, 'r': 3},
      'index': 1,
      'removeAbility': gameAbilityToJson(GameAbility.pawnSideways),
      'stateHash': 'h1',
    };
    final reaction = <String, dynamic>{
      'type': 'reaction',
      'gameId': 'g1',
      'accepted': true,
      'ability': gameAbilityToJson(GameAbility.pawnRansom),
      'stateHash': 'h2',
    };
    final reroll = <String, dynamic>{
      'type': 'reroll',
      'gameId': 'g1',
      'color': 'white',
      'stateHash': 'h3',
    };
    final skip = <String, dynamic>{
      'type': 'skip_turn',
      'gameId': 'g1',
      'stateHash': 'h4',
    };
    final gameOver = <String, dynamic>{
      'type': 'game_over',
      'gameId': 'g1',
      'winner': 'black',
      'reason': 'alternativeVictory',
      'stateHash': 'h5',
    };

    for (final payload in [abilityTarget, reaction, reroll, skip, gameOver]) {
      final encoded = jsonEncode(payload);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      expect(decoded, payload);
      expect(relayMessageTypes, contains(decoded['type']));
    }

    final square = abilityTarget['square'] as Map<String, dynamic>;
    expect(Square(square['f'] as int, square['r'] as int), const Square(2, 3));
    expect(
      gameAbilityFromJson(abilityTarget['removeAbility'] as String),
      GameAbility.pawnSideways,
    );
    expect(reaction['accepted'], isTrue);
    expect(gameOver['winner'], 'black');
  });

  test('baked random AbilityOffer fields survive JSON for sync', () {
    const offer = AbilityOffer(
      ability: GameAbility.rookCustoms,
      applyMode: AbilityApplyMode.capturingPiece,
      axis: AbilityAxis.file,
      durationMoves: 3,
      route: [Square(0, 1), Square(0, 2)],
      targetCell: Square(4, 4),
      typhoonOrigin: Square(3, 3),
      affectedPieceType: PieceType.rook,
      hiddenData: {'pieceId': 'forced'},
    );
    final roundTrip = AbilityOffer.fromJson(offer.toJson());
    expect(roundTrip.axis, AbilityAxis.file);
    expect(roundTrip.durationMoves, 3);
    expect(roundTrip.route, const [Square(0, 1), Square(0, 2)]);
    expect(roundTrip.targetCell, const Square(4, 4));
    expect(roundTrip.typhoonOrigin, const Square(3, 3));
    expect(roundTrip.affectedPieceType, PieceType.rook);
    expect(roundTrip.hiddenData['pieceId'], 'forced');
  });

  test('move payload carries clock snapshot for peer sync', () {
    const move = Move(from: Square(4, 1), to: Square(4, 3));
    final payload = <String, dynamic>{
      'type': 'move',
      'gameId': 'g1',
      'move': MoveCodec.toJson(move),
      'whiteMs': 290_000,
      'blackMs': 301_500,
    };

    final encoded = jsonEncode(payload);
    final decoded = jsonDecode(encoded) as Map<String, dynamic>;
    expect(decoded['whiteMs'], 290_000);
    expect(decoded['blackMs'], 301_500);
    final event = OnlineOpponentMove(
      MoveCodec.fromJson(decoded['move'] as Map<String, dynamic>),
      whiteMs: decoded['whiteMs'] as int?,
      blackMs: decoded['blackMs'] as int?,
    );
    expect(event.move.from, const Square(4, 1));
    expect(event.whiteMs, 290_000);
    expect(event.blackMs, 301_500);
    expect(relayMessageTypes, contains('clock_sync'));
  });
}
