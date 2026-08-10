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

  /// Accepts flat `{fromF,fromR,toF,toR}` or nested `{from:{f,r},to:{f,r}}`.
  static Map<String, dynamic> normalizeJson(Map<String, dynamic> json) {
    if (json['fromF'] is int && json['toF'] is int) {
      return json;
    }
    final from = json['from'];
    final to = json['to'];
    if (from is Map && to is Map) {
      return {
        ...json,
        'fromF': (from['f'] as num).toInt(),
        'fromR': (from['r'] as num).toInt(),
        'toF': (to['f'] as num).toInt(),
        'toR': (to['r'] as num).toInt(),
      };
    }
    return json;
  }

  static Move fromJson(Map<String, dynamic> json) {
    final n = normalizeJson(json);
    return Move(
      from: Square(n['fromF'] as int, n['fromR'] as int),
      to: Square(n['toF'] as int, n['toR'] as int),
      promotion: n['promotion'] != null
          ? PieceType.values.byName(n['promotion'] as String)
          : null,
      isEnPassant: n['enPassant'] as bool? ?? false,
      isCastle: n['castle'] as bool? ?? false,
      isCastleSwap: n['castleSwap'] as bool? ?? false,
      isKnightRearSwap: n['knightRearSwap'] as bool? ?? false,
      isRookPush: n['rookPush'] as bool? ?? false,
      isColorChaos: n['colorChaos'] as bool? ?? false,
      isAirborne: n['airborne'] as bool? ?? false,
      isInquisitorStrip: n['inquisitorStrip'] as bool? ?? false,
      pieceIndex: n['pieceIndex'] as int? ?? 0,
    );
  }
}
