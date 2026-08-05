import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../chess/move.dart';
import '../chess/move_codec.dart';
import '../models/game_ability.dart';
import '../models/piece.dart';
import '../models/square.dart';
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
  Future<void> findGame({String playerName = 'Player'}) async {
    _send({'type': 'find_game', 'name': playerName});
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
      'stateHash': ?stateHash,
    });
  }

  void _send(Map<String, dynamic> message) {
    _channel?.sink.add(jsonEncode(message));
  }

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
            ),
          ),
        );
      case 'move':
        if (data['gameId'] == _gameId) {
          _events.add(
            OnlineOpponentMove(
              MoveCodec.fromJson(data['move'] as Map<String, dynamic>),
            ),
          );
        }
      case 'ability':
        if (data['gameId'] == _gameId) {
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
        if (data['gameId'] == _gameId) {
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
        if (data['gameId'] == _gameId) {
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
        if (data['gameId'] == _gameId) {
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
        if (data['gameId'] == _gameId) {
          _events.add(
            OnlineOpponentReroll(
              data['color'] == 'white' ? PieceColor.white : PieceColor.black,
              stateHash: data['stateHash'] as String?,
            ),
          );
        }
      case 'skip_turn':
        if (data['gameId'] == _gameId) {
          _events.add(
            OnlineOpponentSkipTurn(stateHash: data['stateHash'] as String?),
          );
        }
      case 'game_over':
        if (data['gameId'] == _gameId) {
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
              stateHash: data['stateHash'] as String?,
            ),
          );
        }
      case 'state_resync':
        if (data['gameId'] == _gameId) {
          final snapshot = data['snapshot'];
          if (snapshot is Map<String, dynamic>) {
            _events.add(OnlineStateResync(snapshot));
          } else if (snapshot is Map) {
            _events.add(
              OnlineStateResync(Map<String, dynamic>.from(snapshot)),
            );
          }
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
