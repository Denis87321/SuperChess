import 'package:flutter/material.dart';

import '../l10n/models/piece.dart';

abstract final class BalatroTheme {
  static const background = Color(0xFF111517);
  static const felt = Color(0xFF1A2022);
  static const appBar = Color(0xFF111517);
  static const accent = Color(0xFFE07A5F);
  static const accentSoft = Color(0xFFF0A18B);
  static const gold = Color(0xFFD8B36A);
  static const cream = Color(0xFFF1EEE8);
  static const ink = Color(0xFF111517);

  static const lightSquare = Color(0xFFD8CBB8);
  static const darkSquare = Color(0xFF756354);
  static const selectedSquare = Color(0xFFE07A5F);
  static const moveHint = Color(0x88E07A5F);
  static const checkHighlight = Color(0xCCD56C55);

  static const boardBorder = Color(0xFF343B3D);
  static const boardGlow = Color(0x22E07A5F);

  static Color pieceFill(PieceColor color) =>
      color == PieceColor.white ? cream : const Color(0xFF2B2520);

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
