import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../l10n/app_strings.dart';
import '../theme/balatro_theme.dart';

class RivalriesScreen extends StatefulWidget {
  const RivalriesScreen({super.key, required this.auth});

  final AuthService auth;

  @override
  State<RivalriesScreen> createState() => _RivalriesScreenState();
}

class _RivalriesScreenState extends State<RivalriesScreen> {
  late Future<List<RivalryScore>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.auth.fetchRivalries();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: BalatroTheme.background,
      appBar: AppBar(
        title: Text(
          s.rivalries,
          style: BalatroTheme.titleStyle.copyWith(fontSize: 18),
        ),
        backgroundColor: BalatroTheme.appBar,
        foregroundColor: BalatroTheme.cream,
      ),
      body: FutureBuilder<List<RivalryScore>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: BalatroTheme.gold),
            );
          }
          final list = snap.data ?? const [];
          if (list.isEmpty) {
            return Center(
              child: Text(
                s.noRivalriesYet,
                textAlign: TextAlign.center,
                style: BalatroTheme.statusStyle.copyWith(
                  color: BalatroTheme.cream.withValues(alpha: 0.6),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final r = list[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: BalatroTheme.felt,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.opponentName,
                        style: BalatroTheme.statusStyle.copyWith(fontSize: 15),
                      ),
                    ),
                    Text(
                      '${r.wins}:${r.losses}',
                      style: BalatroTheme.titleStyle.copyWith(fontSize: 18),
                    ),
                    if (r.draws > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(${r.draws} нич.)',
                        style: BalatroTheme.statusStyle.copyWith(
                          fontSize: 12,
                          color: BalatroTheme.cream.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
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
