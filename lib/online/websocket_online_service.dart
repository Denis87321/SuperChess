import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../chess/move.dart';
import '../chess/move_codec.dart';
import '../l10n/models/game_ability.dart';
import '../l10n/models/piece.dart';
import '../l10n/models/square.dart';
import 'online_game_service.dart';

const _prefsGameId = 'online_resume_gameId';
const _prefsToken = 'online_resume_token';
const _prefsColor = 'online_resume_color';
const _prefsOpponent = 'online_resume_opponent';

class WebSocketOnlineService implements OnlineGameService {
  WebSocketOnlineService({required this.serverUrl});

  final String serverUrl;
  final _events = StreamController<OnlineEvent>.broadcast();
  WebSocketChannel? _channel;
  StreamSubscription? _socketSub;
  String? _gameId;
  String? _resumeToken;
  PieceColor? _localColor;
  String? _opponentName;

  bool _intentionalClose = false;
  bool _disposed = false;
  bool _reconnecting = false;
  int _reconnectAttempt = 0;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  DateTime? _lastPongAt;

  @override
  Stream<OnlineEvent> get events => _events.stream;

  String? get gameId => _gameId;
  String? get resumeToken => _resumeToken;

  @override
  Future<void> connect() async {
    await _openSocket(resumeAfterConnect: false);
  }

  Future<void> _openSocket({required bool resumeAfterConnect}) async {
    await _socketSub?.cancel();
    _socketSub = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = WebSocketChannel.connect(Uri.parse(serverUrl));
    _intentionalClose = false;
    _lastPongAt = DateTime.now();
    _socketSub = _channel!.stream.listen(
      _onMessage,
      onError: (_) => _handleSocketLost(),
      onDone: _handleSocketLost,
      cancelOnError: true,
    );
    _startHeartbeat();
    if (resumeAfterConnect &&
        _gameId != null &&
        _resumeToken != null &&
        _resumeToken!.isNotEmpty) {
      _send({
        'type': 'resume_game',
        'gameId': _gameId,
        'resumeToken': _resumeToken,
      });
    }
  }

  void _handleSocketLost() {
    if (_disposed || _intentionalClose) return;
    _stopHeartbeat();
    if (_gameId != null &&
        _resumeToken != null &&
        _resumeToken!.isNotEmpty) {
      if (!_reconnecting) {
        _events.add(OnlineConnectionLost());
      }
      _scheduleReconnect();
      return;
    }
    _events.add(OnlineConnectionLost());
  }

