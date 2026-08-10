import '../models/game_ability.dart';
import '../models/piece.dart';
import '../models/square.dart';
import 'chess_game.dart';
import 'move.dart';

enum ModEventKind { appeared, removed, activated }

/// Short mod note attached to a ply in the move list.
class ModEvent {
  const ModEvent({
    required this.kind,
    required this.label,
  });

  final ModEventKind kind;
  final String label;

  String get prefix => switch (kind) {
        ModEventKind.appeared => '+',
        ModEventKind.removed => '−',
        ModEventKind.activated => '⚡',
      };

  String get short => '$prefix$label';
}

/// One half-move in the game log.
class PlyRecord {
  PlyRecord({
    required this.plyIndex,
    required this.move,
    required this.side,
    required this.notation,
    required this.after,
    List<ModEvent> modEvents = const [],
  }) : modEvents = List<ModEvent>.from(modEvents);

  final int plyIndex;
  final Move move;
  final PieceColor side;
  final String notation;
  GameSnapshot after;
  List<ModEvent> modEvents;
}

/// Lichess-style move log with snapshots for view-only rewind.
class MoveHistoryLog {
  final List<PlyRecord> plies = [];

  int get length => plies.length;
  bool get isEmpty => plies.isEmpty;
  bool get isNotEmpty => plies.isNotEmpty;

  void clear() => plies.clear();

  void add(PlyRecord ply) => plies.add(ply);

  void removeLast() {
    if (plies.isNotEmpty) plies.removeLast();
  }

  /// Full-move rows: (moveNumber, white?, black?).
  List<({int number, PlyRecord? white, PlyRecord? black})> get rows {
    final out = <({int number, PlyRecord? white, PlyRecord? black})>[];
    for (var i = 0; i < plies.length; i += 2) {
      final white = plies[i];
      final black = i + 1 < plies.length ? plies[i + 1] : null;
      out.add((
        number: (i ~/ 2) + 1,
        white: white,
        black: black,
      ));
    }
    return out;
  }
}

/// [game] must be the position *before* [move] is applied.
String formatMoveNotation(
  ChessGame game,
  Move move, {
  Piece? movingPiece,
}) {
  final piece = movingPiece ??
      game.pieceAt(move.from, index: move.pieceIndex);
  final fileCount = game.fileCount;
  final extra = game.extraFilePlacement;
  String sq(Square s) => squareLabel(
        s,
        fileCount: fileCount,
        extraFile: extra,
      );

  if (move.isCastle || move.isCastleSwap) {
    final kingside = move.to.file > move.from.file;
    return kingside ? 'O-O' : 'O-O-O';
  }

  final dest = sq(move.to);
  final isCapture = move.isEnPassant ||
      game.piecesAt(move.to).any((p) => p.color != piece?.color);

  if (piece == null || piece.type == PieceType.pawn) {
    final fromFile = fileLabel(
      move.from.file,
      fileCount: fileCount,
      extraFile: extra,
    );
    final base = isCapture || move.isEnPassant
        ? '$fromFile×$dest'
        : dest;
    if (move.promotion != null) {
      return '$base=${_pieceLetter(move.promotion!)}';
    }
    return base;
  }

  final letter = _pieceLetter(piece.type);
  final capture = isCapture ? '×' : '';
  return '$letter$capture$dest';
}

String shortModLabel(String title) {
  final t = title.trim();
  if (t.length <= 16) return t;
  return '${t.substring(0, 14)}…';
}

String _pieceLetter(PieceType type) => switch (type) {
      PieceType.king => 'K',
      PieceType.queen => 'Q',
      PieceType.rook => 'R',
      PieceType.bishop => 'B',
      PieceType.knight => 'N',
      PieceType.pawn => '',
    };

/// Compact fingerprint of active mods for before/after diff.
Map<String, String> collectModFingerprint(ChessGame game) {
  final map = <String, String>{};
  final snap = game.activeAbilitiesSnapshot();
  if (snap.whiteStart != null) {
    map['ws'] = snap.whiteStart!.title;
  }
  if (snap.blackStart != null) {
    map['bs'] = snap.blackStart!.title;
  }
  for (final c in snap.whiteChosen) {
    map['w:${c.ability.name}:${c.title}'] = c.title;
  }
  for (final c in snap.blackChosen) {
    map['b:${c.ability.name}:${c.title}'] = c.title;
  }
  for (var rank = 0; rank < game.rankCount; rank++) {
    for (var file = 0; file < game.fileCount; file++) {
      final square = Square(file, rank);
      for (final piece in game.piecesAt(square)) {
        if (piece.abilities.isEmpty) continue;
        final labels = piece.abilities.map((a) => a.title).toList()..sort();
        map['p:${piece.pieceId}'] = labels.join(',');
      }
    }
  }
  if (game.fogOfWarActive) map['board:fog'] = 'Туман войны';
  if (game.zebrasActive) map['board:zebras'] = 'Зебры';
  if (game.teleportA != null) map['board:teleport'] = 'Телепорт';
  if (game.frostMapActive) map['board:frost'] = 'Морозная карта';
  if (game.scorchingSunActive) map['board:sun'] = 'Палящее солнце';
  return map;
}

List<ModEvent> diffModFingerprints(
  Map<String, String> before,
  Map<String, String> after,
) {
  final events = <ModEvent>[];
  for (final key in after.keys) {
    if (!before.containsKey(key)) {
      events.add(ModEvent(kind: ModEventKind.appeared, label: after[key]!));
    } else if (before[key] != after[key]) {
      // Piece ability set changed — show as activated/changed.
      events.add(ModEvent(kind: ModEventKind.activated, label: after[key]!));
    }
  }
  for (final key in before.keys) {
    if (!after.containsKey(key)) {
      events.add(ModEvent(kind: ModEventKind.removed, label: before[key]!));
    }
  }
  final shortened = events
      .map(
        (e) => ModEvent(kind: e.kind, label: shortModLabel(e.label)),
      )
      .toList();
  // Cap noise for the sidebar.
  if (shortened.length > 6) {
    return [
      ...shortened.take(5),
      ModEvent(
        kind: ModEventKind.activated,
        label: '+${shortened.length - 5}',
      ),
    ];
  }
  return shortened;
}
