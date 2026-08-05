import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../l10n/app_strings.dart';
import '../theme/balatro_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.auth});

  final AuthService auth;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<HistoryGame>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.auth.fetchHistory();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: BalatroTheme.background,
      appBar: AppBar(
        title: Text(
          s.history,
          style: BalatroTheme.titleStyle.copyWith(fontSize: 18),
        ),
        backgroundColor: BalatroTheme.appBar,
        foregroundColor: BalatroTheme.cream,
      ),
      body: FutureBuilder<List<HistoryGame>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: BalatroTheme.gold),
            );
          }
          final games = snap.data ?? const [];
          if (games.isEmpty) {
            return Center(
              child: Text(
                s.noHistory,
                style: BalatroTheme.statusStyle.copyWith(
                  color: BalatroTheme.cream.withValues(alpha: 0.6),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: games.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final g = games[index];
              final resultLabel = switch (g.result) {
                'win' => s.resultWin,
                'loss' => s.resultLoss,
                _ => s.resultDraw,
              };
              final delta = g.ratingDelta;
              final deltaText = delta == null
                  ? ''
                  : (delta >= 0 ? ' (+$delta)' : ' ($delta)');
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BalatroTheme.felt,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'vs ${g.opponentName}',
                            style: BalatroTheme.statusStyle.copyWith(
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Text(
                          resultLabel,
                          style: BalatroTheme.statusStyle.copyWith(
                            fontSize: 13,
                            color: g.result == 'win'
                                ? const Color(0xFF6BCB77)
                                : g.result == 'loss'
                                    ? const Color(0xFFE57373)
                                    : BalatroTheme.gold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${g.color == 'white' ? s.white : s.black}'
                      ' · ${g.rated ? s.ratedGame : s.casualGame}'
                      '${g.ratingAfter != null ? ' · ${g.ratingAfter}$deltaText' : ''}',
                      style: BalatroTheme.statusStyle.copyWith(
                        fontSize: 12,
                        color: BalatroTheme.cream.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
