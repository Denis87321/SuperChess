import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';
import '../models/piece.dart';
import '../theme/balatro_theme.dart';
import 'game_screen.dart';
import 'login_screen.dart';
import 'matchmaking_screen.dart';
import 'profile_screen.dart';
import 'register_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.auth,
    required this.localeController,
  });

  final AuthService auth;
  final LocaleController localeController;

  void _playOnline(BuildContext context) {
    final s = AppStrings.of(context);
    final name = auth.username ?? s.anonymous;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MatchmakingScreen(
          playerName: name,
          auth: auth,
        ),
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

  void _playComputer(BuildContext context) {
    final s = AppStrings.of(context);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(
          localColor: PieceColor.white,
          vsComputer: true,
          opponentName: s.computer,
        ),
      ),
    );
  }

  Future<void> _openLogin(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LoginScreen(auth: auth),
      ),
    );
  }

  Future<void> _openRegister(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RegisterScreen(auth: auth),
      ),
    );
  }

  void _showLanguageSheet(BuildContext context) {
    final s = AppStrings.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: BalatroTheme.felt,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(s.languageSystem, style: BalatroTheme.statusStyle),
                trailing: localeController.preference == 'system'
                    ? const Icon(Icons.check, color: BalatroTheme.gold)
                    : null,
                onTap: () {
                  localeController.setPreference('system');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(s.languageRu, style: BalatroTheme.statusStyle),
                trailing: localeController.preference == 'ru'
                    ? const Icon(Icons.check, color: BalatroTheme.gold)
                    : null,
                onTap: () {
                  localeController.setPreference('ru');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(s.languageEn, style: BalatroTheme.statusStyle),
                trailing: localeController.preference == 'en'
                    ? const Icon(Icons.check, color: BalatroTheme.gold)
                    : null,
                onTap: () {
                  localeController.setPreference('en');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: BalatroTheme.background,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: auth.isLoggedIn
                              ? () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          ProfileScreen(auth: auth),
                                    ),
                                  );
                                }
                              : null,
                          child: Text(
                            auth.isLoggedIn
                                ? '${s.loggedInAs} ${auth.username}'
                                    '${auth.rating > 0 ? ' · ${auth.rating}' : ''}'
                                : s.guest,
                            style: BalatroTheme.statusStyle.copyWith(
                              fontSize: 12,
                              color: BalatroTheme.cream.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                      if (auth.isLoggedIn)
                        IconButton(
                          tooltip: s.profile,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ProfileScreen(auth: auth),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.person_rounded,
                            color: BalatroTheme.cream,
                          ),
                        ),
                      IconButton(
                        tooltip: s.language,
                        onPressed: () => _showLanguageSheet(context),
                        icon: const Icon(
                          Icons.language_rounded,
                          color: BalatroTheme.cream,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    s.appTitle.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: BalatroTheme.titleStyle.copyWith(fontSize: 36),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.tagline,
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
                      s.playOnline,
                      style: BalatroTheme.statusStyle.copyWith(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => _playLocal(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BalatroTheme.gold,
                      side: BorderSide(
                        color: BalatroTheme.gold.withValues(alpha: 0.6),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      s.playLocal,
                      style: BalatroTheme.statusStyle.copyWith(
                        fontSize: 16,
                        color: BalatroTheme.gold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => _playComputer(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BalatroTheme.cream,
                      side: BorderSide(
                        color: BalatroTheme.cream.withValues(alpha: 0.45),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      s.playComputer,
                      style: BalatroTheme.statusStyle.copyWith(
                        fontSize: 16,
                        color: BalatroTheme.cream,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (auth.isLoggedIn)
                    TextButton(
                      onPressed: () => auth.logout(),
                      child: Text(
                        s.logout,
                        style: BalatroTheme.statusStyle.copyWith(
                          fontSize: 13,
                          color: BalatroTheme.cream.withValues(alpha: 0.7),
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _openLogin(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: BalatroTheme.cream,
                              side: BorderSide(
                                color: BalatroTheme.cream.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              s.login,
                              style: BalatroTheme.statusStyle.copyWith(
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _openRegister(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: BalatroTheme.cream,
                              side: BorderSide(
                                color: BalatroTheme.cream.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              s.register,
                              style: BalatroTheme.statusStyle.copyWith(
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
