import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/models/piece.dart';
import '../theme/balatro_theme.dart';
import 'board_fx/piece_fx_layer.dart';

class ChessPieceWidget extends StatelessWidget {
  const ChessPieceWidget({
    super.key,
    required this.piece,
    required this.size,
    this.displayAs,
    this.isZebra = false,
    this.inDuel = false,
    this.hasSanctuaryWard = false,
    this.underCurfew = false,
    this.siegeCounter,
    this.tourBadge,
    this.hasTorch = false,
    this.isFrozen = false,
    this.isEnemyTurncoat = false,
    this.showFrostCounter = false,
    this.sandStuck = false,
  });

  final Piece piece;
  final double size;
  final PieceType? displayAs;
  final bool isZebra;
  final bool inDuel;
  final bool hasSanctuaryWard;
  final bool underCurfew;
  final int? siegeCounter;
  final String? tourBadge;
  final bool hasTorch;
  final bool isFrozen;
  final bool isEnemyTurncoat;
  final bool showFrostCounter;
  final bool sandStuck;

  static String assetFor(PieceColor color, PieceType type) {
    final prefix = color == PieceColor.white ? 'w' : 'b';
    final letter = switch (type) {
      PieceType.pawn => 'P',
      PieceType.rook => 'R',
      PieceType.knight => 'N',
      PieceType.bishop => 'B',
      PieceType.queen => 'Q',
      PieceType.king => 'K',
    };
    return 'assets/pieces/caliente/$prefix$letter.svg';
  }

  @override
  Widget build(BuildContext context) {
    return _ChessPieceRender(
      piece: piece,
      size: size,
      displayAs: displayAs,
      isZebra: isZebra,
      inDuel: inDuel,
      hasSanctuaryWard: hasSanctuaryWard,
      underCurfew: underCurfew,
      siegeCounter: siegeCounter,
      tourBadge: tourBadge,
      hasTorch: hasTorch,
      isFrozen: isFrozen,
      isEnemyTurncoat: isEnemyTurncoat,
      showFrostCounter: showFrostCounter,
      sandStuck: sandStuck,
    );
  }
}

class _ChessPieceRender extends StatefulWidget {
  const _ChessPieceRender({
    required this.piece,
    required this.size,
    required this.displayAs,
    required this.isZebra,
    required this.inDuel,
    required this.hasSanctuaryWard,
    required this.underCurfew,
    required this.siegeCounter,
    required this.tourBadge,
    required this.hasTorch,
    required this.isFrozen,
    required this.isEnemyTurncoat,
    required this.showFrostCounter,
    required this.sandStuck,
  });

  final Piece piece;
  final double size;
  final PieceType? displayAs;
  final bool isZebra;
  final bool inDuel;
  final bool hasSanctuaryWard;
  final bool underCurfew;
  final int? siegeCounter;
  final String? tourBadge;
  final bool hasTorch;
  final bool isFrozen;
  final bool isEnemyTurncoat;
  final bool showFrostCounter;
  final bool sandStuck;

  @override
  State<_ChessPieceRender> createState() => _ChessPieceRenderState();
}

