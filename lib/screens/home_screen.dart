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

bool _langSelected(LocaleController c, String code) {
  if (c.preference == code) return true;
  if (c.preference == 'system') {
    return c.locale.languageCode.toLowerCase().startsWith(code);
  }
  return false;
}

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

  void _showSettingsSheet(BuildContext context) {
    final s = AppStrings.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: BalatroTheme.felt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    s.settings.toUpperCase(),
                    style: BalatroTheme.titleStyle.copyWith(fontSize: 16),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    s.language,
                    style: BalatroTheme.statusStyle.copyWith(
                      fontSize: 12,
                      color: BalatroTheme.cream.withValues(alpha: 0.55),
                    ),
                  ),
                ),
                ListTile(
                  title: Text(s.languageRu, style: BalatroTheme.statusStyle),
                  trailing: _langSelected(localeController, 'ru')
                      ? const Icon(Icons.check, color: BalatroTheme.gold)
                      : null,
                  onTap: () {
                    localeController.setPreference('ru');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: Text(s.languageEn, style: BalatroTheme.statusStyle),
                  trailing: _langSelected(localeController, 'en')
                      ? const Icon(Icons.check, color: BalatroTheme.gold)
                      : null,
                  onTap: () {
                    localeController.setPreference('en');
                    Navigator.pop(context);
                  },
                ),
                if (auth.isLoggedIn) ...[
                  const Divider(color: Color(0x33F5E6C8)),
                  ListTile(
                    title: Text(s.logout, style: BalatroTheme.statusStyle),
                    onTap: () {
                      auth.logout();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([auth, localeController]),
      builder: (context, _) {
        return Scaffold(
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0E1218),
                  BalatroTheme.background,
                  Color(0xFF1A2433),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TopBar(
                      auth: auth,
                      strings: s,
                      onLogin: () => _openLogin(context),
                      onRegister: () => _openRegister(context),
                      onProfile: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ProfileScreen(auth: auth),
                          ),
                        );
                      },
                      onSettings: () => _showSettingsSheet(context),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      s.appTitle.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: BalatroTheme.titleStyle.copyWith(
                        fontSize: 42,
                        letterSpacing: 4,
                        height: 1.05,
                      ),
                    ),
                    const Spacer(flex: 2),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final maxW = constraints.maxWidth;
                        final center = (maxW * 0.38).clamp(118.0, 168.0);
                        final side = center * 0.78;
                        final gap = (maxW * 0.03).clamp(8.0, 14.0);
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _ModeTile(
                              size: side,
                              label: s.playLocal,
                              accent: BalatroTheme.gold,
                              filled: false,
                              onTap: () => _playLocal(context),
                            ),
                            SizedBox(width: gap),
                            _ModeTile(
                              size: center,
                              label: s.playOnline,
                              accent: BalatroTheme.accent,
                              filled: true,
                              onTap: () => _playOnline(context),
                            ),
                            SizedBox(width: gap),
                            _ModeTile(
                              size: side,
                              label: s.playComputer,
                              accent: BalatroTheme.cream,
                              filled: false,
                              onTap: () => _playComputer(context),
                            ),
                          ],
                        );
                      },
                    ),
                    const Spacer(flex: 3),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.auth,
    required this.strings,
    required this.onLogin,
    required this.onRegister,
    required this.onProfile,
    required this.onSettings,
  });

  final AuthService auth;
  final AppStrings strings;
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onProfile;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: auth.isLoggedIn ? onProfile : null,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                auth.isLoggedIn
                    ? '${auth.username}'
                        '${auth.rating > 0 ? ' · ${auth.rating}' : ''}'
                    : strings.guest,
                style: BalatroTheme.statusStyle.copyWith(
                  fontSize: 12,
                  color: BalatroTheme.cream.withValues(alpha: 0.7),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        if (!auth.isLoggedIn) ...[
          TextButton(
            onPressed: onLogin,
            style: TextButton.styleFrom(
              foregroundColor: BalatroTheme.cream,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              strings.login,
              style: BalatroTheme.statusStyle.copyWith(fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: onRegister,
            style: TextButton.styleFrom(
              foregroundColor: BalatroTheme.gold,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              strings.register,
              style: BalatroTheme.statusStyle.copyWith(
                fontSize: 12,
                color: BalatroTheme.gold,
              ),
            ),
          ),
        ] else
          IconButton(
            tooltip: strings.profile,
            onPressed: onProfile,
            icon: const Icon(Icons.person_rounded, color: BalatroTheme.cream),
          ),
        IconButton(
          tooltip: strings.settings,
          onPressed: onSettings,
          icon: const Icon(Icons.settings_rounded, color: BalatroTheme.cream),
        ),
      ],
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.size,
    required this.label,
    required this.accent,
    required this.filled,
    required this.onTap,
  });

  final double size;
  final String label;
  final Color accent;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: radius,
            color: filled
                ? accent.withValues(alpha: 0.92)
                : BalatroTheme.felt.withValues(alpha: 0.85),
            border: Border.all(
              color: accent.withValues(alpha: filled ? 0.95 : 0.55),
              width: filled ? 2.2 : 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: filled ? 0.28 : 0.12),
                blurRadius: filled ? 22 : 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(size * 0.1),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: BalatroTheme.titleStyle.copyWith(
                  fontSize: filled ? 15 : 12,
                  letterSpacing: 1.2,
                  height: 1.25,
                  color: filled ? BalatroTheme.ink : accent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
