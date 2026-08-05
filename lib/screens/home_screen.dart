import 'package:flutter/material.dart';

import '../screens/matchmaking_screen.dart';
import '../theme/balatro_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _playOnline(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const MatchmakingScreen(),
      ),
    );
  }

  void _playLocal(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const MatchmakingScreen(isLocal: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BalatroTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                'SUPERCHESS',
                textAlign: TextAlign.center,
                style: BalatroTheme.titleStyle.copyWith(fontSize: 36),
              ),
              const SizedBox(height: 12),
              Text(
                'Шахматы с модификациями',
                textAlign: TextAlign.center,
                style: BalatroTheme.statusStyle.copyWith(
                  fontSize: 14,
                  color: BalatroTheme.cream.withValues(alpha: 0.75),
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => _playOnline(context),
                style: FilledButton.styleFrom(
                  backgroundColor: BalatroTheme.accent,
                  foregroundColor: BalatroTheme.cream,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'ИГРАТЬ ОНЛАЙН',
                  style: BalatroTheme.statusStyle.copyWith(fontSize: 16),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => _playLocal(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: BalatroTheme.gold,
                  side: BorderSide(color: BalatroTheme.gold.withValues(alpha: 0.6)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'ЛОКАЛЬНАЯ ИГРА',
                  style: BalatroTheme.statusStyle.copyWith(
                    fontSize: 16,
                    color: BalatroTheme.gold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
