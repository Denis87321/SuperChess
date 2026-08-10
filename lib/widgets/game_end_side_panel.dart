import 'package:flutter/material.dart';

import '../chess/chess_game.dart';
import '../chess/game_end_messages.dart';
import '../l10n/models/piece.dart';
import '../theme/balatro_theme.dart';

/// Result header + rematch actions for the move-history column (Lichess-style).
class GameEndSidePanel extends StatelessWidget {
  const GameEndSidePanel({
    super.key,
    required this.winner,
    required this.reason,
    this.detail,
    this.localColor,
    this.online = false,
    this.onRematch,
    this.onFindAnother,
    this.rematchPending = false,
    this.rematchIncoming = false,
  });

  final PieceColor? winner;
  final GameEndReason? reason;
  final String? detail;
  final PieceColor? localColor;
  final bool online;
  final VoidCallback? onRematch;
  final VoidCallback? onFindAnother;
  final bool rematchPending;
  final bool rematchIncoming;

  @override
  Widget build(BuildContext context) {
    final score = GameEndMessages.score(winner);
    final line = GameEndMessages.panelLine(
      reason: reason,
      detail: detail,
      winner: winner,
      localColor: localColor,
      online: online,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: BalatroTheme.background.withValues(alpha: 0.55),
        border: Border(
          top: BorderSide(color: BalatroTheme.cream.withValues(alpha: 0.12)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  line,
                  style: BalatroTheme.statusStyle.copyWith(
                    fontSize: 12,
                    height: 1.25,
                    fontStyle: FontStyle.italic,
                    color: BalatroTheme.cream.withValues(alpha: 0.78),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                score,
                style: BalatroTheme.titleStyle.copyWith(fontSize: 22),
              ),
            ],
          ),
          if (onRematch != null || onFindAnother != null) ...[
            const SizedBox(height: 12),
            if (onRematch != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: rematchPending ? null : onRematch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3A3F4A),
                    foregroundColor: BalatroTheme.cream,
                    disabledBackgroundColor: const Color(0xFF2A2E36),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    rematchIncoming
                        ? 'ПРИНЯТЬ РЕВАНШ'
                        : rematchPending
                            ? 'ОЖИДАНИЕ…'
                            : 'РЕВАНШ',
                    style: BalatroTheme.titleStyle.copyWith(fontSize: 13),
                  ),
                ),
              ),
            if (onFindAnother != null) ...[
              const SizedBox(height: 6),
              TextButton(
                onPressed: onFindAnother,
                child: Text(
                  online ? 'NEW OPPONENT' : 'MENU',
                  style: BalatroTheme.statusStyle.copyWith(
                    fontSize: 11,
                    color: BalatroTheme.cream.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
