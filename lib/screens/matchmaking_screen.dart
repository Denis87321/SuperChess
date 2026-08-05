import 'dart:async';

import 'package:flutter/material.dart';

import '../online/online_game_service.dart';
import '../online/server_config.dart';
import '../online/websocket_online_service.dart';
import '../theme/balatro_theme.dart';
import 'game_screen.dart';

class MatchmakingScreen extends StatefulWidget {
  const MatchmakingScreen({super.key, this.isLocal = false});

  final bool isLocal;

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> {
  OnlineGameService? _service;
  StreamSubscription<OnlineEvent>? _subscription;
  String _status = 'Подключение...';
  late final String _serverUrl = defaultServerUrl();

  @override
  void initState() {
    super.initState();
    if (widget.isLocal) {
      _status = 'Локальная партия';
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
    _startMatchmaking();
  }

  Future<void> _startMatchmaking() async {
    _subscription = _service!.events.listen(_onEvent);
    try {
      await _service!.connect();
      await _service!.findGame();
    } catch (_) {
      if (mounted) {
        setState(() => _status = 'Не удалось подключиться к серверу');
      }
    }
  }

  void _onEvent(OnlineEvent event) {
    switch (event) {
      case OnlineSearching(:final count):
        setState(() {
          if (count == null) {
            _status = 'Поиск соперника...';
          } else if (count <= 1) {
            _status =
                'Поиск соперника...\nСейчас ищут: $count (Это Вы)';
          } else {
            _status =
                'Поиск соперника...\nСейчас ищут: $count';
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
            ),
          ),
        );
      case OnlineError():
        setState(() => _status = event.message);
      case OnlineOpponentDisconnected():
        setState(() => _status = 'Соперник отключился');
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
    if (widget.isLocal) {
      return const Scaffold(
        backgroundColor: BalatroTheme.background,
        body: Center(child: CircularProgressIndicator(color: BalatroTheme.gold)),
      );
    }

    return Scaffold(
      backgroundColor: BalatroTheme.background,
      appBar: AppBar(
        title: Text('ОНЛАЙН', style: BalatroTheme.titleStyle.copyWith(fontSize: 18)),
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
              Text(_status, textAlign: TextAlign.center, style: BalatroTheme.statusStyle),
              const SizedBox(height: 32),
              Text(
                'Сервер: $_serverUrl',
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
