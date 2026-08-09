import 'package:flutter/material.dart';

import '../../chess/ability_fx_map.dart';
import '../../l10n/models/game_ability.dart';
import '../../l10n/models/piece.dart';
import 'frost_ice_overlay.dart';
import 'fx_host.dart';
import 'fx_painters.dart';

/// Animated status FX stacked on a piece (frost, heat, aura, sticky…).
class PieceFxLayer extends StatelessWidget {
  const PieceFxLayer({
    super.key,
    required this.piece,
    required this.size,
    this.isFrozen = false,
    this.inDuel = false,
    this.hasSanctuaryWard = false,
    this.underCurfew = false,
    this.hasTorch = false,
    this.isZebra = false,
    this.sandStuck = false,
    this.siegeCounter,
    this.showFrost = false,
  });

  final Piece piece;
  final double size;
  final bool isFrozen;
  final bool inDuel;
  final bool hasSanctuaryWard;
  final bool underCurfew;
  final bool hasTorch;
  final bool isZebra;
  final bool sandStuck;
  final int? siegeCounter;
  final bool showFrost;

  List<(FxSkin, Color?)> get _skins {
    final out = <(FxSkin, Color?)>[];
    if (sandStuck) out.add((FxSkin.sandSink, null));
    if (piece.heatLevel > 0) out.add((FxSkin.heatPulse, null));
    if (piece.isPlagued) out.add((FxSkin.poisonPulse, null));
    if (piece.skipTurnsLeft > 0) out.add((FxSkin.stickyDrip, null));
    if (inDuel || underCurfew) out.add((FxSkin.chainLink, null));
    if (hasSanctuaryWard) out.add((FxSkin.wardShield, null));
    if (hasTorch) out.add((FxSkin.torchFlame, null));
    if (isZebra) out.add((FxSkin.zebraStripe, null));
    if (siegeCounter != null && siegeCounter! > 0) {
      out.add((FxSkin.siegeTick, null));
    }
    if (piece.lavaStreak > 0) out.add((FxSkin.lavaGlow, null));
    if (piece.trojanTurnsLeft > 0) out.add((FxSkin.fuseTick, null));

    for (final ability in piece.abilities) {
      final profile = fxProfileFor(ability);
      if (profile.layer != FxLayer.piece && profile.layer != FxLayer.burst) {
        continue;
      }
      final skin = profile.layer == FxLayer.burst
          ? FxSkin.modAura
          : profile.skin;
      if (skin == FxSkin.none || skin == FxSkin.iceGrow) continue;
      if (out.any((e) => e.$1 == skin)) continue;
      out.add((skin, _colorForAbility(ability)));
    }

    // Any modified piece gets at least a subtle aura.
    if (out.isEmpty &&
        (piece.abilities.isNotEmpty || piece.hasModifiedMoveSet)) {
      out.add((FxSkin.modAura, const Color(0xFFEAB308)));
    }
    return out.take(3).toList(); // keep readable
  }

  static Color _colorForAbility(GameAbility a) {
    final name = a.name;
    if (name.contains('king')) return const Color(0xFFFBBF24);
    if (name.contains('queen')) return const Color(0xFFA78BFA);
    if (name.contains('rook')) return const Color(0xFF60A5FA);
    if (name.contains('bishop')) return const Color(0xFF34D399);
    if (name.contains('knight')) return const Color(0xFFF472B6);
    if (name.contains('pawn')) return const Color(0xFFFDA4AF);
    return const Color(0xFFEAB308);
  }

  @override
  Widget build(BuildContext context) {
    final skins = _skins;
    final frostLevel = piece.frostLevel.clamp(0, 3);
    final showIce = isFrozen || (showFrost && frostLevel > 0);
    if (skins.isEmpty && !showIce) return const SizedBox.shrink();

    return Stack(
      fit: StackFit.expand,
      children: [
        for (final (skin, color) in skins)
          FxHost(
            duration: Duration(
              milliseconds: skin == FxSkin.torchFlame ? 900 : 1800,
            ),
            builder: (_, t) => CustomPaint(
              painter: FxSkinPainter(
                skin: skin,
                t: t,
                level: piece.heatLevel > 0
                    ? piece.heatLevel
                    : (siegeCounter ?? piece.trojanTurnsLeft).clamp(0, 3),
                seed: piece.pieceId.hashCode,
                color: color,
              ),
            ),
          ),
        if (showIce)
          FrostIceOverlay(
            level: frostLevel,
            size: size,
            frozen: isFrozen,
          ),
      ],
    );
  }
}
