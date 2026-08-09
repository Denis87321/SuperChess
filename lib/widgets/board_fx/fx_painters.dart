import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../chess/fx_skin.dart';

/// Parameterized painter covering all idle/burst FX skins.
class FxSkinPainter extends CustomPainter {
  FxSkinPainter({
    required this.skin,
    required this.t,
    this.level = 1,
    this.seed = 1,
    this.color,
  });

  final FxSkin skin;
  final double t;
  final int level;
  final int seed;
  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    switch (skin) {
      case FxSkin.lavaGlow:
        _lava(canvas, size, t);
      case FxSkin.sandSink:
        _sand(canvas, size, t, sinking: true);
      case FxSkin.dustCloud:
        _dust(canvas, size, t, rng);
      case FxSkin.inkBleed:
        _ink(canvas, size, t, rng);
      case FxSkin.poisonPulse:
        _poison(canvas, size, t);
      case FxSkin.virusSpark:
        _virus(canvas, size, t, rng);
      case FxSkin.portalSpin:
        _portal(canvas, size, t);
      case FxSkin.ghostFade:
        _ghost(canvas, size, t);
      case FxSkin.mineSpike:
        _mines(canvas, size, t, rng);
      case FxSkin.swampMurk:
        _swamp(canvas, size, t);
      case FxSkin.slimeTrail:
        _slime(canvas, size, t);
      case FxSkin.riverFlow:
        _river(canvas, size, t);
      case FxSkin.volcanoGlow:
        _volcano(canvas, size, t, rng);
      case FxSkin.heatPulse:
        _heat(canvas, size, t, level);
      case FxSkin.iceGrow:
        // Handled by FrostIceOverlay for pieces; square chill tint here.
        _chill(canvas, size, t);
      case FxSkin.hazardStripe:
        _stripes(canvas, size, t);
      case FxSkin.markerBadge:
        _marker(canvas, size, t, color ?? const Color(0xFFFBBF24));
      case FxSkin.wallBeam:
        _wall(canvas, size, t);
      case FxSkin.routeLine:
        _route(canvas, size, t);
      case FxSkin.territoryPaint:
        _territoryCrack(canvas, size, t, rng);
      case FxSkin.seedSprout:
        _seed(canvas, size, t);
      case FxSkin.fuseTick:
        _fuse(canvas, size, t, level);
      case FxSkin.duckMarker:
        _duck(canvas, size, t);
      case FxSkin.modAura:
        _aura(canvas, size, t, color ?? const Color(0xFFEAB308));
      case FxSkin.statusBadge:
        _aura(canvas, size, t, color ?? const Color(0xFF38BDF8), tight: true);
      case FxSkin.chainLink:
        _chain(canvas, size, t);
      case FxSkin.wardShield:
        _ward(canvas, size, t);
      case FxSkin.torchFlame:
        _torch(canvas, size, t, rng);
      case FxSkin.siegeTick:
        _siege(canvas, size, t, level);
      case FxSkin.stickyDrip:
        _sticky(canvas, size, t);
      case FxSkin.shadowTwin:
        _shadow(canvas, size, t);
      case FxSkin.zebraStripe:
        _zebra(canvas, size, t);
      case FxSkin.vanityHue:
        _vanity(canvas, size, t);
      case FxSkin.hungerGnaw:
        _hunger(canvas, size, t, rng);
      case FxSkin.boardWash:
        _wash(canvas, size, t, color ?? const Color(0x33F8FAFC));
      case FxSkin.seasonWash:
        _season(canvas, size, t);
      case FxSkin.attractionPull:
        _attract(canvas, size, t);
      case FxSkin.eclipseDim:
        _eclipse(canvas, size, t);
      case FxSkin.borderWall:
        _border(canvas, size, t);
      case FxSkin.meatGrinder:
        _grinder(canvas, size, t);
      case FxSkin.timeWarp:
        _time(canvas, size, t);
      case FxSkin.burstImpact:
        _burst(canvas, size, t, color ?? const Color(0xFFFF6B00));
      case FxSkin.none:
        break;
    }
  }

  void _lava(Canvas c, Size s, double t) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Color.lerp(const Color(0xCCFF6B00), const Color(0xFFFFD000), t)!,
          const Color(0x66FF6B00),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & s);
    c.drawRect(Offset.zero & s, paint);
    final bubble = Paint()..color = const Color(0xAAFFD000);
    for (var i = 0; i < 5; i++) {
      final x = s.width * (0.15 + i * 0.18);
      final y = s.height * (0.55 - t * 0.25 - (i % 3) * 0.05);
      c.drawCircle(Offset(x, y), s.shortestSide * (0.04 + t * 0.02), bubble);
    }
  }

  void _sand(Canvas c, Size s, double t, {required bool sinking}) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0x00C4A574),
          Color.lerp(const Color(0x66A9845C), const Color(0x99C4A574), t)!,
          const Color(0xBB8B6914),
        ],
      ).createShader(Offset.zero & s);
    c.drawRect(Offset.zero & s, paint);
    if (sinking) {
      final swirl = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.shortestSide * 0.03
        ..color = const Color(0x88F5E6C8);
      c.drawArc(
        Rect.fromCenter(
          center: Offset(s.width / 2, s.height * (0.55 + t * 0.1)),
          width: s.width * 0.7,
          height: s.height * 0.35,
        ),
        t * math.pi,
        math.pi,
        false,
        swirl,
      );
    }
  }

  void _dust(Canvas c, Size s, double t, math.Random rng) {
    final p = Paint()..color = const Color(0x77A16207);
    for (var i = 0; i < 10; i++) {
      final x = s.width * rng.nextDouble();
      final y = s.height * ((rng.nextDouble() + t * 0.3) % 1.0);
      c.drawCircle(Offset(x, y), s.shortestSide * 0.03, p);
    }
  }

  void _ink(Canvas c, Size s, double t, math.Random rng) {
    final p = Paint()..color = Color.lerp(const Color(0x99000000), const Color(0xCC1E1B4B), t)!;
    for (var i = 0; i < 4; i++) {
      final cx = s.width * (0.3 + rng.nextDouble() * 0.4);
      final cy = s.height * (0.3 + rng.nextDouble() * 0.4);
      c.drawCircle(Offset(cx, cy), s.shortestSide * (0.18 + t * 0.08 + i * 0.04), p);
    }
  }

  void _poison(Canvas c, Size s, double t) {
    final p = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.lerp(const Color(0x88B9E96A), const Color(0xCCD7F56A), t)!,
          const Color(0x553A5E15),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & s);
    c.drawCircle(Offset(s.width / 2, s.height / 2), s.shortestSide * 0.48, p);
  }

  void _virus(Canvas c, Size s, double t, math.Random rng) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.shortestSide * 0.03
      ..color = Color.lerp(const Color(0xAA22C55E), const Color(0xFF4ADE80), t)!;
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3 + t * math.pi;
      final r = s.shortestSide * 0.28;
      c.drawLine(
        Offset(s.width / 2, s.height / 2),
        Offset(s.width / 2 + math.cos(a) * r, s.height / 2 + math.sin(a) * r),
        p,
      );
    }
  }

  void _portal(Canvas c, Size s, double t) {
    final cx = s.width / 2;
    final cy = s.height / 2;
    for (var i = 0; i < 3; i++) {
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.shortestSide * 0.04
        ..color = Color.lerp(const Color(0x887B2FF7), const Color(0xFF2EC4B6), (t + i / 3) % 1)!;
      final r = s.shortestSide * (0.18 + i * 0.1 + t * 0.04);
      c.save();
      c.translate(cx, cy);
      c.rotate(t * math.pi * 2 + i);
      c.drawOval(Rect.fromCenter(center: Offset.zero, width: r * 2, height: r * 1.4), p);
      c.restore();
    }
  }

  void _ghost(Canvas c, Size s, double t) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.12 + t * 0.12);
    c.drawRect(Offset.zero & s, p);
  }

  void _mines(Canvas c, Size s, double t, math.Random rng) {
    final p = Paint()..color = Color.lerp(const Color(0xAA111827), const Color(0xFF374151), t)!;
    final spike = Paint()..color = const Color(0xFFEF4444);
    c.drawCircle(Offset(s.width / 2, s.height / 2), s.shortestSide * 0.16, p);
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3 + t * 0.4;
      final r = s.shortestSide * 0.22;
      c.drawCircle(
        Offset(s.width / 2 + math.cos(a) * r, s.height / 2 + math.sin(a) * r),
        s.shortestSide * 0.035,
        spike,
      );
    }
  }

  void _swamp(Canvas c, Size s, double t) {
    final p = Paint()
      ..shader = LinearGradient(
        colors: [
          Color.lerp(const Color(0x66365A2E), const Color(0x884D7C3F), t)!,
          const Color(0x442A3C1E),
        ],
      ).createShader(Offset.zero & s);
    c.drawRect(Offset.zero & s, p);
  }

  void _slime(Canvas c, Size s, double t) {
    final p = Paint()..color = Color.lerp(const Color(0x8865A30D), const Color(0xBB84CC16), t)!;
    final path = Path()
      ..moveTo(0, s.height * 0.7)
      ..quadraticBezierTo(s.width * 0.3, s.height * (0.55 - t * 0.1), s.width * 0.5, s.height * 0.75)
      ..quadraticBezierTo(s.width * 0.75, s.height * 0.9, s.width, s.height * 0.65)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    c.drawPath(path, p);
  }

  void _river(Canvas c, Size s, double t) {
    final p = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-1 + t * 2, 0),
        end: Alignment(1 + t * 2, 0),
        colors: const [
          Color(0x4438BDF8),
          Color(0x8838BDF8),
          Color(0x440EA5E9),
        ],
      ).createShader(Offset.zero & s);
    c.drawRect(Rect.fromLTWH(0, s.height * 0.35, s.width, s.height * 0.3), p);
  }

  void _volcano(Canvas c, Size s, double t, math.Random rng) {
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.lerp(const Color(0xAAEF4444), const Color(0xFFFF6B00), t)!,
          Colors.transparent,
        ],
      ).createShader(Offset.zero & s);
    c.drawCircle(Offset(s.width / 2, s.height / 2), s.shortestSide * 0.45, glow);
    final ember = Paint()..color = const Color(0xFFFFD000);
    for (var i = 0; i < 4; i++) {
      final x = s.width * (0.3 + rng.nextDouble() * 0.4);
      final y = s.height * (0.6 - t * 0.4 - i * 0.05);
      c.drawCircle(Offset(x, y), s.shortestSide * 0.03, ember);
    }
  }

  void _heat(Canvas c, Size s, double t, int level) {
    final strength = (level.clamp(1, 3)) / 3.0;
    final p = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.lerp(const Color(0x00F59E0B), const Color(0xAAF97316), t * strength)!,
          Colors.transparent,
        ],
      ).createShader(Offset.zero & s);
    c.drawCircle(Offset(s.width / 2, s.height / 2), s.shortestSide * 0.5, p);
  }

  void _chill(Canvas c, Size s, double t) {
    final p = Paint()..color = Color.lerp(const Color(0x2238BDF8), const Color(0x4438BDF8), t)!;
    c.drawRect(Offset.zero & s, p);
  }

  void _stripes(Canvas c, Size s, double t) {
    final p = Paint()..color = const Color(0x55EF4444);
    for (var i = 0; i < 5; i++) {
      final x = s.width * ((i / 5 + t * 0.15) % 1.0);
      c.drawRect(Rect.fromLTWH(x, 0, s.width * 0.08, s.height), p);
    }
  }

  void _marker(Canvas c, Size s, double t, Color color) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.shortestSide * 0.05
      ..color = color.withValues(alpha: 0.45 + t * 0.35);
    c.drawCircle(Offset(s.width / 2, s.height / 2), s.shortestSide * (0.28 + t * 0.06), p);
  }

  void _wall(Canvas c, Size s, double t) {
    final p = Paint()..color = Color.lerp(const Color(0x6694A3B8), const Color(0x99CBD5E1), t)!;
    c.drawRect(Rect.fromLTWH(s.width * 0.15, s.height * 0.2, s.width * 0.12, s.height * 0.6), p);
    c.drawRect(Rect.fromLTWH(s.width * 0.73, s.height * 0.2, s.width * 0.12, s.height * 0.6), p);
  }

  void _route(Canvas c, Size s, double t) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.shortestSide * 0.06
      ..color = const Color(0x884ADE80);
    final path = Path()
      ..moveTo(s.width * 0.15, s.height * 0.8)
      ..quadraticBezierTo(s.width * 0.5, s.height * (0.2 + t * 0.1), s.width * 0.85, s.height * 0.75);
    c.drawPath(path, p);
  }

  void _territoryCrack(Canvas c, Size s, double t, math.Random rng) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.shortestSide * 0.025
      ..color = Color.lerp(const Color(0x66A16207), const Color(0x99D97706), t)!;
    for (var i = 0; i < 3; i++) {
      final path = Path()..moveTo(s.width * rng.nextDouble(), s.height * rng.nextDouble());
      for (var j = 0; j < 3; j++) {
        path.lineTo(s.width * rng.nextDouble(), s.height * rng.nextDouble());
      }
      c.drawPath(path, p);
    }
  }

  void _seed(Canvas c, Size s, double t) {
    final stem = Paint()
      ..color = const Color(0xFF22C55E)
      ..strokeWidth = s.shortestSide * 0.04
      ..style = PaintingStyle.stroke;
    final h = s.height * (0.25 + t * 0.15);
    c.drawLine(Offset(s.width / 2, s.height * 0.75), Offset(s.width / 2, s.height * 0.75 - h), stem);
    final leaf = Paint()..color = const Color(0xAA86EFAC);
    c.drawOval(
      Rect.fromCenter(
        center: Offset(s.width / 2 + s.width * 0.08, s.height * 0.75 - h),
        width: s.width * 0.18,
        height: s.height * 0.1,
      ),
      leaf,
    );
  }

  void _fuse(Canvas c, Size s, double t, int level) {
    final p = Paint()..color = Color.lerp(const Color(0xFFF97316), const Color(0xFFEF4444), t)!;
    c.drawCircle(Offset(s.width * 0.78, s.height * 0.22), s.shortestSide * (0.08 + t * 0.03), p);
    final spark = Paint()..color = const Color(0xFFFFF7ED);
    c.drawCircle(
      Offset(s.width * 0.78, s.height * (0.12 - t * 0.04)),
      s.shortestSide * 0.03,
      spark,
    );
  }

  void _duck(Canvas c, Size s, double t) {
    final p = Paint()..color = Color.lerp(const Color(0xFFFACC15), const Color(0xFFFDE047), t)!;
    c.drawOval(
      Rect.fromCenter(
        center: Offset(s.width / 2, s.height / 2),
        width: s.width * 0.45,
        height: s.height * 0.32,
      ),
      p,
    );
  }

  void _aura(Canvas c, Size s, double t, Color color, {bool tight = false}) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.shortestSide * (tight ? 0.045 : 0.055)
      ..color = color.withValues(alpha: 0.35 + t * 0.4);
    c.drawCircle(
      Offset(s.width / 2, s.height / 2),
      s.shortestSide * (tight ? 0.40 : 0.46) * (0.96 + t * 0.04),
      p,
    );
  }

  void _chain(Canvas c, Size s, double t) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.shortestSide * 0.05
      ..color = Color.lerp(const Color(0xFFE11D48), const Color(0xFFF43F5E), t)!;
    c.drawCircle(Offset(s.width / 2, s.height / 2), s.shortestSide * 0.42, p);
    c.drawCircle(Offset(s.width / 2, s.height / 2), s.shortestSide * (0.30 + t * 0.04), p);
  }

  void _ward(Canvas c, Size s, double t) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.shortestSide * 0.05
      ..color = Color.lerp(const Color(0xFF38BDF8), const Color(0xFF7DD3FC), t)!;
    final path = Path()
      ..moveTo(s.width * 0.5, s.height * 0.12)
      ..lineTo(s.width * 0.82, s.height * 0.28)
      ..lineTo(s.width * 0.75, s.height * 0.7)
      ..quadraticBezierTo(s.width * 0.5, s.height * 0.9, s.width * 0.25, s.height * 0.7)
      ..lineTo(s.width * 0.18, s.height * 0.28)
      ..close();
    c.drawPath(path, p);
  }

  void _torch(Canvas c, Size s, double t, math.Random rng) {
    final flame = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.lerp(const Color(0xFFFFF7ED), const Color(0xFFFBBF24), t)!,
          const Color(0x00F97316),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(s.width * 0.2, s.height * 0.8),
        radius: s.shortestSide * 0.22,
      ));
    c.drawCircle(
      Offset(s.width * 0.2, s.height * (0.78 - t * 0.05)),
      s.shortestSide * (0.14 + t * 0.04),
      flame,
    );
  }

  void _siege(Canvas c, Size s, double t, int level) {
    final p = Paint()..color = const Color(0xCC9A3412);
    final w = s.width * 0.22;
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.7, s.height * 0.3, w, s.height * 0.2),
        Radius.circular(s.shortestSide * 0.04),
      ),
      p,
    );
  }

  void _sticky(Canvas c, Size s, double t) {
    final p = Paint()..color = const Color(0x99A3E635);
    for (var i = 0; i < 3; i++) {
      final x = s.width * (0.3 + i * 0.2);
      final y = s.height * (0.55 + t * 0.2 + i * 0.05);
      c.drawCircle(Offset(x, y), s.shortestSide * 0.05, p);
    }
  }

  void _shadow(Canvas c, Size s, double t) {
    final p = Paint()..color = Colors.black.withValues(alpha: 0.25 + t * 0.15);
    c.save();
    c.translate(s.width * 0.08, s.height * 0.04);
    c.drawOval(
      Rect.fromCenter(
        center: Offset(s.width / 2, s.height / 2),
        width: s.width * 0.7,
        height: s.height * 0.85,
      ),
      p,
    );
    c.restore();
  }

  void _zebra(Canvas c, Size s, double t) {
    final p = Paint()..color = const Color(0x991A1A1A);
    for (final y in [0.28, 0.42, 0.56, 0.70]) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(s.width * 0.28, s.height * (y + t * 0.01), s.width * 0.44, s.height * 0.05),
          Radius.circular(s.shortestSide),
        ),
        p,
      );
    }
  }

  void _vanity(Canvas c, Size s, double t) {
    final hue = (t * 360) % 360;
    final color = HSLColor.fromAHSL(0.45, hue, 0.7, 0.6).toColor();
    _aura(c, s, t, color);
  }

  void _hunger(Canvas c, Size s, double t, math.Random rng) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.shortestSide * 0.04
      ..color = Color.lerp(const Color(0xFFB91C1C), const Color(0xFFEF4444), t)!;
    final path = Path()
      ..moveTo(s.width * 0.2, s.height * 0.55)
      ..quadraticBezierTo(s.width * 0.35, s.height * (0.7 + t * 0.05), s.width * 0.5, s.height * 0.55)
      ..quadraticBezierTo(s.width * 0.65, s.height * (0.4 - t * 0.05), s.width * 0.8, s.height * 0.55);
    c.drawPath(path, p);
  }

  void _wash(Canvas c, Size s, double t, Color color) {
    c.drawRect(Offset.zero & s, Paint()..color = color.withValues(alpha: 0.08 + t * 0.08));
  }

  void _season(Canvas c, Size s, double t) {
    final colors = [
      const Color(0x44F97316), // volcano/autumn
      const Color(0x4438BDF8), // winter
      const Color(0x444ADE80), // spring
      const Color(0x44FBBF24), // summer
    ];
    final i = (t * 4).floor() % 4;
    c.drawRect(Offset.zero & s, Paint()..color = colors[i]);
  }

  void _attract(Canvas c, Size s, double t) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.shortestSide * 0.03
      ..color = const Color(0x88A78BFA);
    for (var i = 0; i < 3; i++) {
      final r = s.shortestSide * (0.15 + i * 0.12) * (1 - t * 0.25);
      c.drawCircle(Offset(s.width / 2, s.height / 2), r, p);
    }
  }

  void _eclipse(Canvas c, Size s, double t) {
    c.drawRect(Offset.zero & s, Paint()..color = Colors.black.withValues(alpha: 0.25 + t * 0.2));
    final p = Paint()..color = const Color(0x66FDE68A);
    c.drawCircle(Offset(s.width * 0.7, s.height * 0.25), s.shortestSide * 0.12, p);
  }

  void _border(Canvas c, Size s, double t) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.shortestSide * 0.08
      ..color = Color.lerp(const Color(0x88F87171), const Color(0xCCEF4444), t)!;
    c.drawRect(Rect.fromLTWH(2, 2, s.width - 4, s.height - 4), p);
  }

  void _grinder(Canvas c, Size s, double t) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.shortestSide * 0.04
      ..color = const Color(0x99F97316);
    c.save();
    c.translate(s.width / 2, s.height / 2);
    c.rotate(t * math.pi * 2);
    for (var i = 0; i < 8; i++) {
      c.rotate(math.pi / 4);
      c.drawLine(Offset.zero, Offset(s.shortestSide * 0.35, 0), p);
    }
    c.restore();
  }

  void _time(Canvas c, Size s, double t) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.shortestSide * 0.04
      ..color = Color.lerp(const Color(0x8860A5FA), const Color(0xFFA78BFA), t)!;
    c.drawCircle(Offset(s.width / 2, s.height / 2), s.shortestSide * 0.3, p);
    c.drawLine(
      Offset(s.width / 2, s.height / 2),
      Offset(
        s.width / 2 + math.cos(t * math.pi * 2) * s.shortestSide * 0.22,
        s.height / 2 + math.sin(t * math.pi * 2) * s.shortestSide * 0.22,
      ),
      p,
    );
  }

  void _burst(Canvas c, Size s, double t, Color color) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.shortestSide * 0.06 * (1.2 - t)
      ..color = color.withValues(alpha: 1 - t);
    c.drawCircle(Offset(s.width / 2, s.height / 2), s.shortestSide * (0.15 + t * 0.4), p);
    final fill = Paint()..color = color.withValues(alpha: 0.35 * (1 - t));
    c.drawCircle(Offset(s.width / 2, s.height / 2), s.shortestSide * (0.1 + t * 0.2), fill);
  }

  @override
  bool shouldRepaint(covariant FxSkinPainter oldDelegate) {
    return oldDelegate.skin != skin ||
        oldDelegate.t != t ||
        oldDelegate.level != level ||
        oldDelegate.color != color;
  }
}
