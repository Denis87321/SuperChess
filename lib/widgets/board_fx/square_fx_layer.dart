import 'package:flutter/material.dart';

import '../../chess/fx_skin.dart';
import 'fx_host.dart';
import 'fx_painters.dart';

/// Animated hazard FX for a board square.
class SquareFxLayer extends StatelessWidget {
  const SquareFxLayer({
    super.key,
    required this.size,
    required this.skins,
    this.level = 1,
    this.seed = 1,
  });

  final double size;
  final List<FxSkin> skins;
  final int level;
  final int seed;

  @override
  Widget build(BuildContext context) {
    if (skins.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (final skin in skins.take(2))
            FxHost(
              duration: Duration(
                milliseconds: switch (skin) {
                  FxSkin.lavaGlow || FxSkin.volcanoGlow => 1100,
                  FxSkin.portalSpin || FxSkin.riverFlow => 1600,
                  FxSkin.sandSink => 2000,
                  _ => 1800,
                },
              ),
              builder: (_, t) => CustomPaint(
                size: Size.square(size),
                painter: FxSkinPainter(
                  skin: skin,
                  t: t,
                  level: level,
                  seed: seed ^ skin.index,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
