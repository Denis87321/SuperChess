import '../models/piece.dart';
import '../models/square.dart';
import 'move.dart';

class MoveCodec {
  static Map<String, dynamic> toJson(Move move) {
    return {
      'fromF': move.from.file,
      'fromR': move.from.rank,
      'toF': move.to.file,
      'toR': move.to.rank,
      if (move.promotion != null) 'promotion': move.promotion!.name,
      'enPassant': move.isEnPassant,
      'castle': move.isCastle,
      'castleSwap': move.isCastleSwap,
      'knightRearSwap': move.isKnightRearSwap,
      'rookPush': move.isRookPush,
      'colorChaos': move.isColorChaos,
      'airborne': move.isAirborne,
      'inquisitorStrip': move.isInquisitorStrip,
      'pieceIndex': move.pieceIndex,
    };
  }

  static Move fromJson(Map<String, dynamic> json) {
    return Move(
      from: Square(json['fromF'] as int, json['fromR'] as int),
      to: Square(json['toF'] as int, json['toR'] as int),
      promotion: json['promotion'] != null
          ? PieceType.values.byName(json['promotion'] as String)
          : null,
      isEnPassant: json['enPassant'] as bool? ?? false,
      isCastle: json['castle'] as bool? ?? false,
      isCastleSwap: json['castleSwap'] as bool? ?? false,
      isKnightRearSwap: json['knightRearSwap'] as bool? ?? false,
      isRookPush: json['rookPush'] as bool? ?? false,
      isColorChaos: json['colorChaos'] as bool? ?? false,
      isAirborne: json['airborne'] as bool? ?? false,
      isInquisitorStrip: json['inquisitorStrip'] as bool? ?? false,
      pieceIndex: json['pieceIndex'] as int? ?? 0,
    );
  }
}
