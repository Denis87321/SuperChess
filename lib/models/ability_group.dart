import 'piece.dart';

enum AbilityGroup {
  board,
  pawn,
  knight,
  bishop,
  rook,
  queen,
  king,
  random,
}

extension AbilityGroupInfo on AbilityGroup {
  String get title {
    switch (this) {
      case AbilityGroup.board:
        return 'Доска';
      case AbilityGroup.pawn:
        return 'Пешка';
      case AbilityGroup.knight:
        return 'Конь';
      case AbilityGroup.bishop:
        return 'Слон';
      case AbilityGroup.rook:
        return 'Ладья';
      case AbilityGroup.queen:
        return 'Ферзь';
      case AbilityGroup.king:
        return 'Король';
      case AbilityGroup.random:
        return 'Катаклизмы';
    }
  }

  static AbilityGroup forPieceType(PieceType type) {
    switch (type) {
      case PieceType.pawn:
        return AbilityGroup.pawn;
      case PieceType.knight:
        return AbilityGroup.knight;
      case PieceType.bishop:
        return AbilityGroup.bishop;
      case PieceType.rook:
        return AbilityGroup.rook;
      case PieceType.queen:
        return AbilityGroup.queen;
      case PieceType.king:
        return AbilityGroup.king;
    }
  }
}
