import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../auth/platform_api.dart';
import '../l10n/app_strings.dart';
import '../theme/balatro_theme.dart';

class PublicProfileScreen extends StatefulWidget {
  const PublicProfileScreen({
    super.key,
    required this.auth,
    required this.username,
  });

  final AuthService auth;
  final String username;

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  late final PlatformApi _api = PlatformApi(widget.auth);
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _following = false;
  bool _followBusy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _api.getProfile(widget.username);
      var following = false;
      final myId = widget.auth.userId;
      final theirId = '${profile['id'] ?? ''}';
      if (myId != null &&
          theirId.isNotEmpty &&
          myId != theirId &&
          widget.auth.isLoggedIn) {
        final list = await _api.listFollowing(myId);
        following = list.any((u) => '${u['id']}' == theirId);
      }
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _following = following;
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

  Future<void> _toggleFollow() async {
    final id = '${_profile?['id'] ?? ''}';
    if (id.isEmpty || !widget.auth.isLoggedIn) return;
    setState(() => _followBusy = true);
    try {
      if (_following) {
        await _api.unfollow(id);
      } else {
        await _api.follow(id);
      }
      if (!mounted) return;
      setState(() {
        _following = !_following;
        _followBusy = false;
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _followBusy = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isSelf = widget.auth.username != null &&
        widget.auth.username!.toLowerCase() == widget.username.toLowerCase();

    return Scaffold(
      backgroundColor: BalatroTheme.background,
      appBar: AppBar(
        title: Text(
          widget.username,
          style: BalatroTheme.titleStyle.copyWith(fontSize: 18),
        ),
        backgroundColor: BalatroTheme.appBar,
        foregroundColor: BalatroTheme.cream,
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: BalatroTheme.gold),
            )
          : _error != null && _profile == null
              ? Center(
                  child: Text(
                    _error!,
                    style: BalatroTheme.statusStyle.copyWith(
                      color: Colors.redAccent,
                    ),
                  ),
                )
              : _buildBody(s, isSelf),
    );
  }

  Widget _buildBody(AppStrings s, bool isSelf) {
    final p = _profile!;
    final online = p['online'] == true;
    final bio = '${p['bio'] ?? ''}'.trim();
    final ratings = p['ratings'];
    final ratingMap = <String, int>{};
    if (ratings is Map) {
      for (final e in ratings.entries) {
        ratingMap['${e.key}'] = (e.value as num?)?.toInt() ?? 1500;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _error!,
              style: BalatroTheme.statusStyle.copyWith(color: Colors.redAccent),
            ),
          ),
        Text(
          '${p['username'] ?? widget.username}',
          style: BalatroTheme.titleStyle.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 6),
        Text(
          online ? s.onlineNow : s.offline,
          style: BalatroTheme.statusStyle.copyWith(
            fontSize: 13,
            color: online
                ? const Color(0xFF6BCB77)
                : BalatroTheme.cream.withValues(alpha: 0.5),
          ),
        ),
        if (bio.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(s.bio, style: BalatroTheme.titleStyle.copyWith(fontSize: 14)),
          const SizedBox(height: 6),
          Text(
            bio,
            style: BalatroTheme.statusStyle.copyWith(
              fontSize: 14,
              color: BalatroTheme.cream.withValues(alpha: 0.85),
            ),
          ),
        ],
        if (!isSelf && widget.auth.isLoggedIn) ...[
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _followBusy ? null : _toggleFollow,
            style: FilledButton.styleFrom(
              backgroundColor: BalatroTheme.accent,
              foregroundColor: BalatroTheme.cream,
            ),
            child: Text(
              _following ? s.unfollow : s.follow,
              style: BalatroTheme.statusStyle,
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text(s.rating, style: BalatroTheme.titleStyle.copyWith(fontSize: 16)),
        const SizedBox(height: 8),
        if (ratingMap.isEmpty)
          Text('—', style: BalatroTheme.statusStyle)
        else
          for (final e in ratingMap.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _statRow(e.key, '${e.value}'),
            ),
        const SizedBox(height: 12),
        Text(
          s.isRu ? 'Статистика' : 'Stats',
          style: BalatroTheme.titleStyle.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 8),
        _statRow(s.gamesPlayed, '${p['gamesPlayed'] ?? 0}'),
        const SizedBox(height: 8),
        _statRow(
          s.isRu ? 'Подписчики' : 'Followers',
          '${p['followers'] ?? 0}',
        ),
        const SizedBox(height: 8),
        _statRow(
          s.isRu ? 'Подписки' : 'Following',
          '${p['following'] ?? 0}',
        ),
        if (p['country'] != null && '${p['country']}'.isNotEmpty) ...[
          const SizedBox(height: 8),
          _statRow(
            s.isRu ? 'Страна' : 'Country',
            '${p['country']}',
          ),
        ],
      ],
    );
  }

  Widget _statRow(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: BalatroTheme.felt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: BalatroTheme.statusStyle.copyWith(fontSize: 13),
            ),
          ),
          Text(
            value,
            style: BalatroTheme.titleStyle.copyWith(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
