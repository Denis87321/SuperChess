import 'dart:async';

import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../l10n/app_strings.dart';
import '../online/online_game_service.dart';
import '../online/server_config.dart';
import '../online/websocket_online_service.dart';
import '../theme/balatro_theme.dart';
import 'game_screen.dart';

class MatchmakingScreen extends StatefulWidget {
  const MatchmakingScreen({
    super.key,
    this.isLocal = false,
    this.playerName,
    this.auth,
  });

  final bool isLocal;
  final String? playerName;
  final AuthService? auth;

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> {
  OnlineGameService? _service;
  StreamSubscription<OnlineEvent>? _subscription;
  late String _status;
  late final String _serverUrl = defaultServerUrl();

  @override
  void initState() {
    super.initState();
    _status = '';
    if (widget.isLocal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => const GameScreen(localColor: null),
          ),
        );
      });
      return;
    }
    _service = WebSocketOnlineService(serverUrl: _serverUrl);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _status = AppStrings.of(context).connecting);
      _startMatchmaking();
    });
  }

  Future<void> _startMatchmaking() async {
    final s = AppStrings.of(context);
    _subscription = _service!.events.listen(_onEvent);
    try {
      await _service!.connect();
      await _service!.findGame(
        playerName: widget.playerName ?? s.anonymous,
        token: widget.auth?.token,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _status = s.connectFailed);
      }
    }
  }

  void _onEvent(OnlineEvent event) {
    final s = AppStrings.of(context);
    switch (event) {
      case OnlineSearching(:final count):
        setState(() {
          if (count == null) {
            _status = s.searching;
          } else {
            _status = s.searchingCount(count, onlyYou: count <= 1);
          }
        });
      case OnlineMatched():
        _subscription?.cancel();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => GameScreen(
              localColor: event.match.localColor,
              onlineService: _service,
              opponentName: event.match.opponentName,
              gameId: event.match.gameId,
              auth: widget.auth,
              rated: event.match.rated,
              yourRating: event.match.yourRating,
              opponentRating: event.match.opponentRating,
            ),
          ),
        );
      case OnlineError():
        setState(() => _status = event.message);
      case OnlineConnectionLost():
        setState(() => _status = 'Потеря связи…');
      case OnlineOpponentLeft():
        setState(() => _status = s.opponentLeft);
      default:
        break;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    if (widget.isLocal) {
      return const Scaffold(
        backgroundColor: BalatroTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: BalatroTheme.gold),
        ),
      );
    }

    return Scaffold(
      backgroundColor: BalatroTheme.background,
      appBar: AppBar(
        title: Text(s.online, style: BalatroTheme.titleStyle.copyWith(fontSize: 18)),
        backgroundColor: BalatroTheme.appBar,
        foregroundColor: BalatroTheme.cream,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: BalatroTheme.gold),
              const SizedBox(height: 24),
              Text(
                _status.isEmpty ? s.connecting : _status,
                textAlign: TextAlign.center,
                style: BalatroTheme.statusStyle,
              ),
              const SizedBox(height: 32),
              Text(
                '${s.serverLabel}: $_serverUrl',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: BalatroTheme.cream.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