  void _scheduleReconnect() {
    if (_disposed || _intentionalClose || _reconnecting) return;
    _reconnecting = true;
    _reconnectTimer?.cancel();
    final delayMs = (500 * (1 << _reconnectAttempt.clamp(0, 3)))
        .clamp(500, 5000);
    _reconnectAttempt++;
    _reconnectTimer = Timer(Duration(milliseconds: delayMs), () async {
      if (_disposed || _intentionalClose) return;
      try {
        await _openSocket(resumeAfterConnect: true);
        _reconnecting = false;
      } catch (_) {
        _reconnecting = false;
        _scheduleReconnect();
      }
    });
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    _lastPongAt = DateTime.now();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_disposed || _intentionalClose) return;
      final last = _lastPongAt;
      if (last != null &&
          DateTime.now().difference(last) > const Duration(seconds: 45)) {
        try {
          _channel?.sink.close();
        } catch (_) {}
        _handleSocketLost();
        return;
      }
      _send({'type': 'ping', 't': DateTime.now().millisecondsSinceEpoch});
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> _persistResume() async {
    if (_gameId == null || _resumeToken == null || _localColor == null) {
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsGameId, _gameId!);
      await prefs.setString(_prefsToken, _resumeToken!);
      await prefs.setString(
        _prefsColor,
        _localColor == PieceColor.white ? 'white' : 'black',
      );
      await prefs.setString(_prefsOpponent, _opponentName ?? 'Соперник');
    } catch (_) {
      // Tests / early startup may lack a bindings instance.
    }
  }

  @override
  Future<void> clearResumeSession() async {
    _gameId = null;
    _resumeToken = null;
    _localColor = null;
    _opponentName = null;
    _reconnectAttempt = 0;
    _reconnectTimer?.cancel();
    _reconnecting = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsGameId);
      await prefs.remove(_prefsToken);
      await prefs.remove(_prefsColor);
      await prefs.remove(_prefsOpponent);
    } catch (_) {}
  }

  void _rememberMatch(OnlineMatch match) {
    _gameId = match.gameId;
    _resumeToken = match.resumeToken;
    _localColor = match.localColor;
    _opponentName = match.opponentName;
    _reconnectAttempt = 0;
    unawaited(_persistResume());
  }

  OnlineMatch _matchFromPayload(Map<String, dynamic> data) {
    return OnlineMatch(
      gameId: data['gameId'] as String,
      localColor: data['color'] == 'white'
          ? PieceColor.white
          : PieceColor.black,
      opponentName: data['opponentName'] as String? ?? 'Соперник',
      resumeToken: data['resumeToken'] as String?,
      rated: data['rated'] == true,
      yourRating: data['yourRating'] as int?,
      opponentRating: data['opponentRating'] as int?,
      opponentLoggedIn: data['opponentLoggedIn'] == true,
      timeControlId: data['tc'] as String? ?? '5+0',
      initialMs: data['initialMs'] as int? ?? 300000,
      incrementMs: data['incrementMs'] as int? ?? 0,
    );
  }

  @override
  Future<void> findGame({
    String playerName = 'Player',
    String? token,
    String timeControlId = '5+0',
    bool? rated,
  }) async {
    _send({
      'type': 'seek',
      'name': playerName,
      'tc': timeControlId,
      if (rated != null) 'rated': rated,
      if (token != null && token.isNotEmpty) 'token': token,
    });
  }

  @override
  void cancelSeek() => _send({'type': 'cancel_seek'});

  @override
  void subscribeLobby() => _send({'type': 'lobby_subscribe'});

  @override
  void requeue({
    String playerName = 'Player',
    String? token,
    String timeControlId = '5+0',
    bool? rated,
  }) {
    _send({
      'type': 'requeue',
      'name': playerName,
      'tc': timeControlId,
      if (rated != null) 'rated': rated,
      if (token != null && token.isNotEmpty) 'token': token,
    });
  }

  @override
  void presencePing(String? token) {
    if (token == null || token.isEmpty) return;
    _send({'type': 'presence_ping', 'token': token});
  }

  @override
  void sendDm({required String toUserId, required String body}) {
    _send({'type': 'dm', 'toUserId': toUserId, 'body': body});
  }

  @override
  void createPrivateRoom({String playerName = 'Player', String? token}) {
    _send({
      'type': 'create_private',
      'name': playerName,
      if (token != null && token.isNotEmpty) 'token': token,
    });
  }

  @override
  void joinPrivateRoom({
    required String code,
    String playerName = 'Player',
    String? token,
  }) {
    _send({
      'type': 'join_private',
      'code': code,
      'name': playerName,
      if (token != null && token.isNotEmpty) 'token': token,
    });
  }

  @override
  void cancelPrivateRoom() {
    _send({'type': 'cancel_private'});
  }

  @override
  void spectatePrivateRoom(String code) {
    _send({'type': 'spectate_private', 'code': code});
  }

  @override
  void leaveSpectate({String? gameId}) {
    _send({
      'type': 'leave_spectate',
      if (gameId != null) 'gameId': gameId,
    });
  }

  @override
  void sendStartAbility(
    PieceColor color,
    GameAbility ability, {
    int? lavaRank,
    AbilityOffer? offer,
  }) {
    _send({
      'type': 'start_ability',
      'gameId': _gameId,
      'color': color == PieceColor.white ? 'white' : 'black',
      'ability': gameAbilityToJson(ability),
      'lavaRank': lavaRank ?? offer?.lavaRank,
      'offer': ?offer?.toJson(),
    });
  }

  @override
  void sendMove(Move move, {int? whiteMs, int? blackMs}) {
    _send({
      'type': 'move',
      'gameId': _gameId,
      'move': MoveCodec.toJson(move),
      if (whiteMs != null) 'whiteMs': whiteMs,
      if (blackMs != null) 'blackMs': blackMs,
    });
  }

  @override
  void sendAbility(
    GameAbility ability, {
    AbilityOffer? offer,
    String? stateHash,
  }) {
    _send({
      'type': 'ability',
      'gameId': _gameId,
      'ability': gameAbilityToJson(ability),
      'offer': ?offer?.toJson(),
      'stateHash': ?stateHash,
    });
  }

  @override
  void sendAbilityTarget({
    String? pieceId,
    Square? square,
    int index = 0,
    GameAbility? removeAbility,
    String? stateHash,
  }) {
    final squareJson =
        square == null ? null : {'f': square.file, 'r': square.rank};
    final removeJson =
        removeAbility == null ? null : gameAbilityToJson(removeAbility);
    _send({
      'type': 'ability_target',
      'gameId': _gameId,
      'pieceId': ?pieceId,
      'square': ?squareJson,
      'index': index,
      'removeAbility': ?removeJson,
      'stateHash': ?stateHash,
    });
  }

  @override
  void sendReaction({
    required bool accepted,
    GameAbility? ability,
    String? stateHash,
  }) {
    final abilityJson =
        ability == null ? null : gameAbilityToJson(ability);
    _send({
      'type': 'reaction',
      'gameId': _gameId,
      'accepted': accepted,
      'ability': ?abilityJson,
      'stateHash': ?stateHash,
    });
  }

  @override
  void sendReroll(PieceColor color, {String? stateHash}) {
    _send({
      'type': 'reroll',
      'gameId': _gameId,
      'color': color == PieceColor.white ? 'white' : 'black',
      'stateHash': ?stateHash,
    });
  }

  @override
  void sendSkipTurn({String? stateHash}) {
    _send({
      'type': 'skip_turn',
      'gameId': _gameId,
      'stateHash': ?stateHash,
    });
  }

  @override
  void sendGameOver({
    PieceColor? winner,
    String? reason,
    String? detail,
    String? stateHash,
  }) {
    final winnerJson = winner == null
        ? null
        : (winner == PieceColor.white ? 'white' : 'black');
    _send({
      'type': 'game_over',
      'gameId': _gameId,
      'winner': winnerJson,
      'reason': ?reason,
      'detail': ?detail,
      'stateHash': ?stateHash,
    });
  }

  @override
  void sendRematchOffer() {
    _send({'type': 'rematch_offer', 'gameId': _gameId});
  }

  @override
  void sendRematchAccept() {
    _send({'type': 'rematch_accept', 'gameId': _gameId});
  }

  @override
  void sendChat(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _send({'type': 'chat', 'gameId': _gameId, 'text': trimmed});
  }

  @override
  void sendResign() {
    _send({'type': 'resign', 'gameId': _gameId});
  }

  @override
  void sendDrawOffer() {
    _send({'type': 'draw_offer', 'gameId': _gameId});
  }

  @override
  void sendDrawResponse({required bool accepted}) {
    _send({
      'type': 'draw_response',
      'gameId': _gameId,
      'accepted': accepted,
    });
  }

  @override
  void sendTakebackOffer() {
    _send({'type': 'takeback_offer', 'gameId': _gameId});
  }

  @override
  void sendTakebackResponse({required bool accepted}) {
    _send({
      'type': 'takeback_response',
      'gameId': _gameId,
      'accepted': accepted,
    });
  }

  @override
  void sendClockSync({required int whiteMs, required int blackMs}) {
    _send({
      'type': 'clock_sync',
      'gameId': _gameId,
      'whiteMs': whiteMs,
      'blackMs': blackMs,
    });
  }

  @override
  void sendLeaveGame() {
    if (_gameId != null) {
      _send({'type': 'leave_game', 'gameId': _gameId});
    }
    unawaited(clearResumeSession());
  }

  void _send(Map<String, dynamic> message) {
    try {
      _channel?.sink.add(jsonEncode(message));
    } catch (_) {}
  }

  bool _inGame(Map<String, dynamic> data) => data['gameId'] == _gameId;

  void _onMessage(dynamic raw) {
    final data = jsonDecode(raw as String) as Map<String, dynamic>;
    switch (data['type'] as String) {
      case 'pong':
        _lastPongAt = DateTime.now();
      case 'queue_size':
      case 'searching':
        _events.add(
          OnlineSearching(count: data['count'] as int? ?? 0),
        );
      case 'lobby_snapshot':
        final rawSeeks = data['seeks'];
        final seeks = <Map<String, dynamic>>[];
        if (rawSeeks is List) {
          for (final s in rawSeeks) {
            if (s is Map<String, dynamic>) {
              seeks.add(s);
            } else if (s is Map) {
              seeks.add(Map<String, dynamic>.from(s));
            }
          }
        }
        _events.add(
          OnlineLobbySnapshot(
            seeks: seeks,
            count: data['count'] as int? ?? seeks.length,
          ),
        );
      case 'illegal_move':
        _events.add(
          OnlineIllegalMove(data['message'] as String? ?? 'illegal'),
        );
      case 'illegal_action':
        _events.add(
          OnlineIllegalAction(
            data['message'] as String? ?? 'illegal',
            action: data['action'] as String?,
          ),
        );
      case 'fairplay_alert':
        if (_inGame(data)) {
          _events.add(
            OnlineFairPlayAlert(
              color: data['color'] as String? ?? '',
              matchRate: (data['matchRate'] as num?)?.toDouble() ?? 0,
              samples: (data['samples'] as num?)?.toInt() ?? 0,
              soft: data['soft'] as bool? ?? true,
            ),
          );
        }
      case 'dm':
      case 'dm_ok':
        final msg = data['message'];
        if (msg is Map) {
          _events.add(OnlineDmMessage(Map<String, dynamic>.from(msg)));
        }
      case 'matched':
        final match = _matchFromPayload(data);
        _rememberMatch(match);
        _events.add(OnlineMatched(match));
      case 'resume_ok':
        _reconnectAttempt = 0;
        _reconnecting = false;
        final match = _matchFromPayload(data);
        _rememberMatch(match);
        final rawLog = data['eventLog'];
        final log = <Map<String, dynamic>>[];
        if (rawLog is List) {
          for (final item in rawLog) {
            if (item is Map<String, dynamic>) {
              log.add(item);
            } else if (item is Map) {
              log.add(Map<String, dynamic>.from(item));
            }
          }
        }
        _events.add(OnlineResumeOk(match, eventLog: log));
      case 'resume_failed':
        _reconnecting = false;
        _events.add(
          OnlineResumeFailed(
            data['message'] as String? ?? 'Не удалось переподключиться',
          ),
        );
        unawaited(clearResumeSession());
      case 'private_waiting':
        _events.add(OnlinePrivateWaiting(data['code'] as String? ?? ''));
      case 'spectate_ok':
        final rawLog = data['eventLog'];
        final log = <Map<String, dynamic>>[];
        if (rawLog is List) {
          for (final item in rawLog) {
            if (item is Map<String, dynamic>) {
              log.add(item);
            } else if (item is Map) {
              log.add(Map<String, dynamic>.from(item));
            }
          }
        }
        _gameId = data['gameId'] as String?;
        _events.add(
          OnlineSpectateOk(
            gameId: data['gameId'] as String? ?? '',
            roomCode: data['roomCode'] as String?,
            whiteName: data['whiteName'] as String?,
            blackName: data['blackName'] as String?,
            eventLog: log,
          ),
        );
      case 'move':
        if (_inGame(data)) {
          _events.add(
            OnlineOpponentMove(
              MoveCodec.fromJson(data['move'] as Map<String, dynamic>),
              whiteMs: data['whiteMs'] as int?,
              blackMs: data['blackMs'] as int?,
            ),
          );
        }
      case 'ability':
        if (_inGame(data)) {
          AbilityOffer? offer;
          final offerJson = data['offer'];
          if (offerJson is Map<String, dynamic>) {
            offer = AbilityOffer.fromJson(offerJson);
          } else if (offerJson is Map) {
            offer = AbilityOffer.fromJson(
              Map<String, dynamic>.from(offerJson),
            );
          }
          _events.add(
            OnlineOpponentAbility(
              gameAbilityFromJson(data['ability'] as String),
              offer: offer,
              stateHash: data['stateHash'] as String?,
            ),
          );
        }
      case 'start_ability':
        if (_inGame(data)) {
          AbilityOffer? offer;
          final offerJson = data['offer'];
          if (offerJson is Map<String, dynamic>) {
            offer = AbilityOffer.fromJson(offerJson);
          } else if (offerJson is Map) {
            offer = AbilityOffer.fromJson(
              Map<String, dynamic>.from(offerJson),
            );
          }
          _events.add(
            OnlineOpponentStartAbility(
              data['color'] == 'white' ? PieceColor.white : PieceColor.black,
              gameAbilityFromJson(data['ability'] as String),
              lavaRank: data['lavaRank'] as int? ?? offer?.lavaRank,
              offer: offer,
            ),
          );
        }
      case 'ability_target':
        if (_inGame(data)) {
          final squareJson = data['square'];
          Square? square;
          if (squareJson is Map) {
            final f = squareJson['f'] ?? squareJson['file'];
            final r = squareJson['r'] ?? squareJson['rank'];
            if (f is int && r is int) {
              square = Square(f, r);
            }
          }
          final removeRaw = data['removeAbility'] as String?;
          _events.add(
            OnlineOpponentAbilityTarget(
              pieceId: data['pieceId'] as String?,
              square: square,
              index: data['index'] as int? ?? 0,
              removeAbility: removeRaw == null
                  ? null
                  : gameAbilityFromJson(removeRaw),
              stateHash: data['stateHash'] as String?,
            ),
          );
        }
      case 'reaction':
        if (_inGame(data)) {
          final abilityRaw = data['ability'] as String?;
          _events.add(
            OnlineOpponentReaction(
              accepted: data['accepted'] as bool? ?? false,
              ability: abilityRaw == null
                  ? null
                  : gameAbilityFromJson(abilityRaw),
              stateHash: data['stateHash'] as String?,
            ),
          );
        }
      case 'reroll':
        if (_inGame(data)) {
          _events.add(
            OnlineOpponentReroll(
              data['color'] == 'white' ? PieceColor.white : PieceColor.black,
              stateHash: data['stateHash'] as String?,
            ),
          );
        }
      case 'skip_turn':
        if (_inGame(data)) {
          _events.add(
            OnlineOpponentSkipTurn(stateHash: data['stateHash'] as String?),
          );
        }
      case 'game_over':
        if (_inGame(data)) {
          final winnerRaw = data['winner'] as String?;
          PieceColor? winner;
          if (winnerRaw == 'white') {
            winner = PieceColor.white;
          } else if (winnerRaw == 'black') {
            winner = PieceColor.black;
          }
          unawaited(clearResumeSession());
          _events.add(
            OnlineGameOver(
              winner: winner,
              reason: data['reason'] as String?,
              detail: data['detail'] as String?,
              stateHash: data['stateHash'] as String?,
            ),
          );
        }
      case 'rematch_offer':
        if (_inGame(data)) {
          _events.add(OnlineRematchOffer());
        }
      case 'rematch_start':
        final match = _matchFromPayload(data);
        _rememberMatch(match);
        _events.add(OnlineRematchStart(match));
      case 'state_resync':
        if (_inGame(data)) {
          final snapshot = data['snapshot'];
          if (snapshot is Map<String, dynamic>) {
            _events.add(OnlineStateResync(snapshot));
          } else if (snapshot is Map) {
            _events.add(
              OnlineStateResync(Map<String, dynamic>.from(snapshot)),
            );
          }
        }
      case 'chat':
        if (_inGame(data)) {
          _events.add(
            OnlineChatMessage(
              data['text'] as String? ?? '',
              fromOpponent: true,
            ),
          );
        }
      case 'resign':
        if (_inGame(data)) {
          _events.add(OnlineResign());
        }
      case 'draw_offer':
        if (_inGame(data)) {
          _events.add(OnlineDrawOffer());
        }
      case 'draw_response':
        if (_inGame(data)) {
          _events.add(
            OnlineDrawResponse(accepted: data['accepted'] as bool? ?? false),
          );
        }
      case 'takeback_offer':
        if (_inGame(data)) {
          _events.add(OnlineTakebackOffer());
        }
      case 'takeback_response':
        if (_inGame(data)) {
          _events.add(
            OnlineTakebackResponse(
              accepted: data['accepted'] as bool? ?? false,
            ),
          );
        }
      case 'clock_sync':
        if (_inGame(data)) {
          _events.add(
            OnlineClockSync(
              whiteMs: data['whiteMs'] as int? ?? 0,
              blackMs: data['blackMs'] as int? ?? 0,
            ),
          );
        }
      case 'opponent_disconnected':
        if (_inGame(data) || data['gameId'] == null) {
          _events.add(
            OnlineOpponentDisconnected(
              graceMs: data['graceMs'] as int? ?? 90000,
            ),
          );
        }
      case 'opponent_reconnected':
        if (_inGame(data) || data['gameId'] == null) {
          _events.add(OnlineOpponentReconnected());
        }
      case 'opponent_left':
        unawaited(clearResumeSession());
        _events.add(OnlineOpponentLeft());
      case 'error':
        _events.add(
          OnlineError(data['message'] as String? ?? 'Ошибка сервера'),
        );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _intentionalClose = true;
    _reconnectTimer?.cancel();
    _stopHeartbeat();
    unawaited(_socketSub?.cancel());
    try {
      _channel?.sink.close();
    } catch (_) {}
    if (!_events.isClosed) {
      _events.close();
    }
  }
}
