import 'package:flutter/material.dart';

import '../l10n/models/piece.dart';

abstract final class BalatroTheme {
  static const background = Color(0xFF0F141A);
  static const felt = Color(0xFF18222D);
  static const appBar = Color(0xFF0F141A);
  static const accent = Color(0xFF4C8DCC);
  static const accentSoft = Color(0xFF78B0E2);
  static const gold = Color(0xFFD2B36D);
  static const cream = Color(0xFFF0F3F7);
  static const ink = Color(0xFF0F141A);

  static const lightSquare = Color(0xFFC9D6E2);
  static const darkSquare = Color(0xFF52687D);
  static const selectedSquare = Color(0xFF4C8DCC);
  static const moveHint = Color(0x884C8DCC);
  static const checkHighlight = Color(0xCC3C73AA);

  static const boardBorder = Color(0xFF304252);
  static const boardGlow = Color(0x224C8DCC);

  static Color pieceFill(PieceColor color) =>
      color == PieceColor.white ? cream : const Color(0xFF202B38);

  static Color pieceStroke(PieceColor color) =>
      color == PieceColor.white ? ink : cream;

  static Color pieceAccent(PieceColor color) =>
      color == PieceColor.white ? accent : gold;

  static TextStyle titleStyle = const TextStyle(
    fontFamily: 'sans-serif',
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    color: cream,
  );

  static TextStyle statusStyle = const TextStyle(
    fontFamily: 'sans-serif',
    fontWeight: FontWeight.w500,
    fontSize: 16,
    color: gold,
    letterSpacing: 0.1,
  );
}
