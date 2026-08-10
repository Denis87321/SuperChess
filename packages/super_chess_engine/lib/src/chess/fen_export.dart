import '../models/piece.dart';
import '../models/square.dart';
import 'chess_game.dart';

/// Best-effort FIDE FEN for Stockfish. Returns null if the board is not 8×8
/// classical geometry (extra files/ranks, etc.).
String? tryBuildFen(ChessGame game) {
  if (game.fileCount != 8 || game.rankCount != 8) return null;

  final ranks = <String>[];
  for (var rank = 7; rank >= 0; rank--) {
    final buf = StringBuffer();
    var empty = 0;
    for (var file = 0; file < 8; file++) {
      final pieces = game.piecesAt(Square(file, rank));
      if (pieces.isEmpty) {
        empty++;
        continue;
      }
      if (empty > 0) {
        buf.write(empty);
        empty = 0;
      }
      // Stacked pieces: expose the primary (index 0) only.
      buf.write(_fenChar(pieces.first));
    }
    if (empty > 0) buf.write(empty);
    ranks.add(buf.toString());
  }

  final turn = game.turn == PieceColor.white ? 'w' : 'b';
  final castling = _castlingRights(game);
  final ep = game.enPassantTarget;
  final epStr =
      (ep != null && ep.file >= 0 && ep.file < 8 && ep.rank >= 0 && ep.rank < 8)
      ? ep.algebraic
      : '-';

  return '${ranks.join('/')} $turn $castling $epStr 0 1';
}

String _fenChar(Piece piece) {
  final c = switch (piece.type) {
    PieceType.pawn => 'p',
    PieceType.knight => 'n',
    PieceType.bishop => 'b',
    PieceType.rook => 'r',
    PieceType.queen => 'q',
    PieceType.king => 'k',
  };
  return piece.color == PieceColor.white ? c.toUpperCase() : c;
}

String _castlingRights(ChessGame game) {
  final rights = StringBuffer();
  final wk = game.pieceAt(const Square(4, 0));
  final bk = game.pieceAt(const Square(4, 7));
  if (wk != null &&
      wk.type == PieceType.king &&
      wk.color == PieceColor.white &&
      !wk.hasMoved) {
    final h1 = game.pieceAt(const Square(7, 0));
    final a1 = game.pieceAt(const Square(0, 0));
    if (h1 != null &&
        h1.type == PieceType.rook &&
        h1.color == PieceColor.white &&
        !h1.hasMoved) {
      rights.write('K');
    }
    if (a1 != null &&
        a1.type == PieceType.rook &&
        a1.color == PieceColor.white &&
        !a1.hasMoved) {
      rights.write('Q');
    }
  }
  if (bk != null &&
      bk.type == PieceType.king &&
      bk.color == PieceColor.black &&
      !bk.hasMoved) {
    final h8 = game.pieceAt(const Square(7, 7));
    final a8 = game.pieceAt(const Square(0, 7));
    if (h8 != null &&
        h8.type == PieceType.rook &&
        h8.color == PieceColor.black &&
        !h8.hasMoved) {
      rights.write('k');
    }
    if (a8 != null &&
        a8.type == PieceType.rook &&
        a8.color == PieceColor.black &&
        !a8.hasMoved) {
      rights.write('q');
    }
  }
  final s = rights.toString();
  return s.isEmpty ? '-' : s;
}
