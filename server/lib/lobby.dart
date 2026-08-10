import 'package:super_chess_engine/super_chess_engine.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class LobbySeek {
  LobbySeek({
    required this.player,
    required this.tc,
    required this.rated,
    this.ratingDelta = 400,
  });

  final LobbyPlayer player;
  final TimeControl tc;
  final bool rated;
  final int ratingDelta;
  final DateTime createdAt = DateTime.now();

  String get key => '${tc.id}|$rated';

  Map<String, dynamic> toJson() => {
        'name': player.name,
        'rating': player.rating,
        'tc': tc.id,
        'rated': rated,
        'createdAt': createdAt.toIso8601String(),
      };
}

class LobbyPlayer {
  LobbyPlayer({
    required this.channel,
    required this.name,
    this.userId,
    this.rating,
  });

  WebSocketChannel channel;
  final String name;
  final String? userId;
  final int? rating;
}

/// Open lobby: seeks keyed by time control + rated.
class Lobby {
  final Map<String, List<LobbySeek>> _seeks = {};

  List<Map<String, dynamic>> snapshot({WebSocketChannel? exclude}) {
    final out = <Map<String, dynamic>>[];
    for (final list in _seeks.values) {
      for (final s in list) {
        if (exclude != null && identical(s.player.channel, exclude)) continue;
        out.add(s.toJson());
      }
    }
    return out;
  }

  void cancel(WebSocketChannel channel) {
    for (final list in _seeks.values) {
      list.removeWhere((s) => identical(s.player.channel, channel));
    }
    _seeks.removeWhere((_, v) => v.isEmpty);
  }

  /// Returns a matched pair if someone was waiting, else null and seek is stored.
  ({LobbySeek a, LobbySeek b})? place(LobbySeek seek) {
    cancel(seek.player.channel);
    final list = _seeks.putIfAbsent(seek.key, () => []);
    for (var i = 0; i < list.length; i++) {
      final other = list[i];
      if (!_ratingCompatible(other, seek)) continue;
      list.removeAt(i);
      if (list.isEmpty) _seeks.remove(seek.key);
      return (a: other, b: seek);
    }
    list.add(seek);
    return null;
  }

  bool _ratingCompatible(LobbySeek a, LobbySeek b) {
    final ra = a.player.rating;
    final rb = b.player.rating;
    if (ra == null || rb == null) return true;
    final delta = a.ratingDelta < b.ratingDelta ? a.ratingDelta : b.ratingDelta;
    return (ra - rb).abs() <= delta;
  }

  int get totalSeekers =>
      _seeks.values.fold<int>(0, (sum, list) => sum + list.length);
}
