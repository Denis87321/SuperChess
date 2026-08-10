import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../auth/platform_api.dart';
import '../l10n/app_strings.dart';
import '../theme/balatro_theme.dart';

class ClubsScreen extends StatefulWidget {
  const ClubsScreen({super.key, required this.auth});

  final AuthService auth;

  @override
  State<ClubsScreen> createState() => _ClubsScreenState();
}

class _ClubsScreenState extends State<ClubsScreen> {
  late final PlatformApi _api = PlatformApi(widget.auth);
  List<Map<String, dynamic>> _clubs = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final clubs = await _api.listClubs();
      if (!mounted) return;
      setState(() {
        _clubs = clubs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _createClub() async {
    final s = AppStrings.of(context);
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BalatroTheme.felt,
        title: Text(s.clubs, style: BalatroTheme.titleStyle.copyWith(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: BalatroTheme.statusStyle,
              decoration: InputDecoration(
                labelText: s.isRu ? 'Название' : 'Name',
                labelStyle: BalatroTheme.statusStyle.copyWith(fontSize: 12),
              ),
            ),
            TextField(
              controller: descCtrl,
              style: BalatroTheme.statusStyle,
              decoration: InputDecoration(
                labelText: s.isRu ? 'Описание' : 'Description',
                labelStyle: BalatroTheme.statusStyle.copyWith(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.createRoom),
          ),
        ],
      ),
    );
    if (ok != true || nameCtrl.text.trim().isEmpty) return;
    try {
      await _api.createClub(
        name: nameCtrl.text.trim(),
        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  void _openClub(Map<String, dynamic> club) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ClubDetailScreen(
          auth: widget.auth,
          clubId: '${club['id']}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: BalatroTheme.background,
      appBar: AppBar(
        title: Text(s.clubs, style: BalatroTheme.titleStyle.copyWith(fontSize: 18)),
        backgroundColor: BalatroTheme.appBar,
        foregroundColor: BalatroTheme.cream,
        actions: [
          if (widget.auth.isLoggedIn)
            IconButton(
              onPressed: _createClub,
              icon: const Icon(Icons.add),
            ),
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: BalatroTheme.gold),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: BalatroTheme.statusStyle.copyWith(
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                if (_clubs.isEmpty)
                  Text(
                    s.isRu ? 'Пока нет клубов' : 'No clubs yet',
                    style: BalatroTheme.statusStyle,
                  ),
                for (final c in _clubs)
                  ListTile(
                    tileColor: BalatroTheme.felt,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    title: Text(
                      '${c['name']}',
                      style: BalatroTheme.statusStyle,
                    ),
                    subtitle: Text(
                      '${c['description'] ?? ''} · ${c['members'] ?? 0}',
                      style: BalatroTheme.statusStyle.copyWith(
                        fontSize: 12,
                        color: BalatroTheme.cream.withValues(alpha: 0.55),
                      ),
                    ),
                    onTap: () => _openClub(c),
                  ),
              ],
            ),
    );
  }
}

class ClubDetailScreen extends StatefulWidget {
  const ClubDetailScreen({
    super.key,
    required this.auth,
    required this.clubId,
  });

  final AuthService auth;
  final String clubId;

  @override
  State<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends State<ClubDetailScreen> {
  late final PlatformApi _api = PlatformApi(widget.auth);
  Map<String, dynamic>? _club;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final club = await _api.getClub(widget.clubId);
      if (!mounted) return;
      setState(() {
        _club = club;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _join() async {
    try {
      await _api.joinClub(widget.clubId);
      await _reload();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final club = _club;
    return Scaffold(
      backgroundColor: BalatroTheme.background,
      appBar: AppBar(
        title: Text(
          club == null ? s.clubs : '${club['name']}',
          style: BalatroTheme.titleStyle.copyWith(fontSize: 18),
        ),
        backgroundColor: BalatroTheme.appBar,
        foregroundColor: BalatroTheme.cream,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: BalatroTheme.gold),
            )
          : club == null
              ? Center(
                  child: Text(
                    _error ?? '—',
                    style: BalatroTheme.statusStyle,
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_error != null)
                      Text(
                        _error!,
                        style: BalatroTheme.statusStyle.copyWith(
                          color: Colors.redAccent,
                        ),
                      ),
                    if ('${club['description'] ?? ''}'.isNotEmpty)
                      Text(
                        '${club['description']}',
                        style: BalatroTheme.statusStyle.copyWith(fontSize: 14),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      '${s.isRu ? 'Владелец' : 'Owner'}: ${club['ownerName'] ?? ''}',
                      style: BalatroTheme.statusStyle.copyWith(fontSize: 12),
                    ),
                    if (widget.auth.isLoggedIn) ...[
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _join,
                        style: FilledButton.styleFrom(
                          backgroundColor: BalatroTheme.accent,
                          foregroundColor: BalatroTheme.cream,
                        ),
                        child: Text(
                          s.isRu ? 'Вступить' : 'Join',
                          style: BalatroTheme.statusStyle,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      s.isRu ? 'Участники' : 'Members',
                      style: BalatroTheme.titleStyle.copyWith(fontSize: 16),
                    ),
                    for (final m in (club['members'] as List? ?? const []))
                      if (m is Map)
                        ListTile(
                          title: Text(
                            '${m['username']}',
                            style: BalatroTheme.statusStyle,
                          ),
                          subtitle: Text(
                            '${m['role'] ?? ''}',
                            style: BalatroTheme.statusStyle.copyWith(
                              fontSize: 12,
                            ),
                          ),
                        ),
                  ],
                ),
    );
  }
}
