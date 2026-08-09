import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated ice crust for frost-map levels 1–3.
///
/// Idle: slow shimmer. On level-up: ice grows over ~420ms.
class FrostIceOverlay extends StatefulWidget {
  const FrostIceOverlay({
    super.key,
    required this.level,
    required this.size,
    this.frozen = false,
  });

  /// Frost counter 0–3. Frozen pieces render as full ice even if level < 3.
  final int level;
  final double size;
  final bool frozen;

  int get effectiveLevel {
    if (frozen) return 3;
    return level.clamp(0, 3);
  }

  @override
  State<FrostIceOverlay> createState() => _FrostIceOverlayState();
}

class _FrostIceOverlayState extends State<FrostIceOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _grow;
  late Animation<double> _coverage;

  double _fromCoverage = 0;
  double _toCoverage = 0;

  static double _coverageFor(int level) => switch (level) {
        0 => 0.0,
        1 => 0.32,
        2 => 0.62,
        _ => 1.0,
      };

  @override
  void initState() {
    super.initState();
    _toCoverage = _coverageFor(widget.effectiveLevel);
    _fromCoverage = 0;
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _grow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _coverage = Tween<double>(begin: _fromCoverage, end: _toCoverage).animate(
      CurvedAnimation(parent: _grow, curve: Curves.easeOutCubic),
    );
    if (_toCoverage > 0) {
      _grow.forward(from: 0);
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant FrostIceOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _coverageFor(widget.effectiveLevel);
    final prev = _coverageFor(oldWidget.effectiveLevel);
    if (next != prev) {
      _fromCoverage = prev;
      _toCoverage = next;
      _coverage = Tween<double>(begin: _fromCoverage, end: _toCoverage).animate(
        CurvedAnimation(parent: _grow, curve: Curves.easeOutCubic),
      );
      _grow.forward(from: 0);
    }
    final shouldPulse = widget.effectiveLevel > 0;
    if (shouldPulse && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!shouldPulse && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _grow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.effectiveLevel <= 0 && _toCoverage <= 0) {
      return const SizedBox.shrink();
    }
    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _grow]),
      builder: (context, _) {
        final coverage = _grow.isAnimating ? _coverage.value : _toCoverage;
        if (coverage <= 0.01) return const SizedBox.shrink();
        return CustomPaint(
          size: Size.square(widget.size),
          painter: _FrostIcePainter(
            coverage: coverage,
            shimmer: _pulse.value,
            level: widget.effectiveLevel,
            seed: widget.size.hashCode,
          ),
        );
      },
    );
  }
}

class _FrostIcePainter extends CustomPainter {
  _FrostIcePainter({
    required this.coverage,
    required this.shimmer,
    required this.level,
    required this.seed,
  });

  final double coverage;
  final double shimmer;
  final int level;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.shortestSide * 0.46;
    final rng = math.Random(seed);

    // Soft cold glow under the ice.
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.lerp(
            const Color(0x0038BDF8),
            const Color(0x6638BDF8),
            coverage,
          )!,
          const Color(0x00000000),
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r * 1.15));
    canvas.drawCircle(Offset(cx, cy), r * 1.1, glow);

    // Rising ice fill from the bottom of the piece silhouette.
    final fillTop = size.height * (1.0 - coverage * 0.92);
    final iceRect = Rect.fromLTRB(
      size.width * 0.12,
      fillTop,
      size.width * 0.88,
      size.height * 0.92,
    );
    final icePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Color.lerp(
            const Color(0xAA7DD3FC),
            const Color(0xCC38BDF8),
            shimmer,
          )!,
          Color.lerp(
            const Color(0x667DD3FC),
            const Color(0x9938BDF8),
            1 - shimmer,
          )!,
          const Color(0x227DD3FC),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(iceRect);
    final icePath = Path()
      ..moveTo(iceRect.left, iceRect.bottom)
      ..lineTo(iceRect.right, iceRect.bottom)
      ..lineTo(iceRect.right, iceRect.top + size.height * 0.04)
      ..quadraticBezierTo(
        iceRect.center.dx,
        iceRect.top - size.height * 0.06 * coverage,
        iceRect.left,
        iceRect.top + size.height * 0.04,
      )
      ..close();
    canvas.drawPath(icePath, icePaint);

    // Crystal spikes along the ice rim — denser at higher levels.
    final spikeCount = 4 + level * 3;
    final rimY = fillTop + size.height * 0.02;
    final spikePaint = Paint()
      ..color = Color.lerp(
        const Color(0xCCE0F2FE),
        const Color(0xFFFFFFFF),
        shimmer,
      )!
      ..style = PaintingStyle.fill;
    final edgePaint = Paint()
      ..color = const Color(0xAA0EA5E9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.012;

    for (var i = 0; i < spikeCount; i++) {
      final t = (i + 0.5) / spikeCount;
      final x = size.width * (0.16 + t * 0.68);
      final h =
          size.height * (0.06 + coverage * 0.10 + rng.nextDouble() * 0.05) *
          (0.85 + shimmer * 0.2);
      final w = size.width * (0.035 + rng.nextDouble() * 0.02);
      final spike = Path()
        ..moveTo(x - w, rimY + h * 0.35)
        ..lineTo(x, rimY - h)
        ..lineTo(x + w, rimY + h * 0.35)
        ..close();
      canvas.drawPath(spike, spikePaint);
      canvas.drawPath(spike, edgePaint);
    }

    // Specular sparkle dots.
    final sparkle = Paint()..color = Colors.white.withValues(alpha: 0.35 + shimmer * 0.35);
    final sparkleCount = 2 + level;
    for (var i = 0; i < sparkleCount; i++) {
      final sx = size.width * (0.25 + rng.nextDouble() * 0.5);
      final sy = fillTop + size.height * (0.08 + rng.nextDouble() * 0.35 * coverage);
      canvas.drawCircle(Offset(sx, sy), size.shortestSide * 0.018, sparkle);
    }

    // Full freeze shell ring at level 3.
    if (coverage > 0.9) {
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * 0.045
        ..color = Color.lerp(
          const Color(0xBB38BDF8),
          const Color(0xFFE0F2FE),
          shimmer,
        )!;
      canvas.drawCircle(Offset(cx, cy), r * 0.92, ring);
    }
  }

  @override
  bool shouldRepaint(covariant _FrostIcePainter oldDelegate) {
    return oldDelegate.coverage != coverage ||
        oldDelegate.shimmer != shimmer ||
        oldDelegate.level != level;
  }
}
