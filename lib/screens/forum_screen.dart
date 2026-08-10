import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../auth/platform_api.dart';
import '../l10n/app_strings.dart';
import '../theme/balatro_theme.dart';

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key, required this.auth});

  final AuthService auth;

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  late final PlatformApi _api = PlatformApi(widget.auth);
  List<Map<String, dynamic>> _categories = const [];
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
      final cats = await _api.listForumCategories();
      if (!mounted) return;
      setState(() {
        _categories = cats;
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

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: BalatroTheme.background,
      appBar: AppBar(
        title: Text(s.forum, style: BalatroTheme.titleStyle.copyWith(fontSize: 18)),
        backgroundColor: BalatroTheme.appBar,
        foregroundColor: BalatroTheme.cream,
        actions: [
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
                if (_categories.isEmpty)
                  Text(
                    s.isRu ? 'Нет категорий' : 'No categories',
                    style: BalatroTheme.statusStyle,
                  ),
                for (final c in _categories)
                  ListTile(
                    tileColor: BalatroTheme.felt,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    title: Text(
                      '${c['title']}',
                      style: BalatroTheme.statusStyle,
                    ),
                    subtitle: Text(
                      '${c['slug'] ?? ''}',
                      style: BalatroTheme.statusStyle.copyWith(fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ForumTopicsScreen(
                            auth: widget.auth,
                            categoryId: '${c['id']}',
                            categoryTitle: '${c['title']}',
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
    );
  }
}

class ForumTopicsScreen extends StatefulWidget {
  const ForumTopicsScreen({
    super.key,
    required this.auth,
    required this.categoryId,
    required this.categoryTitle,
  });

  final AuthService auth;
  final String categoryId;
  final String categoryTitle;

  @override
  State<ForumTopicsScreen> createState() => _ForumTopicsScreenState();
}

class _ForumTopicsScreenState extends State<ForumTopicsScreen> {
  late final PlatformApi _api = PlatformApi(widget.auth);
  List<Map<String, dynamic>> _topics = const [];
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
      final topics = await _api.listForumTopics(widget.categoryId);
      if (!mounted) return;
      setState(() {
        _topics = topics;
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

  Future<void> _createTopic() async {
    final s = AppStrings.of(context);
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BalatroTheme.felt,
        title: Text(
          s.isRu ? 'Новая тема' : 'New topic',
          style: BalatroTheme.titleStyle.copyWith(fontSize: 16),
        ),
        content: TextField(
          controller: ctrl,
          style: BalatroTheme.statusStyle,
          decoration: InputDecoration(
            labelText: s.isRu ? 'Заголовок' : 'Title',
            labelStyle: BalatroTheme.statusStyle.copyWith(fontSize: 12),
          ),
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
    if (ok != true || ctrl.text.trim().isEmpty) return;
    try {
      await _api.createForumTopic(
        categoryId: widget.categoryId,
        title: ctrl.text.trim(),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: BalatroTheme.background,
      appBar: AppBar(
        title: Text(
          widget.categoryTitle,
          style: BalatroTheme.titleStyle.copyWith(fontSize: 18),
        ),
        backgroundColor: BalatroTheme.appBar,
        foregroundColor: BalatroTheme.cream,
        actions: [
          if (widget.auth.isLoggedIn)
            IconButton(onPressed: _createTopic, icon: const Icon(Icons.add)),
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
                  Text(
                    _error!,
                    style: BalatroTheme.statusStyle.copyWith(
                      color: Colors.redAccent,
                    ),
                  ),
                if (_topics.isEmpty)
                  Text(
                    s.isRu ? 'Нет тем' : 'No topics',
                    style: BalatroTheme.statusStyle,
                  ),
                for (final t in _topics)
                  ListTile(
                    tileColor: BalatroTheme.felt,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    title: Text(
                      '${t['title']}',
                      style: BalatroTheme.statusStyle,
                    ),
                    subtitle: Text(
                      '${t['authorName'] ?? ''}',
                      style: BalatroTheme.statusStyle.copyWith(fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ForumPostsScreen(
                            auth: widget.auth,
                            topicId: '${t['id']}',
                            topicTitle: '${t['title']}',
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
    );
  }
}

class ForumPostsScreen extends StatefulWidget {
  const ForumPostsScreen({
    super.key,
    required this.auth,
    required this.topicId,
    required this.topicTitle,
  });

  final AuthService auth;
  final String topicId;
  final String topicTitle;

  @override
  State<ForumPostsScreen> createState() => _ForumPostsScreenState();
}

class _ForumPostsScreenState extends State<ForumPostsScreen> {
  late final PlatformApi _api = PlatformApi(widget.auth);
  final _postCtrl = TextEditingController();
  List<Map<String, dynamic>> _posts = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _postCtrl.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final posts = await _api.listForumPosts(widget.topicId);
      if (!mounted) return;
      setState(() {
        _posts = posts;
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

  Future<void> _send() async {
    final text = _postCtrl.text.trim();
    if (text.isEmpty) return;
    try {
      await _api.createForumPost(topicId: widget.topicId, body: text);
      _postCtrl.clear();
      await _reload();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: BalatroTheme.background,
      appBar: AppBar(
        title: Text(
          widget.topicTitle,
          style: BalatroTheme.titleStyle.copyWith(fontSize: 16),
        ),
        backgroundColor: BalatroTheme.appBar,
        foregroundColor: BalatroTheme.cream,
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: BalatroTheme.gold),
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
                      if (_posts.isEmpty)
                        Text(s.chatEmpty, style: BalatroTheme.statusStyle),
                      for (final p in _posts)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: BalatroTheme.felt,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${p['authorName'] ?? ''}',
                                  style: BalatroTheme.statusStyle.copyWith(
                                    fontSize: 12,
                                    color: BalatroTheme.gold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${p['body']}',
                                  style: BalatroTheme.statusStyle.copyWith(
                                    fontSize: 14,
                                    color: BalatroTheme.cream,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          if (widget.auth.isLoggedIn)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _postCtrl,
                        style: BalatroTheme.statusStyle,
                        decoration: InputDecoration(
                          hintText: s.messageHint,
                          filled: true,
                          fillColor: BalatroTheme.felt,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _send,
                      icon: const Icon(Icons.send, color: BalatroTheme.gold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
