import 'dart:async';

import 'package:flutter/material.dart';
import 'package:super_chess_engine/time_control.dart';

import '../auth/auth_service.dart';
import '../l10n/app_strings.dart';
import '../online/online_game_service.dart';
import '../online/server_config.dart';
import '../online/websocket_online_service.dart';
import '../theme/balatro_theme.dart';
import 'game_screen.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({
    super.key,
    required this.auth,
    this.initialTc = '5+0',
    this.initialRated = true,
  });

  final AuthService auth;
  final String initialTc;
  final bool initialRated;

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  late final WebSocketOnlineService _service;
  StreamSubscription<OnlineEvent>? _sub;
  late String _tcId;
  late bool _rated;
  var _searching = false;
  var _connecting = true;
  var _handedOff = false;
  String? _status;
  List<Map<String, dynamic>> _seeks = const [];

  @override
  void initState() {
    super.initState();
    _tcId = widget.initialTc;
    _rated = widget.initialRated && widget.auth.isLoggedIn;
    _service = WebSocketOnlineService(serverUrl: defaultServerUrl());
    _sub = _service.events.listen(_onEvent);
    _connect();
  }

  Future<void> _connect() async {
    final s = AppStrings.of(context);
    try {
      await _service.connect();
      if (!mounted) return;
      _service.subscribeLobby();
      _service.presencePing(widget.auth.token);
      setState(() {
        _connecting = false;
        _status = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _status = s.connectFailed;
      });
    }
  }

  void _onEvent(OnlineEvent event) {
    switch (event) {
      case OnlineSearching():
        setState(() {
          _searching = true;
          _status = null;
        });
      case OnlineLobbySnapshot():
        setState(() => _seeks = event.seeks);
      case OnlineMatched():
        _handedOff = true;
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
              initialClockMs: event.match.initialMs,
              incrementMs: event.match.incrementMs,
              timeControlId: event.match.timeControlId,
            ),
          ),
        );
      case OnlineError():
        setState(() {
          _searching = false;
          _status = event.message;
        });
      case OnlineConnectionLost():
        setState(() => _status = AppStrings.of(context).connectFailed);
      default:
        break;
    }
  }

  Future<void> _seek() async {
    final name = widget.auth.username ?? AppStrings.of(context).anonymous;
    setState(() => _searching = true);
    await _service.findGame(
      playerName: name,
      token: widget.auth.token,
      timeControlId: _tcId,
      rated: _rated,
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    if (!_handedOff) {
      if (_searching) _service.cancelSeek();
      _service.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: BalatroTheme.background,
      appBar: AppBar(
        title: Text(
          s.playOnline,
          style: BalatroTheme.titleStyle.copyWith(fontSize: 18),
        ),
        backgroundColor: BalatroTheme.appBar,
        foregroundColor: BalatroTheme.cream,
      ),
      body: _connecting
          ? Center(child: Text(s.connecting, style: BalatroTheme.statusStyle))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_status != null)
                    Text(
                      _status!,
                      style: BalatroTheme.statusStyle.copyWith(
                        color: Colors.redAccent,
                      ),
                    ),
                  Text(
                    s.timeControl,
                    style: BalatroTheme.titleStyle.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tc in kLobbyTimeControls)
                        ChoiceChip(
                          label: Text(tc.label),
                          selected: _tcId == tc.id,
                          onSelected: _searching
                              ? null
                              : (_) => setState(() => _tcId = tc.id),
                          selectedColor: BalatroTheme.gold,
                          labelStyle: BalatroTheme.statusStyle.copyWith(
                            color: _tcId == tc.id
                                ? BalatroTheme.ink
                                : BalatroTheme.cream,
                            fontSize: 12,
                          ),
                          backgroundColor: BalatroTheme.felt,
                        ),
                    ],
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(s.ratedGame, style: BalatroTheme.statusStyle),
                    value: _rated,
                    onChanged: !widget.auth.isLoggedIn || _searching
                        ? null
                        : (v) => setState(() => _rated = v),
                    activeThumbColor: BalatroTheme.gold,
                  ),
                  FilledButton(
                    onPressed: _searching
                        ? () {
                            _service.cancelSeek();
                            setState(() => _searching = false);
                          }
                        : _seek,
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          _searching ? Colors.redAccent : BalatroTheme.accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      _searching ? s.cancel : s.playOnline,
                      style: BalatroTheme.statusStyle,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s.openSeeks,
                    style: BalatroTheme.titleStyle.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _seeks.isEmpty
                        ? Text(
                            s.noSeeks,
                            style: BalatroTheme.statusStyle.copyWith(
                              color: BalatroTheme.cream.withValues(alpha: 0.5),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _seeks.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 6),
                            itemBuilder: (context, i) {
                              final seek = _seeks[i];
                              return ListTile(
                                tileColor: BalatroTheme.felt,
                                title: Text(
                                  '${seek['name']} · ${seek['tc']}'
                                  '${seek['rated'] == true ? ' · rated' : ''}',
                                  style: BalatroTheme.statusStyle,
                                ),
                                subtitle: Text(
                                  '${s.rating}: ${seek['rating'] ?? '—'}',
                                  style: BalatroTheme.statusStyle.copyWith(
                                    fontSize: 12,
                                    color: BalatroTheme.cream
                                        .withValues(alpha: 0.55),
                                  ),
                                ),
                                onTap: _searching
                                    ? null
                                    : () {
                                        setState(() {
                                          _tcId = '${seek['tc'] ?? _tcId}';
                                          _rated = seek['rated'] == true;
                                        });
                                        _seek();
                                      },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
