import 'package:flutter/material.dart';

import '../l10n/models/piece.dart';
import 'chess_piece_widget.dart';

/// Анимация: фигура проваливается сквозь доску и растворяется в лаве.
class LavaDeathOverlay extends StatefulWidget {
  const LavaDeathOverlay({
    super.key,
    required this.piece,
    required this.size,
    required this.onFinished,
  });

  final Piece piece;
  final double size;
  final VoidCallback onFinished;

  @override
  State<LavaDeathOverlay> createState() => _LavaDeathOverlayState();
}

class _LavaDeathOverlayState extends State<LavaDeathOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fall;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _melt;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );
    _fall = CurvedAnimation(parent: _controller, curve: Curves.easeInCubic);
    _fade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 1, curve: Curves.easeIn),
      ),
    );
    _scale = Tween<double>(begin: 1, end: 0.55).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1, curve: Curves.easeIn),
      ),
    );
    _melt = Tween<double>(begin: 1, end: 1.35).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.85, curve: Curves.easeInOut),
      ),
    );
    _controller.forward().whenComplete(widget.onFinished);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, widget.size * 0.55 * _fall.value),
          child: Opacity(
            opacity: _fade.value,
            child: Transform.scale(
              scaleY: _scale.value,
              scaleX: _melt.value,
              child: child,
            ),
          ),
        );
      },
      child: ChessPieceWidget(piece: widget.piece, size: widget.size),
    );
  }
}
