import 'ability_effects.dart';
import 'game_ability.dart';
import 'square.dart';

enum PieceColor { white, black }

enum PieceType { pawn, rook, knight, bishop, queen, king }

class Piece {
  const Piece({
    this.pieceId = '',
    required this.type,
    required this.color,
    this.hasMoved = false,
    this.abilities = const {},
    this.lavaStreak = 0,
    this.royalDecreeUsed = false,
    this.tripleStepUsed = false,
    this.airborneUsed = false,
    this.colorChaosUsed = false,
    this.kingShieldUsed = false,
    this.previousSquare,
    this.restoreAs,
    this.restoreAfterMoves = 0,
    this.cosmeticHue,
    this.pawnRevealed = false,
    this.skipTurnsLeft = 0,
    this.boundIsLight,
    this.caliphGrace = false,
    this.polymorphGrace = false,
    this.moveAsType,
    this.matkaTurns = 0,
    this.plagueTurnsLeft = 0,
    this.trojanTurnsLeft = 0,
    this.horsemenCaptureUsed = false,
    this.idleTurns = 0,
    this.alcoveUsed = false,
    this.parallelWorldsUsed = false,
    this.doppelgangerOnceUsed = false,
    this.stompPending = false,
    this.magicHoovesPending = false,
  });

  /// Stable identity assigned by [ChessGame].
  ///
  /// An empty value is allowed for UI previews and externally constructed
  /// pieces; the game assigns a deterministic per-game id when such a piece is
  /// placed on the board.
  final String pieceId;
  final PieceType type;
  final PieceColor color;
  final bool hasMoved;
  final Set<GameAbility> abilities;
  final int lavaStreak;
  final bool royalDecreeUsed;
  final bool tripleStepUsed;
  final bool airborneUsed;
  final bool colorChaosUsed;
  final bool kingShieldUsed;
  final Square? previousSquare;
  final PieceType? restoreAs;
  final int restoreAfterMoves;
  final int? cosmeticHue;
  final bool pawnRevealed;

  /// Сколько своих ходов фигура пропускает («Липота»).
  final int skipTurnsLeft;

  /// Цвет клятвы слона / императрицы теней; null = нет привязки.
  final bool? boundIsLight;

  /// Не снимать «Халифа» на ближайшем тике конца хода.
  final bool caliphGrace;

  /// Не снимать полиморф на ближайшем тике конца хода.
  final bool polymorphGrace;

  /// Король после «Объединения семей» ходит только как этот тип.
  final PieceType? moveAsType;

  /// Счётчик ходов «Матки» (спавн на 3).
  final int matkaTurns;

  /// Ходов до смерти от чумы; 0 = не заражена.
  final int plagueTurnsLeft;

  /// Ходов до взрыва троянского коня; 0 = нет таймера.
  final int trojanTurnsLeft;

  /// «4 всадника»: первое взятие этого коня уже использовано.
  final bool horsemenCaptureUsed;

  /// Ходов подряд без движения (для «Окопа»).
  final int idleTurns;

  final bool alcoveUsed;
  final bool parallelWorldsUsed;
  final bool doppelgangerOnceUsed;
  final bool stompPending;
  final bool magicHoovesPending;

  bool get hasModifiedMoveSet {
    for (final ability in abilities) {
      if (ability.effects.isNotEmpty) return true;
    }
    return false;
  }

  bool get isPlagued => plagueTurnsLeft > 0;

  bool hasEffect(AbilityEffect effect) {
    for (final ability in abilities) {
      if (ability.effects.contains(effect)) return true;
    }
    return false;
  }

  bool hasAbility(GameAbility ability) => abilities.contains(ability);

