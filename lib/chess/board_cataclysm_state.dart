import '../l10n/models/game_ability.dart';
import '../l10n/models/piece.dart';
import '../l10n/models/square.dart';

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
  /// Legacy global flag; prefer [bigAssortmentOwners].
  bool bigAssortmentActive = false;
  /// Players who chose «Большой ассортимент» (only they get 4 mid-game choices).
  final Set<PieceColor> bigAssortmentOwners = {};
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

  // --- New board / cataclysm batch ---
  bool swampActive = false;
  bool collectiveMyopiaActive = false;

  bool frostMapActive = false;
  final Map<PieceColor, Set<String>> torchPieceIds = {
    PieceColor.white: {},
    PieceColor.black: {},
  };
  final Map<String, int> frostIdleTurns = {}; // pieceId -> frost stage 0..3 (mirror)
  final Set<String> frozenPieceIds = {};

  bool scorchingSunActive = false;
  final Set<Square> sunSquares = {};
  int sunPliesUntilRotate = 10; // 5 full moves * 2 plies

  bool turncoatsActive = false;
  /// Visible color -> pieceId of the spy that secretly belongs to the opponent.
  final Map<PieceColor, String> turncoatSpyIds = {};
  final Set<String> revealedTurncoats = {};

  final Set<Square> quicksandHidden = {};
  final Set<Square> quicksandRevealed = {};
  /// After landing: turns remaining immobilized (owner plies).
  final Map<Square, int> quicksandDuration = {};
  final Map<String, int> quicksandSkipLeft = {}; // pieceId -> skips

  int queuedSkillChoices = 0;

  /// Full turns completed by each side since the last ability wave (or start).
  int whiteMovesSinceAbilityWave = 0;
  int blackMovesSinceAbilityWave = 0;

  /// Choosers waiting in the current periodic wave (typically white then black).
  final List<PieceColor> pendingPeriodicChooserQueue = [];

  // --- Expanded mode / board / cataclysm batch (2026) ---
  bool timeZoneActive = false;
  /// true = odd plies (1,3,5…), false = even; null = not chosen yet.
  final Map<PieceColor, bool?> timeZoneOddHour = {
    PieceColor.white: null,
    PieceColor.black: null,
  };
  int globalPlyIndex = 0; // increments each completed half-move

  /// Enemy piece ids that cannot deliver mate ("1").
  final Map<PieceColor, String?> mateVetoEnemyPieceId = {
    PieceColor.white: null,
    PieceColor.black: null,
  };

  bool debtPitActive = false;
  int whiteDebt = 0;
  int blackDebt = 0;

  bool wastelandActive = false;
  /// square -> owner of barren land left after a move
  final Map<Square, PieceColor> wastelandClaims = {};
  final Map<String, int> wastelandTollSkip = {}; // pieceId -> skip turns

  bool busActive = false;

  bool shopTokenActive = false;
  final Map<PieceColor, bool> shopAvailable = {
    PieceColor.white: true,
    PieceColor.black: true,
  };
  final Map<PieceColor, bool> shopTokenHeld = {
    PieceColor.white: false,
    PieceColor.black: false,
  };
  String? shopPendingSellPieceId;
  PieceColor? shopPendingSellColor;
  String? shopMateCancelBanner;
  String? mateVetoBanner;

  bool seasonsActive = false;
  int seasonFullMoves = 0; // increments each black move completed
  /// 0 spring, 1 summer, 2 autumn, 3 winter
  int seasonIndex = 0;
  final Set<String> springDoubleUsedThisSeason = {};

  bool bloodFeudActive = false;
  /// After a capture: victim color must capture within 2 of their plies.
  PieceColor? bloodFeudVictimColor;
  int bloodFeudPliesLeft = 0;
  String? bloodFeudBanner; // UI toast text

  bool prioritySetupActive = false;
  final Set<Square> priorityCells = {};

  bool brokenPerspectiveActive = false;

  bool kriegspielActive = false;
  String? kriegspielAnnouncement;

  bool kingCenterActive = false;

  bool atomicActive = false;

  bool crazyhouseActive = false;
  final Map<PieceColor, List<PieceType>> crazyhouseHand = {
    PieceColor.white: [],
    PieceColor.black: [],
  };

  bool duckChessActive = false;
  Square? duckSquare;
  bool duckNeedsPlacement = false;

  // Board
  bool inkBlotActive = false;
  final Map<Square, int> inkBlotPlies = {}; // square -> plies left
  Square? gravityWellSquare;
  int gravityWellPlies = 0;
  String? shadowPieceId;
  bool shadowJumpAvailable = false;
  bool centerTaxActive = false;
  final Set<String> centerTaxSkipNext = {};
  bool walkingCastleActive = false;
  String? invisibleHandForcedPieceId;
  PieceColor? invisibleHandOwner;
  int invisibleHandPlies = 0;
  int? riverRank;
  int riverDirection = 1; // +file or -file
  int? forbiddenFile;
  int forbiddenFilePlies = 0;
  Square? earnedRestSquare;
  int earnedRestCaptures = 0;
  bool earnedRestBurned = false;

  // Cataclysm
  bool moveStealPending = false;
  final Map<String, int> serialCaptureCounts = {};
  String? snailTrailPieceId;
  final Map<Square, int> snailSlimePlies = {};
  final Set<Square> disinfoFakeSquares = {};
  PieceType? familyContractType;
  PieceColor? familyContractOwner;
  int familyContractMoves = 0;
  Square? kansasTyphoon;
  Square? kansasTyphoonNext;
  int kansasPlies = 0;
  String? loneWarriorPieceId;
  bool twentyOneResolved = false;

  // --- Batch: pawn / light / mode / board / cataclysm (2026-08) ---
  bool holyRandomActive = false;
  bool zooShuffleApplied = false;
  bool insatiableHungerActive = false;
  final Map<String, int> queenHungerPlies = {}; // queenId -> plies since capture
  bool comeOnActive = false;
  bool comeOnConsumed = false;
  bool volcanoActive = false;
  final Set<Square> volcanoSquares = {};
  int volcanoPliesLeft = 4; // 2 full moves = 4 plies

  /// Kings must leave these squares within [restlessKingsPliesLeft] plies.
  final Map<PieceColor, Square> restlessKingStart = {};
  int restlessKingsPliesLeft = 0;

  PieceColor? ownHandsOwner; // kingOwnHands chooser
  PieceColor? hereditaryEdictOwner; // opponent restricted on promo

  bool warehouseActive = false;
  GameAbility? warehousePendingAbility;
  PieceType? warehousePendingType;

  final Map<String, int> twilightInvisibleUntilPly = {}; // pieceId -> globalPly
  PieceColor? twilightOwner;
  int twilightOwnerPliesLeft = 0;

  bool gestureMirrorPending = false;
  bool? gestureMirrorRequiredLight; // color of last mover's landing square

  String? blackMarkPieceId;
  PieceColor? blackMarkChooser;

  final Map<String, Set<Square>> archivistVisited = {};
  final Set<String> archivistRecallUsed = {};
  final Map<String, String> pairStepPartner = {}; // pawnId -> partnerId
  final Map<String, int> mortarCooldown = {}; // 0 = fires this turn
  final Map<String, int> starvationPlies = {}; // enemy pawn id
  final Map<Square, ({PieceColor color, int fullMovesLeft})> pawnSeeds = {};
  final Map<String, PieceType> doubleLifeHidden = {};
  final Set<String> doubleLifeUsed = {};
  final Map<String, int> spotlightUnderFire = {};
  final Map<Square, int> fuseTimers = {}; // square -> plies until boom
  final Map<Square, int> inkTrailBlocked = {}; // square -> plies (enemy pawns)
  final Set<Square> donkeySwampSquares = {};
  final Set<Square> hoofSmokeSquares = {};
  final Map<String, String> nonAggressionLink = {}; // a->b and b->a
  final Map<String, List<Square>> gallopContractRoute = {};
  final Map<String, int> gallopContractProgress = {};
  final Map<String, int> bucephalusCaptures = {};
  final Set<String> bucephalusKingJumpUsed = {};
  final Map<String, Square> relicDeathSquare = {};
  final Map<String, int> relicPliesLeft = {};
  final Map<Square, int> blindingSacristy = {}; // next lander skip attack 1 turn
  final Set<String> blindingExemptPieceIds = {};
  final Map<String, int> schismDiagSign = {}; // pieceId -> +1 or -1 (file*rank)
  String? sealRookId;
  String? sealVictimId;
  String? illDriveRookId;
  Square? illDriveFrom;
  Square? illDriveTo;
  String? courtIntrigueQueenId;
  String? courtIntrigueVictimId;

  // --- Interactive batch flows ---
  final List<Square> multiCellPicks = [];
  int multiCellNeeded = 0;
  GameAbility? multiCellAbility;
  String? multiCellSourceId;
  PieceColor? multiCellColor;

  bool rpsSessionActive = false;
  final List<(Square, Square)> rpsPairs = [];
  int? rpsPairIndex;
  String? rpsLastA; // rock | paper | scissors
  String? rpsLastB;
  int rpsRound = 0;
  PieceColor? rpsChooser;
  bool rpsResolved = false;

  String? tangledKnightBaseId;
  Square? tangledFrom;
  Square? tangledFirstDest;
  String? tangledCloneId;
  bool tangledAwaitingKeep = false;
  bool tangledAwaitingSecondDest = false;

  String? customsKnightId;
  Square? customsFrom;
  Square? customsTo;
  final List<List<Square>> customsPaths = [];
  bool awaitingCustomsPath = false;
  bool customsPathResolvedSkip = false;

  final Set<String> doubleLifeArmed = {};
  String? spotlightPromoId;
  final Set<String> kingGuardPieceIds = {};
  final Set<String> littleBrotherSkipIds = {};
  final Set<String> archivistRecallArmed = {};

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
    bigAssortmentOwners
      ..clear()
      ..addAll(other.bigAssortmentOwners);
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
    swampActive = other.swampActive;
    collectiveMyopiaActive = other.collectiveMyopiaActive;
    frostMapActive = other.frostMapActive;
    torchPieceIds
      ..clear()
      ..addAll({
        for (final e in other.torchPieceIds.entries)
          e.key: Set<String>.from(e.value),
      });
    frostIdleTurns
      ..clear()
      ..addAll(other.frostIdleTurns);
    frozenPieceIds
      ..clear()
      ..addAll(other.frozenPieceIds);
    scorchingSunActive = other.scorchingSunActive;
    sunSquares
      ..clear()
      ..addAll(other.sunSquares);
    sunPliesUntilRotate = other.sunPliesUntilRotate;
    turncoatsActive = other.turncoatsActive;
    turncoatSpyIds
      ..clear()
      ..addAll(other.turncoatSpyIds);
    revealedTurncoats
      ..clear()
      ..addAll(other.revealedTurncoats);
    quicksandHidden
      ..clear()
      ..addAll(other.quicksandHidden);
    quicksandRevealed
      ..clear()
      ..addAll(other.quicksandRevealed);
    quicksandDuration
      ..clear()
      ..addAll(other.quicksandDuration);
    quicksandSkipLeft
      ..clear()
      ..addAll(other.quicksandSkipLeft);
    queuedSkillChoices = other.queuedSkillChoices;
    whiteMovesSinceAbilityWave = other.whiteMovesSinceAbilityWave;
    blackMovesSinceAbilityWave = other.blackMovesSinceAbilityWave;
    pendingPeriodicChooserQueue
      ..clear()
      ..addAll(other.pendingPeriodicChooserQueue);

    timeZoneActive = other.timeZoneActive;
    timeZoneOddHour
      ..clear()
      ..addAll(other.timeZoneOddHour);
    globalPlyIndex = other.globalPlyIndex;
    mateVetoEnemyPieceId
      ..clear()
      ..addAll(other.mateVetoEnemyPieceId);
    debtPitActive = other.debtPitActive;
    whiteDebt = other.whiteDebt;
    blackDebt = other.blackDebt;
    wastelandActive = other.wastelandActive;
    wastelandClaims
      ..clear()
      ..addAll(other.wastelandClaims);
    wastelandTollSkip
      ..clear()
      ..addAll(other.wastelandTollSkip);
    busActive = other.busActive;
    shopTokenActive = other.shopTokenActive;
    shopAvailable
      ..clear()
      ..addAll(other.shopAvailable);
    shopTokenHeld
      ..clear()
      ..addAll(other.shopTokenHeld);
    shopPendingSellPieceId = other.shopPendingSellPieceId;
    shopPendingSellColor = other.shopPendingSellColor;
    shopMateCancelBanner = other.shopMateCancelBanner;
    mateVetoBanner = other.mateVetoBanner;
    seasonsActive = other.seasonsActive;
    seasonFullMoves = other.seasonFullMoves;
    seasonIndex = other.seasonIndex;
    springDoubleUsedThisSeason
      ..clear()
      ..addAll(other.springDoubleUsedThisSeason);
    bloodFeudActive = other.bloodFeudActive;
    bloodFeudVictimColor = other.bloodFeudVictimColor;
    bloodFeudPliesLeft = other.bloodFeudPliesLeft;
    bloodFeudBanner = other.bloodFeudBanner;
    prioritySetupActive = other.prioritySetupActive;
    priorityCells
      ..clear()
      ..addAll(other.priorityCells);
    brokenPerspectiveActive = other.brokenPerspectiveActive;
    kriegspielActive = other.kriegspielActive;
    kriegspielAnnouncement = other.kriegspielAnnouncement;
    kingCenterActive = other.kingCenterActive;
    atomicActive = other.atomicActive;
    crazyhouseActive = other.crazyhouseActive;
    crazyhouseHand
      ..clear()
      ..addAll({
        for (final e in other.crazyhouseHand.entries)
          e.key: List<PieceType>.from(e.value),
      });
    duckChessActive = other.duckChessActive;
    duckSquare = other.duckSquare;
    duckNeedsPlacement = other.duckNeedsPlacement;
    inkBlotActive = other.inkBlotActive;
    inkBlotPlies
      ..clear()
      ..addAll(other.inkBlotPlies);
    gravityWellSquare = other.gravityWellSquare;
    gravityWellPlies = other.gravityWellPlies;
    shadowPieceId = other.shadowPieceId;
    shadowJumpAvailable = other.shadowJumpAvailable;
    centerTaxActive = other.centerTaxActive;
    centerTaxSkipNext
      ..clear()
      ..addAll(other.centerTaxSkipNext);
    walkingCastleActive = other.walkingCastleActive;
    invisibleHandForcedPieceId = other.invisibleHandForcedPieceId;
    invisibleHandOwner = other.invisibleHandOwner;
    invisibleHandPlies = other.invisibleHandPlies;
    riverRank = other.riverRank;
    riverDirection = other.riverDirection;
    forbiddenFile = other.forbiddenFile;
    forbiddenFilePlies = other.forbiddenFilePlies;
    earnedRestSquare = other.earnedRestSquare;
    earnedRestCaptures = other.earnedRestCaptures;
    earnedRestBurned = other.earnedRestBurned;
    moveStealPending = other.moveStealPending;
    serialCaptureCounts
      ..clear()
      ..addAll(other.serialCaptureCounts);
    snailTrailPieceId = other.snailTrailPieceId;
    snailSlimePlies
      ..clear()
      ..addAll(other.snailSlimePlies);
    disinfoFakeSquares
      ..clear()
      ..addAll(other.disinfoFakeSquares);
    familyContractType = other.familyContractType;
    familyContractOwner = other.familyContractOwner;
    familyContractMoves = other.familyContractMoves;
    kansasTyphoon = other.kansasTyphoon;
    kansasTyphoonNext = other.kansasTyphoonNext;
    kansasPlies = other.kansasPlies;
    loneWarriorPieceId = other.loneWarriorPieceId;
    twentyOneResolved = other.twentyOneResolved;

    holyRandomActive = other.holyRandomActive;
    zooShuffleApplied = other.zooShuffleApplied;
    insatiableHungerActive = other.insatiableHungerActive;
    queenHungerPlies
      ..clear()
      ..addAll(other.queenHungerPlies);
    comeOnActive = other.comeOnActive;
    comeOnConsumed = other.comeOnConsumed;
    volcanoActive = other.volcanoActive;
    volcanoSquares
      ..clear()
      ..addAll(other.volcanoSquares);
    volcanoPliesLeft = other.volcanoPliesLeft;
    restlessKingStart
      ..clear()
      ..addAll(other.restlessKingStart);
    restlessKingsPliesLeft = other.restlessKingsPliesLeft;
    ownHandsOwner = other.ownHandsOwner;
    hereditaryEdictOwner = other.hereditaryEdictOwner;
    warehouseActive = other.warehouseActive;
    warehousePendingAbility = other.warehousePendingAbility;
    warehousePendingType = other.warehousePendingType;
    twilightInvisibleUntilPly
      ..clear()
      ..addAll(other.twilightInvisibleUntilPly);
    twilightOwner = other.twilightOwner;
    twilightOwnerPliesLeft = other.twilightOwnerPliesLeft;
    gestureMirrorPending = other.gestureMirrorPending;
    gestureMirrorRequiredLight = other.gestureMirrorRequiredLight;
    blackMarkPieceId = other.blackMarkPieceId;
    blackMarkChooser = other.blackMarkChooser;
    archivistVisited
      ..clear()
      ..addAll({
        for (final e in other.archivistVisited.entries)
          e.key: Set<Square>.from(e.value),
      });
    archivistRecallUsed
      ..clear()
      ..addAll(other.archivistRecallUsed);
    pairStepPartner
      ..clear()
      ..addAll(other.pairStepPartner);
    mortarCooldown
      ..clear()
      ..addAll(other.mortarCooldown);
    starvationPlies
      ..clear()
      ..addAll(other.starvationPlies);
    pawnSeeds
      ..clear()
      ..addAll(other.pawnSeeds);
    doubleLifeHidden
      ..clear()
      ..addAll(other.doubleLifeHidden);
    doubleLifeUsed
      ..clear()
      ..addAll(other.doubleLifeUsed);
    spotlightUnderFire
      ..clear()
      ..addAll(other.spotlightUnderFire);
    fuseTimers
      ..clear()
      ..addAll(other.fuseTimers);
    inkTrailBlocked
      ..clear()
      ..addAll(other.inkTrailBlocked);
    donkeySwampSquares
      ..clear()
      ..addAll(other.donkeySwampSquares);
    hoofSmokeSquares
      ..clear()
      ..addAll(other.hoofSmokeSquares);
    nonAggressionLink
      ..clear()
      ..addAll(other.nonAggressionLink);
    gallopContractRoute
      ..clear()
      ..addAll({
        for (final e in other.gallopContractRoute.entries)
          e.key: List<Square>.from(e.value),
      });
    gallopContractProgress
      ..clear()
      ..addAll(other.gallopContractProgress);
    bucephalusCaptures
      ..clear()
      ..addAll(other.bucephalusCaptures);
    bucephalusKingJumpUsed
      ..clear()
      ..addAll(other.bucephalusKingJumpUsed);
    relicDeathSquare
      ..clear()
      ..addAll(other.relicDeathSquare);
    relicPliesLeft
      ..clear()
      ..addAll(other.relicPliesLeft);
    blindingSacristy
      ..clear()
      ..addAll(other.blindingSacristy);
    blindingExemptPieceIds
      ..clear()
      ..addAll(other.blindingExemptPieceIds);
    schismDiagSign
      ..clear()
      ..addAll(other.schismDiagSign);
    sealRookId = other.sealRookId;
    sealVictimId = other.sealVictimId;
    illDriveRookId = other.illDriveRookId;
    illDriveFrom = other.illDriveFrom;
    illDriveTo = other.illDriveTo;
    courtIntrigueQueenId = other.courtIntrigueQueenId;
    courtIntrigueVictimId = other.courtIntrigueVictimId;

    multiCellPicks
      ..clear()
      ..addAll(other.multiCellPicks);
    multiCellNeeded = other.multiCellNeeded;
    multiCellAbility = other.multiCellAbility;
    multiCellSourceId = other.multiCellSourceId;
    multiCellColor = other.multiCellColor;

    rpsSessionActive = other.rpsSessionActive;
    rpsPairs
      ..clear()
      ..addAll(other.rpsPairs);
    rpsPairIndex = other.rpsPairIndex;
    rpsLastA = other.rpsLastA;
    rpsLastB = other.rpsLastB;
    rpsRound = other.rpsRound;
    rpsChooser = other.rpsChooser;
    rpsResolved = other.rpsResolved;

    tangledKnightBaseId = other.tangledKnightBaseId;
    tangledFrom = other.tangledFrom;
    tangledFirstDest = other.tangledFirstDest;
    tangledCloneId = other.tangledCloneId;
    tangledAwaitingKeep = other.tangledAwaitingKeep;
    tangledAwaitingSecondDest = other.tangledAwaitingSecondDest;

    customsKnightId = other.customsKnightId;
    customsFrom = other.customsFrom;
    customsTo = other.customsTo;
    customsPaths
      ..clear()
      ..addAll(other.customsPaths.map((p) => List<Square>.from(p)));
    awaitingCustomsPath = other.awaitingCustomsPath;
    customsPathResolvedSkip = other.customsPathResolvedSkip;

    doubleLifeArmed
      ..clear()
      ..addAll(other.doubleLifeArmed);
    spotlightPromoId = other.spotlightPromoId;
    kingGuardPieceIds
      ..clear()
      ..addAll(other.kingGuardPieceIds);
    littleBrotherSkipIds
      ..clear()
      ..addAll(other.littleBrotherSkipIds);
    archivistRecallArmed
      ..clear()
      ..addAll(other.archivistRecallArmed);
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
