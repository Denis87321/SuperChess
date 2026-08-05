import 'package:flutter/material.dart';

import '../online/game_clock.dart';
import '../theme/balatro_theme.dart';

class OnlineSidePanel extends StatelessWidget {
  const OnlineSidePanel({
    super.key,
    required this.opponentName,
    required this.localName,
    required this.opponentMs,
    required this.localMs,
    required this.opponentActive,
    required this.localActive,
    required this.onTakeback,
    required this.onDraw,
    required this.onResign,
    this.canTakeback = true,
  });

  final String opponentName;
  final String localName;
  final int opponentMs;
  final int localMs;
  final bool opponentActive;
  final bool localActive;
  final VoidCallback onTakeback;
  final VoidCallback onDraw;
  final VoidCallback onResign;
  final bool canTakeback;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: BalatroTheme.felt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          _clockBlock(
            name: opponentName,
            ms: opponentMs,
            active: opponentActive,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    tooltip: 'Попросить вернуть ход',
                    onPressed: canTakeback ? onTakeback : null,
                    child: const Icon(Icons.u_turn_left_rounded, size: 22),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _ActionBtn(
                    tooltip: 'Предложить ничью',
                    onPressed: onDraw,
                    child: Text(
                      '½',
                      style: BalatroTheme.titleStyle.copyWith(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _ActionBtn(
                    tooltip: 'Сдаться',
                    onPressed: onResign,
                    color: const Color(0xFFB33A3A),
                    child: const Icon(Icons.flag_rounded, size: 22),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          _clockBlock(
            name: localName,
            ms: localMs,
            active: localActive,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _clockBlock({
    required String name,
    required int ms,
    required bool active,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF3D6B4F) : BalatroTheme.background,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              GameClock.formatMs(ms),
              style: BalatroTheme.titleStyle.copyWith(
                fontSize: 32,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF6BCB77),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: BalatroTheme.statusStyle.copyWith(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.child,
    required this.onPressed,
    required this.tooltip,
    this.color,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color ?? BalatroTheme.background,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 44,
            child: Center(
              child: IconTheme(
                data: IconThemeData(
                  color: onPressed == null
                      ? BalatroTheme.cream.withValues(alpha: 0.3)
                      : BalatroTheme.cream,
                ),
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: onPressed == null
                        ? BalatroTheme.cream.withValues(alpha: 0.3)
                        : BalatroTheme.cream,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