  Piece copyWith({
    String? pieceId,
    PieceType? type,
    PieceColor? color,
    bool? hasMoved,
    Set<GameAbility>? abilities,
    int? lavaStreak,
    bool? royalDecreeUsed,
    bool? tripleStepUsed,
    bool? airborneUsed,
    bool? colorChaosUsed,
    bool? kingShieldUsed,
    Square? previousSquare,
    bool clearPreviousSquare = false,
    PieceType? restoreAs,
    bool clearRestoreAs = false,
    int? restoreAfterMoves,
    int? cosmeticHue,
    bool clearCosmeticHue = false,
    bool? pawnRevealed,
    int? skipTurnsLeft,
    bool? boundIsLight,
    bool clearBoundIsLight = false,
    bool? caliphGrace,
    bool? polymorphGrace,
    PieceType? moveAsType,
    bool clearMoveAsType = false,
    int? matkaTurns,
    int? plagueTurnsLeft,
    int? trojanTurnsLeft,
    bool? horsemenCaptureUsed,
    int? idleTurns,
    bool? alcoveUsed,
    bool? parallelWorldsUsed,
    bool? doppelgangerOnceUsed,
    bool? stompPending,
    bool? magicHoovesPending,
  }) {
    return Piece(
      pieceId: pieceId ?? this.pieceId,
      type: type ?? this.type,
      color: color ?? this.color,
      hasMoved: hasMoved ?? this.hasMoved,
      abilities: abilities ?? this.abilities,
      lavaStreak: lavaStreak ?? this.lavaStreak,
      royalDecreeUsed: royalDecreeUsed ?? this.royalDecreeUsed,
      tripleStepUsed: tripleStepUsed ?? this.tripleStepUsed,
      airborneUsed: airborneUsed ?? this.airborneUsed,
      colorChaosUsed: colorChaosUsed ?? this.colorChaosUsed,
      kingShieldUsed: kingShieldUsed ?? this.kingShieldUsed,
      previousSquare: clearPreviousSquare
          ? null
          : (previousSquare ?? this.previousSquare),
      restoreAs: clearRestoreAs ? null : (restoreAs ?? this.restoreAs),
      restoreAfterMoves: restoreAfterMoves ?? this.restoreAfterMoves,
      cosmeticHue: clearCosmeticHue ? null : (cosmeticHue ?? this.cosmeticHue),
      pawnRevealed: pawnRevealed ?? this.pawnRevealed,
      skipTurnsLeft: skipTurnsLeft ?? this.skipTurnsLeft,
      boundIsLight: clearBoundIsLight
          ? null
          : (boundIsLight ?? this.boundIsLight),
      caliphGrace: caliphGrace ?? this.caliphGrace,
      polymorphGrace: polymorphGrace ?? this.polymorphGrace,
      moveAsType: clearMoveAsType ? null : (moveAsType ?? this.moveAsType),
      matkaTurns: matkaTurns ?? this.matkaTurns,
      plagueTurnsLeft: plagueTurnsLeft ?? this.plagueTurnsLeft,
      trojanTurnsLeft: trojanTurnsLeft ?? this.trojanTurnsLeft,
      horsemenCaptureUsed: horsemenCaptureUsed ?? this.horsemenCaptureUsed,
      idleTurns: idleTurns ?? this.idleTurns,
      alcoveUsed: alcoveUsed ?? this.alcoveUsed,
      parallelWorldsUsed: parallelWorldsUsed ?? this.parallelWorldsUsed,
      doppelgangerOnceUsed: doppelgangerOnceUsed ?? this.doppelgangerOnceUsed,
      stompPending: stompPending ?? this.stompPending,
      magicHoovesPending: magicHoovesPending ?? this.magicHoovesPending,
    );
  }

  Piece withAbility(GameAbility ability) {
    if (abilities.contains(ability)) return this;
    return copyWith(abilities: {...abilities, ability});
  }

  Piece withoutAbility(GameAbility ability) {
    if (!abilities.contains(ability)) return this;
    final next = {...abilities}..remove(ability);
    return copyWith(abilities: next);
  }

  PieceColor get opponent =>
      color == PieceColor.white ? PieceColor.black : PieceColor.white;
}
