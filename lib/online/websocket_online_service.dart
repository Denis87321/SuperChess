import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../chess/move.dart';
import '../chess/move_codec.dart';
import '../l10n/models/game_ability.dart';
import '../l10n/models/piece.dart';
import '../l10n/models/square.dart';
import 'online_game_service.dart';

class WebSocketOnlineService implements OnlineGameService {
  WebSocketOnlineService({required this.serverUrl});

  final String serverUrl;
  final _events = StreamController<OnlineEvent>.broadcast();
  WebSocketChannel? _channel;
  String? _gameId;

  @override
  Stream<OnlineEvent> get events => _events.stream;

  @override
  Future<void> connect() async {
    _channel = WebSocketChannel.connect(Uri.parse(serverUrl));
    _channel!.stream.listen(
      _onMessage,
      onError: (_) => _events.add(OnlineError('Ошибка соединения')),
      onDone: () => _events.add(OnlineOpponentDisconnected()),
    );
  }

  @override
  Future<void> findGame({
    String playerName = 'Player',
    String? token,
  }) async {
    _send({
      'type': 'find_game',
      'name': playerName,
      if (token != null && token.isNotEmpty) 'token': token,
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
  void sendMove(Move move) {
    _send({'type': 'move', 'gameId': _gameId, 'move': MoveCodec.toJson(move)});
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

  void _send(Map<String, dynamic> message) {
    _channel?.sink.add(jsonEncode(message));
  }

  bool _inGame(Map<String, dynamic> data) => data['gameId'] == _gameId;

  void _onMessage(dynamic raw) {
    final data = jsonDecode(raw as String) as Map<String, dynamic>;
    switch (data['type'] as String) {
      case 'queue_size':
      case 'searching':
        _events.add(
          OnlineSearching(count: data['count'] as int? ?? 0),
        );
      case 'matched':
        _gameId = data['gameId'] as String;
        _events.add(
          OnlineMatched(
            OnlineMatch(
              gameId: _gameId!,
              localColor: data['color'] == 'white'
                  ? PieceColor.white
                  : PieceColor.black,
              opponentName: data['opponentName'] as String? ?? 'Соперник',
              rated: data['rated'] == true,
              yourRating: data['yourRating'] as int?,
              opponentRating: data['opponentRating'] as int?,
              opponentLoggedIn: data['opponentLoggedIn'] == true,
            ),
          ),
        );
      case 'move':
        if (_inGame(data)) {
          _events.add(
            OnlineOpponentMove(
              MoveCodec.fromJson(data['move'] as Map<String, dynamic>),
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
        _gameId = data['gameId'] as String;
        _events.add(
          OnlineRematchStart(
            OnlineMatch(
              gameId: _gameId!,
              localColor: data['color'] == 'white'
                  ? PieceColor.white
                  : PieceColor.black,
              opponentName: data['opponentName'] as String? ?? 'Соперник',
              rated: data['rated'] == true,
              yourRating: data['yourRating'] as int?,
              opponentRating: data['opponentRating'] as int?,
              opponentLoggedIn: data['opponentLoggedIn'] == true,
            ),
          ),
        );
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
      case 'error':
        _events.add(
          OnlineError(data['message'] as String? ?? 'Ошибка сервера'),
        );
      case 'opponent_left':
        _events.add(OnlineOpponentDisconnected());
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _events.close();
  }
}
