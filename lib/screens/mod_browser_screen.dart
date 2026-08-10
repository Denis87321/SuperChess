import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../l10n/app_strings.dart';
import '../l10n/models/ability_catalog.dart';
import '../l10n/models/ability_group.dart';
import '../l10n/models/ability_l10n.dart';
import '../l10n/models/game_ability.dart';
import '../theme/balatro_theme.dart';

class ModBrowserScreen extends StatefulWidget {
  const ModBrowserScreen({super.key, this.auth});

  final AuthService? auth;

  @override
  State<ModBrowserScreen> createState() => _ModBrowserScreenState();
}

class _ModBrowserScreenState extends State<ModBrowserScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _groups = AbilityGroup.values;
  Set<String> _seen = {};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _groups.length, vsync: this);
    _loadSeen();
  }

  Future<void> _loadSeen() async {
    final auth = widget.auth;
    if (auth == null || !auth.isLoggedIn) return;
    try {
      final ids = await auth.fetchSeenAbilities();
      if (!mounted) return;
      setState(() => _seen = ids.toSet());
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final locale = Localizations.localeOf(context);

    return Scaffold(
      backgroundColor: BalatroTheme.background,
      appBar: AppBar(
        title: Text(
          s.mods,
          style: BalatroTheme.titleStyle.copyWith(fontSize: 18),
        ),
        backgroundColor: BalatroTheme.appBar,
        foregroundColor: BalatroTheme.cream,
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          indicatorColor: BalatroTheme.gold,
          labelColor: BalatroTheme.gold,
          unselectedLabelColor: BalatroTheme.cream.withValues(alpha: 0.6),
          tabs: [
            for (final g in _groups) Tab(text: g.titleFor(locale)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          for (final g in _groups)
            _ModGroupList(
              abilities: AbilityCatalog.abilitiesForGroup(g),
              seen: _seen,
              locale: locale,
              strings: s,
            ),
        ],
      ),
    );
  }
}

class _ModGroupList extends StatelessWidget {
  const _ModGroupList({
    required this.abilities,
    required this.seen,
    required this.locale,
    required this.strings,
  });

  final List<GameAbility> abilities;
  final Set<String> seen;
  final Locale locale;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: abilities.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final a = abilities[i];
        final known = seen.contains(a.name);
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: BalatroTheme.felt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: known
                  ? BalatroTheme.gold.withValues(alpha: 0.45)
                  : Colors.white10,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      a.titleFor(locale),
                      style: BalatroTheme.titleStyle.copyWith(fontSize: 15),
                    ),
                  ),
                  if (seen.isNotEmpty)
                    Text(
                      known ? strings.seenMod : strings.newMod,
                      style: BalatroTheme.statusStyle.copyWith(
                        fontSize: 11,
                        color: known
                            ? BalatroTheme.gold
                            : BalatroTheme.cream.withValues(alpha: 0.45),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                a.descriptionForLocale(locale),
                style: BalatroTheme.statusStyle.copyWith(
                  fontSize: 13,
                  height: 1.35,
                  color: BalatroTheme.cream.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
