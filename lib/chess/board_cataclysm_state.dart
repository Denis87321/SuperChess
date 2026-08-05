import '../models/piece.dart';
import '../models/square.dart';

/// Mutable board-rule / cataclysm flags shared with [GameSnapshot].
class BoardCataclysmState {
  bool passiveAggressionActive = false;
  int whitePassiveAggression = 10;
  int blackPassiveAggression = 10;

  bool skipTurnEnabled = false;

  bool troopFatigueActive = false;
  String? whiteLastMovedPieceId;
  String? blackLastMovedPieceId;

  bool combatOpticsActive = false;

  bool kingOfHillActive = false;
  Map<Square, PieceColor> territory = {};

  final Map<PieceColor, List<Square>> secretRoutes = {};
  final Map<PieceColor, int> secretRouteProgress = {};

  bool royalPilgrimageActive = false;
  bool mightMakesRightActive = false;
  bool expeditionaryCorpsActive = false;
  final Set<String> expeditionCaptured = {};

  final Map<PieceColor, String> witnessProtectedPieceId = {};
  String? revealedWitnessPieceId;

  String? forcedMovePieceId;
  PieceColor? forcedMoveOwner;

  Square? wordOfHonorSquare;
  PieceColor? wordOfHonorColor;

  int symmetryTurnsLeft = 0;
  PieceType? symmetryRequiredType;
  PieceColor? symmetryVictimColor;
  PieceColor? symmetryChooserColor;

  String? vetoPieceId;
  int vetoTurnsLeft = 0;
  PieceColor? vetoOwner;

  PieceColor? bonusQuietMoveColor;

  PieceType? strikePieceType;
  int strikeTurnsLeft = 0;

  int borderClosureTurnsLeft = 0;
  int myopiaTurnsLeft = 0;
  int magicShutdownTurnsLeft = 0;

  int timeCapsuleRemainingPlies = 0;
  List<List<Piece?>>? timeCapsuleBoard;
  Map<String, Piece>? timeCapsuleStackExtra;

  bool suicideCapturePending = false;

  // --- Expansion batch ---
  bool desertersActive = false;
  final Map<PieceColor, String> deserterPawnIds = {};
  final Set<String> revealedDeserters = {};

  bool letterHActive = false;
  bool fullCircleActive = false;
  final Map<String, Set<Square>> rookCornerVisits = {};

  final Set<String> architectWalls = {}; // "f1,r1|f2,r2" canonical key
  bool bigAssortmentActive = false;
  bool blindSpotActive = false;
  bool onlyEqualsKillActive = false;
  bool marseillesActive = false;
  bool initiativeFearActive = false;
  bool initiativeFearConsumed = false;
  // Balanced variant rule: белые на первом ходу партии делают только 1 движение.
  bool marseillesWhiteFirstTurnSingleDone = false;
  // Сколько "движений" осталось у текущего игрока в сегменте хода (1..2).
  int marseillesMovesLeft = 0;
  final Map<PieceColor, int> sameTypeCaptureCounts = {
    PieceColor.white: 0,
    PieceColor.black: 0,
  };

  final Map<PieceColor, Set<Square>> permanentFogReveals = {
    PieceColor.white: {},
    PieceColor.black: {},
  };

  final List<({Square square, PieceColor color})> knightIllusions = [];

  Square? avengeCaptureSquare;
  PieceColor? avengeVictimColor;
  int avengePlyLeft = 0;

  final Map<String, int> crusadeCaptureCounts = {};
  final Map<String, int> postQuietMoveCounts = {};
  final Map<String, Set<Square>> surveyorSafeSquares = {};
  final Map<String, Set<Square>> cornerQuestVisits = {};

  String? pendingRideKnightId;
  String? pendingRidePawnId;

  Square? magicHoovesFrom;
  Square? magicHoovesTo;

  int meatGrinderTurnsLeft = 0;

  int queuedSkillChoices = 0;

  /// Full turns completed by each side since the last ability wave (or start).
  int whiteMovesSinceAbilityWave = 0;
  int blackMovesSinceAbilityWave = 0;

  /// Choosers waiting in the current periodic wave (typically white then black).
  final List<PieceColor> pendingPeriodicChooserQueue = [];

  bool get abilityEffectsActive => magicShutdownTurnsLeft <= 0;

  BoardCataclysmState copy() {
    final copy = BoardCataclysmState();
    copy.restoreFrom(this);
    return copy;
  }

