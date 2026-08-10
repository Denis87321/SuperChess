import 'package:flutter/material.dart';

import '../l10n/models/piece.dart';

abstract final class BalatroTheme {
  static const background = Color(0xFF141820);
  static const felt = Color(0xFF1E2430);
  static const appBar = Color(0xFF2A3F5F);
  static const accent = Color(0xFF6BA3D4);
  static const accentSoft = Color(0xFF8CBCE0);
  static const gold = Color(0xFFF2C14E);
  static const cream = Color(0xFFF5E6C8);
  static const ink = Color(0xFF141820);

  static const lightSquare = Color(0xFFD4A574);
  static const darkSquare = Color(0xFF5C4030);
  static const selectedSquare = Color(0xFF5B9BD5);
  static const moveHint = Color(0x886BA3D4);
  static const checkHighlight = Color(0xCC5A7FD4);

  static const boardBorder = Color(0xFF2E3A4A);
  static const boardGlow = Color(0x446BA3D4);

  static Color pieceFill(PieceColor color) =>
      color == PieceColor.white ? cream : const Color(0xFF2B2520);

  static Color pieceStroke(PieceColor color) =>
      color == PieceColor.white ? ink : cream;

  static Color pieceAccent(PieceColor color) =>
      color == PieceColor.white ? accent : gold;

  static TextStyle titleStyle = const TextStyle(
    fontFamily: 'monospace',
    fontWeight: FontWeight.w800,
    letterSpacing: 2,
    color: cream,
  );

  static TextStyle statusStyle = const TextStyle(
    fontFamily: 'monospace',
    fontWeight: FontWeight.w600,
    fontSize: 16,
    color: gold,
    letterSpacing: 1,
  );
}
