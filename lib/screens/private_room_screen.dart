import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../auth/auth_service.dart';
import '../l10n/app_strings.dart';
import '../online/online_game_service.dart';
import '../online/websocket_online_service.dart';
import '../online/server_config.dart';
import '../theme/balatro_theme.dart';
import 'game_screen.dart';
import 'spectate_screen.dart';

class PrivateRoomScreen extends StatefulWidget {
  const PrivateRoomScreen({
    super.key,
    required this.auth,
    this.initialCode,
    this.spectateOnly = false,
  });

  final AuthService auth;
  final String? initialCode;
  final bool spectateOnly;

  @override
  State<PrivateRoomScreen> createState() => _PrivateRoomScreenState();
}

class _PrivateRoomScreenState extends State<PrivateRoomScreen> {
  late final WebSocketOnlineService _service;
  StreamSubscription<OnlineEvent>? _sub;
  final _codeCtrl = TextEditingController();
  String? _hostCode;
  String? _status;
  bool _connecting = true;
  bool _handedOff = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null) {
      _codeCtrl.text = widget.initialCode!;
    }
    _service = WebSocketOnlineService(serverUrl: defaultServerUrl());
    _sub = _service.events.listen(_onEvent);
    _connect();
  }

  Future<void> _connect() async {
    final s = AppStrings.of(context);
    try {
      await _service.connect();
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _status = null;
      });
      if (widget.spectateOnly && (widget.initialCode?.isNotEmpty ?? false)) {
        _service.spectatePrivateRoom(widget.initialCode!);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _status = s.connectFailed;
      });
    }
  }

  void _onEvent(OnlineEvent event) {
    final s = AppStrings.of(context);
    switch (event) {
      case OnlinePrivateWaiting():
        setState(() => _hostCode = event.code);
      case OnlineMatched():
        _openGame(event.match);
      case OnlineSpectateOk():
        _handedOff = true;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => SpectateScreen(
              service: _service,
              payload: event,
            ),
          ),
        );
      case OnlineError():
        setState(() => _status = event.message);
      case OnlineConnectionLost():
        setState(() => _status = s.connectFailed);
      default:
        break;
    }
  }

  void _openGame(OnlineMatch match) {
    _handedOff = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(
          localColor: match.localColor,
          onlineService: _service,
          opponentName: match.opponentName,
          gameId: match.gameId,
          auth: widget.auth,
          rated: match.rated,
          yourRating: match.yourRating,
          opponentRating: match.opponentRating,
        ),
      ),
    );
  }

  String get _playerName =>
      widget.auth.username ?? AppStrings.of(context).anonymous;

  @override
  void dispose() {
    _sub?.cancel();
    if (!_handedOff) {
      if (_hostCode != null) {
        _service.cancelPrivateRoom();
      }
      _service.dispose();
    }
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: BalatroTheme.background,
      appBar: AppBar(
        title: Text(
          widget.spectateOnly ? s.spectate : s.privateRoom,
          style: BalatroTheme.titleStyle.copyWith(fontSize: 18),
        ),
        backgroundColor: BalatroTheme.appBar,
        foregroundColor: BalatroTheme.cream,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _connecting
            ? Center(child: Text(s.connecting, style: BalatroTheme.statusStyle))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_status != null) ...[
                    Text(
                      _status!,
                      style: BalatroTheme.statusStyle.copyWith(
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (!widget.spectateOnly) ...[
                    FilledButton(
                      onPressed: _hostCode != null
                          ? null
                          : () {
                              _service.createPrivateRoom(
                                playerName: _playerName,
                                token: widget.auth.token,
                              );
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: BalatroTheme.accent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(s.createRoom, style: BalatroTheme.statusStyle),
                    ),
                    if (_hostCode != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        s.waitingForOpponent,
                        style: BalatroTheme.statusStyle,
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        _hostCode!,
                        style: BalatroTheme.titleStyle.copyWith(
                          fontSize: 32,
                          letterSpacing: 6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: _hostCode!),
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(s.codeCopied)),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        label: Text(s.copyCode),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(s.joinByCode, style: BalatroTheme.titleStyle.copyWith(fontSize: 16)),
                    const SizedBox(height: 8),
                  ],
                  TextField(
                    controller: _codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    style: BalatroTheme.statusStyle,
                    decoration: InputDecoration(
                      labelText: s.roomCode,
                      labelStyle: BalatroTheme.statusStyle.copyWith(
                        color: BalatroTheme.cream.withValues(alpha: 0.6),
                      ),
                      filled: true,
                      fillColor: BalatroTheme.felt,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      final code = _codeCtrl.text.trim().toUpperCase();
                      if (code.isEmpty) return;
                      if (widget.spectateOnly) {
                        _service.spectatePrivateRoom(code);
                      } else {
                        _service.joinPrivateRoom(
                          code: code,
                          playerName: _playerName,
                          token: widget.auth.token,
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: BalatroTheme.gold,
                      foregroundColor: BalatroTheme.ink,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      widget.spectateOnly ? s.spectate : s.joinByCode,
                      style: BalatroTheme.statusStyle.copyWith(
                        color: BalatroTheme.ink,
                      ),
                    ),
                  ),
                  if (!widget.spectateOnly) ...[
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        final code = _codeCtrl.text.trim().toUpperCase();
                        if (code.isEmpty) return;
                        _service.spectatePrivateRoom(code);
                      },
                      child: Text(s.spectate, style: BalatroTheme.statusStyle),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
