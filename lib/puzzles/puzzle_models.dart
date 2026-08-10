import 'dart:convert';

import '../l10n/models/game_ability.dart';
import '../l10n/models/piece.dart';
import '../l10n/models/square.dart';

enum PuzzleGoal { checkmate, captureKing, surviveNMoves, alternativeWin }

class PuzzleDefinition {
  const PuzzleDefinition({
    required this.id,
    required this.titleRu,
    required this.titleEn,
    required this.turn,
    required this.goal,
    required this.pieces,
    this.boardAbilities = const [],
    this.hintAbility,
    this.surviveMoves,
    this.solution = const [],
  });

  final String id;
  final String titleRu;
  final String titleEn;
  final PieceColor turn;
  final PuzzleGoal goal;
  final List<PuzzlePiece> pieces;
  final List<GameAbility> boardAbilities;
  final GameAbility? hintAbility;
  final int? surviveMoves;
  final List<PuzzleMove> solution;

  String titleFor(bool isRu) => isRu ? titleRu : titleEn;

  factory PuzzleDefinition.fromJson(Map<String, dynamic> json) {
    final goalName = json['goal'] as String? ?? 'checkmate';
    final goal = PuzzleGoal.values.firstWhere(
      (g) => g.name == goalName,
      orElse: () => PuzzleGoal.checkmate,
    );
    final turnName = json['turn'] as String? ?? 'white';
    final board = <GameAbility>[];
    for (final raw in (json['boardAbilities'] as List? ?? const [])) {
      board.add(gameAbilityFromJson('$raw'));
    }
    final hintRaw = json['hintAbility'];
    return PuzzleDefinition(
      id: json['id'] as String,
      titleRu: json['titleRu'] as String? ?? json['id'] as String,
      titleEn: json['titleEn'] as String? ?? json['id'] as String,
      turn: turnName == 'black' ? PieceColor.black : PieceColor.white,
      goal: goal,
      boardAbilities: board,
      hintAbility: hintRaw == null ? null : gameAbilityFromJson('$hintRaw'),
      surviveMoves: json['surviveMoves'] as int?,
      pieces: [
        for (final p in (json['pieces'] as List? ?? const []))
          PuzzlePiece.fromJson(Map<String, dynamic>.from(p as Map)),
      ],
      solution: [
        for (final m in (json['solution'] as List? ?? const []))
          PuzzleMove.fromJson(Map<String, dynamic>.from(m as Map)),
      ],
    );
  }
}

class PuzzlePiece {
  const PuzzlePiece({
    required this.square,
    required this.type,
    required this.color,
    this.id = '',
    this.abilities = const {},
    this.hasMoved = true,
  });

  final Square square;
  final PieceType type;
  final PieceColor color;
  final String id;
  final Set<GameAbility> abilities;
  final bool hasMoved;

  Piece toPiece() => Piece(
        pieceId: id,
        type: type,
        color: color,
        hasMoved: hasMoved,
        abilities: abilities,
      );

  factory PuzzlePiece.fromJson(Map<String, dynamic> json) {
    final abilities = <GameAbility>{};
    for (final raw in (json['abilities'] as List? ?? const [])) {
      abilities.add(gameAbilityFromJson('$raw'));
    }
    return PuzzlePiece(
      square: parseSquareLabel(json['square'] as String),
      type: PieceType.values.byName(json['type'] as String),
      color: (json['color'] as String) == 'black'
          ? PieceColor.black
          : PieceColor.white,
      id: json['id'] as String? ?? '',
      abilities: abilities,
      hasMoved: json['hasMoved'] as bool? ?? true,
    );
  }
}

class PuzzleMove {
  const PuzzleMove({required this.from, required this.to});

  final Square from;
  final Square to;

  factory PuzzleMove.fromJson(Map<String, dynamic> json) => PuzzleMove(
        from: parseSquareLabel(json['from'] as String),
        to: parseSquareLabel(json['to'] as String),
      );
}

Square parseSquareLabel(String label) {
  final t = label.trim().toLowerCase();
  if (t.length < 2) {
    throw FormatException('Bad square: $label');
  }
  final file = t.codeUnitAt(0) - 97;
  final rank = int.parse(t.substring(1)) - 1;
  return Square(file, rank);
}

List<PuzzleDefinition> parsePuzzlePack(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is! List) return const [];
  return [
    for (final item in decoded)
      PuzzleDefinition.fromJson(Map<String, dynamic>.from(item as Map)),
  ];
}
