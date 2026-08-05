import 'package:flutter/material.dart';

import '../theme/balatro_theme.dart';
import '../online/game_clock.dart';

class OnlinePlayerBar extends StatelessWidget {
  const OnlinePlayerBar({
    super.key,
    required this.name,
    required this.clockMs,
    required this.active,
    this.rating,
    this.compact = false,
  });

  final String name;
  final int clockMs;
  final bool active;
  final int? rating;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final clockBg = active
        ? const Color(0xFF3D6B4F)
        : BalatroTheme.felt;
    final label = rating == null ? name : '$name ($rating)';
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      child: Row(
        children: [
          Expanded(
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
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: BalatroTheme.statusStyle.copyWith(
                      fontSize: compact ? 13 : 14,
                      color: BalatroTheme.cream,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 14,
              vertical: compact ? 6 : 8,
            ),
            decoration: BoxDecoration(
              color: clockBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              GameClock.formatMs(clockMs),
              style: BalatroTheme.titleStyle.copyWith(
                fontSize: compact ? 16 : 20,
                letterSpacing: 1,
                color: BalatroTheme.cream,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
