import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../auth/platform_api.dart';
import '../l10n/app_strings.dart';
import '../theme/balatro_theme.dart';
import 'private_room_screen.dart';
import 'public_profile_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key, required this.auth});

  final AuthService auth;

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final PlatformApi _api = PlatformApi(widget.auth);

  FriendsBundle _bundle = FriendsBundle.empty;
  final _searchCtrl = TextEditingController();
  List<FriendUser> _search = const [];
  String? _error;
  bool _loading = true;

  List<Map<String, dynamic>> _following = const [];
  bool _followingLoading = false;

  FriendUser? _chatPeer;
  List<Map<String, dynamic>> _messages = const [];
  final _msgCtrl = TextEditingController();
  bool _messagesLoading = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (_tabs.indexIsChanging) return;
      if (_tabs.index == 2) _loadFollowing();
    });
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bundle = await widget.auth.fetchFriends();
      if (!mounted) return;
      setState(() {
        _bundle = bundle;
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

  Future<void> _loadFollowing() async {
    final id = widget.auth.userId;
    if (id == null) return;
    setState(() => _followingLoading = true);
    try {
      final list = await _api.listFollowing(id);
      if (!mounted) return;
      setState(() {
        _following = list;
        _followingLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _followingLoading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _openChat(FriendUser peer) async {
    setState(() {
      _chatPeer = peer;
      _messagesLoading = true;
      _messages = const [];
    });
    try {
      final msgs = await _api.listMessages(peer.id);
      if (!mounted) return;
      setState(() {
        _messages = msgs.reversed.toList();
        _messagesLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messagesLoading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _sendMessage() async {
    final peer = _chatPeer;
    final text = _msgCtrl.text.trim();
    if (peer == null || text.isEmpty) return;
    try {
      await _api.sendMessage(peer.id, text);
      _msgCtrl.clear();
      await _openChat(peer);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  Future<void> _runSearch(String q) async {
    if (q.trim().length < 2) {
      setState(() => _search = const []);
      return;
    }
    try {
      final users = await widget.auth.searchUsers(q.trim());
      if (!mounted) return;
      setState(() => _search = users);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    if (!widget.auth.isLoggedIn) {
      return Scaffold(
        backgroundColor: BalatroTheme.background,
        appBar: AppBar(
          title: Text(s.friends, style: BalatroTheme.titleStyle.copyWith(fontSize: 18)),
          backgroundColor: BalatroTheme.appBar,
          foregroundColor: BalatroTheme.cream,
        ),
        body: Center(
          child: Text(s.loginRequired, style: BalatroTheme.statusStyle),
        ),
      );
    }

    return Scaffold(
      backgroundColor: BalatroTheme.background,
      appBar: AppBar(
        title: Text(s.friends, style: BalatroTheme.titleStyle.copyWith(fontSize: 18)),
        backgroundColor: BalatroTheme.appBar,
        foregroundColor: BalatroTheme.cream,
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: BalatroTheme.gold,
          unselectedLabelColor: BalatroTheme.cream.withValues(alpha: 0.55),
          indicatorColor: BalatroTheme.gold,
          tabs: [
            Tab(text: s.friends),
            Tab(text: s.messages),
            Tab(text: s.isRu ? 'Подписки' : 'Following'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _friendsTab(s),
          _messagesTab(s),
          _followingTab(s),
        ],
      ),
    );
  }

  Widget _friendsTab(AppStrings s) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
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
        TextField(
          controller: _searchCtrl,
          style: BalatroTheme.statusStyle,
          decoration: InputDecoration(
            labelText: s.searchPlayers,
            filled: true,
            fillColor: BalatroTheme.felt,
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _runSearch(_searchCtrl.text),
            ),
          ),
          onSubmitted: _runSearch,
        ),
        if (_search.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final u in _search)
            ListTile(
              title: Text(u.username, style: BalatroTheme.statusStyle),
              subtitle: Text(
                '${s.rating}: ${u.rating}',
                style: BalatroTheme.statusStyle.copyWith(fontSize: 12),
              ),
              trailing: TextButton(
                onPressed: () async {
                  try {
                    await widget.auth.requestFriend(u.username);
                    await _reload();
                  } catch (e) {
                    setState(() => _error = '$e');
                  }
                },
                child: Text(s.addFriend),
              ),
            ),
        ],
        if (_bundle.incoming.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            s.incomingRequests,
            style: BalatroTheme.titleStyle.copyWith(fontSize: 16),
          ),
          for (final u in _bundle.incoming)
            ListTile(
              title: Text(u.username, style: BalatroTheme.statusStyle),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () async {
                      await widget.auth.respondFriend(
                        userId: u.id,
                        accept: true,
                      );
                      await _reload();
                    },
                    child: Text(s.accept),
                  ),
                  TextButton(
                    onPressed: () async {
                      await widget.auth.respondFriend(
                        userId: u.id,
                        accept: false,
                      );
                      await _reload();
                    },
                    child: Text(s.decline),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: 20),
        Text(
          s.friends,
          style: BalatroTheme.titleStyle.copyWith(fontSize: 16),
        ),
        if (_bundle.friends.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(s.noFriends, style: BalatroTheme.statusStyle),
          ),
        for (final u in _bundle.friends)
          ListTile(
            title: Text(u.username, style: BalatroTheme.statusStyle),
            subtitle: Text(
              '${s.rating}: ${u.rating}',
              style: BalatroTheme.statusStyle.copyWith(fontSize: 12),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PublicProfileScreen(
                    auth: widget.auth,
                    username: u.username,
                  ),
                ),
              );
            },
            trailing: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PrivateRoomScreen(auth: widget.auth),
                  ),
                );
              },
              child: Text(s.challenge),
            ),
          ),
        if (_bundle.outgoing.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            s.outgoingRequests,
            style: BalatroTheme.titleStyle.copyWith(fontSize: 16),
          ),
          for (final u in _bundle.outgoing)
            ListTile(
              title: Text(u.username, style: BalatroTheme.statusStyle),
              subtitle: Text(
                s.outgoingRequests,
                style: BalatroTheme.statusStyle.copyWith(fontSize: 12),
              ),
            ),
        ],
      ],
    );
  }

  Widget _messagesTab(AppStrings s) {
    if (_chatPeer == null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            s.isRu ? 'Выберите друга' : 'Pick a friend',
            style: BalatroTheme.titleStyle.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (_bundle.friends.isEmpty)
            Text(s.noFriends, style: BalatroTheme.statusStyle),
          for (final u in _bundle.friends)
            ListTile(
              title: Text(u.username, style: BalatroTheme.statusStyle),
              trailing: const Icon(Icons.chat_bubble_outline,
                  color: BalatroTheme.cream),
              onTap: () => _openChat(u),
            ),
        ],
      );
    }

    return Column(
      children: [
        ListTile(
          title: Text(_chatPeer!.username, style: BalatroTheme.statusStyle),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: BalatroTheme.cream),
            onPressed: () => setState(() => _chatPeer = null),
          ),
        ),
        Expanded(
          child: _messagesLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length,
                  itemBuilder: (context, i) {
                    final m = _messages[i];
                    final mine = '${m['fromId']}' == widget.auth.userId;
                    return Align(
                      alignment:
                          mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: mine
                              ? BalatroTheme.accent.withValues(alpha: 0.35)
                              : BalatroTheme.felt,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${m['body']}',
                          style: BalatroTheme.statusStyle.copyWith(
                            fontSize: 14,
                            color: BalatroTheme.cream,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    style: BalatroTheme.statusStyle,
                    decoration: InputDecoration(
                      hintText: s.messageHint,
                      filled: true,
                      fillColor: BalatroTheme.felt,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send, color: BalatroTheme.gold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _followingTab(AppStrings s) {
    if (_followingLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_following.isEmpty) {
      return Center(
        child: Text(
          s.isRu ? 'Пока нет подписок' : 'Not following anyone',
          style: BalatroTheme.statusStyle,
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _following.length,
      itemBuilder: (context, i) {
        final u = _following[i];
        return ListTile(
          tileColor: BalatroTheme.felt,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: Text('${u['username']}', style: BalatroTheme.statusStyle),
          subtitle: Text(
            '${s.rating}: ${u['rating'] ?? 1500}',
            style: BalatroTheme.statusStyle.copyWith(fontSize: 12),
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PublicProfileScreen(
                  auth: widget.auth,
                  username: '${u['username']}',
                ),
              ),
            );
          },
          trailing: TextButton(
            onPressed: () async {
              try {
                await _api.unfollow('${u['id']}');
                await _loadFollowing();
              } catch (e) {
                setState(() => _error = '$e');
              }
            },
            child: Text(s.unfollow),
          ),
        );
      },
    );
  }
}
