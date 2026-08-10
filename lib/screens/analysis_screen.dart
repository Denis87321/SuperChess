import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../auth/platform_api.dart';
import '../l10n/app_strings.dart';
import '../theme/balatro_theme.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({
    super.key,
    required this.auth,
    required this.gameId,
  });

  final AuthService auth;
  final String gameId;

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  late final PlatformApi _api = PlatformApi(widget.auth);
  Map<String, dynamic>? _data;
  bool _loading = true;
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
      final data = await _api.getAnalysis(widget.gameId);
      if (!mounted) return;
      setState(() {
        _data = data;
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

  Future<void> _request() async {
    try {
      await _api.requestAnalysis(widget.gameId);
      await Future<void>.delayed(const Duration(seconds: 2));
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  List<Map<String, dynamic>> _evals(Map<String, dynamic> data) {
    final analysis = data['analysis'];
    if (analysis is Map) {
      final evals = analysis['evals'];
      if (evals is List) {
        return [
          for (final e in evals)
            if (e is Map) Map<String, dynamic>.from(e),
        ];
      }
    }
    return const [];
  }

  Color _judgmentColor(String? j) {
    switch (j) {
      case 'best':
        return Colors.greenAccent;
      case 'inaccuracy':
        return Colors.orangeAccent;
      default:
        return BalatroTheme.cream.withValues(alpha: 0.7);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final status = '${_data?['status'] ?? _data?['jobStatus'] ?? '—'}';
    final evals = _data == null ? const <Map<String, dynamic>>[] : _evals(_data!);
    final note = _data?['analysis'] is Map
        ? '${(_data!['analysis'] as Map)['note'] ?? ''}'
        : '';

    return Scaffold(
      backgroundColor: BalatroTheme.background,
      appBar: AppBar(
        title: Text(
          s.analysis,
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
                Text(
                  'ID: ${widget.gameId}',
                  style: BalatroTheme.statusStyle.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  '${s.isRu ? 'Статус' : 'Status'}: $status',
                  style: BalatroTheme.titleStyle.copyWith(fontSize: 16),
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    note,
                    style: BalatroTheme.statusStyle.copyWith(
                      fontSize: 12,
                      color: BalatroTheme.cream.withValues(alpha: 0.55),
                    ),
                  ),
                ],
                if (widget.auth.isLoggedIn) ...[
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _request,
                    style: FilledButton.styleFrom(
                      backgroundColor: BalatroTheme.accent,
                      foregroundColor: BalatroTheme.cream,
                    ),
                    child: Text(
                      s.isRu ? 'Запросить анализ' : 'Request analysis',
                      style: BalatroTheme.statusStyle,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  s.isRu ? 'Ходы' : 'Moves',
                  style: BalatroTheme.titleStyle.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (evals.isEmpty)
                  Text('—', style: BalatroTheme.statusStyle)
                else
                  for (final e in evals)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 48,
                            child: Text(
                              '#${e['ply'] ?? '?'}',
                              style: BalatroTheme.statusStyle.copyWith(
                                fontSize: 13,
                                color: BalatroTheme.gold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              [
                                if (e['played'] != null) 'played ${e['played']}',
                                if (e['best'] != null) 'best ${e['best']}',
                                if (e['judgment'] != null) '${e['judgment']}',
                              ].join(' · '),
                              style: BalatroTheme.statusStyle.copyWith(
                                fontSize: 13,
                                color: _judgmentColor(e['judgment'] as String?),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
    );
  }
}
