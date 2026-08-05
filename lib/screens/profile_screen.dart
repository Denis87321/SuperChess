import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../l10n/app_strings.dart';
import '../theme/balatro_theme.dart';
import 'history_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.auth});

  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: BalatroTheme.background,
          appBar: AppBar(
            title: Text(
              s.profile,
              style: BalatroTheme.titleStyle.copyWith(fontSize: 18),
            ),
            backgroundColor: BalatroTheme.appBar,
            foregroundColor: BalatroTheme.cream,
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                auth.username ?? s.guest,
                style: BalatroTheme.titleStyle.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 16),
              _statCard(
                title: s.rating,
                value: '${auth.rating}',
              ),
              const SizedBox(height: 10),
              _statCard(
                title: s.gamesPlayed,
                value: '${auth.gamesPlayed}',
              ),
              const SizedBox(height: 10),
              _statCard(
                title: s.abilitiesProgress(
                  auth.abilitiesUnlocked,
                  auth.abilitiesTotal,
                ),
                value:
                    '${((auth.abilitiesUnlocked / auth.abilitiesTotal.clamp(1, 9999)) * 100).floor()}%',
              ),
              const SizedBox(height: 20),
              Text(s.collector, style: BalatroTheme.titleStyle.copyWith(fontSize: 16)),
              const SizedBox(height: 6),
              Text(
                s.collectorDesc,
                style: BalatroTheme.statusStyle.copyWith(
                  fontSize: 13,
                  color: BalatroTheme.cream.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: BalatroTheme.felt,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: auth.hasCollectorAchievement
                        ? BalatroTheme.gold
                        : Colors.white12,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      auth.hasCollectorAchievement
                          ? Icons.emoji_events_rounded
                          : Icons.lock_outline_rounded,
                      color: auth.hasCollectorAchievement
                          ? BalatroTheme.gold
                          : BalatroTheme.cream.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        auth.hasCollectorAchievement
                            ? s.achievementUnlocked
                            : s.achievementLocked,
                        style: BalatroTheme.statusStyle.copyWith(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => HistoryScreen(auth: auth),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: BalatroTheme.accent,
                  foregroundColor: BalatroTheme.cream,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(s.history, style: BalatroTheme.statusStyle),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard({required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: BalatroTheme.felt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: BalatroTheme.statusStyle.copyWith(fontSize: 13)),
          ),
          Text(
            value,
            style: BalatroTheme.titleStyle.copyWith(fontSize: 18),
          ),
        ],
      ),
    );
  }
}
