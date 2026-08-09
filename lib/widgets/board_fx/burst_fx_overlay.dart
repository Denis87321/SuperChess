import 'package:flutter/material.dart';

import '../../chess/board_vfx_event.dart';
import '../../chess/fx_skin.dart';
import 'fx_painters.dart';

/// Plays a short one-shot burst for [BoardVfxEvent].
class BurstFxOverlay extends StatefulWidget {
  const BurstFxOverlay({
    super.key,
    required this.event,
    required this.size,
    required this.onFinished,
  });

  final BoardVfxEvent event;
  final double size;
  final VoidCallback onFinished;

  @override
  State<BurstFxOverlay> createState() => _BurstFxOverlayState();
}

class _BurstFxOverlayState extends State<BurstFxOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward().whenComplete(widget.onFinished);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skin = widget.event.skin == FxSkin.none
        ? FxSkin.burstImpact
        : widget.event.skin;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return CustomPaint(
          size: Size.square(widget.size),
          painter: FxSkinPainter(
            skin: skin == FxSkin.burstImpact ? skin : FxSkin.burstImpact,
            t: _c.value,
            seed: widget.event.square.hashCode,
            color: _colorFor(skin),
          ),
        );
      },
    );
  }

  Color _colorFor(FxSkin skin) {
    return switch (skin) {
      FxSkin.lavaGlow || FxSkin.volcanoGlow || FxSkin.heatPulse =>
        const Color(0xFFFF6B00),
      FxSkin.iceGrow => const Color(0xFF38BDF8),
      FxSkin.poisonPulse || FxSkin.virusSpark => const Color(0xFF84CC16),
      FxSkin.portalSpin => const Color(0xFFA78BFA),
      FxSkin.sandSink || FxSkin.dustCloud => const Color(0xFFD97706),
      FxSkin.inkBleed => const Color(0xFF312E81),
      _ => const Color(0xFFFF6B00),
    };
  }
}
