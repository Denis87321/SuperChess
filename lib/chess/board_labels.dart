import '../models/piece.dart';
import '../models/square.dart';

/// Фигура, уничтоженная лавой — для анимации на UI.
class LavaDeathEvent {
  const LavaDeathEvent({required this.square, required this.piece});

  final Square square;
  final Piece piece;
}

/// Шахматная горизонталь 1–8+ для отображения игроку.
int chessRankLabel(int rankIndex) => rankIndex + 1;

enum ExtraFilePlacement { none, left, right, both }

String fileLabel(
  int file, {
  int fileCount = 8,
  ExtraFilePlacement extraFile = ExtraFilePlacement.none,
}) {
  if (fileCount == 10 || extraFile == ExtraFilePlacement.both) {
    // z a b c d e f g h i
    if (file == 0) return 'z';
    if (file == fileCount - 1) return 'i';
    return String.fromCharCode(96 + file); // file 1 -> 'a'
  }
  if (fileCount == 9 && extraFile == ExtraFilePlacement.left) {
    return file == 0 ? 'z' : String.fromCharCode(96 + file);
  }
  if (fileCount == 9 && extraFile == ExtraFilePlacement.right) {
    return file == 8 ? 'i' : String.fromCharCode(97 + file);
  }
  return String.fromCharCode(97 + file);
}

String squareLabel(
  Square square, {
  int fileCount = 8,
  ExtraFilePlacement extraFile = ExtraFilePlacement.none,
}) {
  return '${fileLabel(square.file, fileCount: fileCount, extraFile: extraFile)}'
      '${square.rank + 1}';
}
