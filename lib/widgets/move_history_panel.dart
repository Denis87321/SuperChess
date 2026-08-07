import 'package:flutter/material.dart';

import '../chess/move_history.dart';
import '../l10n/models/piece.dart';
import '../theme/balatro_theme.dart';

/// Lichess-style move list: numbered rows, clickable plies, step nav.
class MoveHistoryPanel extends StatelessWidget {
  const MoveHistoryPanel({
    super.key,
    required this.log,
    required this.viewPlyIndex,
    required this.onSelectPly,
    required this.onGoLive,
    this.compact = false,
  });

  final MoveHistoryLog log;
  /// `null` = viewing live position (after last ply).
  final int? viewPlyIndex;
  final ValueChanged<int> onSelectPly;
  final VoidCallback onGoLive;
  final bool compact;

  bool get _isLive =>
      viewPlyIndex == null ||
      (log.isNotEmpty && viewPlyIndex == log.length - 1);

  int get _effectiveIndex {
    if (log.isEmpty) return -1;
    return viewPlyIndex ?? (log.length - 1);
  }

  void _step(int delta) {
    if (log.isEmpty) return;
    final next = (_effectiveIndex + delta).clamp(0, log.length - 1);
    if (next == log.length - 1 && viewPlyIndex == null) {
      onGoLive();
      return;
    }
    if (next == log.length - 1) {
      onGoLive();
    } else {
      onSelectPly(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = log.rows;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _navBar(),
        Expanded(
          child: rows.isEmpty
              ? Center(
                  child: Text(
                    'Ходов пока нет',
                    style: BalatroTheme.statusStyle.copyWith(
                      fontSize: 12,
                      color: BalatroTheme.cream.withValues(alpha: 0.45),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  itemCount: rows.length,
                  itemBuilder: (context, i) {
                    final row = rows[i];
                    return _MoveRow(
                      number: row.number,
                      white: row.white,
                      black: row.black,
                      selectedIndex: viewPlyIndex,
                      isLive: _isLive,
                      lastPlyIndex: log.length - 1,
                      onSelect: onSelectPly,
                      compact: compact,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _navBar() {
    final canBack = log.isNotEmpty && _effectiveIndex > 0;
    final canForward = log.isNotEmpty && !_isLive;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 6),
      child: Row(
        children: [
          _NavIcon(
            icon: Icons.first_page_rounded,
            tooltip: 'В начало',
            onPressed: canBack ? () => onSelectPly(0) : null,
          ),
          _NavIcon(
            icon: Icons.chevron_left_rounded,
            tooltip: 'Назад',
            onPressed: canBack ? () => _step(-1) : null,
          ),
          _NavIcon(
            icon: Icons.chevron_right_rounded,
            tooltip: 'Вперёд',
            onPressed: canForward ? () => _step(1) : null,
          ),
          _NavIcon(
            icon: Icons.last_page_rounded,
            tooltip: 'К последнему ходу',
            onPressed: canForward ? onGoLive : null,
          ),
          if (!_isLive) ...[
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'просмотр',
                textAlign: TextAlign.right,
                style: BalatroTheme.statusStyle.copyWith(
                  fontSize: 10,
                  color: BalatroTheme.gold.withValues(alpha: 0.85),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 28),
      icon: Icon(
        icon,
        size: 22,
        color: onPressed == null
            ? BalatroTheme.cream.withValues(alpha: 0.25)
            : BalatroTheme.cream,
      ),
    );
  }
}

class _MoveRow extends StatelessWidget {
  const _MoveRow({
    required this.number,
    required this.white,
    required this.black,
    required this.selectedIndex,
    required this.isLive,
    required this.lastPlyIndex,
    required this.onSelect,
    required this.compact,
  });

  final int number;
  final PlyRecord? white;
  final PlyRecord? black;
  final int? selectedIndex;
  final bool isLive;
  final int lastPlyIndex;
  final ValueChanged<int> onSelect;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$number.',
              style: BalatroTheme.statusStyle.copyWith(
                fontSize: 12,
                color: BalatroTheme.cream.withValues(alpha: 0.45),
              ),
            ),
          ),
          Expanded(
            child: white == null
                ? const SizedBox.shrink()
                : _PlyCell(
                    ply: white!,
                    selected: _isSelected(white!),
                    onTap: () => onSelect(white!.plyIndex),
                    compact: compact,
                  ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: black == null
                ? const SizedBox.shrink()
                : _PlyCell(
                    ply: black!,
                    selected: _isSelected(black!),
                    onTap: () => onSelect(black!.plyIndex),
                    compact: compact,
                  ),
          ),
        ],
      ),
    );
  }

  bool _isSelected(PlyRecord ply) {
    if (selectedIndex != null) return selectedIndex == ply.plyIndex;
    // Live: highlight last ply only.
    return isLive && ply.plyIndex == lastPlyIndex;
  }
}

class _PlyCell extends StatelessWidget {
  const _PlyCell({
    required this.ply,
    required this.selected,
    required this.onTap,
    required this.compact,
  });

  final PlyRecord ply;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final mods = ply.modEvents;
    return Material(
      color: selected ? const Color(0xFF3A4A5C) : Colors.transparent,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ply.notation,
                style: BalatroTheme.statusStyle.copyWith(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: ply.side == PieceColor.white
                      ? BalatroTheme.cream
                      : BalatroTheme.cream.withValues(alpha: 0.92),
                ),
              ),
              if (mods.isNotEmpty && !compact)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Wrap(
                    spacing: 3,
                    runSpacing: 2,
                    children: [
                      for (final e in mods.take(4))
                        Text(
                          e.short,
                          style: TextStyle(
                            fontSize: 9,
                            height: 1.1,
                            color: switch (e.kind) {
                              ModEventKind.appeared =>
                                const Color(0xFF6BCB77),
                              ModEventKind.removed =>
                                const Color(0xFFE57373),
                              ModEventKind.activated =>
                                BalatroTheme.gold,
                            },
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thin side chrome wrapping [MoveHistoryPanel] for offline / narrow layouts.
class MoveHistorySideChrome extends StatelessWidget {
  const MoveHistorySideChrome({
    super.key,
    required this.child,
    this.width = 220,
  });

  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: BalatroTheme.felt,
        border: Border(
          left: BorderSide(color: Color(0x33FFFFFF)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Text(
              'ХОДЫ',
              style: BalatroTheme.titleStyle.copyWith(fontSize: 12),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
