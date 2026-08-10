import 'dart:convert';

import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../auth/platform_api.dart';
import '../l10n/app_strings.dart';
import '../l10n/models/ability_l10n.dart';
import '../puzzles/puzzle_loader.dart';
import '../puzzles/puzzle_models.dart';
import '../theme/balatro_theme.dart';
import 'puzzle_game_screen.dart';

class PuzzleListScreen extends StatefulWidget {
  const PuzzleListScreen({super.key, this.auth});

  final AuthService? auth;

  @override
  State<PuzzleListScreen> createState() => _PuzzleListScreenState();
}

class _PuzzleListScreenState extends State<PuzzleListScreen> {
  List<PuzzleDefinition> _puzzles = const [];
  int? _puzzleRating;
  bool _loading = true;
  String? _sourceNote;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final auth = widget.auth;
    final local = await loadPuzzlePack();
    var puzzles = List<PuzzleDefinition>.from(local);
    var note = 'local';
    int? rating;

    if (auth != null && auth.isLoggedIn) {
      final api = PlatformApi(auth);
      try {
        final me = await api.myPuzzleRating();
        rating = (me['rating'] as num?)?.toInt();
      } catch (_) {}

      try {
        final remote = await api.nextPuzzle();
        final parsed = puzzleFromApi(remote);
        if (parsed != null) {
          puzzles = [
            parsed,
            ...local.where((p) => p.id != parsed.id),
          ];
          note = 'API';
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _puzzles = puzzles;
      _puzzleRating = rating;
      _sourceNote = note;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: BalatroTheme.background,
      appBar: AppBar(
        title: Text(
          s.puzzles,
          style: BalatroTheme.titleStyle.copyWith(fontSize: 18),
        ),
        backgroundColor: BalatroTheme.appBar,
        foregroundColor: BalatroTheme.cream,
        actions: [
          if (_puzzleRating != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  '${s.rating}: $_puzzleRating',
                  style: BalatroTheme.statusStyle.copyWith(fontSize: 12),
                ),
              ),
            ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _puzzles.isEmpty
              ? Center(
                  child: Text(s.puzzleFailed, style: BalatroTheme.statusStyle),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _puzzles.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return Text(
                        _sourceNote == 'API'
                            ? (s.isRu
                                ? 'Серверная задача + локальный набор'
                                : 'Server puzzle + local pack')
                            : (s.isRu
                                ? 'Локальный набор задач'
                                : 'Local puzzle pack'),
                        style: BalatroTheme.statusStyle.copyWith(
                          fontSize: 12,
                          color: BalatroTheme.cream.withValues(alpha: 0.55),
                        ),
                      );
                    }
                    final p = _puzzles[i - 1];
                    final locale = Localizations.localeOf(context);
                    final hint = p.hintAbility?.titleFor(locale);
                    return ListTile(
                      tileColor: BalatroTheme.felt,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      title: Text(
                        p.titleFor(s.isRu),
                        style: BalatroTheme.statusStyle.copyWith(fontSize: 15),
                      ),
                      subtitle: hint == null
                          ? null
                          : Text(
                              hint,
                              style: BalatroTheme.statusStyle.copyWith(
                                fontSize: 12,
                                color:
                                    BalatroTheme.cream.withValues(alpha: 0.55),
                              ),
                            ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: BalatroTheme.cream,
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => PuzzleGameScreen(puzzle: p),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}

/// Converts `/puzzles/next` payload into a [PuzzleDefinition].
/// Server stores the full asset JSON in `setup`.
PuzzleDefinition? puzzleFromApi(Map<String, dynamic> remote) {
  try {
    Map<String, dynamic>? setupMap;
    final setup = remote['setup'];
    if (setup is Map) {
      setupMap = Map<String, dynamic>.from(setup);
    } else if (setup is String && setup.trim().isNotEmpty) {
      final decoded = jsonDecode(setup);
      if (decoded is Map) {
        setupMap = Map<String, dynamic>.from(decoded);
      }
    }

    final json = <String, dynamic>{
      ...?setupMap,
      'id': setupMap?['id'] ?? remote['id'],
      'titleRu': setupMap?['titleRu'] ?? remote['titleRu'] ?? remote['id'],
      'titleEn': setupMap?['titleEn'] ?? remote['titleEn'] ?? remote['id'],
      'goal': setupMap?['goal'] ?? remote['goal'] ?? 'checkmate',
    };
    if (json['id'] == null || json['pieces'] == null) return null;
    return PuzzleDefinition.fromJson(json);
  } catch (_) {
    return null;
  }
}