class _ChessPieceRenderState extends State<_ChessPieceRender>
    with SingleTickerProviderStateMixin {
  AnimationController? _hueController;

  bool get _daltonicActive =>
      widget.piece.cosmeticHue != null && !widget.isZebra;

  @override
  void initState() {
    super.initState();
    if (_daltonicActive) _startHueAnimation();
  }

  void _startHueAnimation() {
    _hueController?.dispose();
    // Бесконечный цикл без пауз: value идёт 0→1 и сразу снова.
    _hueController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  void _stopHueAnimation() {
    _hueController?.dispose();
    _hueController = null;
  }

  @override
  void didUpdateWidget(covariant _ChessPieceRender oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldDaltonic =
        oldWidget.piece.cosmeticHue != null && !oldWidget.isZebra;
    if (oldDaltonic != _daltonicActive) {
      if (_daltonicActive) {
        _startHueAnimation();
      } else {
        _stopHueAnimation();
      }
    }
  }

  @override
  void dispose() {
    _stopHueAnimation();
    super.dispose();
  }

  Color _hueAt(double t) {
    final base = widget.piece.cosmeticHue!.toDouble();
    return HSLColor.fromAHSL(
      1,
      (base + t * 360.0) % 360.0,
      0.65,
      0.72,
    ).toColor();
  }

  Widget _baseSvg() {
    final visualType = widget.displayAs ?? widget.piece.type;
    final assetColor = _daltonicActive ? PieceColor.white : widget.piece.color;
    return SvgPicture.asset(
      ChessPieceWidget.assetFor(assetColor, visualType),
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
    );
  }

  Widget _paintSvg(Widget svg, {required double hueT}) {
    if (widget.isZebra) {
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.6,
          0.6,
          0.6,
          0,
          20,
          0.55,
          0.55,
          0.55,
          0,
          10,
          0.5,
          0.5,
          0.5,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: svg,
      );
    }
    if (!_daltonicActive) return svg;

    // Бесшовный цикл: при t=0 и t=1 градиент и поворот совпадают,
    // поэтому нет резкого скачка при repeat() контроллера.
    return ShaderMask(
      blendMode: BlendMode.modulate,
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          transform: GradientRotation(hueT * 6.283185307179586), // 2π
          colors: [
            _hueAt(hueT),
            _hueAt(hueT + 0.25),
            _hueAt(hueT + 0.5),
            _hueAt(hueT + 0.75),
            _hueAt(hueT + 1.0), // = _hueAt(hueT) — замыкаем радугу
          ],
        ).createShader(bounds);
      },
      child: svg,
    );
  }

  Widget _withOverlays(Widget svg) {
    final modified = widget.piece.hasModifiedMoveSet;
    final isPlagued = widget.piece.isPlagued;
    final trojanTurns = widget.piece.trojanTurnsLeft;
    final siege = widget.siegeCounter;
    final tour = widget.tourBadge;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (modified)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: BalatroTheme.gold.withValues(alpha: 0.22),
                  border: Border.all(
                    color: BalatroTheme.gold,
                    width: widget.size * 0.04,
                  ),
                ),
              ),
            ),
          if (widget.inDuel)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE11D48),
                    width: widget.size * 0.055,
                  ),
                ),
              ),
            ),
          svg,
          if (isPlagued)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0x66D7F56A),
                      const Color(0x553A5E15),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.62, 1.0],
                  ),
                  border: Border.all(
                    color: const Color(0xFFB9E96A),
                    width: widget.size * 0.04,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.coronavirus_rounded,
                    size: widget.size * 0.28,
                    color: const Color(0xDDF4FF9A),
                  ),
                ),
              ),
            ),
          if (widget.isZebra) ...[
            for (final y in [0.28, 0.42, 0.56, 0.70])
              Positioned(
                left: widget.size * 0.28,
                top: widget.size * y,
                child: Container(
                  width: widget.size * 0.44,
                  height: widget.size * 0.05,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A).withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(widget.size),
                  ),
                ),
              ),
          ],
          if (modified) ...[
            for (final offset in [
              Offset(widget.size * 0.12, widget.size * 0.12),
              Offset(widget.size * 0.88, widget.size * 0.12),
              Offset(widget.size * 0.12, widget.size * 0.82),
              Offset(widget.size * 0.88, widget.size * 0.82),
            ])
              Positioned(
                left: offset.dx - widget.size * 0.045,
                top: offset.dy - widget.size * 0.045,
                child: Container(
                  width: widget.size * 0.09,
                  height: widget.size * 0.09,
                  decoration: const BoxDecoration(
                    color: BalatroTheme.gold,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ] else if (widget.piece.abilities.isNotEmpty)
            Positioned(
              right: widget.size * 0.06,
              top: widget.size * 0.06,
              child: Container(
                width: widget.size * 0.14,
                height: widget.size * 0.14,
                decoration: BoxDecoration(
                  color: BalatroTheme.gold,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.black87,
                    width: widget.size * 0.02,
                  ),
                ),
              ),
            ),
          if (widget.hasSanctuaryWard)
            Positioned(
              left: widget.size * 0.02,
              top: widget.size * 0.02,
              child: Icon(
                Icons.shield_rounded,
                size: widget.size * 0.28,
                color: const Color(0xFF38BDF8),
                shadows: const [
                  Shadow(color: Colors.black54, blurRadius: 2),
                ],
              ),
            ),
          if (widget.underCurfew)
            Positioned(
              left: widget.size * 0.04,
              bottom: widget.size * 0.04,
              child: Icon(
                Icons.link_rounded,
                size: widget.size * 0.26,
                color: const Color(0xFFCBD5E1),
                shadows: const [
                  Shadow(color: Colors.black54, blurRadius: 2),
                ],
              ),
            ),
          if (siege != null && siege > 0)
            Positioned(
              right: widget.size * 0.02,
              top: widget.size * 0.34,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.size * 0.05,
                  vertical: widget.size * 0.02,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF9A3412),
                  borderRadius: BorderRadius.circular(widget.size * 0.08),
                  border: Border.all(color: Colors.black87, width: 1),
                ),
                child: Text(
                  '$siege/3',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: widget.size * 0.11,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          if (tour != null && tour.isNotEmpty)
            Positioned(
              left: widget.size * 0.28,
              bottom: -widget.size * 0.02,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.size * 0.05,
                  vertical: widget.size * 0.015,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A5F),
                  borderRadius: BorderRadius.circular(widget.size * 0.08),
                  border: Border.all(
                    color: BalatroTheme.gold.withValues(alpha: 0.7),
                    width: 1,
                  ),
                ),
                child: Text(
                  tour,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: widget.size * 0.11,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: BalatroTheme.cream,
                  ),
                ),
              ),
            ),
          if (trojanTurns > 0)
            Positioned(
              right: widget.size * 0.04,
              bottom: widget.size * 0.04,
              child: Container(
                width: widget.size * 0.18,
                height: widget.size * 0.18,
                decoration: BoxDecoration(
                  color: trojanTurns == 1
                      ? const Color(0xFFB42318)
                      : const Color(0xFFF97316),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.black87,
                    width: widget.size * 0.02,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$trojanTurns',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: widget.size * 0.11,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          if (widget.hasTorch)
            Positioned(
              left: widget.size * 0.02,
              bottom: widget.size * 0.02,
              child: Icon(
                Icons.local_fire_department_rounded,
                size: widget.size * 0.28,
                color: const Color(0xFFFBBF24),
                shadows: const [
                  Shadow(color: Colors.black54, blurRadius: 2),
                ],
              ),
            ),
          Positioned.fill(
            child: PieceFxLayer(
              piece: widget.piece,
              size: widget.size,
              isFrozen: widget.isFrozen,
              inDuel: widget.inDuel,
              hasSanctuaryWard: widget.hasSanctuaryWard,
              underCurfew: widget.underCurfew,
              hasTorch: widget.hasTorch,
              isZebra: widget.isZebra,
              sandStuck: widget.sandStuck,
              siegeCounter: widget.siegeCounter,
              showFrost: widget.showFrostCounter,
            ),
          ),
          if (widget.isEnemyTurncoat)
            Positioned(
              right: widget.size * 0.02,
              bottom: widget.size * 0.28,
              child: Icon(
                Icons.visibility_rounded,
                size: widget.size * 0.24,
                color: const Color(0xFFA78BFA),
                shadows: const [
                  Shadow(color: Colors.black54, blurRadius: 2),
                ],
              ),
            ),
          if (widget.piece.heatLevel > 0)
            Positioned(
              left: widget.size * 0.30,
              top: widget.size * 0.02,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.size * 0.04,
                  vertical: widget.size * 0.01,
                ),
                decoration: BoxDecoration(
                  color: switch (widget.piece.heatLevel) {
                    1 => const Color(0xFFF59E0B),
                    2 => const Color(0xFFEA580C),
                    _ => const Color(0xFFB91C1C),
                  },
                  borderRadius: BorderRadius.circular(widget.size * 0.06),
                ),
                child: Text(
                  'H${widget.piece.heatLevel}',
                  style: TextStyle(
                    fontSize: widget.size * 0.10,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          if (widget.showFrostCounter)
            Positioned(
              right: widget.size * 0.02,
              top: widget.size * 0.02,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.size * 0.04,
                  vertical: widget.size * 0.01,
                ),
                decoration: BoxDecoration(
                  color: switch (widget.piece.frostLevel.clamp(0, 3)) {
                    0 => const Color(0xFF64748B),
                    1 => const Color(0xFF38BDF8),
                    2 => const Color(0xFF2563EB),
                    _ => const Color(0xFF1E3A8A),
                  },
                  borderRadius: BorderRadius.circular(widget.size * 0.06),
                  border: Border.all(
                    color: Colors.white24,
                    width: widget.size * 0.015,
                  ),
                ),
                child: Text(
                  '${widget.piece.frostLevel.clamp(0, 3)}',
                  style: TextStyle(
                    fontSize: widget.size * 0.11,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final base = _baseSvg();
    final controller = _hueController;
    if (controller == null) {
      return _withOverlays(_paintSvg(base, hueT: 0));
    }

    // SVG в child — не пересоздаётся каждый кадр; перекраска — каждый кадр.
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return _withOverlays(_paintSvg(child!, hueT: controller.value));
      },
      child: base,
    );
  }
}
