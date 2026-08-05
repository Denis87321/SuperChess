import '../models/piece.dart';
import '../models/square.dart';

class Move {
  const Move({
    required this.from,
    required this.to,
    this.promotion,
    this.isEnPassant = false,
    this.isCastle = false,
    this.isCastleSwap = false,
    this.isKnightRearSwap = false,
    this.isRookPush = false,
    this.isColorChaos = false,
    this.isAirborne = false,
    this.isInquisitorStrip = false,
    this.pieceIndex = 0,
  });

  final Square from;
  final Square to;
  final PieceType? promotion;
  final bool isEnPassant;
  final bool isCastle;
  final bool isCastleSwap;
  final bool isKnightRearSwap;
  final bool isRookPush;
  final bool isColorChaos;
  final bool isAirborne;
  final bool isInquisitorStrip;
  /// Index within stacked pieces on [from] (0 = primary).
  final int pieceIndex;

  @override
  bool operator ==(Object other) {
    return other is Move &&
        other.from == from &&
        other.to == to &&
        other.promotion == promotion &&
        other.isEnPassant == isEnPassant &&
        other.isCastle == isCastle &&
        other.isCastleSwap == isCastleSwap &&
        other.isKnightRearSwap == isKnightRearSwap &&
        other.isRookPush == isRookPush &&
        other.isColorChaos == isColorChaos &&
        other.isAirborne == isAirborne &&
        other.isInquisitorStrip == isInquisitorStrip &&
        other.pieceIndex == pieceIndex;
  }

  @override
  int get hashCode => Object.hash(
        from,
        to,
        promotion,
        isEnPassant,
        isCastle,
        isCastleSwap,
        isKnightRearSwap,
        isRookPush,
        isColorChaos,
        isAirborne,
        isInquisitorStrip,
        pieceIndex,
      );

  @override
  String toString() {
    final promo = promotion != null ? '=${promotion!.name[0]}' : '';
    return '${from.algebraic}${to.algebraic}$promo';
  }
}