  void restoreFrom(BoardCataclysmState other) {
    passiveAggressionActive = other.passiveAggressionActive;
    whitePassiveAggression = other.whitePassiveAggression;
    blackPassiveAggression = other.blackPassiveAggression;
    skipTurnEnabled = other.skipTurnEnabled;
    troopFatigueActive = other.troopFatigueActive;
    whiteLastMovedPieceId = other.whiteLastMovedPieceId;
    blackLastMovedPieceId = other.blackLastMovedPieceId;
    combatOpticsActive = other.combatOpticsActive;
    kingOfHillActive = other.kingOfHillActive;
    territory
      ..clear()
      ..addAll(other.territory);
    secretRoutes
      ..clear()
      ..addAll({
        for (final e in other.secretRoutes.entries)
          e.key: List<Square>.from(e.value),
      });
    secretRouteProgress
      ..clear()
      ..addAll(other.secretRouteProgress);
    royalPilgrimageActive = other.royalPilgrimageActive;
    mightMakesRightActive = other.mightMakesRightActive;
    expeditionaryCorpsActive = other.expeditionaryCorpsActive;
    expeditionCaptured
      ..clear()
      ..addAll(other.expeditionCaptured);
    witnessProtectedPieceId
      ..clear()
      ..addAll(other.witnessProtectedPieceId);
    revealedWitnessPieceId = other.revealedWitnessPieceId;
    forcedMovePieceId = other.forcedMovePieceId;
    forcedMoveOwner = other.forcedMoveOwner;
    wordOfHonorSquare = other.wordOfHonorSquare;
    wordOfHonorColor = other.wordOfHonorColor;
    symmetryTurnsLeft = other.symmetryTurnsLeft;
    symmetryRequiredType = other.symmetryRequiredType;
    symmetryVictimColor = other.symmetryVictimColor;
    symmetryChooserColor = other.symmetryChooserColor;
    vetoPieceId = other.vetoPieceId;
    vetoTurnsLeft = other.vetoTurnsLeft;
    vetoOwner = other.vetoOwner;
    bonusQuietMoveColor = other.bonusQuietMoveColor;
    strikePieceType = other.strikePieceType;
    strikeTurnsLeft = other.strikeTurnsLeft;
    borderClosureTurnsLeft = other.borderClosureTurnsLeft;
    myopiaTurnsLeft = other.myopiaTurnsLeft;
    magicShutdownTurnsLeft = other.magicShutdownTurnsLeft;
    timeCapsuleRemainingPlies = other.timeCapsuleRemainingPlies;
    timeCapsuleBoard = other.timeCapsuleBoard
        ?.map((row) => List<Piece?>.from(row))
        .toList();
    timeCapsuleStackExtra = other.timeCapsuleStackExtra == null
        ? null
        : Map<String, Piece>.from(other.timeCapsuleStackExtra!);
    suicideCapturePending = other.suicideCapturePending;

    desertersActive = other.desertersActive;
    deserterPawnIds
      ..clear()
      ..addAll(other.deserterPawnIds);
    revealedDeserters
      ..clear()
      ..addAll(other.revealedDeserters);
    letterHActive = other.letterHActive;
    fullCircleActive = other.fullCircleActive;
    rookCornerVisits
      ..clear()
      ..addAll({
        for (final e in other.rookCornerVisits.entries)
          e.key: Set<Square>.from(e.value),
      });
    architectWalls
      ..clear()
      ..addAll(other.architectWalls);
    bigAssortmentActive = other.bigAssortmentActive;
    blindSpotActive = other.blindSpotActive;
    onlyEqualsKillActive = other.onlyEqualsKillActive;
    marseillesActive = other.marseillesActive;
    initiativeFearActive = other.initiativeFearActive;
    initiativeFearConsumed = other.initiativeFearConsumed;
    marseillesWhiteFirstTurnSingleDone =
        other.marseillesWhiteFirstTurnSingleDone;
    marseillesMovesLeft = other.marseillesMovesLeft;
    sameTypeCaptureCounts
      ..clear()
      ..addAll(other.sameTypeCaptureCounts);
    permanentFogReveals
      ..clear()
      ..addAll({
        for (final e in other.permanentFogReveals.entries)
          e.key: Set<Square>.from(e.value),
      });
    knightIllusions
      ..clear()
      ..addAll(other.knightIllusions);
    avengeCaptureSquare = other.avengeCaptureSquare;
    avengeVictimColor = other.avengeVictimColor;
    avengePlyLeft = other.avengePlyLeft;
    crusadeCaptureCounts
      ..clear()
      ..addAll(other.crusadeCaptureCounts);
    postQuietMoveCounts
      ..clear()
      ..addAll(other.postQuietMoveCounts);
    surveyorSafeSquares
      ..clear()
      ..addAll({
        for (final e in other.surveyorSafeSquares.entries)
          e.key: Set<Square>.from(e.value),
      });
    cornerQuestVisits
      ..clear()
      ..addAll({
        for (final e in other.cornerQuestVisits.entries)
          e.key: Set<Square>.from(e.value),
      });
    pendingRideKnightId = other.pendingRideKnightId;
    pendingRidePawnId = other.pendingRidePawnId;
    magicHoovesFrom = other.magicHoovesFrom;
    magicHoovesTo = other.magicHoovesTo;
    meatGrinderTurnsLeft = other.meatGrinderTurnsLeft;
    queuedSkillChoices = other.queuedSkillChoices;
    whiteMovesSinceAbilityWave = other.whiteMovesSinceAbilityWave;
    blackMovesSinceAbilityWave = other.blackMovesSinceAbilityWave;
    pendingPeriodicChooserQueue
      ..clear()
      ..addAll(other.pendingPeriodicChooserQueue);
  }

  static String wallKey(Square a, Square b) {
    final aFirst = a.file < b.file || (a.file == b.file && a.rank <= b.rank);
    final first = aFirst ? a : b;
    final second = aFirst ? b : a;
    return '${first.file},${first.rank}|${second.file},${second.rank}';
  }

  bool hasWallBetween(Square a, Square b) => architectWalls.contains(wallKey(a, b));

  static int pieceCombatValue(PieceType type) {
    switch (type) {
      case PieceType.pawn:
        return 1;
      case PieceType.knight:
      case PieceType.bishop:
        return 3;
      case PieceType.rook:
        return 5;
      case PieceType.queen:
        return 9;
      case PieceType.king:
        return 1000;
    }
  }
}
