import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';
import '../l10n/models/piece.dart';
import '../l10n/supported_locales.dart';
import '../theme/balatro_theme.dart';
import 'game_screen.dart';
import 'login_screen.dart';
import 'clubs_screen.dart';
import 'forum_screen.dart';
import 'lobby_screen.dart';
import 'matchmaking_screen.dart';
import 'mod_browser_screen.dart';
import 'private_room_screen.dart';
import 'profile_screen.dart';
import 'puzzle_list_screen.dart';
import 'register_screen.dart';
import 'tutorial_screen.dart';

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
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LobbyScreen(auth: auth),
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
                SizedBox(
                  height: 220,
                  child: ListView(
                    children: [
                      for (final e in kLocaleLabels.entries)
                        ListTile(
                          dense: true,
                          title: Text(e.value, style: BalatroTheme.statusStyle),
                          trailing: _langSelected(localeController, e.key)
                              ? const Icon(Icons.check, color: BalatroTheme.gold)
                              : null,
                          onTap: () {
                            localeController.setPreference(e.key);
                            Navigator.pop(context);
                          },
                        ),
                    ],
                  ),
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
          backgroundColor: BalatroTheme.background,
          body: SafeArea(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
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
                        const SizedBox(height: 56),
                        Text(
                          s.appTitle,
                          style: BalatroTheme.titleStyle.copyWith(
                            fontSize: 40,
                            letterSpacing: -0.5,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.playOnline,
                          style: BalatroTheme.statusStyle.copyWith(
                            fontSize: 14,
                            color: BalatroTheme.cream.withValues(alpha: 0.52),
                          ),
                        ),
                        const SizedBox(height: 22),
                        const TutorialHomeCta(),
                        const Spacer(flex: 2),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final maxW = constraints.maxWidth;
                            final center = (maxW * 0.34).clamp(124.0, 190.0);
                            final side = center * 0.82;
                            final gap = (maxW * 0.025).clamp(8.0, 16.0);
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _ModeTile(
                                  size: side,
                                  label: s.playLocal,
                                  icon: Icons.people_outline_rounded,
                                  accent: BalatroTheme.gold,
                                  filled: false,
                                  onTap: () => _playLocal(context),
                                ),
                                SizedBox(width: gap),
                                _ModeTile(
                                  size: center,
                                  label: s.playOnline,
                                  icon: Icons.public_rounded,
                                  accent: BalatroTheme.accent,
                                  filled: true,
                                  onTap: () => _playOnline(context),
                                ),
                                SizedBox(width: gap),
                                _ModeTile(
                                  size: side,
                                  label: s.playComputer,
                                  icon: Icons.smart_toy_outlined,
                                  accent: BalatroTheme.cream,
                                  filled: false,
                                  onTap: () => _playComputer(context),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 28),
                        Wrap(
                          alignment: WrapAlignment.start,
                          spacing: 4,
                          runSpacing: 2,
                          children: [
                        _LinkChip(
                          label: s.tutorial,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const TutorialScreen(),
                              ),
                            );
                          },
                        ),
                        _LinkChip(
                          label: s.mods,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ModBrowserScreen(auth: auth),
                              ),
                            );
                          },
                        ),
                        _LinkChip(
                          label: s.puzzles,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => PuzzleListScreen(auth: auth),
                              ),
                            );
                          },
                        ),
                        _LinkChip(
                          label: s.privateRoom,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => PrivateRoomScreen(auth: auth),
                              ),
                            );
                          },
                        ),
                        _LinkChip(
                          label: s.joinByCode,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => PrivateRoomScreen(auth: auth),
                              ),
                            );
                          },
                        ),
                        _LinkChip(
                          label: s.spectate,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => PrivateRoomScreen(
                                  auth: auth,
                                  spectateOnly: true,
                                ),
                              ),
                            );
                          },
                        ),
                        _LinkChip(
                          label: s.clubs,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ClubsScreen(auth: auth),
                              ),
                            );
                          },
                        ),
                        _LinkChip(
                          label: s.forum,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ForumScreen(auth: auth),
                              ),
                            );
                          },
                        ),
                          ],
                        ),
                        const Spacer(flex: 2),
                      ],
                    ),
                  ),
                ),
              ),
          ),
        );
      },
    );
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: BalatroTheme.cream.withValues(alpha: 0.85),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: BalatroTheme.statusStyle.copyWith(fontSize: 12),
      ),
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
    required this.icon,
    required this.accent,
    required this.filled,
    required this.onTap,
  });

  final double size;
  final String label;
  final IconData icon;
  final Color accent;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(10);
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
                ? accent
                : BalatroTheme.felt,
            border: Border.all(
              color: accent.withValues(alpha: filled ? 1 : 0.32),
              width: filled ? 0 : 1,
            ),
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(size * 0.08),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: size * 0.22,
                    color: filled ? BalatroTheme.ink : accent,
                  ),
                  SizedBox(height: size * 0.08),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: BalatroTheme.titleStyle.copyWith(
                      fontSize: filled ? 15 : 12,
                      height: 1.2,
                      color: filled ? BalatroTheme.ink : accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
