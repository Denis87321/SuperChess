import 'dart:math';

import 'package:flutter/foundation.dart';

import '../l10n/models/ability_group.dart';
import '../l10n/models/ability_catalog.dart';
import '../l10n/models/ability_effects.dart';
import '../l10n/models/game_ability.dart';
import '../l10n/models/piece.dart';
import '../l10n/models/square.dart';
import 'board_cataclysm_state.dart';
import 'board_labels.dart';
import 'move.dart';

export 'board_labels.dart'
    show
        ExtraFilePlacement,
        LavaDeathEvent,
        chessRankLabel,
        fileLabel,
        squareLabel;

enum GameStatus { playing, check, checkmate, stalemate }

enum GameEnginePhase { play, skillChoice, abilityTarget, reaction }

enum MoveOutcome {
  completed,
  awaitingSkillChoice,
  awaitingTarget,
  awaitingReaction,
  cancelled,
}

enum GameEndReason {
  checkmate,
  stalemate,
  draw,
  drawAgreed,
  resign,
  timeout,
  kingDestroyed,
  baskerville,
  exterminatus,
  alternativeVictory,
}

enum _SquareColorLock { light, dark }

class MoveResult {
  const MoveResult({
    required this.requiresSkillChoice,
    this.outcome = MoveOutcome.completed,
  });

  final bool requiresSkillChoice;
  final MoveOutcome outcome;
  bool get isAwaitingReaction => outcome == MoveOutcome.awaitingReaction;
  bool get wasCancelled => outcome == MoveOutcome.cancelled;
}

class KnightGuardState {
  const KnightGuardState({
    required this.knightId,
    required this.square,
    required this.ownerTurnsLeft,
  });

  final String knightId;
  final Square square;
  final int ownerTurnsLeft;
}

enum GraveyardReason { capture, explosion, plague, ability, environment }

class GraveyardRecord {
  const GraveyardRecord({
    required this.piece,
    required this.originalOwner,
    required this.capturingColor,
    required this.sequence,
    required this.reason,
  });

  final Piece piece;
  final PieceColor originalOwner;
  final PieceColor? capturingColor;
  final int sequence;
  final GraveyardReason reason;

  bool get wasCapturedByOpponent =>
      reason == GraveyardReason.capture &&
      capturingColor != null &&
      capturingColor != originalOwner;
}

class RookSiegeState {
  const RookSiegeState({
    required this.rookId,
    required this.targetPieceId,
    required this.counter,
  });

  final String rookId;
  final String targetPieceId;
  final int counter;
}

class RookCurfewState {
  const RookCurfewState({
    required this.rookId,
    required this.pieceId,
    required this.ownerTurnsLeft,
  });

  final String rookId;
  final String pieceId;
  final int ownerTurnsLeft;
}

class CustomsState {
  const CustomsState({
    required this.rookId,
    required this.owner,
    required this.axis,
    required this.line,
    required this.turnsLeft,
    required this.exemptPieceIds,
  });

  final String rookId;
  final PieceColor owner;
  final AbilityAxis axis;
  final int line;
  final int turnsLeft;
  final Set<String> exemptPieceIds;

  CustomsState copyWith({int? turnsLeft, Set<String>? exemptPieceIds}) =>
      CustomsState(
        rookId: rookId,
        owner: owner,
        axis: axis,
        line: line,
        turnsLeft: turnsLeft ?? this.turnsLeft,
        exemptPieceIds: exemptPieceIds ?? this.exemptPieceIds,
      );
}

class DelayedSentenceState {
  const DelayedSentenceState({
    required this.queenId,
    required this.targetId,
    required this.targetOwner,
  });

  final String queenId;
  final String targetId;
  final PieceColor targetOwner;
}

class SiegeInternalState {
  const SiegeInternalState({
    required this.targetId,
    required this.counter,
    required this.rookSquare,
  });

  final String targetId;
  final int counter;
  final Square rookSquare;
}

class ChessGame {
  static const defaultFileCount = 8;
  static const defaultRankCount = 8;

  ChessGame({
    AbilityCatalog? catalog,
    Random? random,
    Set<PieceColor>? abilityChoosingColors,
    Set<GameAbility>? excludedAbilities,
  }) : _catalog = catalog ?? AbilityCatalog(),
       _random = random ?? Random(),
       _abilityChoosingColors =
           abilityChoosingColors ??
           const {PieceColor.white, PieceColor.black},
       _excludedAbilities = excludedAbilities ?? const {} {
    _board = _createInitialBoard();
    _whiteStartOffers = _resolveTeleportOffers(
      _catalog.pickStartOffers(
        forColor: PieceColor.white,
        excludedAbilities: _excludedAbilities,
      ),
    );
    _blackStartOffers = _resolveTeleportOffers(
      _catalog.pickStartOffers(
        forColor: PieceColor.black,
        excludedAbilities: _excludedAbilities,
      ),
    );
    // Sides that never pick mods (e.g. computer) skip start selection.
    if (!_abilityChoosingColors.contains(PieceColor.white)) {
      _whiteStartChosen = true;
    }
    if (!_abilityChoosingColors.contains(PieceColor.black)) {
      _blackStartChosen = true;
    }
  }

  final AbilityCatalog _catalog;
  final Random _random;
  final Set<PieceColor> _abilityChoosingColors;
  final Set<GameAbility> _excludedAbilities;
  final BoardCataclysmState _rules = BoardCataclysmState();

  late List<List<Piece?>> _board;
  final Map<String, Piece> _stackExtra = {};
  int _nextPieceId = 32;
  int _fileCount = defaultFileCount;
  int _rankCount = defaultRankCount;
  bool? _extraFileOnLeft;
  PieceColor _turn = PieceColor.white;
  Square? _enPassantTarget;
  GameStatus _status = GameStatus.playing;
  PieceColor? _winnerColor;
  GameEndReason? _endReason;
  /// Machine key for mod-specific endings (debtPit, kingOfHill, ...).
  String? _endDetail;
  bool _isSimulatingLegality = false;
  GameSnapshot? _undoSnapshot;

  bool _whiteStartChosen = false;
  bool _blackStartChosen = false;
  late List<AbilityOffer> _whiteStartOffers;
  late List<AbilityOffer> _blackStartOffers;

  Square? _pendingSkillSquare;
  String? _pendingSkillPieceId;
  PieceColor? _pendingSkillColor;
  List<AbilityOffer> _pendingCaptureOffers = const [];
  Square? _auctionSquare;
  Square? _pendingAuctionSquare;
  PieceColor? _pendingAuctionColor;
  PieceColor? _pendingBonusSkillColor;
  bool _skillChoiceIsBonus = false;
  GameAbility? _whiteBoardAbility;
  GameAbility? _blackBoardAbility;
  bool _bloodOathActive = false;
  bool _baskervilleActive = false;
  int _whiteBaskervilleChecks = 0;
  int _blackBaskervilleChecks = 0;
  bool _goldenThroneWhite = false;
  bool _goldenThroneBlack = false;
  PieceColor? _pendingGoldenThroneColor;
  int _exterminatusPliesLeft = 0;
  int? _silentFile;
  bool _suppressCaptureSideEffects = false;
  ChosenAbilityInfo? _whiteStartAbilityInfo;
  ChosenAbilityInfo? _blackStartAbilityInfo;
  final List<ChosenAbilityInfo> _whiteChosenAbilities = [];
  final List<ChosenAbilityInfo> _blackChosenAbilities = [];
  bool _whiteOneShotReroll = false;
  bool _blackOneShotReroll = false;
  bool _whitePermanentReroll = false;
  bool _blackPermanentReroll = false;
  /// How many times the current skill-choice screen was refreshed (max 1).
  int _skillChoiceRerollsUsed = 0;
  final Set<int> _lavaRanks = {};
  final List<LavaDeathEvent> _pendingLavaDeaths = [];
  bool _fogOfWar = false;
  bool _sprintActive = false;
  Square? _quarantineSquare;
  int _quarantineMovesLeft = 0;
  final Set<Square> _wormholes = {};
  bool _zebrasActive = false;
  bool _whiteDoppelganger = false;
  bool _blackDoppelganger = false;
  _SquareColorLock? _squareColorLock;
  int _squareColorLockMovesLeft = 0;
  int _truceMovesLeft = 0;
  bool _mirrorActive = false;
  int _whiteCavalryMovesLeft = 0;
  int _blackCavalryMovesLeft = 0;
  Square _whiteThrone = const Square(4, 0);
  Square _blackThrone = const Square(4, 7);
  bool _plagueActive = false;
  bool _fourHorsemenActive = false;

  final Set<Square> _ghostCells = {};
  bool _attractionActive = false;
  int _attractionMoveCounter = 0;
  bool _virusActive = false;
  bool _invisibleRegiment = false;
  List<List<bool>>? _shuffledSquareLight;
  Square? _teleportA;
  Square? _teleportB;
  final Set<Square> _mines = {};
  bool _golcondaActive = false;
  bool _unbridledHorse = false;
  final Map<Square, int> _dustSquares = {};
  final Map<int, int> _laserFiles = {}; // deprecated structure
  final Map<int, PieceColor> _laserFileOwner = {};
  Square? _awaitingGallopFrom;
  int _awaitingGallopIndex = 0;

  AbilityTargetSelection? _pendingTargetSelection;
  GameAbility? _pendingTargetAbility;
  String? _pendingTargetSourceId;
  PieceColor? _pendingTargetColor;
  bool _pendingTargetPassesTurn = true;
  Move? _pendingReactionMove;
  String? _pendingRansomPawnId;
  String? _queuedSkillPieceId;
  PieceColor? _queuedSkillColor;

  /// Offer waiting for the player to pick which friendly piece receives it.
  AbilityOffer? _pendingSelectOffer;
  PieceType? _pendingSelectPieceType;

  final Map<String, String> _duelLinks = {};
  final Map<String, Square> _guardSquares = {};
  final Map<String, int> _guardTurnsLeft = {};
  final Map<String, Set<Square>> _knightTourVisited = {};
  final Set<String> _knightTourRewardUsed = {};
  final Map<String, String> _sanctuaryTargets = {};
  final Map<String, PieceType> _excommunicationTypes = {};
  final Map<String, Map<String, GameAbility>> _titheSuppressions = {};
  final Map<String, Set<int>> _pilgrimageQuadrants = {};
  final Set<String> _pilgrimageCompleted = {};
  final Set<String> _pilgrimageProtected = {};
  final Map<String, CustomsState> _customsStates = {};
  final Map<String, RookCurfewState> _curfewBindings = {};
  final Map<String, SiegeInternalState> _siegeStates = {};
  final Map<String, DelayedSentenceState> _delayedSentences = {};
  final List<GraveyardRecord> _graveyard = [];
  int _graveyardSequence = 0;
  int? _pendingExchangeOwnSequence;
  String? _pendingRemoveModTargetId;

  List<List<Piece?>> get board =>
      _board.map((row) => List<Piece?>.from(row)).toList();

  PieceColor get turn => _turn;
  Square? get enPassantTarget => _enPassantTarget;
  GameStatus get status => _status;
  PieceColor? get winnerColor => _winnerColor;
  GameEndReason? get endReason => _endReason;
  String? get endDetail => _endDetail;
  bool get isGameOver => _endReason != null;

  /// Stable fingerprint of turn, status, end state, and board piece identities.
  String get stateHash {
    final b = StringBuffer()
      ..write(turn.name)
      ..write('|')
      ..write(status.name)
      ..write('|')
      ..write(endReason?.name ?? '-')
      ..write('|')
      ..write(winnerColor?.name ?? '-');
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        for (final piece in piecesAt(Square(file, rank))) {
          final abilities = piece.abilities.map((a) => a.name).toList()..sort();
          b.write(
            '|${piece.pieceId}:${piece.type.name}:${piece.color.name}:${abilities.join(",")}',
          );
        }
      }
    }
    return b.toString().hashCode.toRadixString(16);
  }

  bool get isAwaitingSkillChoice =>
      !isGameOver &&
      _pendingSkillColor != null &&
      _pendingCaptureOffers.isNotEmpty;
  bool get isBonusSkillChoice => isAwaitingSkillChoice && _skillChoiceIsBonus;
  GameEnginePhase get enginePhase {
    if (_pendingReactionMove != null) return GameEnginePhase.reaction;
    if (_rules.spotlightPromoId != null) return GameEnginePhase.reaction;
    if (_rules.awaitingCustomsPath) return GameEnginePhase.abilityTarget;
    if (_rules.tangledAwaitingKeep) {
      final owner = _pieceById(_rules.tangledKnightBaseId ?? '')?.piece.color ??
          _pieceById(_rules.tangledCloneId ?? '')?.piece.color;
      if (owner == null || owner == _turn) {
        return GameEnginePhase.abilityTarget;
      }
    }
    if (_rules.tangledAwaitingSecondDest) return GameEnginePhase.play;
    if (_pendingTargetSelection != null) return GameEnginePhase.abilityTarget;
    if (isAwaitingSkillChoice) return GameEnginePhase.skillChoice;
    return GameEnginePhase.play;
  }

  bool get isAwaitingAbilityTarget =>
      enginePhase == GameEnginePhase.abilityTarget;
  bool get isAwaitingReaction =>
      enginePhase == GameEnginePhase.reaction ||
      _rules.spotlightPromoId != null;
  GameAbility? get pendingTargetAbility => _pendingTargetAbility;
  String? get pendingTargetSourcePieceId => _pendingTargetSourceId;
  PieceColor? get pendingTargetColor => _pendingTargetColor;
  Move? get pendingReactionMove => _pendingReactionMove;
  List<GameAbility> get pendingRansomAbilities {
    final pawn = _pieceById(_pendingRansomPawnId)?.piece;
    if (pawn == null) return const [];
    final result = pawn.abilities.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    return result;
  }

  List<KnightGuardState> get knightGuards {
    final result = <KnightGuardState>[];
    for (final entry in _guardSquares.entries.toList()) {
      result.add(
        KnightGuardState(
          knightId: entry.key,
          square: entry.value,
          ownerTurnsLeft: min(3, _guardTurnsLeft[entry.key] ?? 0),
        ),
      );
    }
    result.sort((a, b) => a.knightId.compareTo(b.knightId));
    return result;
  }

  String? duelPartnerOf(String pieceId) => _pieceById(pieceId) == null
      ? null
      : _activeDuelPartner(_pieceById(pieceId)!.piece);
  String? sanctuaryTargetOf(String bishopId) => _sanctuaryTargets[bishopId];
  Set<Square> knightTourVisited(String knightId) =>
      Set<Square>.from(_knightTourVisited[knightId] ?? const {});
  bool knightTourRewardUsed(String knightId) =>
      _knightTourRewardUsed.contains(knightId);
  Set<int> bishopPilgrimageQuadrants(String bishopId) =>
      Set<int>.from(_pilgrimageQuadrants[bishopId] ?? const {});
  bool bishopPilgrimageCompleted(String bishopId) =>
      _pilgrimageCompleted.contains(bishopId);
  List<GraveyardRecord> get graveyard => List.unmodifiable(_graveyard);
  List<RookCurfewState> get rookCurfews =>
      (_curfewBindings.values.toList()
            ..sort((a, b) => a.pieceId.compareTo(b.pieceId)))
          .toList(growable: false);
  List<RookSiegeState> get rookSieges {
    final result = <RookSiegeState>[
      for (final entry in _siegeStates.entries)
        RookSiegeState(
          rookId: entry.key,
          targetPieceId: entry.value.targetId,
          counter: entry.value.counter,
        ),
    ]..sort((a, b) => a.rookId.compareTo(b.rookId));
    return result;
  }
  RookSiegeState? rookSiegeFor(String rookId) {
    final state = _siegeStates[rookId];
    return state == null
        ? null
        : RookSiegeState(
            rookId: rookId,
            targetPieceId: state.targetId,
            counter: state.counter,
          );
  }

  String get pendingAbilityPrompt {
    if (!isAwaitingAbilityTarget) return '';
    if (_pendingSelectOffer != null) {
      final title = _pendingSelectOffer!.ability.title;
      final type = _pendingSelectPieceType;
      final typeName = switch (type) {
        PieceType.pawn => 'пешку',
        PieceType.knight => 'коня',
        PieceType.bishop => 'слона',
        PieceType.rook => 'ладью',
        PieceType.queen => 'ферзя',
        PieceType.king => 'короля',
        null => 'фигуру',
      };
      return '«$title»: выберите $typeName';
    }
    if (_pendingTargetAbility == GameAbility.kingPrisonerExchange) {
      return _pendingExchangeOwnSequence == null
          ? 'Выберите свою фигуру, взятую соперником'
          : 'Соперник выбирает свою взятую фигуру';
    }
    if (_pendingTargetAbility == GameAbility.kingRemoveEnemyMod) {
      return _pendingRemoveModTargetId == null
          ? 'Выберите вражескую фигуру с модами'
          : 'Выберите мод для удаления';
    }
    if (_pendingTargetAbility == GameAbility.queenDelayedSentence) {
      return 'Выберите атакованную вражескую фигуру';
    }
    if (_pendingTargetAbility == GameAbility.knightGallopContract) {
      return 'Контракт галопа: выберите ${_rules.multiCellPicks.length + 1}/3 клетки маршрута';
    }
    if (_pendingTargetAbility == GameAbility.bishopHeretic) {
      return 'Еретик: выберите ${_rules.multiCellPicks.length + 1}/4 клетки для пешек';
    }
    if (_pendingTargetAbility == GameAbility.bishopCartographer) {
      return 'Картограф: выберите клетку на диагонали слона';
    }
    if (_pendingTargetAbility == GameAbility.pawnArchivist) {
      return 'Архивариус: выберите клетку для возврата';
    }
    if (_pendingTargetAbility == GameAbility.bishopProcession) {
      return 'Процессия: выберите союзную пешку на диагонали';
    }
    if (_pendingTargetAbility == GameAbility.pawnPairStep) {
      return 'Парный шаг: выберите соседнюю пешку-союзницу';
    }
    if (_pendingTargetAbility == GameAbility.pawnRockPaperScissors) {
      return 'Цу-е-фа: выберите пару блокирующих пешек';
    }
    return 'Выберите цель способности';
  }

  List<GameAbility> get legalAbilityOptions {
    if (_pendingTargetAbility != GameAbility.kingRemoveEnemyMod ||
        _pendingRemoveModTargetId == null) {
      return const [];
    }
    final target = _pieceById(_pendingRemoveModTargetId)?.piece;
    if (target == null) return const [];
    return target.abilities.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
  }

  List<GraveyardRecord> get legalCapturedAbilityTargets {
    if (_pendingTargetAbility != GameAbility.kingPrisonerExchange) {
      return const [];
    }
    final owner = _pendingTargetColor;
    if (owner == null) return const [];
    return _graveyard
        .where(
          (record) =>
              record.originalOwner == owner &&
              record.capturingColor == owner.opponent &&
              record.wasCapturedByOpponent,
        )
        .toList()
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
  }

  bool get isReadyToPlay => _whiteStartChosen && _blackStartChosen;
  List<AbilityOffer> get pendingCaptureOffers =>
      List<AbilityOffer>.from(_pendingCaptureOffers);
  Square? get auctionSquare => _auctionSquare;
  bool get isAuctionSquare => _auctionSquare != null;
  PieceColor? get pendingSkillColor => _pendingSkillColor;
  bool canRerollPendingOffers(PieceColor color) {
    if (!isAwaitingSkillChoice || pendingSkillColor != color) return false;
    // «Перевыбор» / one-shot: at most one refresh per choice screen.
    if (_skillChoiceRerollsUsed >= 1) return false;
    return color == PieceColor.white
        ? (_whitePermanentReroll || _whiteOneShotReroll)
        : (_blackPermanentReroll || _blackOneShotReroll);
  }

  bool get hasPermanentRerollForPending {
    final c = pendingSkillColor;
    if (c == null) return false;
    return c == PieceColor.white ? _whitePermanentReroll : _blackPermanentReroll;
  }

  List<CustomsState> get customs {
    final result = _customsStates.values.toList()
      ..sort((a, b) => a.rookId.compareTo(b.rookId));
    return result;
  }

  PieceColor? get pendingRansomColor =>
      _pieceById(_pendingRansomPawnId)?.piece.color;

  GameAbility? get whiteBoardAbility => _whiteBoardAbility;
  GameAbility? get blackBoardAbility => _blackBoardAbility;
  Set<int> get lavaRanks => Set<int>.from(_lavaRanks);
  bool get fogOfWarActive => _fogOfWar;

  /// Orthogonal edges blocked by Architect walls.
  List<(Square, Square)> get architectWallEdges {
    final out = <(Square, Square)>[];
    for (final key in _rules.architectWalls) {
      final parts = key.split('|');
      if (parts.length != 2) continue;
      final a = parts[0].split(',');
      final b = parts[1].split(',');
      if (a.length != 2 || b.length != 2) continue;
      final af = int.tryParse(a[0]);
      final ar = int.tryParse(a[1]);
      final bf = int.tryParse(b[0]);
      final br = int.tryParse(b[1]);
      if (af == null || ar == null || bf == null || br == null) continue;
      out.add((Square(af, ar), Square(bf, br)));
    }
    return out;
  }
  bool get sprintActive => _sprintActive;
  int get skillChoiceSeconds => _sprintActive ? 10 : 30;
  Set<Square> get wormholes => Set<Square>.from(_wormholes);
  Set<Square> get ghostCells => Set<Square>.from(_ghostCells);
  Square? get teleportA => _teleportA;
  Square? get teleportB => _teleportB;
  bool get invisibleRegimentActive => _invisibleRegiment;
  bool get attractionActive => _attractionActive;
  bool get virusActive => _virusActive;
  bool get shuffleActive => _shuffledSquareLight != null;
  bool get golcondaActive => _golcondaActive;
  bool get unbridledHorseActive => _unbridledHorse;
  bool get isAwaitingGallop => _awaitingGallopFrom != null;
  Square? get awaitingGallopFrom => _awaitingGallopFrom;
  int get mineCount => _mines.length;
  Map<int, int> get laserFiles => Map<int, int>.from(_laserFiles);
  Set<Square> get dustSquares => _dustSquares.keys.toSet();
  int? get silentFile => _silentFile;

  bool get skipTurnEnabled => _rules.skipTurnEnabled;
  bool get canSkipTurn =>
      _rules.skipTurnEnabled &&
      isReadyToPlay &&
      !isGameOver &&
      enginePhase == GameEnginePhase.play &&
      !isInCheck(_turn);
  bool get troopFatigueActive => _rules.troopFatigueActive;
  bool get combatOpticsActive => _rules.combatOpticsActive;
  bool get kingOfHillActive => _rules.kingOfHillActive;
  Map<Square, PieceColor> get territory =>
      Map<Square, PieceColor>.from(_rules.territory);
  bool get swampActive => _rules.swampActive;
  bool get collectiveMyopiaActive => _rules.collectiveMyopiaActive;
  bool get frostMapActive => _rules.frostMapActive;
  bool get scorchingSunActive => _rules.scorchingSunActive;
  bool get turncoatsActive => _rules.turncoatsActive;
  Set<Square> get sunSquares => Set<Square>.from(_rules.sunSquares);
  Set<Square> get quicksandRevealed =>
      Set<Square>.from(_rules.quicksandRevealed);
  bool isFrozenPiece(String pieceId) =>
      _rules.frozenPieceIds.contains(pieceId);
  bool hasTorch(String pieceId) {
    for (final ids in _rules.torchPieceIds.values) {
      if (ids.contains(pieceId)) return true;
    }
    return false;
  }
  /// Enemy spy id visible to [viewer] (unrevealed).
  String? visibleEnemyTurncoatId(PieceColor viewer) {
    if (!_rules.turncoatsActive) return null;
    final id = _rules.turncoatSpyIds[viewer.opponent];
    if (id == null || _rules.revealedTurncoats.contains(id)) return null;
    return id;
  }

  Move? get lastMove => _lastMove;
  Move? _lastMove;
  bool get royalPilgrimageActive => _rules.royalPilgrimageActive;
  bool get mightMakesRightActive => _rules.mightMakesRightActive;
  bool get expeditionaryCorpsActive => _rules.expeditionaryCorpsActive;
  bool get passiveAggressionActive => _rules.passiveAggressionActive;
  int passiveAggressionCounter(PieceColor color) => color == PieceColor.white
      ? _rules.whitePassiveAggression
      : _rules.blackPassiveAggression;
  List<Square>? secretRouteFor(PieceColor color) {
    final route = _rules.secretRoutes[color];
    return route == null ? null : List<Square>.from(route);
  }
  int secretRouteProgressFor(PieceColor color) =>
      _rules.secretRouteProgress[color] ?? 0;
  String? witnessProtectedPieceId(PieceColor color) =>
      _rules.witnessProtectedPieceId[color];
  String? get revealedWitnessPieceId => _rules.revealedWitnessPieceId;
  String? get forcedMovePieceId => _rules.forcedMovePieceId;
  PieceColor? get bonusQuietMoveColor => _rules.bonusQuietMoveColor;
  PieceType? get strikePieceType =>
      _rules.strikeTurnsLeft > 0 ? _rules.strikePieceType : null;
  int get borderClosureTurnsLeft => _rules.borderClosureTurnsLeft;
  int get myopiaTurnsLeft => _rules.myopiaTurnsLeft;
  int get magicShutdownTurnsLeft => _rules.magicShutdownTurnsLeft;
  bool get suicideCapturePending => _rules.suicideCapturePending;
  bool get abilityEffectsActive => _rules.abilityEffectsActive;

  bool isDustSquare(Square square) => (_dustSquares[square] ?? 0) > 0;

  bool isLaserFile(int file) => (_laserFiles[file] ?? 0) > 0;
  bool isSilentFile(int file) => _silentFile == file;
  Square? get quarantineSquare =>
      _quarantineMovesLeft > 0 ? _quarantineSquare : null;
  int get quarantineMovesLeft => _quarantineMovesLeft;
  bool get zebrasActive => _zebrasActive;
  int get rankCount => _rankCount;
  int get fileCount => _fileCount;
  int get squareColorLockMovesLeft => _squareColorLockMovesLeft;
  int get truceMovesLeft => _truceMovesLeft;
  bool get mirrorActive => _mirrorActive;
  int get whiteCavalryMovesLeft => _whiteCavalryMovesLeft;
  int get blackCavalryMovesLeft => _blackCavalryMovesLeft;
  bool get darkSquaresOnly =>
      _squareColorLock == _SquareColorLock.dark &&
      _squareColorLockMovesLeft > 0;
  bool get lightSquaresOnly =>
      _squareColorLock == _SquareColorLock.light &&
      _squareColorLockMovesLeft > 0;
  bool hasDoppelganger(PieceColor color) =>
      color == PieceColor.white ? _whiteDoppelganger : _blackDoppelganger;

  bool isGhostCell(Square square) => _ghostCells.contains(square);

  bool isTeleportSquare(Square square) =>
      square == _teleportA || square == _teleportB;

  bool isSquareLight(Square square) {
    final shuffled = _shuffledSquareLight;
    if (shuffled != null &&
        square.rank >= 0 &&
        square.rank < shuffled.length &&
        square.file >= 0 &&
        square.file < shuffled[square.rank].length) {
      return shuffled[square.rank][square.file];
    }
    // a1 (file 0, rank 0) is dark — standard chess coloring.
    return (square.file + square.rank).isOdd;
  }

  /// Пешка соперника скрыта эффектом «Невидимый полк».
  bool isPawnHiddenFrom(Piece piece, PieceColor viewer) {
    if (!_invisibleRegiment) return false;
    if (piece.type != PieceType.pawn) return false;
    if (piece.color == viewer) return false;
    return !piece.pawnRevealed;
  }

  /// Стартовые моды доски и выбранные по ходу — для UI.
  ActiveAbilitiesSnapshot activeAbilitiesSnapshot() {
    return ActiveAbilitiesSnapshot(
      whiteStart: _whiteStartAbilityInfo,
      blackStart: _blackStartAbilityInfo,
      whiteChosen: List<ChosenAbilityInfo>.unmodifiable(_whiteChosenAbilities),
      blackChosen: List<ChosenAbilityInfo>.unmodifiable(_blackChosenAbilities),
    );
  }

  ChosenAbilityInfo _infoFromOffer(AbilityOffer offer) {
    return ChosenAbilityInfo(
      ability: offer.ability,
      title: offer.ability.title,
      description: offer.displayDescription,
    );
  }

  void _recordChosenAbility(PieceColor color, AbilityOffer offer) {
    final info = _infoFromOffer(offer);
    if (color == PieceColor.white) {
      _whiteChosenAbilities.add(info);
    } else {
      _blackChosenAbilities.add(info);
    }
  }

  Set<GameAbility> _chosenAbilitiesFor(PieceColor color) {
    final start = color == PieceColor.white
        ? _whiteStartAbilityInfo
        : _blackStartAbilityInfo;
    final chosen = color == PieceColor.white
        ? _whiteChosenAbilities
        : _blackChosenAbilities;
    return {
      if (start != null) start.ability,
      ...chosen
          .map((info) => info.ability)
          .where(
            (ability) =>
                ability.group == AbilityGroup.board ||
                ability.group == AbilityGroup.random,
          ),
    };
  }

  ExtraFilePlacement get extraFilePlacement {
    if (_fileCount >= 10) return ExtraFilePlacement.both;
    if (_fileCount <= defaultFileCount) return ExtraFilePlacement.none;
    return _extraFileOnLeft == true
        ? ExtraFilePlacement.left
        : ExtraFilePlacement.right;
  }

  bool isOnBoard(Square square) =>
      square.file >= 0 &&
      square.file < _fileCount &&
      square.rank >= 0 &&
      square.rank < _rankCount;

  bool isQuarantined(Square square) =>
      _quarantineMovesLeft > 0 && _quarantineSquare == square;

  bool isBlocked(Square square) =>
      isQuarantined(square) ||
      _wormholes.contains(square) ||
      isDustSquare(square);

  String _stackKey(Square square) => '${square.file},${square.rank}';

  List<Piece> piecesAt(Square square) {
    if (!isOnBoard(square)) return const [];
    final primary = _board[square.rank][square.file];
    final extra = _stackExtra[_stackKey(square)];
    if (primary == null && extra == null) return const [];
    if (primary == null) return [extra!];
    if (extra == null) return [primary];
    return [primary, extra];
  }

  Piece? pieceAt(Square square, {int index = 0}) {
    final pieces = piecesAt(square);
    if (index < 0 || index >= pieces.length) return null;
    return pieces[index];
  }

  void _setPrimary(Square square, Piece? piece) {
    if (!isOnBoard(square)) return;
    _board[square.rank][square.file] = piece == null
        ? null
        : _ensurePieceIdentity(piece);
  }

  void _setExtra(Square square, Piece? piece) {
    if (!isOnBoard(square)) return;
    final key = _stackKey(square);
    if (piece == null) {
      _stackExtra.remove(key);
    } else {
      _stackExtra[key] = _ensurePieceIdentity(piece);
    }
  }

  Piece _ensurePieceIdentity(Piece piece) {
    if (piece.pieceId.isNotEmpty) return piece;
    final id = 'piece-${_nextPieceId++}';
    return piece.copyWith(pieceId: id);
  }

  void _clearSquare(Square square) {
    _setPrimary(square, null);
    _setExtra(square, null);
  }

  void _setCell(Square square, List<Piece> pieces) {
    _clearSquare(square);
    if (pieces.isEmpty) return;
    _setPrimary(square, pieces.first);
    if (pieces.length > 1) {
      _setExtra(square, pieces[1]);
    }
  }

  void _replacePieceAt(Square square, int index, Piece piece) {
    final pieces = piecesAt(square);
    if (index < 0 || index >= pieces.length) return;
    final next = List<Piece>.from(pieces);
    next[index] = piece;
    _setCell(square, next);
  }

  void _rekeyStackExtras({
    int fileDelta = 0,
    int rankDelta = 0,
    bool Function(Square square)? shouldShift,
  }) {
    final next = <String, Piece>{};
    for (final entry in _stackExtra.entries) {
      final parts = entry.key.split(',');
      final square = Square(int.parse(parts[0]), int.parse(parts[1]));
      if (shouldShift != null && !shouldShift(square)) {
        next[entry.key] = entry.value;
        continue;
      }

      final target = Square(square.file + fileDelta, square.rank + rankDelta);
      next[_stackKey(target)] = entry.value;
    }

    _stackExtra
      ..clear()
      ..addAll(next);
  }

  Piece? _takePieceAt(Square square, int index) {
    final pieces = piecesAt(square);
    if (index < 0 || index >= pieces.length) return null;
    final taken = pieces[index];
    if (pieces.length == 1) {
      _clearSquare(square);
    } else if (index == 0) {
      _setCell(square, [pieces[1]]);
    } else {
      _setCell(square, [pieces[0]]);
    }
    return taken;
  }

  Set<Square> visibleSquaresFor(PieceColor color) {
    final visible = <Square>{};

    // Kriegspiel: only your own pieces (and duck) are visible.
    if (_rules.kriegspielActive && !_fogOfWar) {
      for (var rank = 0; rank < _rankCount; rank++) {
        for (var file = 0; file < _fileCount; file++) {
          final square = Square(file, rank);
          if (piecesAt(square).any((p) => _canControl(p, color))) {
            visible.add(square);
          }
        }
      }
      if (_rules.duckSquare != null) visible.add(_rules.duckSquare!);
      return visible;
    }

    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        final pieces = piecesAt(square);
        for (var index = 0; index < pieces.length; index++) {
          final piece = pieces[index];
          if (!_canControl(piece, color)) continue;

          visible.add(square);

          // Dark chess: squares the piece can move to or capture onto
          // (pawns also see empty diagonals they could capture on).
          for (final move in _getPseudoLegalMoves(
            square,
            piece,
            pieceIndex: index,
          )) {
            visible.add(move.to);
          }
          if (piece.type == PieceType.pawn) {
            final dir = piece.color == PieceColor.white ? 1 : -1;
            for (final df in const [-1, 1]) {
              final attack = Square(file + df, rank + dir);
              if (isOnBoard(attack)) visible.add(attack);
            }
          }

          if (_hasEffect(piece, AbilityEffect.signalTower)) {
            for (var r = 0; r < _rankCount; r++) {
              visible.add(Square(file, r));
            }
            for (var f = 0; f < _fileCount; f++) {
              visible.add(Square(f, rank));
            }
          }
        }
      }
    }

    visible.addAll(_rules.permanentFogReveals[color] ?? const {});
    return visible;
  }

  bool get blindSpotActive => _rules.blindSpotActive;

  bool isPieceHiddenFrom(Piece piece, PieceColor viewer) {
    if (isPawnHiddenFrom(piece, viewer)) return true;
    if (piece.color == viewer) return false;
    if (!_rules.abilityEffectsActive) return false;
    return _isCamouflaged(piece);
  }

  List<({Square square, PieceColor color})> illusionsVisibleTo(
    PieceColor viewer,
  ) {
    return [
      for (final illusion in _rules.knightIllusions)
        if (illusion.color != viewer) illusion,
    ];
  }

  bool _isCamouflaged(Piece piece) {
    if (!_sideHasEffect(piece.color, AbilityEffect.camouflageNet)) {
      return false;
    }
    final ref = _pieceById(piece.pieceId);
    if (ref == null) return false;
    var pawns = 0;
    for (var dr = -1; dr <= 1; dr++) {
      for (var df = -1; df <= 1; df++) {
        if (df == 0 && dr == 0) continue;
        final n = _offsetSquare(ref.square, df, dr);
        if (n == null) continue;
        for (final p in piecesAt(n)) {
          if (p.color == piece.color && p.type == PieceType.pawn) pawns++;
        }
      }
    }
    return pawns >= 3;
  }

  bool _sideHasEffect(PieceColor color, AbilityEffect effect) {
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        for (final piece in piecesAt(Square(file, rank))) {
          if (piece.color == color && _hasEffect(piece, effect)) return true;
        }
      }
    }
    return false;
  }

  List<LavaDeathEvent> consumeLavaDeaths() {
    if (_pendingLavaDeaths.isEmpty) return const [];
    final events = List<LavaDeathEvent>.from(_pendingLavaDeaths);
    _pendingLavaDeaths.clear();
    return events;
  }

  /// Local UI-only preview of applying [offer] (does not sync online).
  void previewApplyOffer(PieceColor color, AbilityOffer offer) {
    _applyOffer(color, offer, null);
  }

  @visibleForTesting
  void debugSetPiece(Square square, Piece? piece) {
    if (piece == null) {
      _clearSquare(square);
    } else {
      _setPrimary(square, piece);
    }
  }

  @visibleForTesting
  void debugAttractionPulse() {
    _applyAttractionPulse();
  }

  @visibleForTesting
  void debugTickFrostMap(PieceColor finished) {
    _tickFrostMap(finished);
  }

  @visibleForTesting
  void debugSetTorchIds(PieceColor color, Set<String> ids) {
    _rules.torchPieceIds[color] = {...ids};
  }

  @visibleForTesting
  void debugSetTurn(PieceColor color) {
    _turn = color;
  }

  @visibleForTesting
  void debugUpdateStatus() {
    _updateStatus();
  }

  @visibleForTesting
  void debugGrantAbility(
    Square square,
    GameAbility ability, {
    int pieceIndex = 0,
    AbilityOffer? offer,
  }) {
    _grantAbility(square, ability, pieceIndex: pieceIndex, offer: offer);
  }

  @visibleForTesting
  void debugApplyOffer(PieceColor color, AbilityOffer offer) {
    _applyOffer(color, offer, null);
  }

  @visibleForTesting
  void debugPaintTerritory(Square square, PieceColor color) {
    _rules.territory[square] = color;
  }

  @visibleForTesting
  void debugSetPassiveAggressionCounter(PieceColor color, int value) {
    if (color == PieceColor.white) {
      _rules.whitePassiveAggression = value;
    } else {
      _rules.blackPassiveAggression = value;
    }
  }

  List<Square> get legalAbilityTargetSquares {
    if (_rules.tangledAwaitingKeep) {
      final owner = _pieceById(_rules.tangledKnightBaseId ?? '')?.piece.color ??
          _pieceById(_rules.tangledCloneId ?? '')?.piece.color;
      if (owner == _turn || owner == null) {
        return tangledKeepSquares;
      }
    }
    if (!isAwaitingAbilityTarget) return const [];
    if (isAwaitingMultiCell) {
      return _legalMultiCellSquares();
    }
    if (_pendingTargetSelection == AbilityTargetSelection.cell) {
      if (_pendingTargetAbility == GameAbility.randomWordOfHonor) {
        final squares = <Square>[];
        for (var rank = 0; rank < _rankCount; rank++) {
          for (var file = 0; file < _fileCount; file++) {
            squares.add(Square(file, rank));
          }
        }
        return squares;
      }
      if (_pendingTargetAbility == GameAbility.knightGallopContract ||
          _pendingTargetAbility == GameAbility.bishopHeretic ||
          _pendingTargetAbility == GameAbility.bishopCartographer ||
          _pendingTargetAbility == GameAbility.pawnArchivist) {
        return _legalMultiCellSquares();
      }
      if (_pendingTargetAbility == GameAbility.knightGuard) {
        final source = _pieceById(_pendingTargetSourceId);
        if (source == null) return const [];
        return _knightJumpMoves(
              source.square,
              source.piece,
              pieceIndex: source.index,
            )
            .where((move) => piecesAt(move.to).isEmpty)
            .map((move) => move.to)
            .toList();
      }
      // Generic empty cells fallback
      final squares = <Square>[];
      for (var rank = 0; rank < _rankCount; rank++) {
        for (var file = 0; file < _fileCount; file++) {
          final s = Square(file, rank);
          if (piecesAt(s).isEmpty && !isBlocked(s)) squares.add(s);
        }
      }
      return squares;
    }
    return [for (final target in _legalPieceTargets()) target.square];
  }

  List<String> get legalAbilityTargetPieceIds =>
      _legalPieceTargets().map((target) => target.piece.pieceId).toList();

  List<({Square square, int index, Piece piece})> _legalPieceTargets() {
    if (!isAwaitingAbilityTarget) return const [];
    final source = _pieceById(_pendingTargetSourceId);
    final chooser = _pendingTargetColor ?? source?.piece.color;
    if (chooser == null) return const [];
    final selectingRecipient = _pendingSelectOffer != null;
    final friendly =
        _pendingTargetSelection == AbilityTargetSelection.friendlyPiece ||
        _pendingTargetSelection == AbilityTargetSelection.secretFriendlyPiece;
    final enemy = _pendingTargetSelection == AbilityTargetSelection.enemyPiece;
    final enemyAbility =
        _pendingTargetSelection == AbilityTargetSelection.enemyAbility;
    if (!friendly && !enemy && !enemyAbility) return const [];
    final result = <({Square square, int index, Piece piece})>[];
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        final pieces = piecesAt(square);
        for (var index = 0; index < pieces.length; index++) {
          final piece = pieces[index];
          if (!selectingRecipient && piece.type == PieceType.king) continue;
          if (selectingRecipient &&
              _pendingSelectPieceType != null &&
              piece.type != _pendingSelectPieceType) {
            continue;
          }
          if (friendly && piece.color != chooser) continue;
          if ((enemy || enemyAbility) && piece.color == chooser) {
            continue;
          }
          if (enemyAbility && piece.abilities.isEmpty) continue;
          if (source != null && piece.pieceId == source.piece.pieceId) continue;
          if (source != null &&
              _pendingTargetAbility == GameAbility.queenDelayedSentence &&
              !_canAttack(source.square, square, source.piece)) {
            continue;
          }
          if (source != null &&
              _pendingTargetAbility == GameAbility.knightRideMe) {
            if (piece.type != PieceType.pawn) continue;
            if (_chebyshevDistance(source.square, square) != 1) continue;
          }
          if (source != null &&
              _pendingTargetAbility == GameAbility.bishopParallelWorlds) {
            final df = (square.file - source.square.file).abs();
            final dr = (square.rank - source.square.rank).abs();
            if (df != dr || df == 0) continue;
            if (source.piece.parallelWorldsUsed) continue;
          }
          if (source != null &&
              _pendingTargetAbility == GameAbility.pawnPairStep) {
            if (piece.type != PieceType.pawn) continue;
            if (_chebyshevDistance(source.square, square) != 1) continue;
          }
          if (source != null &&
              _pendingTargetAbility == GameAbility.bishopProcession) {
            if (piece.type != PieceType.pawn) continue;
            final df = (square.file - source.square.file).abs();
            final dr = (square.rank - source.square.rank).abs();
            if (df != dr || df == 0) continue;
          }
          if (source != null &&
              (_pendingTargetAbility == GameAbility.knightNonAggression ||
                  _pendingTargetAbility == GameAbility.bishopNonAggression)) {
            if (piece.type != PieceType.knight &&
                piece.type != PieceType.bishop) {
              continue;
            }
          }
          if (source != null &&
              _pendingTargetAbility == GameAbility.rookSeal) {
            if (!_canAttack(source.square, square, source.piece)) continue;
          }
          if (source != null &&
              _pendingTargetAbility == GameAbility.queenCourtIntrigue) {
            final enemyKing = findKing(piece.color);
            if (enemyKing != null &&
                _chebyshevDistance(square, enemyKing) <= 2) {
              continue;
            }
          }
          if (_pendingTargetAbility == GameAbility.pawnStarvation) {
            if (piece.type != PieceType.pawn) continue;
          }
          if (_pendingTargetAbility == GameAbility.pawnRockPaperScissors) {
            continue; // handled via RPS overlay, not piece taps
          }
          result.add((square: square, index: index, piece: piece));
        }
      }
    }
    return result;
  }

  bool chooseAbilityTarget({String? pieceId, Square? square, int index = 0}) {
    if (_rules.tangledAwaitingKeep && square != null) {
      return chooseTangledKeep(square);
    }
    if (!isAwaitingAbilityTarget) return false;
    final ability = _pendingTargetAbility;
    final sourceId = _pendingTargetSourceId;
    if (ability == null || sourceId == null) return false;

    if (_pendingTargetSelection == AbilityTargetSelection.cell) {
      if (square == null || !legalAbilityTargetSquares.contains(square)) {
        return false;
      }
      if (_rules.tangledAwaitingKeep) {
        return chooseTangledKeep(square);
      }
      if (ability == GameAbility.randomWordOfHonor) {
        _rules.wordOfHonorSquare = square;
        _rules.wordOfHonorColor = _pendingTargetColor ?? PieceColor.white;
      } else if (ability == GameAbility.knightGuard) {
        _guardSquares[sourceId] = square;
        _guardTurnsLeft[sourceId] = 4;
      } else if (ability == GameAbility.knightGallopContract ||
          ability == GameAbility.bishopHeretic ||
          ability == GameAbility.bishopCartographer ||
          ability == GameAbility.pawnArchivist ||
          isAwaitingMultiCell) {
        if (_rules.multiCellAbility == null) {
          _rules.multiCellAbility = ability;
          _rules.multiCellSourceId = sourceId;
          _rules.multiCellColor = _pendingTargetColor;
          _rules.multiCellNeeded = switch (ability) {
            GameAbility.knightGallopContract => 3,
            GameAbility.bishopHeretic => 4,
            _ => 1,
          };
          _rules.multiCellPicks.clear();
        }
        return _acceptMultiCellPick(square);
      } else {
        return false;
      }
    } else if (_pendingTargetSelection ==
        AbilityTargetSelection.capturedFriendlyPiece) {
      final options = legalCapturedAbilityTargets;
      GraveyardRecord? selectedRecord;
      for (final record in options) {
        if (pieceId != null && record.piece.pieceId == pieceId) {
          selectedRecord = record;
          break;
        }
        if (pieceId == null && record.sequence == index) {
          selectedRecord = record;
          break;
        }
      }
      if (selectedRecord == null) return false;
      if (_pendingExchangeOwnSequence == null) {
        _pendingExchangeOwnSequence = selectedRecord.sequence;
        final chooser = _pendingTargetColor;
        if (chooser != null) {
          _pendingTargetColor = chooser.opponent;
        }
        _updateStatus();
        return true;
      }
      final ownRecord = _graveyard.cast<GraveyardRecord?>().firstWhere(
        (record) => record!.sequence == _pendingExchangeOwnSequence,
        orElse: () => null,
      );
      if (ownRecord == null) return false;
      _completePrisonerExchange(ownRecord, selectedRecord);
    } else if (_pendingTargetSelection == AbilityTargetSelection.enemyAbility ||
        (_pendingTargetAbility == GameAbility.kingRemoveEnemyMod &&
            _pendingRemoveModTargetId == null)) {
      ({Square square, int index, Piece piece})? selected;
      for (final target in _legalPieceTargets()) {
        if ((pieceId != null && target.piece.pieceId == pieceId) ||
            (pieceId == null &&
                square == target.square &&
                index == target.index)) {
          selected = target;
          break;
        }
      }
      if (selected == null || selected.piece.abilities.isEmpty) return false;
      final abilities = selected.piece.abilities.toList()
        ..sort((a, b) => a.index.compareTo(b.index));
      if (abilities.length == 1) {
        _replacePieceAt(
          selected.square,
          selected.index,
          selected.piece.withoutAbility(abilities.first),
        );
        _refreshDoppelgangerFlags();
      } else {
        _pendingRemoveModTargetId = selected.piece.pieceId;
        _updateStatus();
        return true;
      }
    } else {
      ({Square square, int index, Piece piece})? selected;
      for (final target in _legalPieceTargets()) {
        if ((pieceId != null && target.piece.pieceId == pieceId) ||
            (pieceId == null &&
                square == target.square &&
                index == target.index)) {
          selected = target;
          break;
        }
      }
      if (selected == null) return false;
      final selectOffer = _pendingSelectOffer;
      if (selectOffer != null) {
        final chooser = _pendingTargetColor ?? selected.piece.color;
        _pendingSelectOffer = null;
        _pendingSelectPieceType = null;
        // End the "which piece gets the mod" phase before granting.
        // `_grantAbility` may start a genuine secondary target (duel/guard/…).
        _clearPendingTarget();
        if (selectOffer.ability == GameAbility.queenSplit) {
          _splitQueen(selected.square);
        } else {
          _grantAbility(
            selected.square,
            selectOffer.ability,
            offer: selectOffer,
            pieceIndex: selected.index,
          );
        }
        if (isAwaitingAbilityTarget) {
          _updateStatus();
          return true;
        }
        _completeSkillChoiceResolution(chooser, offer: selectOffer);
        return true;
      }
      switch (ability) {
        case GameAbility.knightDuel:
          _duelLinks[sourceId] = selected.piece.pieceId;
          _duelLinks[selected.piece.pieceId] = sourceId;
        case GameAbility.bishopSanctuary:
          _sanctuaryTargets[sourceId] = selected.piece.pieceId;
        case GameAbility.bishopPilgrimage:
          _pilgrimageProtected.add(selected.piece.pieceId);
          _pilgrimageCompleted.add(sourceId);
        case GameAbility.queenDelayedSentence:
          _delayedSentences[sourceId] = DelayedSentenceState(
            queenId: sourceId,
            targetId: selected.piece.pieceId,
            targetOwner: selected.piece.color,
          );
        case GameAbility.boardWitnessProtection:
          _rules.witnessProtectedPieceId[
                  _pendingTargetColor ?? selected.piece.color] =
              selected.piece.pieceId;
        case GameAbility.randomRightToMove:
          _rules.forcedMovePieceId = selected.piece.pieceId;
          _rules.forcedMoveOwner = selected.piece.color;
        case GameAbility.randomVeto:
          _rules.vetoPieceId = selected.piece.pieceId;
          _rules.vetoOwner = selected.piece.color;
          if (_rules.vetoTurnsLeft <= 0) {
            _rules.vetoTurnsLeft = 3;
          }
        case GameAbility.knightRideMe:
          _rules.pendingRideKnightId = sourceId;
          _rules.pendingRidePawnId = selected.piece.pieceId;
        case GameAbility.knightNonAggression:
        case GameAbility.bishopNonAggression:
          _rules.nonAggressionLink[sourceId] = selected.piece.pieceId;
          _rules.nonAggressionLink[selected.piece.pieceId] = sourceId;
        case GameAbility.pawnPairStep:
          _rules.pairStepPartner[sourceId] = selected.piece.pieceId;
          _rules.pairStepPartner[selected.piece.pieceId] = sourceId;
        case GameAbility.bishopProcession:
          _applyProcessionNudge(sourceId, selected.piece.pieceId);
        case GameAbility.pawnStarvation:
          _rules.starvationPlies[selected.piece.pieceId] = 6;
        case GameAbility.rookSeal:
          _rules.sealRookId = sourceId;
          _rules.sealVictimId = selected.piece.pieceId;
        case GameAbility.queenCourtIntrigue:
          _rules.courtIntrigueQueenId = sourceId;
          _rules.courtIntrigueVictimId = selected.piece.pieceId;
        case GameAbility.bishopParallelWorlds:
          final source = _pieceById(sourceId);
          if (source == null || source.piece.parallelWorldsUsed) return false;
          final sourcePiece = source.piece.copyWith(parallelWorldsUsed: true);
          final selectedPiece = selected.piece;
          _clearSquare(source.square);
          _clearSquare(selected.square);
          _setPrimary(selected.square, sourcePiece);
          _setPrimary(source.square, selectedPiece);
        default:
          return false;
      }
    }

    return _finishAbilityTargetSelection();
  }

  bool chooseAbilityToRemove(GameAbility ability) {
    if (!isAwaitingAbilityTarget ||
        _pendingTargetAbility != GameAbility.kingRemoveEnemyMod ||
        _pendingRemoveModTargetId == null) {
      return false;
    }
    if (!legalAbilityOptions.contains(ability)) return false;
    final target = _pieceById(_pendingRemoveModTargetId);
    if (target == null || !target.piece.abilities.contains(ability)) {
      return false;
    }
    _replacePieceAt(
      target.square,
      target.index,
      target.piece.withoutAbility(ability),
    );
    _refreshDoppelgangerFlags();
    return _finishAbilityTargetSelection();
  }

  void _completePrisonerExchange(
    GraveyardRecord ownRecord,
    GraveyardRecord opponentRecord,
  ) {
    _graveyard.removeWhere(
      (record) =>
          record.sequence == ownRecord.sequence ||
          record.sequence == opponentRecord.sequence,
    );
    final slots = _randomEmptyPlaceableSquares(2);
    if (slots.isNotEmpty) {
      _setPrimary(
        slots[0],
        ownRecord.piece.copyWith(hasMoved: true),
      );
    }
    if (slots.length > 1) {
      _setPrimary(
        slots[1],
        opponentRecord.piece.copyWith(hasMoved: true),
      );
    }
  }

  List<Square> _randomEmptyPlaceableSquares(int count) {
    final candidates = <Square>[];
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        if (piecesAt(square).isNotEmpty) continue;
        if (isBlocked(square) || isGhostCell(square)) continue;
        candidates.add(square);
      }
    }
    candidates.shuffle(_random);
    return candidates.take(count).toList();
  }

  bool _finishAbilityTargetSelection() {
    final passesTurn = _pendingTargetPassesTurn;
    final chooser = _pendingTargetColor;
    _clearPendingTarget();
    if (_startQueuedPieceChoice()) {
      _updateStatus();
      return true;
    }
    if (_rules.pendingPeriodicChooserQueue.isNotEmpty && chooser != null) {
      _completeSkillChoiceResolution(
        chooser,
        offer: AbilityOffer(
          ability: GameAbility.boardReroll,
          applyMode: AbilityApplyMode.boardWide,
        ),
      );
      return true;
    }
    if (passesTurn) _passTurn();
    _updateStatus();
    return true;
  }

  bool acceptRansom(GameAbility ability) {
    final pawnRef = _pieceById(_pendingRansomPawnId);
    if (!isAwaitingReaction ||
        pawnRef == null ||
        !pawnRef.piece.abilities.contains(ability)) {
      return false;
    }
    _replacePieceAt(
      pawnRef.square,
      pawnRef.index,
      pawnRef.piece.withoutAbility(ability),
    );
    _pendingReactionMove = null;
    _pendingRansomPawnId = null;
    _updateStatus();
    return true;
  }

  MoveResult? declineRansom() {
    final move = _pendingReactionMove;
    if (move == null) return null;
    _pendingReactionMove = null;
    _pendingRansomPawnId = null;
    return _executeLegalMove(move, skipReaction: true);
  }

  bool isAwaitingStartChoice(PieceColor color) {
    if (!_abilityChoosingColors.contains(color)) return false;
    if (color == PieceColor.white) return !_whiteStartChosen;
    return !_blackStartChosen;
  }

  bool choosesAbilities(PieceColor color) =>
      _abilityChoosingColors.contains(color);

  List<AbilityOffer> startOffersFor(PieceColor color) {
    return color == PieceColor.white ? _whiteStartOffers : _blackStartOffers;
  }

  /// Mark start selection done without applying a board mod (vs computer).
  void skipStartAbility(PieceColor color) {
    if (!isAwaitingStartChoice(color) &&
        ((color == PieceColor.white && _whiteStartChosen) ||
            (color == PieceColor.black && _blackStartChosen))) {
      return;
    }
    if (color == PieceColor.white) {
      _whiteStartChosen = true;
    } else {
      _blackStartChosen = true;
    }
    if (isReadyToPlay) {
      _updateStatus();
    }
  }

  /// Decline a mid-game / capture skill offer without applying it.
  void skipPendingAbility() {
    if (_pendingSkillColor == null) return;
    final chooserColor = _pendingSkillColor!;
    _pendingSkillSquare = null;
    _pendingSkillPieceId = null;
    _pendingSkillColor = null;
    _pendingCaptureOffers = const [];
    _completeSkillChoiceResolution(
      chooserColor,
      offer: const AbilityOffer(
        ability: GameAbility.boardReroll,
        applyMode: AbilityApplyMode.boardWide,
      ),
    );
  }

  /// Auto-pick any pending ability target (computer / search).
  bool autoResolveAbilityTarget() {
    var guard = 0;
    while (isAwaitingAbilityTarget && guard++ < 8) {
      if (legalAbilityOptions.isNotEmpty) {
        if (!chooseAbilityToRemove(legalAbilityOptions.first)) break;
        continue;
      }
      final captured = legalCapturedAbilityTargets;
      if (captured.isNotEmpty) {
        if (!chooseAbilityTarget(pieceId: captured.first.piece.pieceId)) {
          break;
        }
        continue;
      }
      final ids = legalAbilityTargetPieceIds;
      if (ids.isNotEmpty) {
        if (!chooseAbilityTarget(pieceId: ids.first)) break;
        continue;
      }
      final squares = legalAbilityTargetSquares;
      if (squares.isNotEmpty) {
        if (!chooseAbilityTarget(square: squares.first)) break;
        continue;
      }
      return _finishAbilityTargetSelection();
    }
    return !isAwaitingAbilityTarget;
  }

  void applyStartAbility(
    PieceColor color,
    GameAbility ability, {
    int? lavaRank,
    AbilityOffer? remoteOffer,
  }) {
    if (!isAwaitingStartChoice(color)) return;
    final offers = startOffersFor(color);
    AbilityOffer? offer = remoteOffer;
    offer ??= offers.cast<AbilityOffer?>().firstWhere(
      (o) => o!.ability == ability,
      orElse: () => null,
    );

    if (offer == null &&
        ability == GameAbility.boardLavaRank &&
        lavaRank != null) {
      offer = AbilityOffer(
        ability: ability,
        applyMode: AbilityApplyMode.boardWide,
        lavaRank: lavaRank,
        forColor: color,
      );
    }
    // Online: opponent's pick is almost never in our locally rolled offer
    // list — still apply the ability so both sides reach isReadyToPlay.
    offer ??= AbilityOffer(
      ability: ability,
      applyMode: AbilityApplyMode.boardWide,
      lavaRank: lavaRank,
      forColor: color,
    );

    _applyOffer(color, offer, null);

    final info = _infoFromOffer(offer);
    if (color == PieceColor.white) {
      _whiteStartChosen = true;
      if (offer.ability.group == AbilityGroup.board ||
          offer.ability.group == AbilityGroup.mode) {
        _whiteBoardAbility = offer.ability;
      }
      _whiteStartAbilityInfo = info;
    } else {
      _blackStartChosen = true;
      if (offer.ability.group == AbilityGroup.board ||
          offer.ability.group == AbilityGroup.mode) {
        _blackBoardAbility = offer.ability;
      }
      _blackStartAbilityInfo = info;
    }

    if (isReadyToPlay) {
      _updateStatus();
    }
  }

  void applyRemoteStartAbility(
    PieceColor color,
    GameAbility ability, {
    int? lavaRank,
    AbilityOffer? offer,
  }) {
    applyStartAbility(
      color,
      ability,
      lavaRank: lavaRank ?? offer?.lavaRank,
      remoteOffer: offer,
    );
  }

  bool _canControl(Piece piece, [PieceColor? viewerColor]) {
    final side = viewerColor ?? _turn;
    if (_zebrasActive && piece.type == PieceType.knight) return true;
    if (_isUnrevealedEnemySpy(piece, side)) return true;
    return piece.color == side;
  }

  /// Public UI gate (includes turncoat spies, zebras, …).
  bool canControlPiece(Piece piece, [PieceColor? viewerColor]) =>
      _canControl(piece, viewerColor);

  bool _isUnrevealedEnemySpy(Piece piece, [PieceColor? sideToMove]) {
    final side = sideToMove ?? _turn;
    if (!_rules.turncoatsActive) return false;
    if (_rules.revealedTurncoats.contains(piece.pieceId)) return false;
    return piece.color == side.opponent &&
        _rules.turncoatSpyIds[piece.color] == piece.pieceId;
  }

  PieceColor _actingColor(Piece piece, [PieceColor? sideToMove]) {
    final side = sideToMove ?? _turn;
    if (_isUnrevealedEnemySpy(piece, side)) return side;
    return piece.color;
  }

  bool get _truceActive => _truceMovesLeft > 0;

  bool _isLandingAllowed(Square square, {Piece? forPiece}) {
    if (_rules.duckSquare == square) return false;
    if (isGhostCell(square)) return false;
    if (forPiece != null && !_customsLandingAllowed(square, forPiece)) {
      return false;
    }
    if (forPiece != null &&
        forPiece.hasEffect(AbilityEffect.queenShadowEmpress) &&
        forPiece.boundIsLight != null &&
        isSquareLight(square) != forPiece.boundIsLight) {
      return false;
    }
    if (forPiece != null &&
        forPiece.type == PieceType.pawn &&
        (_rules.inkTrailBlocked[square] ?? 0) > 0) {
      // Ink trail blocks enemy pawns only.
      // Owner of ink is the bishop's color — we block if this pawn's opponent
      // laid the trail; trail map doesn't store owner, so block all enemy-of-
      // none: simply block any pawn landing while trail active (enemy-only
      // effect). Allies of the bishop shouldn't be blocked — without owner we
      // approximate: block if pawn color differs from any ink-trail bishop.
      // Safer: store nothing and block only if an opposing ink-trail bishop exists.
      var enemyInk = false;
      for (var r = 0; r < _rankCount; r++) {
        for (var f = 0; f < _fileCount; f++) {
          for (final p in piecesAt(Square(f, r))) {
            if (_hasEffect(p, AbilityEffect.bishopInkTrail) &&
                p.color != forPiece.color) {
              enemyInk = true;
            }
          }
        }
      }
      if (enemyInk) return false;
    }
    if (forPiece?.type == PieceType.king) {
      for (final entry in _guardSquares.entries) {
        if (entry.value != square || (_guardTurnsLeft[entry.key] ?? 0) <= 0) {
          continue;
        }
        final guard = _pieceById(entry.key);
        if (guard != null && guard.piece.color != forPiece!.color) return false;
      }
      final left = _laserFiles[square.file] ?? 0;
      if (left > 0) {
        final owner = _laserFileOwner[square.file];
        if (owner != null && owner != forPiece!.color) return false;
      }
    }
    if (_squareColorLockMovesLeft <= 0 || _squareColorLock == null) {
      return true;
    }
    final isLightSquare = isSquareLight(square);
    return switch (_squareColorLock!) {
      _SquareColorLock.light => isLightSquare,
      _SquareColorLock.dark => !isLightSquare,
    };
  }

  bool _customsLandingAllowed(Square square, Piece piece) {
    for (final state in _customsStates.values) {
      if (state.turnsLeft <= 0 || state.owner == piece.color) continue;
      final onLine = state.axis == AbilityAxis.rank
          ? square.rank == state.line
          : square.file == state.line;
      if (!onLine) continue;
      if (!state.exemptPieceIds.contains(piece.pieceId)) return false;
    }
    return true;
  }

  /// Central gate for all involuntary ability movement.
  bool canForceMove(Square square, [String? pieceId]) {
    final pieces = piecesAt(square);
    if (pieces.isEmpty) return false;
    if (pieceId != null && !pieces.any((piece) => piece.pieceId == pieceId)) {
      return false;
    }
    final subject = pieceId == null
        ? pieces.first
        : pieces.firstWhere((piece) => piece.pieceId == pieceId);
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final rookSquare = Square(file, rank);
        if (_chebyshevDistance(rookSquare, square) != 1) continue;
        for (final rook in piecesAt(rookSquare)) {
          if (rook.type == PieceType.rook &&
              rook.color == subject.color &&
              _hasEffect(rook, AbilityEffect.rookStandardBearer)) {
            return false;
          }
        }
      }
    }
    return true;
  }

  bool _squareForceMovable(Square square) {
    final pieces = piecesAt(square);
    if (pieces.isEmpty) return true;
    return pieces.every((piece) => canForceMove(square, piece.pieceId));
  }

  bool _curfewAllowsMove(Piece piece, Square from, Square to) {
    final binding = _curfewBindings[piece.pieceId];
    if (binding == null) return true;
    final rook = _pieceById(binding.rookId);
    if (rook == null) {
      _curfewBindings.remove(piece.pieceId);
      return true;
    }
    final fromDist = _chebyshevDistance(from, rook.square);
    final toDist = _chebyshevDistance(to, rook.square);
    return toDist <= fromDist;
  }

  int _wrapFile(int file) {
    final wrapped = file % _fileCount;
    return wrapped < 0 ? wrapped + _fileCount : wrapped;
  }

  Square? _offsetSquare(Square from, int fileDelta, int rankDelta) {
    final rank = from.rank + rankDelta;
    if (rank < 0 || rank >= _rankCount) return null;

    var file = from.file + fileDelta;
    if (_mirrorActive && fileDelta != 0) {
      file = _wrapFile(file);
    } else if (file < 0 || file >= _fileCount) {
      return null;
    }

    return Square(file, rank);
  }

  int _fileDistance(int a, int b) {
    final raw = (a - b).abs();
    if (!_mirrorActive) return raw;
    return min(raw, _fileCount - raw);
  }

  int _stepFileToward(Square from, Square to) {
    final diff = to.file - from.file;
    if (!_mirrorActive || diff == 0) return diff.sign;
    final wrapped = _fileCount - diff.abs();
    if (wrapped < diff.abs()) {
      return diff > 0 ? -1 : 1;
    }
    return diff.sign;
  }

  int _chebyshevDistance(Square a, Square b) {
    return max(_fileDistance(a.file, b.file), (a.rank - b.rank).abs());
  }

  Square _throneFor(PieceColor color) =>
      color == PieceColor.white ? _whiteThrone : _blackThrone;

  void _setThroneFor(PieceColor color, Square square) {
    if (color == PieceColor.white) {
      _whiteThrone = square;
    } else {
      _blackThrone = square;
    }
  }

  bool _isKingOnThrone(PieceColor color, Square square) {
    return _throneFor(color) == square;
  }

  bool _throneBlocksAttack(Square from, Square to, PieceColor byColor) {
    final defender = pieceAt(to);
    if (defender == null ||
        defender.type != PieceType.king ||
        defender.color == byColor ||
        !defender.hasEffect(AbilityEffect.kingThrone) ||
        !_isKingOnThrone(defender.color, to)) {
      return false;
    }
    return _chebyshevDistance(from, to) > 3;
  }

  bool isSquareAttacked(
    Square square,
    PieceColor byColor, {
    bool includeTurncoatSpies = false,
  }) {
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final from = Square(file, rank);
        if (_silentFile != null && from.file == _silentFile) continue;
        for (final piece in piecesAt(from)) {
          if (piece.color != byColor) continue;
          if (_zebrasActive && piece.type == PieceType.knight) continue;
          if (!includeTurncoatSpies &&
              _rules.turncoatsActive &&
              !_rules.revealedTurncoats.contains(piece.pieceId) &&
              _rules.turncoatSpyIds[byColor] == piece.pieceId) {
            // Unrevealed spy secretly serves the opponent — no attacks.
            continue;
          }
          // Ink blot: pieces on a blot cannot give check.
          if (_rules.inkBlotPlies.containsKey(from)) {
            final kingSq = findKing(byColor.opponent);
            if (kingSq == square) continue;
          }
          if (_throneBlocksAttack(from, square, byColor)) continue;
          if (_canAttack(from, square, piece)) return true;
        }
      }
    }
    return false;
  }

  Square? findKing(PieceColor color) {
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        for (final piece in piecesAt(square)) {
          if (piece.type == PieceType.king && piece.color == color) {
            return square;
          }
        }
      }
    }
    return null;
  }

  bool isInCheck(
    PieceColor color, {
    bool includeTurncoatSpies = false,
  }) {
    final kingSquare = findKing(color);
    if (kingSquare == null) return false;
    return isSquareAttacked(
      kingSquare,
      color.opponent,
      includeTurncoatSpies: includeTurncoatSpies,
    );
  }

  List<Move> getLegalMoves({Square? from}) {
    if (!isReadyToPlay || isGameOver) {
      return const [];
    }

    if (_rules.tangledAwaitingSecondDest) {
      final origin = _rules.tangledFrom;
      final first = _rules.tangledFirstDest;
      final id = _rules.tangledKnightBaseId;
      if (origin == null || first == null || id == null) return const [];
      if (from != null && from != origin) return const [];
      final piece = pieceAt(origin);
      if (piece == null || piece.pieceId != id) return const [];
      return _knightJumpMoves(origin, piece, pieceIndex: 0)
          .where((m) => m.to != first)
          .where(_isLegalMove)
          .where(_isBoardRuleLegalMove)
          .toList();
    }

    if (enginePhase != GameEnginePhase.play) {
      return const [];
    }

    if (_awaitingGallopFrom != null) {
      final square = _awaitingGallopFrom!;
      final piece = pieceAt(square, index: _awaitingGallopIndex);
      if (piece == null) {
        _awaitingGallopFrom = null;
        return const [];
      }
      // Только прыжок коня (без шагов кентавра), и только на пустую клетку.
      return _knightJumpMoves(
        square,
        piece,
        pieceIndex: _awaitingGallopIndex,
      ).where((m) => pieceAt(m.to) == null).where(_isLegalMove).toList();
    }

    final moves = <Move>[];

    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        if (from != null && square != from) continue;

        final pieces = piecesAt(square);
        for (var index = 0; index < pieces.length; index++) {
          final piece = pieces[index];
          if (!_canControl(piece)) continue;
          if (piece.skipTurnsLeft > 0) continue;
          if (_rules.frozenPieceIds.contains(piece.pieceId)) continue;
          if ((_rules.quicksandSkipLeft[piece.pieceId] ?? 0) > 0) continue;
          if (_isFaceControlled(piece, square)) continue;
          if (!_pieceAllowedToMoveThisTurn(piece)) continue;

          final movePiece = _isUnrevealedEnemySpy(piece)
              ? piece.copyWith(color: _turn)
              : piece;
          moves.addAll(
            _getPseudoLegalMoves(square, movePiece, pieceIndex: index),
          );
        }
      }
    }

    var legal = moves.where(_isLegalMove).where(_isBoardRuleLegalMove).toList();
    if (_rules.meatGrinderTurnsLeft > 0) {
      final captures = legal.where(_isCapture).toList();
      if (captures.isNotEmpty) legal = captures;
    }
    if (_rules.avengeCaptureSquare != null &&
        _rules.avengeVictimColor == _turn) {
      legal = [...legal, ..._avengeMoves()];
    }
    // Only clear a forced-move lock when the full move list is empty.
    // Per-square queries must not wipe the lock for other pieces.
    if (from == null &&
        _rules.forcedMovePieceId != null &&
        _rules.forcedMoveOwner == _turn &&
        legal.isEmpty) {
      _rules.forcedMovePieceId = null;
      _rules.forcedMoveOwner = null;
      // Recompute without forced-piece filter.
      final retry = <Move>[];
      for (var rank = 0; rank < _rankCount; rank++) {
        for (var file = 0; file < _fileCount; file++) {
          final square = Square(file, rank);
          if (from != null && square != from) continue;
          final pieces = piecesAt(square);
          for (var index = 0; index < pieces.length; index++) {
            final piece = pieces[index];
            if (!_canControl(piece)) continue;
            if (piece.skipTurnsLeft > 0) continue;
            if (_rules.frozenPieceIds.contains(piece.pieceId)) continue;
            if ((_rules.quicksandSkipLeft[piece.pieceId] ?? 0) > 0) continue;
            if (!_pieceAllowedToMoveThisTurn(piece)) continue;
            final movePiece = _isUnrevealedEnemySpy(piece)
                ? piece.copyWith(color: _turn)
                : piece;
            retry.addAll(
              _getPseudoLegalMoves(square, movePiece, pieceIndex: index),
            );
          }
        }
      }
      legal = retry.where(_isLegalMove).where(_isBoardRuleLegalMove).toList();
    }
    return legal;
  }

  /// Pseudo-legal moves a seated player may queue while waiting for the
  /// opponent. Validated again with [getLegalMoves] / [makeMove] on execute.
  List<Move> getPremoveMoves({
    required PieceColor forColor,
    required Square from,
    int pieceIndex = 0,
  }) {
    if (!isReadyToPlay || isGameOver) return const [];
    final pieces = piecesAt(from);
    if (pieceIndex < 0 || pieceIndex >= pieces.length) return const [];
    final piece = pieces[pieceIndex];
    if (!_canControl(piece, forColor)) return const [];
    if (piece.skipTurnsLeft > 0) return const [];
    if (_rules.frozenPieceIds.contains(piece.pieceId)) return const [];
    if ((_rules.quicksandSkipLeft[piece.pieceId] ?? 0) > 0) return const [];
    final movePiece = _isUnrevealedEnemySpy(piece, forColor)
        ? piece.copyWith(color: forColor)
        : piece;
    return _getPseudoLegalMoves(from, movePiece, pieceIndex: pieceIndex)
        .where(_isBoardRuleLegalMove)
        .toList();
  }

  /// View-only last-move highlight (history browse). Not part of snapshots.
  void setLastMoveHighlight(Move? move) {
    _lastMove = move;
  }

  void applyRemoteMove(Move move) {
    _executeLegalMove(move);
  }

  void resign(PieceColor color) {
    if (isGameOver) return;
    _finishGame(
      winner: color.opponent,
      reason: GameEndReason.resign,
    );
  }

  void agreeDraw() {
    if (isGameOver) return;
    _finishGame(
      winner: null,
      reason: GameEndReason.drawAgreed,
      status: GameStatus.stalemate,
    );
  }

  void flagTimeout(PieceColor color) {
    if (isGameOver) return;
    _finishGame(
      winner: color.opponent,
      reason: GameEndReason.timeout,
    );
  }

  void applyRemoteEnd({
    PieceColor? winner,
    GameEndReason? reason,
    String? detail,
  }) {
    if (isGameOver) return;
    _finishGame(
      winner: winner,
      reason: reason ??
          (winner == null ? GameEndReason.draw : GameEndReason.resign),
      status: winner == null ? GameStatus.stalemate : GameStatus.checkmate,
      detail: detail,
    );
  }

  bool get canTakeback =>
      _undoSnapshot != null &&
      !isGameOver &&
      enginePhase == GameEnginePhase.play;

  bool takeback() {
    if (!canTakeback) return false;
    restoreSnapshot(_undoSnapshot!);
    _undoSnapshot = null;
    return true;
  }

  void applyRemoteAbility(GameAbility ability, {AbilityOffer? offer}) {
    if (!isAwaitingSkillChoice) return;
    if (offer != null) {
      final index = _pendingCaptureOffers.indexWhere(
        (o) => o.ability == ability,
      );
      if (index >= 0) {
        final updated = List<AbilityOffer>.from(_pendingCaptureOffers);
        updated[index] = offer;
        _pendingCaptureOffers = updated;
      } else {
        _pendingCaptureOffers = [..._pendingCaptureOffers, offer];
      }
    }
    applyAbility(ability);
  }

  bool rerollPendingOffers(PieceColor color) {
    if (!canRerollPendingOffers(color)) return false;

    _pendingCaptureOffers = _catalog.rerollPeriodicOffers(
      forColor: color,
      board: _board,
      rankCount: _rankCount,
      extraFilePlacement: extraFilePlacement,
      oldOffers: _pendingCaptureOffers,
      blockedSquares: _captureBlockedSquares(),
      chosenAbilities: _chosenAbilitiesFor(color),
      fogOfWarActive: _fogOfWar,
      minesActive: _mines.isNotEmpty,
      mirrorActive: _mirrorActive,
      offerFourChoices: _rules.bigAssortmentOwners.contains(color) ||
          (_rules.bigAssortmentOwners.isEmpty && _rules.bigAssortmentActive),
    );

    final permanent = color == PieceColor.white
        ? _whitePermanentReroll
        : _blackPermanentReroll;
    _skillChoiceRerollsUsed++;
    if (!permanent) {
      if (color == PieceColor.white) {
        _whiteOneShotReroll = false;
      } else {
        _blackOneShotReroll = false;
      }
    }
    return true;
  }

  MoveResult? makeMove(Move move) {
    return _executeLegalMove(_normalizeCastleMove(move));
  }

  MoveResult? _executeLegalMove(Move move, {bool skipReaction = false}) {
    move = _normalizeCastleMove(move);
    if (!isReadyToPlay || isGameOver || enginePhase != GameEnginePhase.play) {
      return null;
    }

    if (_awaitingGallopFrom != null) {
      final legal = getLegalMoves(from: move.from);
      if (!legal.any((m) => _movesEqual(m, move))) return null;
      if (!_isSimulatingLegality) {
        _undoSnapshot = createSnapshot();
      }
      if (!_isSimulatingLegality) {
        _lastMove = move;
      }
      _applyMove(move);
      _awaitingGallopFrom = null;
      _tickLava(_turn);
      _passTurn();
      _updateStatus();
      return MoveResult(
        requiresSkillChoice: isAwaitingSkillChoice,
        outcome: isAwaitingSkillChoice
            ? MoveOutcome.awaitingSkillChoice
            : MoveOutcome.completed,
      );
    }

    final legal = getLegalMoves(from: move.from);
    if (!legal.any((m) => _movesEqual(m, move))) return null;

    if (!_isSimulatingLegality) {
      _lastMove = move;
    }

    final moverBeforeCustoms = pieceAt(move.from, index: move.pieceIndex);
    // Customs path: after destination chosen, pause for path pick.
    if (!_isSimulatingLegality &&
        moverBeforeCustoms != null &&
        _hasEffect(moverBeforeCustoms, AbilityEffect.knightCustomsPath) &&
        !_rules.awaitingCustomsPath) {
      if (_rules.customsPathResolvedSkip) {
        _rules.customsPathResolvedSkip = false;
      } else {
      final paths = _knightPathOptions(move.from, move.to);
      if (paths.length >= 2) {
        _rules.awaitingCustomsPath = true;
        _rules.customsKnightId = moverBeforeCustoms.pieceId;
        _rules.customsFrom = move.from;
        _rules.customsTo = move.to;
        _rules.customsPaths
          ..clear()
          ..addAll([
            for (final p in paths) [p.$1, p.$2, p.$3, p.$4],
          ]);
        _updateStatus();
        return const MoveResult(
          requiresSkillChoice: false,
          outcome: MoveOutcome.awaitingTarget,
        );
      }
      }
    }

    // Tangled trail: pick two destinations from the same square in one turn.
    if (!_isSimulatingLegality &&
        moverBeforeCustoms != null &&
        _rules.tangledKnightBaseId == moverBeforeCustoms.pieceId &&
        _hasEffect(moverBeforeCustoms, AbilityEffect.knightTangledTrail)) {
      if (_rules.tangledAwaitingKeep) {
        return null;
      }
      if (!_rules.tangledAwaitingSecondDest) {
        _rules.tangledFrom = move.from;
        _rules.tangledFirstDest = move.to;
        _rules.tangledAwaitingSecondDest = true;
        _updateStatus();
        return const MoveResult(
          requiresSkillChoice: false,
          outcome: MoveOutcome.awaitingTarget,
        );
      }
      // Second destination — resolve split without normal single move apply.
      final from = _rules.tangledFrom ?? move.from;
      final destA = _rules.tangledFirstDest;
      final destB = move.to;
      if (destA == null || destA == destB) return null;
      if (!_isSimulatingLegality) {
        _undoSnapshot = createSnapshot();
      }
      final base = pieceAt(from, index: move.pieceIndex);
      if (base == null) return null;
      _takePieceAt(from, move.pieceIndex);
      void land(Square to, {required bool asClone}) {
        final victims = piecesAt(to)
            .where((p) => p.color != base.color)
            .toList();
        for (final v in victims) {
          final ref = _pieceById(v.pieceId);
          if (ref == null) continue;
          final removed = _takePieceAt(ref.square, ref.index);
          if (removed != null) {
            _onFinalDeath(
              removed,
              ref.square,
              capturingColor: base.color,
              reason: GraveyardReason.capture,
            );
          }
        }
        final placed = base.copyWith(
          pieceId: asClone ? '${base.pieceId}-tangled' : base.pieceId,
          hasMoved: true,
        );
        _setPrimary(to, placed);
        if (asClone) _rules.tangledCloneId = placed.pieceId;
      }

      land(destA, asClone: false);
      land(destB, asClone: true);
      _rules.tangledAwaitingSecondDest = false;
      _rules.tangledAwaitingKeep = true;
      _rules.tangledKnightBaseId = base.pieceId;
      _passTurnUnlessDuckPending();
      _updateStatus();
      return const MoveResult(
        requiresSkillChoice: false,
        outcome: MoveOutcome.completed,
      );
    }

    final captured = _isCapture(move);
    final moverBefore = pieceAt(move.from, index: move.pieceIndex);
    PieceColor? initiativeFearVictim;
    if (captured && moverBefore != null) {
      final victim = _captureVictim(move, _actingColor(moverBefore));
      if (!skipReaction &&
          victim != null &&
          victim.piece.hasAbility(GameAbility.pawnRansom) &&
          victim.piece.abilities.isNotEmpty) {
        _pendingReactionMove = move;
        _pendingRansomPawnId = victim.piece.pieceId;
        return const MoveResult(
          requiresSkillChoice: false,
          outcome: MoveOutcome.awaitingReaction,
        );
      }
      if (victim != null && _interceptProtectedCapture(victim)) {
        _updateStatus();
        return const MoveResult(
          requiresSkillChoice: false,
          outcome: MoveOutcome.cancelled,
        );
      }
      if (victim != null &&
          victim.piece.color != moverBefore.color &&
          _rules.initiativeFearActive &&
          !_rules.initiativeFearConsumed &&
          !_isSimulatingLegality) {
        initiativeFearVictim = victim.piece.color;
      }
    }
    final hadGallop =
        moverBefore != null && _hasEffect(moverBefore, AbilityEffect.gallop);
    final moverColor = _turn;
    if (!_isSimulatingLegality) {
      _undoSnapshot = createSnapshot();
    }
    _applyMove(move);
    if (captured &&
        _rules.suicideCapturePending &&
        !_isSimulatingLegality) {
      _rules.suicideCapturePending = false;
      final end = _pieceSquareAfterMove(move, moverColor);
      if (end != null) {
        final capturer = pieceAt(end);
        if (capturer != null && capturer.pieceId == moverBefore?.pieceId) {
          _capturePiecesAt(end);
        }
      }
    }
    if (moverBefore != null) {
      _afterVoluntaryMove(move, moverBefore, captured: captured);
    }
    if (_rules.bonusQuietMoveColor == moverColor) {
      _rules.bonusQuietMoveColor = null;
    }
    _tickLava(_turn);

    if (captured && _virusActive) {
      _applyVirusInfection(move.to, _turn);
    }

    final endSquare = _pieceSquareAfterMove(move, _turn);
    final capturerAlive =
        endSquare != null && pieceAt(endSquare)?.color == _turn;
    final landedOnAuction =
        endSquare != null &&
        _auctionSquare != null &&
        endSquare == _auctionSquare;

    if (captured && capturerAlive) {
      // Capture no longer grants a modification choice.
      if (initiativeFearVictim != null) {
        _rules.initiativeFearConsumed = true;
        _pendingBonusSkillColor = initiativeFearVictim;
      }
      if (landedOnAuction) {
        _pendingAuctionSquare = endSquare;
        _pendingAuctionColor = _turn;
        _auctionSquare = null;
      }
      if (isAwaitingSkillChoice || isAwaitingAbilityTarget) {
        _updateStatus();
        return MoveResult(
          requiresSkillChoice: isAwaitingSkillChoice,
          outcome: isAwaitingSkillChoice
              ? MoveOutcome.awaitingSkillChoice
              : MoveOutcome.awaitingTarget,
        );
      }
      _passTurnUnlessDuckPending();
      if (_startQueuedBonusSkillChoice()) {
        _updateStatus();
        return MoveResult(
          requiresSkillChoice: isAwaitingSkillChoice,
          outcome: isAwaitingSkillChoice
              ? MoveOutcome.awaitingSkillChoice
              : MoveOutcome.completed,
        );
      }
      if (_startQueuedAuctionChoice()) {
        _updateStatus();
        return MoveResult(
          requiresSkillChoice: isAwaitingSkillChoice,
          outcome: isAwaitingSkillChoice
              ? MoveOutcome.awaitingSkillChoice
              : MoveOutcome.completed,
        );
      }
      _updateStatus();
      return MoveResult(
        requiresSkillChoice: isAwaitingSkillChoice,
        outcome: isAwaitingSkillChoice
            ? MoveOutcome.awaitingSkillChoice
            : MoveOutcome.completed,
      );
    }

    // Галоп: второй прыжок на пустую клетку, если возможно.
    if (!captured &&
        hadGallop &&
        endSquare != null &&
        pieceAt(endSquare)?.type == PieceType.knight) {
      _awaitingGallopFrom = endSquare;
      _awaitingGallopIndex = 0;
      final second = getLegalMoves(from: endSquare);
      if (second.isNotEmpty) {
        _updateStatus();
        return const MoveResult(requiresSkillChoice: false);
      }
      _awaitingGallopFrom = null;
    } else if (landedOnAuction) {
      _auctionSquare = null;
      _pendingAuctionSquare = endSquare;
      _pendingAuctionColor = _turn;
      _passTurn();
      _startQueuedAuctionChoice();
      _updateStatus();
      return MoveResult(
        requiresSkillChoice: isAwaitingSkillChoice,
        outcome: isAwaitingSkillChoice
            ? MoveOutcome.awaitingSkillChoice
            : MoveOutcome.completed,
      );
    }

    if (isAwaitingSkillChoice || isAwaitingAbilityTarget) {
      _updateStatus();
      return MoveResult(
        requiresSkillChoice: isAwaitingSkillChoice,
        outcome: isAwaitingSkillChoice
            ? MoveOutcome.awaitingSkillChoice
            : MoveOutcome.awaitingTarget,
      );
    }
    _passTurnUnlessDuckPending();
    _updateStatus();
    return MoveResult(
      requiresSkillChoice: isAwaitingSkillChoice,
      outcome: isAwaitingSkillChoice
          ? MoveOutcome.awaitingSkillChoice
          : MoveOutcome.completed,
    );
  }

  void skipGallop() {
    if (_awaitingGallopFrom == null) return;
    _awaitingGallopFrom = null;
    _passTurn();
    _updateStatus();
  }

  bool skipTurn() {
    if (!canSkipTurn) return false;
    _passTurn(gaveCheck: false);
    _updateStatus();
    return true;
  }

  void _passTurn({bool? gaveCheck}) {
    if (isGameOver) return;
    // "Марсельские шахматы": у игрока два последовательных движения в рамках
    // одного хода. Поэтому при наличии второго доступного движения мы не
    // переключаем игрока и не тикнем эффекты конца хода.
    if (_rules.marseillesActive) {
      if (_rules.marseillesMovesLeft <= 0) {
        _rules.marseillesMovesLeft = _turn == PieceColor.white
            ? (_rules.marseillesWhiteFirstTurnSingleDone ? 2 : 1)
            : 2;
      }
      if (_rules.marseillesMovesLeft > 1) {
        _rules.marseillesMovesLeft--;
        return;
      }
    }
    final finished = _turn;
    final checkDelivered = gaveCheck ?? isInCheck(finished.opponent);
    _turn = _turn.opponent;
    if (_rules.marseillesActive &&
        finished == PieceColor.white &&
        !_rules.marseillesWhiteFirstTurnSingleDone) {
      // Завершили "первый ход белых" в партии.
      _rules.marseillesWhiteFirstTurnSingleDone = true;
    }
    _tickTurnEffects();
    _tickBoardRuleDurations(finished);
    _resolvePassiveAggression(finished, gaveCheck: checkDelivered);
    _maybeRestoreTimeCapsule();
    _clearForcedMoveIfUnusable();
    _tickRelicAndSpotlight(finished);
    if (checkDelivered) {
      _tryKingGuardAuto(finished.opponent);
    }
    _resolveTurnEndEffects();

    if (_rules.marseillesActive) {
      _rules.marseillesMovesLeft = _turn == PieceColor.white
          ? (_rules.marseillesWhiteFirstTurnSingleDone ? 2 : 1)
          : 2;
    }

    _registerCompletedPlayerMove(finished);
  }

  void _registerCompletedPlayerMove(PieceColor finished) {
    if (isGameOver || _isSimulatingLegality) return;
    if (finished == PieceColor.white) {
      _rules.whiteMovesSinceAbilityWave++;
    } else {
      _rules.blackMovesSinceAbilityWave++;
    }
    if (_rules.whiteMovesSinceAbilityWave >= 3 &&
        _rules.blackMovesSinceAbilityWave >= 3 &&
        !isAwaitingSkillChoice &&
        !isAwaitingAbilityTarget &&
        _rules.pendingPeriodicChooserQueue.isEmpty) {
      final choosers = <PieceColor>[
        if (_abilityChoosingColors.contains(PieceColor.white))
          PieceColor.white,
        if (_abilityChoosingColors.contains(PieceColor.black))
          PieceColor.black,
      ];
      if (choosers.isEmpty) return;
      _rules.whiteMovesSinceAbilityWave = 0;
      _rules.blackMovesSinceAbilityWave = 0;
      _rules.pendingPeriodicChooserQueue
        ..clear()
        ..addAll(choosers);
      _beginPeriodicSkillChoice(choosers.first);
    }
  }

  void _beginPeriodicSkillChoice(PieceColor color) {
    if (!_abilityChoosingColors.contains(color)) {
      _pendingSkillSquare = null;
      _pendingSkillPieceId = null;
      _pendingSkillColor = null;
      _pendingCaptureOffers = const [];
      _completeSkillChoiceResolution(
        color,
        offer: const AbilityOffer(
          ability: GameAbility.boardReroll,
          applyMode: AbilityApplyMode.boardWide,
        ),
      );
      return;
    }
    _pendingSkillSquare = null;
    _pendingSkillPieceId = null;
    _pendingSkillColor = color;
    _skillChoiceRerollsUsed = 0;
    _pendingCaptureOffers = _catalog.pickPeriodicOffers(
      forColor: color,
      board: _board,
      rankCount: _rankCount,
      extraFilePlacement: extraFilePlacement,
      blockedSquares: _captureBlockedSquares(),
      chosenAbilities: _chosenAbilitiesFor(color),
      excludedAbilities: _excludedAbilities,
      fogOfWarActive: _fogOfWar,
      minesActive: _mines.isNotEmpty,
      mirrorActive: _mirrorActive,
      offerFourChoices: _rules.bigAssortmentOwners.contains(color) ||
          (_rules.bigAssortmentOwners.isEmpty && _rules.bigAssortmentActive),
      chooserDeliversCheck: isInCheck(color.opponent),
      hasFriendlyPrisoners: _graveyard.any(
        (r) =>
            r.originalOwner == color &&
            r.capturingColor == color.opponent &&
            r.wasCapturedByOpponent,
      ),
    );
  }

  /// After a skill choice (and any piece-target step) fully resolves.
  void _completeSkillChoiceResolution(
    PieceColor chooserColor, {
    required AbilityOffer offer,
  }) {
    if (_startQueuedPieceChoice()) {
      _updateStatus();
      return;
    }

    if (_rules.queuedSkillChoices > 0) {
      _rules.queuedSkillChoices--;
      _beginPeriodicSkillChoice(chooserColor);
      _updateStatus();
      return;
    }

    // Bonus pick (e.g. initiative fear): outside the 3+3 wave, never pass turn.
    if (_skillChoiceIsBonus) {
      _skillChoiceIsBonus = false;
      if (_startQueuedAuctionChoice()) {
        _updateStatus();
        return;
      }
      if (_rules.pendingPeriodicChooserQueue.isNotEmpty) {
        _beginPeriodicSkillChoice(_rules.pendingPeriodicChooserQueue.first);
        _updateStatus();
        return;
      }
      _updateStatus();
      return;
    }

    if (_startQueuedAuctionChoice()) {
      _updateStatus();
      return;
    }

    if (_rules.pendingPeriodicChooserQueue.isNotEmpty) {
      if (_rules.pendingPeriodicChooserQueue.first == chooserColor) {
        _rules.pendingPeriodicChooserQueue.removeAt(0);
      }
      if (_rules.pendingPeriodicChooserQueue.isNotEmpty) {
        _beginPeriodicSkillChoice(_rules.pendingPeriodicChooserQueue.first);
        _updateStatus();
        return;
      }
      // Wave finished: resume play without passing the turn.
      _updateStatus();
      return;
    }

    // Золотой трон: король выбирает мод в свой ход — ход не передаём.
    if (offer.applyMode == AbilityApplyMode.playerKing) {
      _updateStatus();
      return;
    }

    if (_rules.bonusQuietMoveColor == chooserColor) {
      _updateStatus();
      return;
    }

    _passTurn();
    _updateStatus();
  }

  bool _resolveTurnEndEffects() {
    final current = _turn;
    final kingSquare = findKing(current);
    if (kingSquare == null) {
      _finishGame(
        winner: current.opponent,
        reason: GameEndReason.kingDestroyed,
      );
      return true;
    }

    if (_exterminatusPliesLeft > 0) {
      if (isInCheck(current)) {
        _clearSquare(kingSquare);
        _finishGame(
          winner: current.opponent,
          reason: GameEndReason.exterminatus,
        );
        _exterminatusPliesLeft--;
        return true;
      }
      _exterminatusPliesLeft--;
    }

    if (_baskervilleActive && isInCheck(current)) {
      final mover = current.opponent;
      if (mover == PieceColor.white) {
        _whiteBaskervilleChecks++;
        if (_whiteBaskervilleChecks >= 3) {
          _clearSquare(kingSquare);
          _finishGame(winner: mover, reason: GameEndReason.baskerville);
          return true;
        }
      } else {
        _blackBaskervilleChecks++;
        if (_blackBaskervilleChecks >= 3) {
          _clearSquare(kingSquare);
          _finishGame(winner: mover, reason: GameEndReason.baskerville);
          return true;
        }
      }
    }

    _tryStartGoldenThroneChoice();
    return false;
  }

  void _tryStartGoldenThroneChoice() {
    if (_pendingGoldenThroneColor == null) return;
    if (_pendingGoldenThroneColor != _turn) return;
    if (enginePhase != GameEnginePhase.play) return;

    final kingSquare = findKing(_turn);
    if (kingSquare == null) {
      _pendingGoldenThroneColor = null;
      return;
    }

    _pendingSkillSquare = kingSquare;
    _pendingSkillColor = _turn;
    final king = pieceAt(kingSquare);
    if (king == null) {
      _pendingSkillSquare = null;
      _pendingSkillPieceId = null;
      _pendingSkillColor = null;
      return;
    }
    _pendingSkillPieceId = king.pieceId;
    _skillChoiceRerollsUsed = 0;
    _pendingCaptureOffers = _catalog.pickKingOffers(
      king: king,
      board: _board,
      rankCount: _rankCount,
      extraFilePlacement: extraFilePlacement,
      blockedSquares: _captureBlockedSquares(),
      kingSquare: kingSquare,
      chosenAbilities: _chosenAbilitiesFor(_turn),
    );
    _pendingGoldenThroneColor = null;
  }

  void applyAbility(GameAbility ability) {
    if (_pendingSkillColor == null || _pendingCaptureOffers.isEmpty) return;

    final offer = _pendingCaptureOffers.cast<AbilityOffer?>().firstWhere(
      (o) => o!.ability == ability,
      orElse: () => null,
    );
    if (offer == null) return;

    final chooserColor = _pendingSkillColor!;
    final pendingSquare = _pendingSkillSquare;
    final pendingIndex = pendingSquare == null
        ? null
        : piecesAt(
            pendingSquare,
          ).indexWhere((piece) => piece.pieceId == _pendingSkillPieceId);

    _pendingSkillSquare = null;
    _pendingSkillPieceId = null;
    _pendingSkillColor = null;
    _pendingCaptureOffers = const [];

    _recordChosenAbility(chooserColor, offer);
    _applyOffer(
      chooserColor,
      offer,
      pendingSquare,
      capturingPieceIndex: pendingIndex != null && pendingIndex >= 0
          ? pendingIndex
          : 0,
    );

    if (isAwaitingAbilityTarget) {
      _updateStatus();
      return;
    }

    _completeSkillChoiceResolution(chooserColor, offer: offer);
  }

  void _applyOffer(
    PieceColor color,
    AbilityOffer offer,
    Square? capturingSquare, {
    int capturingPieceIndex = 0,
  }) {
    switch (offer.applyMode) {
      case AbilityApplyMode.boardWide:
        if (offer.ability == GameAbility.boardReroll) {
          _whitePermanentReroll = true;
          _blackPermanentReroll = true;
        } else if (offer.ability == GameAbility.randomFurtherMore) {
          if (color == PieceColor.white) {
            _whiteOneShotReroll = true;
          } else {
            _blackOneShotReroll = true;
          }
        } else if (offer.ability == GameAbility.boardLavaRank &&
            offer.lavaRank != null) {
          _lavaRanks.add(offer.lavaRank!);
        } else if (offer.ability == GameAbility.boardExtraRank) {
          _insertExtraRank();
        } else if (offer.ability == GameAbility.boardExtraFile &&
            offer.extraFileOnLeft != null) {
          if (offer.extraFileOnLeft!) {
            _insertExtraFileLeft();
          } else {
            _insertExtraFileRight();
          }
        } else if (offer.ability == GameAbility.boardFogOfWar) {
          _fogOfWar = true;
        } else if (offer.ability == GameAbility.boardNight) {
          _squareColorLock = _SquareColorLock.dark;
          _squareColorLockMovesLeft = 3;
        } else if (offer.ability == GameAbility.boardDay) {
          _squareColorLock = _SquareColorLock.light;
          _squareColorLockMovesLeft = 3;
        } else if (offer.ability == GameAbility.boardColorblind) {
          _applyColorblind();
        } else if (offer.ability == GameAbility.boardPawnFront) {
          _applyPawnFront(color);
        } else if (offer.ability == GameAbility.boardCavalry) {
          _applyCavalry(color);
        } else if (offer.ability == GameAbility.boardMirror) {
          _mirrorActive = true;
        } else if (offer.ability == GameAbility.boardGhostCells) {
          final rng = _rngForOffer(offer);
          _applyGhostCells(
            offer.ghostCellCount ?? (2 + rng.nextInt(4)),
            rng,
          );
        } else if (offer.ability == GameAbility.boardAttraction) {
          _attractionActive = true;
          _attractionMoveCounter = 0;
        } else if (offer.ability == GameAbility.boardVirus) {
          _virusActive = true;
        } else if (offer.ability == GameAbility.boardInvisibleRegiment) {
          _applyInvisibleRegiment();
        } else if (offer.ability == GameAbility.boardShuffle) {
          _applyShuffle(_rngForOffer(offer));
        } else if (offer.ability == GameAbility.boardTeleport) {
          _applyTeleport(
            offer.teleportA,
            offer.teleportB,
            _rngForOffer(offer),
          );
        } else if (offer.ability == GameAbility.boardVanityFair) {
          _applyVanityFair(color);
        } else if (offer.ability == GameAbility.boardMinefield) {
          final rng = _rngForOffer(offer);
          _applyMinefield(offer.mineCount ?? (1 + rng.nextInt(3)), rng);
        } else if (offer.ability == GameAbility.boardGolconda) {
          _golcondaActive = true;
        } else if (offer.ability == GameAbility.boardUnbridledHorse) {
          _unbridledHorse = true;
        } else if (offer.ability == GameAbility.boardBaskerville) {
          _baskervilleActive = true;
        } else if (offer.ability == GameAbility.boardBloodOath) {
          _bloodOathActive = true;
        } else if (offer.ability == GameAbility.boardSilentFile &&
            offer.silentFile != null) {
          _silentFile = offer.silentFile;
        } else if (offer.ability == GameAbility.boardSprint) {
          _sprintActive = true;
        } else if (offer.ability == GameAbility.boardTide) {
          _applyTide(color);
        } else if (offer.ability == GameAbility.boardZebras) {
          _zebrasActive = true;
        } else if (offer.ability == GameAbility.boardFisher) {
          _applyFisher(madness: false, rngSeed: offer.rngSeed);
        } else if (offer.ability == GameAbility.boardFisherMadness) {
          _applyFisher(madness: true, rngSeed: offer.rngSeed);
        } else if (offer.ability == GameAbility.boardFourHorsemen) {
          _fourHorsemenActive = true;
        } else if (offer.ability == GameAbility.randomShift &&
            offer.shiftFile != null &&
            offer.shiftDirection != null) {
          _applyFileShift(offer.shiftFile!, offer.shiftDirection!);
        } else if (offer.ability == GameAbility.randomEarthquake &&
            offer.quakeRank != null &&
            offer.quakeDirection != null) {
          _shiftRank(offer.quakeRank!, offer.quakeDirection!);
        } else if (offer.ability == GameAbility.randomTyphoon &&
            offer.typhoonOrigin != null) {
          _rotateTyphoon(offer.typhoonOrigin!);
        } else if (offer.ability == GameAbility.randomQuarantine &&
            offer.quarantineSquare != null) {
          _quarantineSquare = offer.quarantineSquare;
          _quarantineMovesLeft =
              offer.quarantineMoves ?? (3 + _random.nextInt(8));
        } else if (offer.ability == GameAbility.randomWormhole &&
            offer.wormholeSquare != null) {
          _wormholes.add(offer.wormholeSquare!);
        } else if (offer.ability == GameAbility.randomClone &&
            offer.cloneSquare != null &&
            piecesAt(offer.cloneSquare!).isEmpty) {
          _setPrimary(
            offer.cloneSquare!,
            Piece(type: PieceType.pawn, color: color),
          );
        } else if (offer.ability == GameAbility.randomNoQueen) {
          _applyNoQueen(color.opponent);
        } else if (offer.ability == GameAbility.randomTruce) {
          _truceMovesLeft = 4;
        } else if (offer.ability == GameAbility.randomMeteorRain) {
          _applyMeteorRain();
        } else if (offer.ability == GameAbility.randomCensus) {
          _applyCensus(color.opponent);
        } else if (offer.ability == GameAbility.randomExterminatus) {
          _exterminatusPliesLeft = 2;
        } else if (offer.ability == GameAbility.randomGoldenThrone) {
          if (color == PieceColor.white) {
            _goldenThroneWhite = true;
          } else {
            _goldenThroneBlack = true;
          }
        } else if (offer.ability == GameAbility.randomLottery) {
          _applyLottery(color);
        } else if (offer.ability == GameAbility.randomPlague) {
          _plagueActive = true;
        } else if (offer.ability == GameAbility.randomMutation) {
          _applyMutation(color);
        } else if (offer.ability == GameAbility.randomAuction) {
          _auctionSquare = offer.auctionSquare;
          _pendingAuctionSquare = null;
          _pendingAuctionColor = null;
        } else if (offer.ability == GameAbility.boardPassiveAggression) {
          _rules.passiveAggressionActive = true;
          _rules.whitePassiveAggression = 10;
          _rules.blackPassiveAggression = 10;
        } else if (offer.ability == GameAbility.boardSkipTurn) {
          _rules.skipTurnEnabled = true;
        } else if (offer.ability == GameAbility.boardTroopFatigue) {
          _rules.troopFatigueActive = true;
        } else if (offer.ability == GameAbility.boardCombatOptics) {
          _rules.combatOpticsActive = true;
        } else if (offer.ability == GameAbility.boardKingOfHill) {
          _rules.kingOfHillActive = true;
        } else if (offer.ability == GameAbility.boardSecretRoute) {
          final route = offer.route.isNotEmpty
              ? List<Square>.from(offer.route)
              : _generateSecretRoute();
          _rules.secretRoutes[color] = route;
          _rules.secretRouteProgress[color] = 0;
        } else if (offer.ability == GameAbility.boardRoyalPilgrimage) {
          _rules.royalPilgrimageActive = true;
        } else if (offer.ability == GameAbility.boardMightMakesRight) {
          _rules.mightMakesRightActive = true;
        } else if (offer.ability == GameAbility.boardExpeditionaryCorps) {
          _rules.expeditionaryCorpsActive = true;
        } else if (offer.ability == GameAbility.boardWitnessProtection) {
          final pieceId = offer.hiddenData['pieceId'] as String?;
          if (pieceId != null) {
            _rules.witnessProtectedPieceId[color] = pieceId;
          } else if (offer.targetSelection ==
              AbilityTargetSelection.secretFriendlyPiece) {
            _beginAbilityTarget(
              ability: offer.ability,
              sourceId: _pendingSkillPieceId ?? 'board-${color.name}',
              color: color,
              selection: AbilityTargetSelection.secretFriendlyPiece,
              passesTurn: capturingSquare != null,
            );
          } else {
            final picked = _pickRandomNonKing(color);
            if (picked != null) {
              _rules.witnessProtectedPieceId[color] = picked;
            }
          }
          // Board start: also protect opponent if unset.
          if (capturingSquare == null &&
              !_rules.witnessProtectedPieceId.containsKey(color.opponent)) {
            final opp = _pickRandomNonKing(color.opponent);
            if (opp != null) {
              _rules.witnessProtectedPieceId[color.opponent] = opp;
            }
          }
        } else if (offer.ability == GameAbility.randomRightToMove) {
          final pieceId = offer.hiddenData['pieceId'] as String?;
          if (pieceId != null) {
            _rules.forcedMovePieceId = pieceId;
            _rules.forcedMoveOwner = color.opponent;
          } else {
            _beginAbilityTarget(
              ability: offer.ability,
              sourceId: _pendingSkillPieceId ?? 'board-${color.name}',
              color: color,
              selection: AbilityTargetSelection.enemyPiece,
            );
          }
        } else if (offer.ability == GameAbility.randomWordOfHonor) {
          if (offer.targetCell != null) {
            _rules.wordOfHonorSquare = offer.targetCell;
            _rules.wordOfHonorColor = color;
          } else {
            _beginAbilityTarget(
              ability: offer.ability,
              sourceId: _pendingSkillPieceId ?? 'board-${color.name}',
              color: color,
              selection: AbilityTargetSelection.cell,
            );
          }
        } else if (offer.ability == GameAbility.randomSymmetry) {
          _rules.symmetryTurnsLeft = offer.durationMoves ?? 3;
          _rules.symmetryVictimColor = color.opponent;
          _rules.symmetryChooserColor = color;
          _rules.symmetryRequiredType = null;
        } else if (offer.ability == GameAbility.randomVeto) {
          final pieceId = offer.hiddenData['pieceId'] as String?;
          _rules.vetoTurnsLeft = offer.durationMoves ?? 3;
          if (pieceId != null) {
            _rules.vetoPieceId = pieceId;
            _rules.vetoOwner = _pieceById(pieceId)?.piece.color ?? color.opponent;
          } else {
            _beginAbilityTarget(
              ability: offer.ability,
              sourceId: _pendingSkillPieceId ?? 'board-${color.name}',
              color: color,
              selection: AbilityTargetSelection.enemyPiece,
            );
          }
        } else if (offer.ability == GameAbility.randomInitiativeIntercept) {
          if (_armyMaterialValue(color) < _armyMaterialValue(color.opponent)) {
            _rules.bonusQuietMoveColor = color;
          }
        } else if (offer.ability == GameAbility.randomStrike) {
          _rules.strikePieceType = offer.affectedPieceType ??
              [
                PieceType.pawn,
                PieceType.bishop,
                PieceType.rook,
                PieceType.knight,
                PieceType.queen,
              ][_random.nextInt(5)];
          _rules.strikeTurnsLeft = offer.durationMoves ?? (3 + _random.nextInt(8));
        } else if (offer.ability == GameAbility.randomBorderClosure) {
          _rules.borderClosureTurnsLeft = offer.durationMoves ?? 2;
        } else if (offer.ability == GameAbility.randomMyopia) {
          _rules.myopiaTurnsLeft = offer.durationMoves ?? 3;
        } else if (offer.ability == GameAbility.randomMagicShutdown) {
          _rules.magicShutdownTurnsLeft =
              offer.durationMoves ?? (3 + _random.nextInt(8));
        } else if (offer.ability == GameAbility.randomTimeCapsule) {
          _rules.timeCapsuleBoard =
              _board.map((row) => List<Piece?>.from(row)).toList();
          _rules.timeCapsuleStackExtra = Map<String, Piece>.from(_stackExtra);
          _rules.timeCapsuleRemainingPlies = offer.durationMoves ?? 4;
        } else if (offer.ability == GameAbility.randomSuicideCapture) {
          _rules.suicideCapturePending = true;
        } else if (offer.ability == GameAbility.boardDeserters) {
          _activateDeserters();
        } else if (offer.ability == GameAbility.boardLetterH) {
          _rules.letterHActive = true;
        } else if (offer.ability == GameAbility.boardFullCircle) {
          _rules.fullCircleActive = true;
        } else if (offer.ability == GameAbility.boardArchitect) {
          _activateArchitectWalls(offer.durationMoves ?? (3 + _random.nextInt(6)));
        } else if (offer.ability == GameAbility.boardBigAssortment) {
          _rules.bigAssortmentOwners.add(color);
        } else if (offer.ability == GameAbility.boardBlindSpot) {
          _rules.blindSpotActive = true;
        } else if (offer.ability == GameAbility.pawnRockPaperScissors) {
          _startRpsSession(color);
          if (_rules.rpsSessionActive && _rules.rpsPairIndex == null) {
            _beginAbilityTarget(
              ability: GameAbility.pawnRockPaperScissors,
              sourceId: 'rps-${color.name}',
              color: color,
              selection: AbilityTargetSelection.cell,
              passesTurn: true,
            );
          }
        } else if (offer.ability == GameAbility.boardOnlyEqualsKill) {
          _rules.onlyEqualsKillActive = true;
        } else if (offer.ability == GameAbility.boardInitiativeFear) {
          _rules.initiativeFearActive = true;
          _rules.initiativeFearConsumed = false;
        } else if (offer.ability == GameAbility.boardSwamp) {
          _rules.swampActive = true;
        } else if (offer.ability == GameAbility.boardCollectiveMyopia) {
          _rules.collectiveMyopiaActive = true;
        } else if (offer.ability == GameAbility.boardTerritoryExpand) {
          _insertTerritoryExpand();
        } else if (offer.ability == GameAbility.boardFrostMap) {
          _activateFrostMap();
        } else if (offer.ability == GameAbility.boardScorchingSun) {
          _activateScorchingSun();
        } else if (offer.ability == GameAbility.boardTurncoats) {
          _activateTurncoats();
        } else if (offer.ability == GameAbility.boardMarseillesChess) {
          final firstActivation = !_rules.marseillesActive;
          _rules.marseillesActive = true;
          if (firstActivation) {
            // Стартуем с правила "белые на первом ходе делают только 1 движение".
            _rules.marseillesWhiteFirstTurnSingleDone = false;
          }
          // Сколько движений доступно прямо сейчас (1..2) в сегменте хода.
          _rules.marseillesMovesLeft = _turn == PieceColor.white
              ? (_rules.marseillesWhiteFirstTurnSingleDone ? 2 : 1)
              : 2;
        } else if (offer.ability == GameAbility.randomMeatGrinder) {
          _rules.meatGrinderTurnsLeft = 2;
        } else if (offer.ability == GameAbility.randomQuicksand) {
          _activateQuicksand(
            cellCount: offer.mineCount ?? (2 + _random.nextInt(4)),
            duration: offer.durationMoves ?? (2 + _random.nextInt(4)),
          );
        } else {
          _applyExpandedModOffer(color, offer);
        }
        return;
      case AbilityApplyMode.capturingPiece:
        if (capturingSquare != null) {
          if (offer.ability == GameAbility.queenSplit) {
            _splitQueen(capturingSquare);
            return;
          }
          _grantAbility(
            capturingSquare,
            offer.ability,
            offer: offer,
            pieceIndex: capturingPieceIndex,
          );
        }
        return;
      case AbilityApplyMode.selectFriendlyPiece:
        _beginSelectFriendlyPiece(color, offer);
        return;
      case AbilityApplyMode.allPiecesOfType:
        _grantToAllOfType(color, offer.ability);
        return;
      case AbilityApplyMode.playerKing:
        final kingSquare = capturingSquare ?? findKing(color);
        if (kingSquare != null) {
          _grantAbility(
            kingSquare,
            offer.ability,
            offer: offer,
            pieceIndex: capturingPieceIndex,
          );
        }
        return;
    }
  }

  List<({Square square, int index, Piece piece})> _friendlyPiecesOfType(
    PieceColor color,
    PieceType type,
  ) {
    final result = <({Square square, int index, Piece piece})>[];
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        final pieces = piecesAt(square);
        for (var index = 0; index < pieces.length; index++) {
          final piece = pieces[index];
          if (piece.color == color && piece.type == type) {
            result.add((square: square, index: index, piece: piece));
          }
        }
      }
    }
    return result;
  }

  void _beginSelectFriendlyPiece(PieceColor color, AbilityOffer offer) {
    final type = offer.ability.primaryPieceType;
    if (type == null) {
      // Fallback: treat as board-wide if group has no piece type.
      return;
    }
    final candidates = _friendlyPiecesOfType(color, type);
    if (candidates.isEmpty) return;
    if (candidates.length == 1) {
      final only = candidates.first;
      if (offer.ability == GameAbility.queenSplit) {
        _splitQueen(only.square);
        return;
      }
      _grantAbility(
        only.square,
        offer.ability,
        offer: offer,
        pieceIndex: only.index,
      );
      return;
    }

    _pendingSelectOffer = offer;
    _pendingSelectPieceType = type;
    _beginAbilityTarget(
      ability: offer.ability,
      sourceId: 'select-${color.name}',
      color: color,
      selection: AbilityTargetSelection.friendlyPiece,
      passesTurn: false,
    );
  }

  Random _rngForOffer(AbilityOffer offer) =>
      offer.rngSeed != null ? Random(offer.rngSeed!) : _random;

  void _applyFisher({required bool madness, int? rngSeed}) {
    final rng = rngSeed != null ? Random(rngSeed) : _random;
    if (madness) {
      _applyFisherMadness(PieceColor.white, rng);
      _applyFisherMadness(PieceColor.black, rng);
    } else {
      _applyClassicFisher(rng);
    }
  }

  /// Классические шахматы Фишера (Chess960):
  /// пешки на 2/7, одна и та же расстановка сзади у обоих (зеркало по файлам),
  /// слоны на разнопольных клетках, король между ладьями.
  void _applyClassicFisher(Random rng) {
    final whiteBack = 0;
    final blackBack = _rankCount - 1;

    final whiteSlots = <int>[];
    final whitePieces = <Piece>[];
    for (var file = 0; file < _fileCount; file++) {
      final piece = pieceAt(Square(file, whiteBack));
      if (piece == null || piece.color != PieceColor.white) continue;
      if (piece.type == PieceType.pawn) continue;
      whiteSlots.add(file);
      whitePieces.add(piece);
    }
    if (whiteSlots.length != 8) return;

    // Типы в исходном порядке слотов — будем переставлять.
    final types = whitePieces.map((p) => p.type).toList();
    var arrangement = List<PieceType>.from(types);
    var valid = false;
    for (var attempt = 0; attempt < 5000 && !valid; attempt++) {
      arrangement.shuffle(rng);
      valid = _isValidChess960Arrangement(arrangement, whiteSlots, whiteBack);
    }
    if (!valid) return;

    // Сохранить объекты фигур по типу (с учётом дублей — по очереди).
    Piece takeWhite(PieceType type) {
      final index = whitePieces.indexWhere((p) => p.type == type);
      return whitePieces.removeAt(index);
    }

    final placedWhite = <Piece>[];
    for (final type in arrangement) {
      placedWhite.add(takeWhite(type));
    }

    // Чёрные фигуры с задней горизонтали в тех же слотах.
    final blackByFile = <int, Piece>{};
    for (final file in whiteSlots) {
      final piece = pieceAt(Square(file, blackBack));
      if (piece == null || piece.color != PieceColor.black) return;
      blackByFile[file] = piece;
    }

    Piece takeBlack(PieceType type) {
      final entry = blackByFile.entries.firstWhere((e) => e.value.type == type);
      blackByFile.remove(entry.key);
      return entry.value;
    }

    final placedBlack = <Piece>[];
    for (final type in arrangement) {
      placedBlack.add(takeBlack(type));
    }

    for (var i = 0; i < whiteSlots.length; i++) {
      final file = whiteSlots[i];
      _setPrimary(Square(file, whiteBack), placedWhite[i]);
      _setPrimary(Square(file, blackBack), placedBlack[i]);
    }

    for (var i = 0; i < whiteSlots.length; i++) {
      if (placedWhite[i].type == PieceType.king) {
        _whiteThrone = Square(whiteSlots[i], whiteBack);
      }
      if (placedBlack[i].type == PieceType.king) {
        _blackThrone = Square(whiteSlots[i], blackBack);
      }
    }
  }

  bool _isValidChess960Arrangement(
    List<PieceType> arrangement,
    List<int> files,
    int rank,
  ) {
    final bishopFiles = <int>[];
    var kingFile = -1;
    final rookFiles = <int>[];
    for (var i = 0; i < arrangement.length; i++) {
      switch (arrangement[i]) {
        case PieceType.bishop:
          bishopFiles.add(files[i]);
        case PieceType.king:
          kingFile = files[i];
        case PieceType.rook:
          rookFiles.add(files[i]);
        default:
          break;
      }
    }
    if (bishopFiles.length != 2 || rookFiles.length != 2 || kingFile == -1) {
      return false;
    }
    rookFiles.sort();
    final oppositeColors =
        (bishopFiles[0] + rank).isEven != (bishopFiles[1] + rank).isEven;
    return oppositeColors &&
        kingFile > rookFiles.first &&
        kingFile < rookFiles.last;
  }

  /// Безумие Фишера: все фигуры на 1+2 (или 7+8) горизонталях перемешиваются
  /// между этими 16 клетками. Слоны на разных цветах; король не обязан
  /// быть между ладьями; расстановки сторон независимы; рокировки нет.
  /// Король после перемешивания не должен оказаться под шахом.
  void _applyFisherMadness(PieceColor color, Random rng) {
    final backRank = color == PieceColor.white ? 0 : _rankCount - 1;
    final pawnRank = color == PieceColor.white ? 1 : _rankCount - 2;

    final squares = <Square>[];
    final pieces = <Piece>[];

    for (final rank in [backRank, pawnRank]) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        final piece = pieceAt(square);
        if (piece == null || piece.color != color) continue;
        squares.add(square);
        pieces.add(piece);
      }
    }

    if (pieces.length < 2) return;

    final original = <Square, List<Piece>>{};
    for (final square in squares) {
      original[square] = piecesAt(square);
    }

    var placed = List<Piece>.from(pieces);
    var valid = false;
    for (var attempt = 0; attempt < 8000 && !valid; attempt++) {
      placed.shuffle(rng);
      if (!_bishopsOnOppositeColors(placed, squares)) continue;

      for (final square in squares) {
        _clearSquare(square);
      }
      Square? kingSquare;
      for (var i = 0; i < squares.length; i++) {
        var piece = placed[i];
        // Рокировки в безумии нет.
        if (piece.type == PieceType.king || piece.type == PieceType.rook) {
          piece = piece.copyWith(hasMoved: true);
        }
        _setPrimary(squares[i], piece);
        if (piece.type == PieceType.king) {
          kingSquare = squares[i];
        }
      }

      if (!isInCheck(PieceColor.white) && !isInCheck(PieceColor.black)) {
        valid = true;
        if (kingSquare != null) {
          if (color == PieceColor.white) {
            _whiteThrone = kingSquare;
          } else {
            _blackThrone = kingSquare;
          }
        }
        break;
      }
    }

    if (!valid) {
      for (final entry in original.entries) {
        _setCell(entry.key, entry.value);
      }
    }
  }

  bool _bishopsOnOppositeColors(List<Piece> pieces, List<Square> squares) {
    final bishopSquares = <Square>[];
    for (var i = 0; i < pieces.length; i++) {
      if (pieces[i].type == PieceType.bishop) {
        bishopSquares.add(squares[i]);
      }
    }
    if (bishopSquares.length < 2) return true;
    if (bishopSquares.length != 2) return false;
    return (bishopSquares[0].file + bishopSquares[0].rank).isEven !=
        (bishopSquares[1].file + bishopSquares[1].rank).isEven;
  }

  void _shiftFile(int file, int direction) {
    final moves = <(int, List<Piece>)>[];
    for (var rank = 0; rank < _rankCount; rank++) {
      final square = Square(file, rank);
      final pieces = piecesAt(square);
      if (pieces.isEmpty) continue;
      final movable = [
        for (final piece in pieces)
          if (canForceMove(square, piece.pieceId)) piece,
      ];
      final stuck = [
        for (final piece in pieces)
          if (!canForceMove(square, piece.pieceId)) piece,
      ];
      if (movable.isEmpty) continue;
      _setCell(square, stuck);
      moves.add((rank, movable));
    }

    for (final (rank, pieces) in moves) {
      final dest = Square(file, rank + direction);
      final existing = piecesAt(dest);
      _setCell(dest, [...existing, ...pieces]);
    }
  }

  void _shiftRank(int rank, int direction) {
    final moves = <(int, List<Piece>)>[];
    for (var file = 0; file < _fileCount; file++) {
      final square = Square(file, rank);
      final pieces = piecesAt(square);
      if (pieces.isEmpty) continue;
      final movable = [
        for (final piece in pieces)
          if (canForceMove(square, piece.pieceId)) piece,
      ];
      final stuck = [
        for (final piece in pieces)
          if (!canForceMove(square, piece.pieceId)) piece,
      ];
      if (movable.isEmpty) continue;
      _setCell(square, stuck);
      moves.add((file, movable));
    }

    for (final (file, pieces) in moves) {
      final dest = Square(file + direction, rank);
      final existing = piecesAt(dest);
      _setCell(dest, [...existing, ...pieces]);
    }
  }

  void _rotateTyphoon(Square origin) {
    final a = origin;
    final b = Square(origin.file, origin.rank + 1);
    final c = Square(origin.file + 1, origin.rank + 1);
    final d = Square(origin.file + 1, origin.rank);

    final cells = [a, b, c, d];
    if (!cells.every(_squareForceMovable)) return;

    final piecesA = piecesAt(a);
    final piecesB = piecesAt(b);
    final piecesC = piecesAt(c);
    final piecesD = piecesAt(d);

    _clearSquare(a);
    _clearSquare(b);
    _clearSquare(c);
    _clearSquare(d);

    _setCell(b, piecesA);
    _setCell(c, piecesB);
    _setCell(d, piecesC);
    _setCell(a, piecesD);
  }

  void _splitQueen(Square square) {
    final queen = pieceAt(square);
    if (queen == null || queen.type != PieceType.queen) return;

    final bishop = queen.copyWith(type: PieceType.bishop, hasMoved: true);
    final rook = queen.copyWith(type: PieceType.rook, hasMoved: true);
    _setPrimary(square, bishop);
    _setExtra(square, rook);
  }

  void _applyTide(PieceColor color) {
    final fromRank = color == PieceColor.white ? 1 : _rankCount - 2;
    final toRank = color == PieceColor.white ? 2 : _rankCount - 3;

    for (var file = 0; file < _fileCount; file++) {
      final piece = _board[fromRank][file];
      if (piece == null ||
          piece.color != color ||
          piece.type != PieceType.pawn) {
        continue;
      }
      if (_board[toRank][file] != null) continue;
      _board[fromRank][file] = null;
      _board[toRank][file] = piece.withAbility(GameAbility.boardTide);
    }

    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final piece = _board[rank][file];
        if (piece == null ||
            piece.color != color ||
            piece.type != PieceType.pawn) {
          continue;
        }
        if (!piece.hasAbility(GameAbility.boardTide)) {
          _board[rank][file] = piece.withAbility(GameAbility.boardTide);
        }
      }
    }
  }

  void _applyPawnFront(PieceColor color) {
    final direction = color == PieceColor.white ? 1 : -1;
    final entries = <(Square, Square, Piece)>[];

    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final from = Square(file, rank);
        final piece = pieceAt(from);
        if (piece == null ||
            piece.color != color ||
            piece.type != PieceType.pawn) {
          continue;
        }

        final to = Square(file, rank + direction);
        if (!isOnBoard(to) || pieceAt(to) != null || isBlocked(to)) continue;
        entries.add((from, to, piece));
      }
    }

    for (final (from, to, piece) in entries) {
      _clearSquare(from);
      _setPrimary(to, _pieceAfterMove(piece, from, to));
    }
  }

  void _applyColorblind() {
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        final pieces = piecesAt(square);
        if (pieces.isEmpty) continue;
        final recolored = [
          for (final piece in pieces)
            piece.copyWith(cosmeticHue: _random.nextInt(360)),
        ];
        _setCell(square, recolored);
      }
    }
  }

  void _applyCavalry(PieceColor color) {
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        final pieces = piecesAt(square);
        if (pieces.isEmpty) continue;

        final updated = <Piece>[];
        var changed = false;
        for (final piece in pieces) {
          if (piece.color == color && piece.type == PieceType.pawn) {
            updated.add(
              piece.copyWith(
                type: PieceType.knight,
                restoreAs: PieceType.pawn,
                restoreAfterMoves: 0,
              ),
            );
            changed = true;
          } else {
            updated.add(piece);
          }
        }

        if (changed) {
          _setCell(square, updated);
        }
      }
    }

    if (color == PieceColor.white) {
      _whiteCavalryMovesLeft = 3;
    } else {
      _blackCavalryMovesLeft = 3;
    }
  }

  void _restoreCavalry(PieceColor color) {
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        final pieces = piecesAt(square);
        if (pieces.isEmpty) continue;

        final updated = <Piece>[];
        var changed = false;
        for (final piece in pieces) {
          if (piece.color == color &&
              piece.type == PieceType.knight &&
              piece.restoreAs == PieceType.pawn) {
            updated.add(
              piece.copyWith(
                type: PieceType.pawn,
                clearRestoreAs: true,
                restoreAfterMoves: 0,
              ),
            );
            changed = true;
          } else {
            updated.add(piece);
          }
        }

        if (changed) {
          _setCell(square, updated);
        }
      }
    }
  }

  void _tickQuarantine() {
    if (_quarantineMovesLeft <= 0) return;
    _quarantineMovesLeft--;
    if (_quarantineMovesLeft <= 0) {
      _quarantineSquare = null;
    }
  }

  void _tickSquareColorLock() {
    if (_squareColorLockMovesLeft <= 0) return;
    _squareColorLockMovesLeft--;
    if (_squareColorLockMovesLeft <= 0) {
      _squareColorLock = null;
    }
  }

  void _tickTruce() {
    if (_truceMovesLeft <= 0) return;
    _truceMovesLeft--;
  }

  void _tickCavalry() {
    if (_whiteCavalryMovesLeft > 0) {
      _whiteCavalryMovesLeft--;
      if (_whiteCavalryMovesLeft == 0) {
        _restoreCavalry(PieceColor.white);
      }
    }

    if (_blackCavalryMovesLeft > 0) {
      _blackCavalryMovesLeft--;
      if (_blackCavalryMovesLeft == 0) {
        _restoreCavalry(PieceColor.black);
      }
    }
  }

  void _tickTurnEffects({int unbridledDepth = 0}) {
    final finished = _turn.opponent;
    _tickQuarantine();
    _tickSquareColorLock();
    _tickTruce();
    _tickCavalry();
    _tickExpandedModsAfterPass(finished);
    _tickAttraction();
    _tickDust();
    _tickLaser();
    _tickKnightGuards();
    _tickCustoms();
    _tickCurfewBindings();
    _updateSiegeFor(finished);
    _resolveDelayedSentencesFor(finished);
    _tickCaliphFor(finished);
    _tickPolymorphFor(finished);
    _tickSkipTurnsFor(finished);
    _tickKamikazeFor(_turn);
    _tickMatkaFor(_turn);
    _tickPlague();
    _tickTrojanFor(_turn);
    final stoleTurn = _tickUnbridledHorseFor(_turn);
    _tickGolconda();
    _resolveAllGuardLandings();
    if (stoleTurn && unbridledDepth < 8) {
      _turn = _turn.opponent;
      _tickTurnEffects(unbridledDepth: unbridledDepth + 1);
    }
  }

  void _tickCustoms() {
    for (final id in _customsStates.keys.toList()) {
      final state = _customsStates[id]!;
      final rook = _pieceById(id);
      if (rook == null ||
          !_hasEffect(rook.piece, AbilityEffect.rookCustoms)) {
        _customsStates.remove(id);
        continue;
      }
      if (state.owner != _turn) continue;
      final left = state.turnsLeft - 1;
      if (left <= 0) {
        _customsStates.remove(id);
      } else {
        _customsStates[id] = state.copyWith(turnsLeft: left);
      }
    }
  }

  void _tickCurfewBindings() {
    for (final entry in _curfewBindings.entries.toList()) {
      final binding = entry.value;
      final piece = _pieceById(binding.pieceId);
      final rook = _pieceById(binding.rookId);
      if (piece == null ||
          rook == null ||
          !_hasEffect(rook.piece, AbilityEffect.rookCurfew) ||
          _chebyshevDistance(rook.square, piece.square) > 1) {
        _curfewBindings.remove(entry.key);
        continue;
      }
      if (piece.piece.color != _turn) continue;
      final left = binding.ownerTurnsLeft - 1;
      if (left <= 0) {
        _curfewBindings.remove(entry.key);
      } else {
        _curfewBindings[entry.key] = RookCurfewState(
          rookId: binding.rookId,
          pieceId: binding.pieceId,
          ownerTurnsLeft: left,
        );
      }
    }
  }

  void _updateSiegeFor(PieceColor finished) {
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        final pieces = piecesAt(square);
        for (var index = 0; index < pieces.length; index++) {
          final rook = pieces[index];
          if (rook.color != finished ||
              rook.type != PieceType.rook ||
              !_hasEffect(rook, AbilityEffect.rookSiegeCalculation)) {
            continue;
          }
          final targets = _siegeCaptureTargetIds(square, rook, index);
          if (targets.isEmpty) {
            _siegeStates.remove(rook.pieceId);
            continue;
          }
          final previous = _siegeStates[rook.pieceId];
          final targetId =
              previous != null && targets.contains(previous.targetId)
              ? previous.targetId
              : targets.first;
          final counter =
              previous != null && previous.targetId == targetId
              ? previous.counter + 1
              : 1;
          if (counter >= 3) {
            final victim = _pieceById(targetId);
            if (victim != null) {
              final removed = _takePieceAt(victim.square, victim.index);
              if (removed != null) {
                _onFinalDeath(
                  removed,
                  victim.square,
                  capturingColor: rook.color,
                  reason: GraveyardReason.ability,
                );
              }
            }
            _siegeStates.remove(rook.pieceId);
          } else {
            _siegeStates[rook.pieceId] = SiegeInternalState(
              targetId: targetId,
              counter: counter,
              rookSquare: square,
            );
          }
        }
      }
    }
  }

  List<String> _siegeCaptureTargetIds(
    Square from,
    Piece rook,
    int pieceIndex,
  ) {
    final ids = <String>[];
    for (final move in _getPseudoLegalMoves(
      from,
      rook,
      pieceIndex: pieceIndex,
    )) {
      if (!_isCapture(move)) continue;
      final victim = _captureVictim(move, rook.color);
      if (victim == null) continue;
      ids.add(victim.piece.pieceId);
    }
    ids.sort();
    return ids;
  }

  void _resolveDelayedSentencesFor(PieceColor finished) {
    for (final entry in _delayedSentences.entries.toList()) {
      final state = entry.value;
      if (state.targetOwner != finished) continue;
      _delayedSentences.remove(entry.key);
      final queen = _pieceById(state.queenId);
      final target = _pieceById(state.targetId);
      if (queen == null ||
          target == null ||
          !_hasEffect(queen.piece, AbilityEffect.queenDelayedSentence) ||
          !_canAttack(queen.square, target.square, queen.piece)) {
        continue;
      }
      final removed = _takePieceAt(target.square, target.index);
      if (removed != null) {
        _onFinalDeath(
          removed,
          target.square,
          capturingColor: queen.piece.color,
          reason: GraveyardReason.ability,
        );
      }
    }
  }

  // Kept for queen trophy-embargo ability; capture rewards no longer consult it.
  // ignore: unused_element
  bool _squareUnderTrophyEmbargo(Square square, PieceColor capturerColor) {
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final from = Square(file, rank);
        for (final piece in piecesAt(from)) {
          if (piece.color == capturerColor) continue;
          if (piece.type != PieceType.queen) continue;
          if (!_hasEffect(piece, AbilityEffect.queenTrophyEmbargo)) continue;
          if (_canAttack(from, square, piece)) return true;
        }
      }
    }
    return false;
  }

  void _applyCurfewBindings(String rookId) {
    final rook = _pieceById(rookId);
    if (rook == null) return;
    _curfewBindings.removeWhere((_, binding) => binding.rookId == rookId);
    for (var dr = -1; dr <= 1; dr++) {
      for (var df = -1; df <= 1; df++) {
        if (df == 0 && dr == 0) continue;
        final square = _offsetSquare(rook.square, df, dr);
        if (square == null) continue;
        for (final piece in piecesAt(square)) {
          if (piece.color == rook.piece.color) continue;
          if (piece.type == PieceType.king) continue;
          _curfewBindings[piece.pieceId] = RookCurfewState(
            rookId: rookId,
            pieceId: piece.pieceId,
            ownerTurnsLeft: 4,
          );
        }
      }
    }
  }

  void _activateCustoms(Piece rook, Square square, AbilityOffer? offer) {
    final axis =
        offer?.axis ??
        (_random.nextBool() ? AbilityAxis.file : AbilityAxis.rank);
    final line = axis == AbilityAxis.file ? square.file : square.rank;
    final exempt = <String>{};
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final onLine = axis == AbilityAxis.file ? file == line : rank == line;
        if (!onLine) continue;
        for (final piece in piecesAt(Square(file, rank))) {
          exempt.add(piece.pieceId);
        }
      }
    }
    _customsStates[rook.pieceId] = CustomsState(
      rookId: rook.pieceId,
      owner: rook.color,
      axis: axis,
      line: line,
      turnsLeft: 4,
      exemptPieceIds: exempt,
    );
  }

  void _tickKnightGuards() {
    for (final id in _guardTurnsLeft.keys.toList()) {
      final guard = _pieceById(id);
      if (guard == null ||
          guard.piece.color != _turn ||
          !_hasEffect(guard.piece, AbilityEffect.knightGuard)) {
        if (guard == null) {
          _guardTurnsLeft.remove(id);
          _guardSquares.remove(id);
        }
        continue;
      }
      final left = (_guardTurnsLeft[id] ?? 0) - 1;
      if (left <= 0) {
        _guardTurnsLeft.remove(id);
        _guardSquares.remove(id);
      } else {
        _guardTurnsLeft[id] = left;
      }
    }
  }

  void _tickDust() {
    final next = <Square, int>{};
    for (final e in _dustSquares.entries) {
      final left = e.value - 1;
      if (left > 0) next[e.key] = left;
    }
    _dustSquares
      ..clear()
      ..addAll(next);
  }

  void _tickLaser() {
    final next = <int, int>{};
    final nextOwner = <int, PieceColor>{};
    for (final e in _laserFiles.entries) {
      final left = e.value - 1;
      if (left > 0) {
        next[e.key] = left;
        final owner = _laserFileOwner[e.key];
        if (owner != null) nextOwner[e.key] = owner;
      }
    }
    _laserFiles
      ..clear()
      ..addAll(next);
    _laserFileOwner
      ..clear()
      ..addAll(nextOwner);
  }

  void _tickCaliphFor(PieceColor color) {
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        final pieces = piecesAt(square);
        for (var i = 0; i < pieces.length; i++) {
          final piece = pieces[i];
          if (piece.color != color) continue;
          if (!piece.hasEffect(AbilityEffect.caliph)) continue;
          if (piece.caliphGrace) {
            _replacePieceAt(square, i, piece.copyWith(caliphGrace: false));
            continue;
          }
          // Конец хода халифа — вернуть в пешку.
          var next = piece.copyWith(
            type: PieceType.pawn,
            clearRestoreAs: true,
            restoreAfterMoves: 0,
          );
          next = next.withoutAbility(GameAbility.pawnCaliph);
          _replacePieceAt(square, i, next);
        }
      }
    }
  }

  void _tickPolymorphFor(PieceColor color) {
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        final pieces = piecesAt(square);
        for (var i = 0; i < pieces.length; i++) {
          final piece = pieces[i];
          if (piece.color != color) continue;
          if (!piece.hasEffect(AbilityEffect.polymorph)) continue;
          if (piece.polymorphGrace) {
            _replacePieceAt(square, i, piece.copyWith(polymorphGrace: false));
            continue;
          }
          if (piece.type == PieceType.pawn) continue;
          _replacePieceAt(
            square,
            i,
            piece.copyWith(type: PieceType.pawn, clearMoveAsType: true),
          );
        }
      }
    }
  }

  void _tickMatkaFor(PieceColor color) {
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        final pieces = piecesAt(square);
        for (var i = 0; i < pieces.length; i++) {
          final piece = pieces[i];
          if (piece.color != color) continue;
          if (piece.type != PieceType.queen) continue;
          if (!piece.hasEffect(AbilityEffect.queenMatka)) continue;

          final nextTurns = piece.matkaTurns + 1;
          if (nextTurns < 3) {
            _replacePieceAt(square, i, piece.copyWith(matkaTurns: nextTurns));
            continue;
          }

          _replacePieceAt(square, i, piece.copyWith(matkaTurns: 0));
          _spawnMatkaPawn(square, color);
        }
      }
    }
  }

  void _tickPlague() {
    if (!_plagueActive) return;

    final snapshot = <(Square, List<Piece>)>[];
    final plaguedSquares = <Square>{};
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        final pieces = piecesAt(square);
        if (pieces.isEmpty) continue;
        snapshot.add((square, pieces));
        if (pieces.any((piece) => piece.isPlagued)) {
          plaguedSquares.add(square);
        }
      }
    }

    for (final (square, pieces) in snapshot) {
      final next = <Piece>[];
      final deaths = <Piece>[];
      for (final piece in pieces) {
        if (piece.plagueTurnsLeft > 0) {
          final turnsLeft = piece.plagueTurnsLeft - 1;
          if (turnsLeft > 0) {
            next.add(piece.copyWith(plagueTurnsLeft: turnsLeft));
          } else {
            deaths.add(piece);
          }
          continue;
        }

        var adjacentPlague = false;
        for (var dr = -1; dr <= 1 && !adjacentPlague; dr++) {
          for (var df = -1; df <= 1; df++) {
            if (df == 0 && dr == 0) continue;
            final neighbor = _offsetSquare(square, df, dr);
            if (neighbor == null) continue;
            if (plaguedSquares.contains(neighbor)) {
              adjacentPlague = true;
              break;
            }
          }
        }

        final chance = adjacentPlague ? 10 : 1;
        if (_random.nextInt(100) < chance) {
          next.add(piece.copyWith(plagueTurnsLeft: 3));
        } else {
          next.add(piece);
        }
      }

      _setCell(square, next);
      for (final piece in deaths) {
        _onFinalDeath(
          piece,
          square,
          reason: GraveyardReason.plague,
        );
      }
    }
  }

  void _tickTrojanFor(PieceColor color) {
    final sources = <(Square, int, Piece)>[];
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        final pieces = piecesAt(square);
        for (var i = 0; i < pieces.length; i++) {
          final piece = pieces[i];
          if (piece.color != color) continue;
          if (!piece.hasEffect(AbilityEffect.knightTrojan)) continue;
          if (piece.trojanTurnsLeft <= 0) continue;
          sources.add((square, i, piece));
        }
      }
    }

    for (final (square, index, _) in sources) {
      final current = pieceAt(square, index: index);
      if (current == null ||
          current.color != color ||
          !current.hasEffect(AbilityEffect.knightTrojan)) {
        continue;
      }

      if (current.trojanTurnsLeft <= 1) {
        _explodeTrojanAt(square);
      } else {
        _replacePieceAt(
          square,
          index,
          current.copyWith(trojanTurnsLeft: current.trojanTurnsLeft - 1),
        );
      }
    }
  }

  void _spawnMatkaPawn(Square queenSquare, PieceColor color) {
    final candidates = <Square>[];
    for (var dr = -1; dr <= 1; dr++) {
      for (var df = -1; df <= 1; df++) {
        if (df == 0 && dr == 0) continue;
        final square = _offsetSquare(queenSquare, df, dr);
        if (square == null) continue;
        if (piecesAt(square).isNotEmpty) continue;
        if (isBlocked(square)) continue;
        if (!_isLandingAllowed(
          square,
          forPiece: Piece(type: PieceType.pawn, color: color),
        )) {
          continue;
        }
        candidates.add(square);
      }
    }
    if (candidates.isEmpty) return;
    final target = candidates[_random.nextInt(candidates.length)];
    _setPrimary(
      target,
      Piece(type: PieceType.pawn, color: color, hasMoved: true),
    );
  }

  void _tickSkipTurnsFor(PieceColor color) {
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        final pieces = piecesAt(square);
        for (var i = 0; i < pieces.length; i++) {
          final piece = pieces[i];
          if (piece.color != color || piece.skipTurnsLeft <= 0) continue;
          _replacePieceAt(
            square,
            i,
            piece.copyWith(skipTurnsLeft: piece.skipTurnsLeft - 1),
          );
        }
      }
    }
  }

  void _tickKamikazeFor(PieceColor color) {
    final blasts = <Square>[];
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        for (final piece in piecesAt(square)) {
          if (piece.color == color &&
              piece.type == PieceType.pawn &&
              piece.hasEffect(AbilityEffect.kamikaze)) {
            blasts.add(square);
          }
        }
      }
    }
    for (final square in blasts) {
      _explodeKamikaze(square);
    }
  }

  void _explodeKamikaze(Square at) {
    final pawn = pieceAt(at);
    if (pawn == null) return;
    // Сначала отброс соседей.
    for (var dr = -1; dr <= 1; dr++) {
      for (var df = -1; df <= 1; df++) {
        if (df == 0 && dr == 0) continue;
        final neighbor = _offsetSquare(at, df, dr);
        if (neighbor == null) continue;
        final victim = pieceAt(neighbor);
        if (victim == null) continue;
        if (!canForceMove(neighbor, victim.pieceId)) continue;
        final dest = _offsetSquare(neighbor, df, dr);
        if (dest == null) continue;
        if (piecesAt(dest).isNotEmpty) continue;
        if (isBlocked(dest) || !_isLandingAllowed(dest, forPiece: victim)) {
          continue;
        }
        _clearSquare(neighbor);
        _setPrimary(dest, victim);
        _resolveMineAt(dest);
        _checkColorVowAt(dest);
      }
    }
    _capturePiecesAt(at); // пешка уничтожается (камикадзе)
  }

  /// Возвращает true, если конь сходил вместо игрока.
  bool _tickUnbridledHorseFor(PieceColor color) {
    if (!_unbridledHorse) return false;
    if (_random.nextInt(100) >= 5) return false;

    final knights = <(Square, int, Piece)>[];
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        final pieces = piecesAt(square);
        for (var i = 0; i < pieces.length; i++) {
          final p = pieces[i];
          if (p.color == color &&
              p.type == PieceType.knight &&
              p.skipTurnsLeft <= 0) {
            knights.add((square, i, p));
          }
        }
      }
    }
    if (knights.isEmpty) return false;
    final (from, index, piece) = knights[_random.nextInt(knights.length)];
    final moves = _knightMoves(
      from,
      piece,
      pieceIndex: index,
    ).where(_isLegalMove).toList();
    if (moves.isEmpty) return false;
    final move = moves[_random.nextInt(moves.length)];
    _applyMove(move);
    _tickLava(color);
    return true;
  }

  void _checkColorVowAt(Square square) {
    final pieces = piecesAt(square);
    for (var i = pieces.length - 1; i >= 0; i--) {
      final piece = pieces[i];
      if (!piece.hasEffect(AbilityEffect.colorVow)) continue;
      if (piece.boundIsLight == null) continue;
      if (isSquareLight(square) != piece.boundIsLight) {
        final removed = _takePieceAt(square, i);
        if (removed != null) _onFinalDeath(removed, square);
      }
    }
  }

  void _tickGolconda() {
    if (!_golcondaActive) return;
    if (_random.nextInt(100) != 0) return; // 1%

    final empty = <Square>[];
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        if (piecesAt(square).isNotEmpty) continue;
        if (isBlocked(square) || isGhostCell(square)) continue;
        if (_mines.contains(square)) continue;
        empty.add(square);
      }
    }
    if (empty.isEmpty) return;

    final square = empty[_random.nextInt(empty.length)];
    final type = switch (_random.nextInt(3)) {
      0 => PieceType.pawn,
      1 => PieceType.knight,
      _ => PieceType.bishop,
    };
    _setPrimary(
      square,
      Piece(
        type: type,
        color: _turn,
        hasMoved: true,
        pawnRevealed: type == PieceType.pawn,
      ),
    );
  }

  void _applyVanityFair(PieceColor color) {
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        final pieces = piecesAt(square);
        for (var i = 0; i < pieces.length; i++) {
          final piece = pieces[i];
          if (piece.color != color) continue;
          if (piece.type != PieceType.knight &&
              piece.type != PieceType.bishop) {
            continue;
          }
          final nextType = _random.nextBool()
              ? PieceType.knight
              : PieceType.bishop;
          if (nextType == piece.type) continue;
          _replacePieceAt(square, i, piece.copyWith(type: nextType));
        }
      }
    }
  }

  void _applyMinefield(int count, [Random? rng]) {
    final random = rng ?? _random;
    final candidates = <Square>[];
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        if (piecesAt(square).isNotEmpty) continue;
        if (isBlocked(square) || isGhostCell(square)) continue;
        if (isTeleportSquare(square)) continue;
        if (_mines.contains(square)) continue;
        candidates.add(square);
      }
    }
    candidates.shuffle(random);
    _mines.addAll(candidates.take(min(count, candidates.length)));
  }

  void _tickAttraction() {
    if (!_attractionActive) return;
    _attractionMoveCounter++;
    if (_attractionMoveCounter % 10 == 0) {
      _applyAttractionPulse();
    }
  }

  Square? _pieceSquareAfterMove(Move move, PieceColor color) {
    // Бумеранг возвращает на клетку хода.
    final onFrom = pieceAt(move.from);
    if (onFrom != null && onFrom.color == color) return move.from;

    if (_teleportA != null && _teleportB != null) {
      if (move.to == _teleportA) {
        final piece = pieceAt(_teleportB!);
        if (piece != null && piece.color == color) return _teleportB;
      }
      if (move.to == _teleportB) {
        final piece = pieceAt(_teleportA!);
        if (piece != null && piece.color == color) return _teleportA;
      }
    }
    return move.to;
  }

  void _applyGhostCells(int count, [Random? rng]) {
    final random = rng ?? _random;
    final candidates = <Square>[];
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        if (piecesAt(square).isNotEmpty) continue;
        if (isBlocked(square)) continue;
        if (_ghostCells.contains(square)) continue;
        if (isTeleportSquare(square)) continue;
        candidates.add(square);
      }
    }
    candidates.shuffle(random);
    final n = min(count, candidates.length);
    _ghostCells.addAll(candidates.take(n));
  }

  void _applyShuffle([Random? rng]) {
    final random = rng ?? _random;
    _shuffledSquareLight = [
      for (var rank = 0; rank < _rankCount; rank++)
        [for (var file = 0; file < _fileCount; file++) random.nextBool()],
    ];
  }

  void _applyTeleport(Square? a, Square? b, [Random? rng]) {
    final random = rng ?? _random;
    if (_isValidTeleportEndpoint(a) &&
        _isValidTeleportEndpoint(b) &&
        a != b) {
      _teleportA = a;
      _teleportB = b;
      return;
    }
    final pair = _pickTwoEmptyTeleportSquares(random);
    if (pair == null) return;
    _teleportA = pair.$1;
    _teleportB = pair.$2;
  }

  bool _isValidTeleportEndpoint(Square? square) {
    if (square == null || !isOnBoard(square)) return false;
    if (piecesAt(square).isNotEmpty) return false;
    if (isBlocked(square) || isGhostCell(square)) return false;
    return true;
  }

  List<Square> _emptyTeleportCandidates() {
    final candidates = <Square>[];
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        if (!_isValidTeleportEndpoint(square)) continue;
        candidates.add(square);
      }
    }
    return candidates;
  }

  (Square, Square)? _pickTwoEmptyTeleportSquares(Random random) {
    final candidates = _emptyTeleportCandidates();
    if (candidates.length < 2) return null;
    candidates.shuffle(random);
    return (candidates[0], candidates[1]);
  }

  /// Телепорт в оффере должен показывать только свободные клетки.
  List<AbilityOffer> _resolveTeleportOffers(List<AbilityOffer> offers) {
    return [
      for (final offer in offers)
        if (offer.ability == GameAbility.boardTeleport)
          _bakeTeleportOffer(offer)
        else
          offer,
    ];
  }

  AbilityOffer _bakeTeleportOffer(AbilityOffer offer) {
    final pair = _pickTwoEmptyTeleportSquares(_rngForOffer(offer));
    if (pair == null) return offer;
    final json = offer.toJson();
    json['teleportA'] = {'file': pair.$1.file, 'rank': pair.$1.rank};
    json['teleportB'] = {'file': pair.$2.file, 'rank': pair.$2.rank};
    return AbilityOffer.fromJson(json);
  }

  void _applyInvisibleRegiment() {
    _invisibleRegiment = true;
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        final pieces = piecesAt(square);
        for (var i = 0; i < pieces.length; i++) {
          final piece = pieces[i];
          if (piece.type != PieceType.pawn || piece.pawnRevealed) continue;
          if (_pawnShouldBeRevealed(piece, square)) {
            _replacePieceAt(square, i, piece.copyWith(pawnRevealed: true));
          }
        }
      }
    }
  }

  bool _pawnShouldBeRevealed(Piece piece, Square square) {
    if (piece.pawnRevealed) return true;
    if (piece.color == PieceColor.white) return square.rank >= 3;
    return square.rank <= 4;
  }

  void _applyVirusInfection(Square at, PieceColor byColor) {
    final enemies = <(Square, int, Piece)>[];
    for (var dr = -1; dr <= 1; dr++) {
      for (var df = -1; df <= 1; df++) {
        if (df == 0 && dr == 0) continue;
        final square = _offsetSquare(at, df, dr);
        if (square == null) continue;
        final pieces = piecesAt(square);
        for (var i = 0; i < pieces.length; i++) {
          final piece = pieces[i];
          if (piece.color == byColor) continue;
          if (piece.abilities.isEmpty) continue;
          enemies.add((square, i, piece));
        }
      }
    }
    if (enemies.isEmpty) return;
    final (square, index, piece) = enemies[_random.nextInt(enemies.length)];
    final abilities = piece.abilities.toList()..shuffle(_random);
    _replacePieceAt(square, index, piece.withoutAbility(abilities.first));
    _refreshDoppelgangerFlags();
  }

  Set<Square> get _centerSquares {
    final f0 = (_fileCount ~/ 2) - 1;
    final f1 = _fileCount ~/ 2;
    final r0 = (_rankCount ~/ 2) - 1;
    final r1 = _rankCount ~/ 2;
    return {Square(f0, r0), Square(f0, r1), Square(f1, r0), Square(f1, r1)};
  }

  void _applyAttractionPulse() {
    final centers = _centerSquares;
    final planned = <Square, Square>{};

    final entries = <(Square, Piece)>[];
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        final piece = pieceAt(square);
        if (piece == null) continue;
        entries.add((square, piece));
      }
    }

    entries.sort((a, b) {
      final da = centers.map((c) => _chebyshevDistance(a.$1, c)).reduce(min);
      final db = centers.map((c) => _chebyshevDistance(b.$1, c)).reduce(min);
      return db.compareTo(da); // outer first
    });

    for (final (from, _) in entries) {
      if (centers.contains(from)) continue;
      var best = centers.first;
      var bestDist = _chebyshevDistance(from, best);
      for (final c in centers) {
        final d = _chebyshevDistance(from, c);
        if (d < bestDist) {
          bestDist = d;
          best = c;
        }
      }
      final df = (best.file - from.file).sign;
      final dr = (best.rank - from.rank).sign;
      if (df == 0 && dr == 0) continue;
      final to = Square(from.file + df, from.rank + dr);
      if (!isOnBoard(to)) continue;
      if (piecesAt(to).isNotEmpty) continue;
      if (isBlocked(to) || !_isLandingAllowed(to)) continue;
      planned[from] = to;
    }

    final claimed = <Square>{};
    final conflicted = <Square>{};
    for (final to in planned.values) {
      if (!claimed.add(to)) conflicted.add(to);
    }

    final moves = <(Square, Square)>[];
    for (final entry in planned.entries) {
      if (conflicted.contains(entry.value)) continue;
      // Don't move onto a square that someone is leaving if that causes issues —
      // apply from outer: destinations must be empty at apply time.
      moves.add((entry.key, entry.value));
    }

    // Apply in order where destination isn't a source still occupied.
    final sources = {for (final m in moves) m.$1};
    final ready = moves.where((m) => !sources.contains(m.$2)).toList();
    final deferred = moves.where((m) => sources.contains(m.$2)).toList();

    void applyOne(Square from, Square to) {
      final piece = pieceAt(from);
      if (piece == null || piecesAt(to).isNotEmpty) return;
      if (!canForceMove(from, piece.pieceId)) return;
      _clearSquare(from);
      _setPrimary(to, piece);
      if (piece.type == PieceType.king) {
        // thrones stay; king just moves
      }
    }

    for (final (from, to) in ready) {
      applyOne(from, to);
    }
    for (final (from, to) in deferred) {
      applyOne(from, to);
    }

    // Мины срабатывают после сдвига притяжения.
    for (final square in _mines.toList()) {
      if (piecesAt(square).isNotEmpty) {
        _resolveMineAt(square);
      }
    }
  }

  void _insertExtraRank() {
    if (_rankCount >= 9) return;
    _board.insert(4, List<Piece?>.filled(_fileCount, null));
    _rekeyStackExtras(rankDelta: 1, shouldShift: (square) => square.rank >= 4);
    _rankCount = 9;
    final updated = <int>{};
    for (final rank in _lavaRanks) {
      updated.add(rank >= 4 ? rank + 1 : rank);
    }
    _lavaRanks
      ..clear()
      ..addAll(updated);
    if (_whiteThrone.rank >= 4) {
      _whiteThrone = Square(_whiteThrone.file, _whiteThrone.rank + 1);
    }
    if (_blackThrone.rank >= 4) {
      _blackThrone = Square(_blackThrone.file, _blackThrone.rank + 1);
    }
    _shiftSpecialSquaresRank(fromRank: 4);
  }

  void _shiftSpecialSquaresRank({required int fromRank}) {
    Square shift(Square s) =>
        s.rank >= fromRank ? Square(s.file, s.rank + 1) : s;

    final nextGhosts = _ghostCells.map(shift).toSet();
    _ghostCells
      ..clear()
      ..addAll(nextGhosts);

    final nextMines = _mines.map(shift).toSet();
    _mines
      ..clear()
      ..addAll(nextMines);

    if (_teleportA != null) _teleportA = shift(_teleportA!);
    if (_teleportB != null) _teleportB = shift(_teleportB!);

    final shuffled = _shuffledSquareLight;
    if (shuffled != null) {
      shuffled.insert(
        fromRank,
        List.generate(_fileCount, (_) => _random.nextBool()),
      );
    }
  }

  void _shiftSpecialSquaresFile({required bool insertOnLeft}) {
    Square shift(Square s) => insertOnLeft ? Square(s.file + 1, s.rank) : s;

    final nextGhosts = _ghostCells.map(shift).toSet();
    _ghostCells
      ..clear()
      ..addAll(nextGhosts);

    final nextMines = _mines.map(shift).toSet();
    _mines
      ..clear()
      ..addAll(nextMines);

    if (_teleportA != null) _teleportA = shift(_teleportA!);
    if (_teleportB != null) _teleportB = shift(_teleportB!);

    final shuffled = _shuffledSquareLight;
    if (shuffled != null) {
      for (var rank = 0; rank < shuffled.length; rank++) {
        if (insertOnLeft) {
          shuffled[rank].insert(0, _random.nextBool());
        } else {
          shuffled[rank].add(_random.nextBool());
        }
      }
    }
  }

  void _insertExtraFileLeft() {
    if (_fileCount >= 10) return;
    if (_extraFileOnLeft == true) return;
    for (var rank = 0; rank < _rankCount; rank++) {
      _board[rank].insert(0, null);
    }
    _rekeyStackExtras(fileDelta: 1);
    _fileCount += 1;
    _extraFileOnLeft = true;
    _whiteThrone = Square(_whiteThrone.file + 1, _whiteThrone.rank);
    _blackThrone = Square(_blackThrone.file + 1, _blackThrone.rank);
    _shiftSpecialSquaresFile(insertOnLeft: true);
  }

  void _insertExtraFileRight() {
    if (_fileCount >= 10) return;
    if (_fileCount > defaultFileCount && _extraFileOnLeft == false) {
      // Already have a right-only extra file.
      return;
    }
    // When expanding from 9 with left file, still allow a right file.
    if (_fileCount > defaultFileCount &&
        _extraFileOnLeft == true &&
        _fileCount >= 10) {
      return;
    }
    for (var rank = 0; rank < _rankCount; rank++) {
      _board[rank].add(null);
    }
    _fileCount += 1;
    if (_extraFileOnLeft != true) {
      _extraFileOnLeft = false;
    }
    _shiftSpecialSquaresFile(insertOnLeft: false);
  }

  void _insertTerritoryExpand() {
    if (_fileCount >= 10) return;
    if (_extraFileOnLeft != true) {
      _insertExtraFileLeft();
    }
    if (_fileCount < 10) {
      // Force right insert even if left is present.
      for (var rank = 0; rank < _rankCount; rank++) {
        _board[rank].add(null);
      }
      _fileCount += 1;
      _shiftSpecialSquaresFile(insertOnLeft: false);
    }
  }

  void _applyFileShift(int file, int direction) {
    _shiftFile(file, direction);
  }

  void _tickLava(PieceColor color, {bool recordDeaths = true}) {
    if (_lavaRanks.isEmpty) return;

    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        if (!_lavaRanks.contains(rank)) continue;

        final square = Square(file, rank);
        final pieces = piecesAt(square);
        if (pieces.isEmpty) continue;

        final updated = <Piece>[];
        for (final piece in pieces) {
          if (piece.color != color) {
            updated.add(piece);
            continue;
          }

          final nextStreak = piece.lavaStreak + 1;
          if (nextStreak >= 4) {
            if (recordDeaths) {
              _pendingLavaDeaths.add(
                LavaDeathEvent(square: square, piece: piece),
              );
            }
          } else {
            updated.add(piece.copyWith(lavaStreak: nextStreak));
          }
        }

        _setCell(square, updated);
      }
    }
  }

  bool _isRearingKnight(Piece? piece) {
    return piece != null &&
        piece.type == PieceType.knight &&
        piece.hasEffect(AbilityEffect.knightRearing);
  }

  void _addMoveToSquare(
    List<Move> moves,
    Square from,
    Square to,
    Piece piece, {
    required int pieceIndex,
    bool isKnightRearSwap = false,
    bool isRookPush = false,
    bool isColorChaos = false,
    bool isAirborne = false,
  }) {
    if (isBlocked(to)) return;
    if (!_isLandingAllowed(to, forPiece: piece)) return;

    if (isKnightRearSwap) {
      if (!_isLandingAllowed(from, forPiece: piece)) return;
      if (_truceActive) return;
      moves.add(
        Move(
          from: from,
          to: to,
          isKnightRearSwap: true,
          pieceIndex: pieceIndex,
        ),
      );
      return;
    }

    final target = pieceAt(to);
    if (target == null) {
      moves.add(
        Move(
          from: from,
          to: to,
          isRookPush: isRookPush,
          isColorChaos: isColorChaos,
          isAirborne: isAirborne,
          pieceIndex: pieceIndex,
        ),
      );
      return;
    }

    if (_isRearingKnight(target)) {
      if (_truceActive) return;
      moves.add(
        Move(
          from: from,
          to: to,
          isKnightRearSwap: true,
          pieceIndex: pieceIndex,
        ),
      );
      return;
    }

    if (target.color == piece.color) {
      final canFamilyUnionCapture =
          piece.type == PieceType.king &&
          piece.hasEffect(AbilityEffect.kingFamilyUnion) &&
          (target.type == PieceType.knight || target.type == PieceType.bishop);
      final canBloodOathCapture =
          piece.type == PieceType.king && _bloodOathActive;
      if (canFamilyUnionCapture || canBloodOathCapture) {
        moves.add(
          Move(
            from: from,
            to: to,
            isRookPush: isRookPush,
            isColorChaos: isColorChaos,
            isAirborne: isAirborne,
            pieceIndex: pieceIndex,
          ),
        );
      }
      return;
    }

    if (target.color != piece.color) {
      if (_truceActive) return;
      if (piece.hasEffect(AbilityEffect.queenMatka)) return;
      if (_isFortressProtected(to, piece)) return;
      if (!_captureAllowed(piece, target)) return;
      moves.add(
        Move(
          from: from,
          to: to,
          isRookPush: isRookPush,
          isColorChaos: isColorChaos,
          isAirborne: isAirborne,
          pieceIndex: pieceIndex,
        ),
      );
    }
  }

  bool _isFortressProtected(Square targetSquare, Piece attacker) {
    if (attacker.type != PieceType.pawn &&
        attacker.type != PieceType.knight &&
        attacker.type != PieceType.bishop) {
      return false;
    }
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        for (final rook in piecesAt(square)) {
          if (rook.type != PieceType.rook) continue;
          if (!rook.hasEffect(AbilityEffect.fortress)) continue;
          if (rook.color == attacker.color) continue;
          final frontRank = rook.color == PieceColor.white
              ? square.rank + 1
              : square.rank - 1;
          if (frontRank == targetSquare.rank &&
              square.file == targetSquare.file) {
            return true;
          }
        }
      }
    }
    return false;
  }

  List<Move> _inquisitorStripMoves(
    Square from,
    Piece piece, {
    required int pieceIndex,
  }) {
    final moves = <Move>[];
    final attacks = _slidingMoves(
      from,
      piece,
      const [(-1, -1), (-1, 1), (1, -1), (1, 1)],
      hopAlly: piece.hasEffect(AbilityEffect.hopOverAlly),
      pieceIndex: pieceIndex,
    );
    for (final attack in attacks) {
      final target = pieceAt(attack.to);
      if (target == null || target.color == piece.color) continue;
      if (target.abilities.isEmpty) continue;
      moves.add(
        Move(
          from: from,
          to: attack.to,
          isInquisitorStrip: true,
          pieceIndex: pieceIndex,
        ),
      );
    }
    return moves;
  }

  List<Move> _bishopRicochetMoves(
    Square from,
    Piece piece, {
    required int pieceIndex,
  }) {
    final moves = <Move>[];
    const dirs = [(-1, -1), (-1, 1), (1, -1), (1, 1)];
    for (final (df, dr) in dirs) {
      var file = from.file;
      var rank = from.rank;
      while (true) {
        final nextFile = file + df;
        final nextRank = rank + dr;
        final nextOnBoard =
            nextRank >= 0 &&
            nextRank < _rankCount &&
            nextFile >= 0 &&
            nextFile < _fileCount;
        if (nextOnBoard) {
          final to = Square(nextFile, nextRank);
          if (isBlocked(to)) break;
          if (pieceAt(to) != null) break;
          file = nextFile;
          rank = nextRank;
          continue;
        }
        if (file == from.file && rank == from.rank) break;
        final edge = Square(file, rank);
        if (pieceAt(edge) != null || isBlocked(edge)) break;
        var rdf = df;
        var rdr = dr;
        if (nextFile < 0 || nextFile >= _fileCount) rdf = -df;
        if (nextRank < 0 || nextRank >= _rankCount) rdr = -dr;
        final bounce = Square(edge.file + rdf, edge.rank + rdr);
        if (!isOnBoard(bounce)) break;
        if (pieceAt(bounce) != null || isBlocked(bounce)) break;
        if (!_isLandingAllowed(bounce, forPiece: piece)) break;
        moves.add(Move(from: from, to: bounce, pieceIndex: pieceIndex));
        break;
      }
    }
    return moves;
  }

  void _grantToAllOfType(PieceColor color, GameAbility ability) {
    final pieceType = ability.primaryPieceType;
    if (pieceType == null) return;

    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        final pieces = piecesAt(square);
        for (var index = 0; index < pieces.length; index++) {
          final piece = pieces[index];
          if (piece.color != color || piece.type != pieceType) continue;
          _replacePieceAt(square, index, piece.withAbility(ability));
        }
      }
    }
  }

  void _grantAbility(
    Square square,
    GameAbility ability, {
    AbilityOffer? offer,
    int pieceIndex = 0,
  }) {
    final piece = pieceAt(square, index: pieceIndex);
    if (piece == null) return;
    var next = piece.withAbility(ability);

    if (ability == GameAbility.pawnCaliph) {
      next = next.copyWith(
        type: PieceType.queen,
        caliphGrace: true,
        clearRestoreAs: true,
        restoreAfterMoves: 0,
      );
    }
    if (ability == GameAbility.bishopColorVow) {
      next = next.copyWith(boundIsLight: isSquareLight(square));
    }
    if (ability == GameAbility.queenMatka) {
      next = next.copyWith(matkaTurns: 0);
    }
    if (ability == GameAbility.queenShadowEmpress) {
      next = next.copyWith(
        boundIsLight: offer?.landOnLight ?? _random.nextBool(),
      );
    }
    if (ability == GameAbility.rookAstronomicon) {
      // +1: сразу после выбора тик уменьшит счётчик.
      _laserFiles[square.file] = 4;
      _laserFileOwner[square.file] = piece.color;
    }
    if (ability == GameAbility.knightTrojan) {
      next = next.copyWith(trojanTurnsLeft: 3);
    }
    if (ability == GameAbility.knightStomp) {
      next = next.copyWith(stompPending: true);
    }
    if (ability == GameAbility.knightMagicHooves) {
      next = next.copyWith(magicHoovesPending: true);
    }
    if (ability == GameAbility.pawnMortar) {
      _rules.mortarCooldown[piece.pieceId] = 3;
    }
    if (ability == GameAbility.pawnDoubleLife) {
      _rules.doubleLifeHidden[piece.pieceId] =
          _random.nextBool() ? PieceType.knight : PieceType.bishop;
    }
    if (ability == GameAbility.kingOwnHands) {
      // Only one player may hold this.
      if (_rules.ownHandsOwner == null) {
        _rules.ownHandsOwner = piece.color;
      }
    }
    if (ability == GameAbility.pawnHereditaryEdict) {
      _rules.hereditaryEdictOwner = piece.color;
    }
    if (ability == GameAbility.queenFatherDream) {
      // Win check happens when abilities grow.
    }

    _replacePieceAt(square, pieceIndex, next);

    if (_hasEffect(next, AbilityEffect.signalFire) && _fogOfWar) {
      _revealSignalFire(next.color);
    }

    if (ability == GameAbility.rookCustoms) {
      _activateCustoms(next, square, offer);
    }
    if (ability == GameAbility.rookCurfew) {
      _applyCurfewBindings(piece.pieceId);
    }

    if (ability == GameAbility.knightTour) {
      _knightTourVisited.putIfAbsent(piece.pieceId, () => {square});
    }
    if (ability == GameAbility.bishopPilgrimage) {
      _pilgrimageQuadrants.putIfAbsent(
        piece.pieceId,
        () => {_quadrantFor(square)},
      );
    }
    if (offer?.targetSelection != null &&
        offer!.targetSelection != AbilityTargetSelection.none) {
      _beginAbilityTarget(
        ability: ability,
        sourceId: piece.pieceId,
        color: piece.color,
        selection: offer.targetSelection,
      );
    } else if (ability == GameAbility.knightDuel ||
        ability == GameAbility.knightGuard ||
        ability == GameAbility.bishopSanctuary ||
        ability == GameAbility.queenDelayedSentence ||
        ability == GameAbility.kingPrisonerExchange ||
        ability == GameAbility.kingRemoveEnemyMod ||
        ability == GameAbility.bishopParallelWorlds ||
        ability == GameAbility.knightRideMe) {
      _beginAbilityTarget(
        ability: ability,
        sourceId: piece.pieceId,
        color: piece.color,
        selection: switch (ability) {
          GameAbility.knightGuard => AbilityTargetSelection.cell,
          GameAbility.knightDuel => AbilityTargetSelection.enemyPiece,
          GameAbility.queenDelayedSentence => AbilityTargetSelection.enemyPiece,
          GameAbility.kingPrisonerExchange =>
            AbilityTargetSelection.capturedFriendlyPiece,
          GameAbility.kingRemoveEnemyMod => AbilityTargetSelection.enemyAbility,
          GameAbility.knightRideMe => AbilityTargetSelection.friendlyPiece,
          _ => AbilityTargetSelection.friendlyPiece,
        },
      );
    }

    if (ability == GameAbility.kingThrone) {
      _setThroneFor(piece.color, square);
    }

    if (ability == GameAbility.kingDoppelganger) {
      if (piece.color == PieceColor.white) {
        _whiteDoppelganger = true;
      } else {
        _blackDoppelganger = true;
      }

      if (piece.type != PieceType.king) {
        final kingSquare = findKing(piece.color);
        if (kingSquare != null) {
          final king = pieceAt(kingSquare);
          if (king != null) {
            _setPrimary(kingSquare, king.withAbility(ability));
          }
        }
      }
    }

    if (ability == GameAbility.knightKingGuard ||
        ability == GameAbility.bishopKingGuard) {
      _rules.kingGuardPieceIds.add(piece.pieceId);
    }
    if (ability == GameAbility.bishopSchism) {
      _applySchismSplit(piece.pieceId);
    }
    if (ability == GameAbility.knightTangledTrail) {
      _rules.tangledKnightBaseId = piece.pieceId;
    }
    if (ability == GameAbility.knightCustomsPath) {
      _rules.customsKnightId = piece.pieceId;
    }
    if (ability == GameAbility.rookIllDrive) {
      _rules.illDriveRookId = piece.pieceId;
    }
    if (ability == GameAbility.knightGallopContract) {
      _beginMultiCellTarget(
        ability: ability,
        sourceId: piece.pieceId,
        color: piece.color,
        needed: 3,
      );
    }
    if (ability == GameAbility.bishopHeretic) {
      _beginMultiCellTarget(
        ability: ability,
        sourceId: piece.pieceId,
        color: piece.color,
        needed: 4,
      );
    }
    if (ability == GameAbility.bishopCartographer) {
      _beginMultiCellTarget(
        ability: ability,
        sourceId: piece.pieceId,
        color: piece.color,
        needed: 1,
      );
    }
  }

  void _applyProcessionNudge(String bishopId, String pawnId) {
    final bishop = _pieceById(bishopId);
    final pawn = _pieceById(pawnId);
    if (bishop == null || pawn == null) return;
    final df = (pawn.square.file - bishop.square.file).sign;
    final dr = (pawn.square.rank - bishop.square.rank).sign;
    if (df == 0 || dr == 0) return;
    final dest = Square(pawn.square.file + df, pawn.square.rank + dr);
    if (!isOnBoard(dest) || piecesAt(dest).isNotEmpty || isBlocked(dest)) {
      return;
    }
    final moved = _takePieceAt(pawn.square, pawn.index);
    if (moved == null) return;
    _setPrimary(dest, moved);
  }

  void _refreshDoppelgangerFlags() {
    var white = false;
    var black = false;

    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        for (final piece in piecesAt(Square(file, rank))) {
          if (!piece.hasAbility(GameAbility.kingDoppelganger)) continue;
          if (piece.color == PieceColor.white) {
            white = true;
          } else {
            black = true;
          }
        }
      }
    }

    _whiteDoppelganger = white;
    _blackDoppelganger = black;
  }

  void _applyNoQueen(PieceColor enemyColor) {
    final queens = <Square>[];
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        final piece = pieceAt(square);
        if (piece == null ||
            piece.color != enemyColor ||
            piece.type != PieceType.queen) {
          continue;
        }
        queens.add(square);
      }
    }
    if (queens.isEmpty) return;

    final target = queens[_random.nextInt(queens.length)];
    final queen = pieceAt(target);
    if (queen == null) return;
    _setPrimary(
      target,
      queen.copyWith(
        type: PieceType.knight,
        restoreAs: PieceType.queen,
        restoreAfterMoves: 2,
      ),
    );
  }

  void _applyMeteorRain() {
    final occupied = <Square>[];
    final fallback = <Square>[];

    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        final pieces = piecesAt(square);
        final hasKing = pieces.any((piece) => piece.type == PieceType.king);
        if (hasKing) continue;
        fallback.add(square);
        if (pieces.isNotEmpty) {
          occupied.add(square);
        }
      }
    }

    occupied.shuffle(_random);
    fallback.shuffle(_random);

    final safe = _allSurveyorSafeSquares();
    final chosen = <Square>[];
    for (final square in occupied) {
      if (chosen.length == 3) break;
      if (safe.contains(square)) continue;
      if (_isAssemblyProtectedSquare(square)) continue;
      chosen.add(square);
    }
    for (final square in fallback) {
      if (chosen.length == 3) break;
      if (safe.contains(square)) continue;
      if (_isAssemblyProtectedSquare(square)) continue;
      if (!chosen.contains(square)) {
        chosen.add(square);
      }
    }

    for (final square in chosen) {
      final pieces = piecesAt(square);
      if (pieces.isNotEmpty) {
        _pendingLavaDeaths.add(
          LavaDeathEvent(square: square, piece: pieces.first),
        );
      }
      _clearSquare(square);
      for (final piece in pieces) {
        _onFinalDeath(piece, square);
      }
    }
  }

  void _applyCensus(PieceColor enemyColor) {
    final candidates = <(Square, int, Piece)>[];

    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        final pieces = piecesAt(square);
        for (var index = 0; index < pieces.length; index++) {
          final piece = pieces[index];
          if (piece.color != enemyColor || piece.abilities.isEmpty) continue;
          candidates.add((square, index, piece));
        }
      }
    }

    if (candidates.isEmpty) return;
    final (square, index, piece) =
        candidates[_random.nextInt(candidates.length)];
    final abilities = piece.abilities.toList()..shuffle(_random);
    _replacePieceAt(square, index, piece.withoutAbility(abilities.first));
    _refreshDoppelgangerFlags();
  }

  bool _reviveSecondChanceKnight(Piece piece) {
    if (!_hasEffect(piece, AbilityEffect.knightSecondChance)) return false;
    final previousSquare = piece.previousSquare;
    if (previousSquare == null ||
        !isOnBoard(previousSquare) ||
        isBlocked(previousSquare) ||
        piecesAt(previousSquare).isNotEmpty) {
      return false;
    }

    _setPrimary(previousSquare, piece.copyWith(clearPreviousSquare: true));
    return true;
  }

  void _capturePiecesAt(
    Square square, {
    PieceColor? capturingColor,
    GraveyardReason reason = GraveyardReason.capture,
  }) {
    final pieces = piecesAt(square);
    if (pieces.isEmpty) return;
    _clearSquare(square);
    for (final piece in pieces) {
      final queenEscape = _hasEffect(piece, AbilityEffect.queenEscape);
      final revived = _reviveSecondChanceKnight(piece);
      if (!revived) {
        _onFinalDeath(
          piece,
          square,
          capturingColor: capturingColor,
          reason: reason,
        );
      }
      if (_suppressCaptureSideEffects) continue;
      if (queenEscape) {
        _spawnQueenEscapePiece(piece);
      }
    }
  }

  final Set<String> _resolvingInheritance = {};

  void _onFinalDeath(
    Piece piece,
    Square deathSquare, {
    PieceColor? capturingColor,
    GraveyardReason reason = GraveyardReason.ability,
  }) {
    final triggersInheritance =
        piece.type == PieceType.pawn &&
        _hasEffect(piece, AbilityEffect.pawnInheritance);
    final partnerId = _duelLinks.remove(piece.pieceId);
    if (partnerId != null) _duelLinks.remove(partnerId);
    _guardSquares.remove(piece.pieceId);
    _guardTurnsLeft.remove(piece.pieceId);
    _sanctuaryTargets.remove(piece.pieceId);
    _sanctuaryTargets.removeWhere((_, target) => target == piece.pieceId);
    _excommunicationTypes.remove(piece.pieceId);
    _titheSuppressions.remove(piece.pieceId);
    for (final suppressions in _titheSuppressions.values) {
      suppressions.remove(piece.pieceId);
    }
    _pilgrimageProtected.remove(piece.pieceId);
    _customsStates.remove(piece.pieceId);
    _curfewBindings.remove(piece.pieceId);
    _curfewBindings.removeWhere((_, binding) => binding.rookId == piece.pieceId);
    _siegeStates.remove(piece.pieceId);
    _delayedSentences.remove(piece.pieceId);
    _delayedSentences.removeWhere(
      (_, state) =>
          state.queenId == piece.pieceId || state.targetId == piece.pieceId,
    );

    if (!_isSimulatingLegality) {
      if (_hasEffect(piece, AbilityEffect.pawnSeed)) {
        _rules.pawnSeeds[deathSquare] = (color: piece.color, fullMovesLeft: 3);
      }
      if (_hasEffect(piece, AbilityEffect.bishopRelicPower)) {
        _rules.relicDeathSquare[piece.pieceId] = deathSquare;
        _rules.relicPliesLeft[piece.pieceId] = 3;
      }
      if (_rules.warehouseActive &&
          piece.abilities.isNotEmpty &&
          capturingColor != null) {
        // Capturer's opponent lost a mod — wait, warehouse is for the chooser
        // who gets the next mod the opponent loses. Warehouse owner is whoever
        // picked the cataclysm — we didn't store owner. Use capturingColor's
        // opponent as the loser; warehouse goes to capturingColor.
        final lost = piece.abilities.first;
        _rules.warehousePendingAbility = lost;
        _rules.warehousePendingType = piece.type;
      }
      _graveyard.add(
        GraveyardRecord(
          piece: piece,
          originalOwner: piece.color,
          capturingColor: capturingColor,
          sequence: _graveyardSequence++,
          reason: reason,
        ),
      );
      if (reason == GraveyardReason.capture && capturingColor != null) {
        if (_rules.crazyhouseActive && piece.type != PieceType.king) {
          final dropType =
              piece.type == PieceType.pawn ? PieceType.pawn : piece.type;
          _rules.crazyhouseHand[capturingColor]!.add(dropType);
        }
        if (_rules.debtPitActive) {
          if (capturingColor == PieceColor.white) {
            _rules.whiteDebt++;
            _rules.blackDebt--;
          } else {
            _rules.blackDebt++;
            _rules.whiteDebt--;
          }
          if (_rules.whiteDebt >= 6) {
            _finishGame(
              winner: PieceColor.black,
              reason: GameEndReason.alternativeVictory,
              detail: 'debtPit',
            );
          } else if (_rules.blackDebt >= 6) {
            _finishGame(
              winner: PieceColor.white,
              reason: GameEndReason.alternativeVictory,
              detail: 'debtPit',
            );
          }
        }
        if (_rules.bloodFeudActive) {
          _rules.bloodFeudVictimColor = piece.color;
          _rules.bloodFeudPliesLeft = 2;
          _rules.bloodFeudBanner =
              'Кровная вражда — отомстите взятием за 2 хода, иначе соперник получит мод';
        }
        if (_rules.inkBlotActive) {
          _rules.inkBlotPlies[deathSquare] = 8; // 4 full moves
        }
        if (_rules.earnedRestSquare == deathSquare &&
            !_rules.earnedRestBurned) {
          _rules.earnedRestCaptures++;
          if (_rules.earnedRestCaptures >= 3) {
            _rules.earnedRestBurned = true;
            _wormholes.add(deathSquare);
          }
        }
        final capturerId = _lastMoveCapturerId();
        if (capturerId != null) {
          _rules.serialCaptureCounts[capturerId] =
              (_rules.serialCaptureCounts[capturerId] ?? 0) + 1;
        }
      }
      if (reason == GraveyardReason.capture &&
          capturingColor != null &&
          _hasEffect(piece, AbilityEffect.avengeMe)) {
        _rules.avengeCaptureSquare = deathSquare;
        _rules.avengeVictimColor = piece.color;
        _rules.avengePlyLeft = 2;
      }
      _transferTorchOnDeath(piece, deathSquare);
    }

    if (!triggersInheritance || !_resolvingInheritance.add(piece.pieceId)) {
      return;
    }
    try {
      final candidates = <({Square square, int index, Piece piece})>[];
      for (var rank = 0; rank < _rankCount; rank++) {
        for (var file = 0; file < _fileCount; file++) {
          final square = Square(file, rank);
          final pieces = piecesAt(square);
          for (var index = 0; index < pieces.length; index++) {
            final candidate = pieces[index];
            if (candidate.color == piece.color &&
                candidate.type == PieceType.pawn &&
                candidate.pieceId != piece.pieceId) {
              candidates.add((square: square, index: index, piece: candidate));
            }
          }
        }
      }
      candidates.sort((a, b) {
        final distance = _chebyshevDistance(
          deathSquare,
          a.square,
        ).compareTo(_chebyshevDistance(deathSquare, b.square));
        if (distance != 0) return distance;
        final squareOrder = (a.square.rank * _fileCount + a.square.file)
            .compareTo(b.square.rank * _fileCount + b.square.file);
        return squareOrder != 0
            ? squareOrder
            : a.piece.pieceId.compareTo(b.piece.pieceId);
      });
      if (candidates.isNotEmpty) {
        final heir = candidates.first;
        _replacePieceAt(
          heir.square,
          heir.index,
          heir.piece.copyWith(
            abilities: {...heir.piece.abilities, ...piece.abilities},
          ),
        );
      }
    } finally {
      _resolvingInheritance.remove(piece.pieceId);
    }
  }

  void _spawnQueenEscapePiece(Piece capturedPiece) {
    final enemyKing = findKing(capturedPiece.opponent);
    final spawnTypes = [PieceType.rook, PieceType.bishop]..shuffle(_random);

    for (final type in spawnTypes) {
      final spawn = Piece(
        type: type,
        color: capturedPiece.color,
        hasMoved: true,
      );
      final candidates = <Square>[];

      for (var rank = 0; rank < _rankCount; rank++) {
        for (var file = 0; file < _fileCount; file++) {
          final square = Square(file, rank);
          if (piecesAt(square).isNotEmpty) continue;
          if (isBlocked(square)) continue;
          if (_mines.contains(square)) continue;
          if (!_isLandingAllowed(square, forPiece: spawn)) continue;

          if (enemyKing != null) {
            _setPrimary(square, spawn);
            final givesCheck = isSquareAttacked(enemyKing, capturedPiece.color);
            _setPrimary(square, null);
            if (givesCheck) continue;
          }

          candidates.add(square);
        }
      }

      if (candidates.isEmpty) continue;
      final target = candidates[_random.nextInt(candidates.length)];
      _setPrimary(target, spawn);
      return;
    }
  }

  void _applyLottery(PieceColor color) {
    final candidates = <(Square, int, Piece)>[];
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        final pieces = piecesAt(square);
        for (var index = 0; index < pieces.length; index++) {
          final piece = pieces[index];
          if (piece.color != color || piece.type == PieceType.king) continue;
          candidates.add((square, index, piece));
        }
      }
    }

    if (candidates.length < 2) return;
    candidates.shuffle(_random);
    final first = candidates[0];
    final second = candidates[1];
    _replacePieceAt(
      first.$1,
      first.$2,
      first.$3.copyWith(type: second.$3.type),
    );
    _replacePieceAt(
      second.$1,
      second.$2,
      second.$3.copyWith(type: first.$3.type),
    );
  }

  bool _isCapture(Move move) {
    if (move.isInquisitorStrip) return false;
    if (move.isEnPassant) return true;
    if (move.isKnightRearSwap) return false;
    if (move.isCastleSwap) return false;
    if (move.isCastle) return false;

    final mover = pieceAt(move.from, index: move.pieceIndex);
    if (mover == null) return false;
    final acting = _actingColor(mover);

    final destinationPieces = piecesAt(move.to);
    if (_fourHorsemenActive &&
        mover.type == PieceType.knight &&
        !mover.horsemenCaptureUsed &&
        destinationPieces.any((piece) => piece.color != acting)) {
      return false;
    }

    return destinationPieces.any((piece) => piece.color != acting);
  }

  void _finishGame({
    required PieceColor? winner,
    required GameEndReason reason,
    GameStatus status = GameStatus.checkmate,
    String? detail,
  }) {
    if (isGameOver) return;
    _undoSnapshot = null;
    _winnerColor = winner;
    _endReason = reason;
    _endDetail = detail;
    _status = status;
    _pendingSkillSquare = null;
    _pendingSkillPieceId = null;
    _pendingSkillColor = null;
    _pendingCaptureOffers = const [];
    _pendingAuctionSquare = null;
    _pendingAuctionColor = null;
    _pendingBonusSkillColor = null;
    _skillChoiceIsBonus = false;
    _pendingGoldenThroneColor = null;
    _awaitingGallopFrom = null;
    _awaitingGallopIndex = 0;
    _clearPendingTarget();
    _pendingReactionMove = null;
    _pendingRansomPawnId = null;
    _queuedSkillPieceId = null;
    _queuedSkillColor = null;
  }

  void _updateStatus() {
    if (isGameOver) return;

    final whiteKingAlive = findKing(PieceColor.white) != null;
    final blackKingAlive = findKing(PieceColor.black) != null;
    if (!whiteKingAlive || !blackKingAlive) {
      final winner = whiteKingAlive == blackKingAlive
          ? null
          : (whiteKingAlive ? PieceColor.white : PieceColor.black);
      _finishGame(
        winner: winner,
        reason: GameEndReason.kingDestroyed,
        status: winner == null ? GameStatus.stalemate : GameStatus.checkmate,
      );
      return;
    }

    if (enginePhase != GameEnginePhase.play) return;

    final legalMoves = getLegalMoves();
    final actualCheck = isInCheck(_turn);
    final inCheck = _truceActive ? false : actualCheck;

    if (legalMoves.isEmpty) {
      // Dark chess: no checkmate — only king capture wins; no moves → draw.
      if (_fogOfWar) {
        _finishGame(
          winner: null,
          reason: GameEndReason.stalemate,
          status: GameStatus.stalemate,
        );
      } else if (_rules.busActive && !inCheck) {
        final whiteN = _countArmy(PieceColor.white);
        final blackN = _countArmy(PieceColor.black);
        PieceColor? winner;
        if (whiteN < blackN) {
          winner = PieceColor.white;
        } else if (blackN < whiteN) {
          winner = PieceColor.black;
        }
        _finishGame(
          winner: winner,
          reason: winner == null
              ? GameEndReason.stalemate
              : GameEndReason.alternativeVictory,
          status: winner == null ? GameStatus.stalemate : GameStatus.checkmate,
          detail: winner == null ? null : 'busArmy',
        );
      } else if (inCheck) {
        if (_tryRevealTurncoatToAvoidMate(_turn)) {
          _updateStatus();
          return;
        }
        final kingSquare = findKing(_turn);
        final king = kingSquare == null ? null : pieceAt(kingSquare);
        if (king != null &&
            king.hasEffect(AbilityEffect.kingShield) &&
            !king.kingShieldUsed &&
            _tryKingShield(_turn)) {
          _updateStatus();
          return;
        }

        if (king != null &&
            king.hasEffect(AbilityEffect.kingAura) &&
            _isOnlyCheckedByPawns(_turn)) {
          _finishGame(
            winner: null,
            reason: GameEndReason.stalemate,
            status: GameStatus.stalemate,
          );
        } else if (_mateVetoBlocksMate(_turn)) {
          _status = GameStatus.playing;
        } else {
          _finishGame(winner: _turn.opponent, reason: GameEndReason.checkmate);
        }
      } else {
        _finishGame(
          winner: null,
          reason: GameEndReason.stalemate,
          status: GameStatus.stalemate,
        );
      }
    } else if (!_fogOfWar && _wouldBeMatedCountingTurncoatSpies(_turn)) {
      // Mate only holds because an unrevealed spy "attacks" — reveal and redo.
      if (_tryRevealTurncoatToAvoidMate(_turn)) {
        _updateStatus();
        return;
      }
      _status = inCheck ? GameStatus.check : GameStatus.playing;
    } else if (!_fogOfWar && inCheck) {
      _status = GameStatus.check;
    } else {
      _status = GameStatus.playing;
    }
  }

  bool _wouldBeMatedCountingTurncoatSpies(PieceColor color) {
    if (!_rules.turncoatsActive || _truceActive) return false;
    final spyId = _rules.turncoatSpyIds[color.opponent];
    if (spyId == null || _rules.revealedTurncoats.contains(spyId)) {
      return false;
    }
    final savedTurn = _turn;
    _turn = color;
    _rules.revealedTurncoats.add(spyId);
    try {
      final inCheck = isInCheck(color, includeTurncoatSpies: true);
      if (!inCheck) return false;
      return getLegalMoves().isEmpty;
    } finally {
      _rules.revealedTurncoats.remove(spyId);
      _turn = savedTurn;
    }
  }

  bool _tryRevealTurncoatToAvoidMate(PieceColor matedColor) {
    if (!_rules.turncoatsActive) return false;
    final matingColor = matedColor.opponent;
    final spyId = _rules.turncoatSpyIds[matingColor];
    if (spyId == null || _rules.revealedTurncoats.contains(spyId)) {
      return false;
    }
    final ref = _pieceById(spyId);
    if (ref == null) return false;

    final snapshot = createSnapshot();
    _rules.revealedTurncoats.add(spyId);
    _replacePieceAt(
      ref.square,
      ref.index,
      ref.piece.copyWith(color: matedColor),
    );
    final savedTurn = _turn;
    _turn = matedColor;
    final stillMated =
        isInCheck(matedColor) && getLegalMoves().isEmpty;
    _turn = savedTurn;
    if (stillMated) {
      restoreSnapshot(snapshot);
      return false;
    }
    return true;
  }

  bool _isOnlyCheckedByPawns(PieceColor color) {
    final kingSquare = findKing(color);
    if (kingSquare == null) return false;

    var sawAttack = false;
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final from = Square(file, rank);
        for (final piece in piecesAt(from)) {
          if (piece.color != color.opponent) continue;
          if (_zebrasActive && piece.type == PieceType.knight) continue;
          if (!_canAttack(from, kingSquare, piece)) continue;
          sawAttack = true;
          if (piece.type != PieceType.pawn) return false;
        }
      }
    }

    return sawAttack;
  }

  bool _tryKingShield(PieceColor color) {
    final kingSquare = findKing(color);
    if (kingSquare == null) return false;
    final king = pieceAt(kingSquare);
    if (king == null ||
        !king.hasEffect(AbilityEffect.kingShield) ||
        king.kingShieldUsed) {
      return false;
    }

    final candidates = <Square>[];
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        if (piecesAt(square).isNotEmpty) continue;
        if (isBlocked(square)) continue;
        if (isSquareAttacked(square, color.opponent)) continue;
        candidates.add(square);
      }
    }

    if (candidates.isEmpty) return false;
    final target = candidates[_random.nextInt(candidates.length)];
    _clearSquare(kingSquare);
    _setPrimary(target, king.copyWith(hasMoved: true, kingShieldUsed: true));
    return true;
  }

  bool _isLegalMove(Move move) {
    final mover = pieceAt(move.from, index: move.pieceIndex);
    if (mover == null) return false;
    final acting = _actingColor(mover);
    if (_isCapture(move)) {
      final victim = _captureVictim(move, acting);
      if (victim != null && !_captureAllowed(mover.copyWith(color: acting), victim.piece)) {
        return false;
      }
    }
    if (!_isLandingAllowed(move.to, forPiece: mover.copyWith(color: acting))) {
      return false;
    }
    if (_rules.duckSquare != null && move.to == _rules.duckSquare) {
      return false;
    }
    if (_rules.forbiddenFile != null &&
        move.to.file == _rules.forbiddenFile &&
        mover.type != PieceType.king) {
      return false;
    }
    if (_rules.centerTaxSkipNext.contains(mover.pieceId)) return false;
    if ((_rules.wastelandTollSkip[mover.pieceId] ?? 0) > 0) return false;
    // Time zone: off-hour → only 1-square steps.
    if (_rules.timeZoneActive) {
      final oddHour = _rules.timeZoneOddHour[acting];
      if (oddHour != null) {
        final plyOdd = (_rules.globalPlyIndex + 1).isOdd;
        final myHour = oddHour == plyOdd;
        if (!myHour) {
          final df = (move.to.file - move.from.file).abs();
          final dr = (move.to.rank - move.from.rank).abs();
          if (df > 1 || dr > 1 || (df == 0 && dr == 0)) return false;
        }
      }
    }
    // Lone warrior: need 2 attackers to capture.
    if (_rules.loneWarriorPieceId != null && _isCapture(move)) {
      final victim = _captureVictim(move, acting);
      if (victim != null &&
          victim.piece.pieceId == _rules.loneWarriorPieceId) {
        final alliesNearby = _countAlliesNear(victim.square, victim.piece.color);
        if (alliesNearby == 0) {
          final attackers = _countAttackersOf(victim.square, acting);
          if (attackers < 2) return false;
        }
      }
    }
    if (!_curfewAllowsMove(mover, move.from, move.to)) return false;
    if (_truceActive && _isCapture(move)) return false;
    if (move.isKnightRearSwap && !_isLandingAllowed(move.from)) return false;
    if (move.isCastleSwap && !_isLandingAllowed(move.from)) return false;
    if (move.isCastle) {
      final castle = _normalizeCastleMove(move);
      final rookTarget = castle.to.file == 6
          ? Square(5, castle.from.rank)
          : Square(3, castle.from.rank);
      if (!_isLandingAllowed(rookTarget)) return false;
    }

    final snapshot = createSnapshot();
    _turn = acting;
    _suppressCaptureSideEffects = true;
    _isSimulatingLegality = true;
    late final bool legal;
    try {
      _applyMove(_normalizeCastleMove(move));
      _tickLava(acting, recordDeaths: false);
      final kingAlive = findKing(acting) != null;
      // Dark chess (fog): king may walk into check; win is by capturing king.
      legal = kingAlive && (_fogOfWar || !isInCheck(acting));
    } finally {
      _suppressCaptureSideEffects = false;
      _isSimulatingLegality = false;
      restoreSnapshot(snapshot);
    }
    return legal;
  }

  List<Move> _getPseudoLegalMoves(
    Square from,
    Piece piece, {
    required int pieceIndex,
  }) {
    piece = _effectivePiece(piece);
    switch (piece.type) {
      case PieceType.pawn:
        return _pawnMoves(from, piece, pieceIndex: pieceIndex);
      case PieceType.knight:
        return _knightMoves(from, piece, pieceIndex: pieceIndex);
      case PieceType.bishop:
        var moves = _slidingMoves(
          from,
          piece,
          const [(-1, -1), (-1, 1), (1, -1), (1, 1)],
          hopAlly: piece.hasEffect(AbilityEffect.hopOverAlly),
          pieceIndex: pieceIndex,
        );
        final schism = _rules.schismDiagSign[piece.pieceId];
        if (schism != null) {
          moves = moves
              .where((m) {
                final df = m.to.file - from.file;
                final dr = m.to.rank - from.rank;
                // sign of df*dr matches schism (+1 or -1)
                if (df == 0 || dr == 0) return false;
                return (df.sign * dr.sign) == schism;
              })
              .toList();
        }
        if (piece.hasEffect(AbilityEffect.colorVow)) {
          moves.addAll(
            _bishopRicochetMoves(from, piece, pieceIndex: pieceIndex),
          );
        }
        if (piece.hasEffect(AbilityEffect.inquisitor)) {
          moves.addAll(
            _inquisitorStripMoves(from, piece, pieceIndex: pieceIndex),
          );
        }
        if (piece.hasEffect(AbilityEffect.bishopColorChaos) &&
            !piece.colorChaosUsed) {
          for (var df = -1; df <= 1; df++) {
            for (var dr = -1; dr <= 1; dr++) {
              if (df == 0 && dr == 0) continue;
              final to = _offsetSquare(from, df, dr);
              if (to == null ||
                  pieceAt(to) != null ||
                  isBlocked(to) ||
                  !_isLandingAllowed(to, forPiece: piece)) {
                continue;
              }
              moves.add(
                Move(
                  from: from,
                  to: to,
                  isColorChaos: true,
                  pieceIndex: pieceIndex,
                ),
              );
            }
          }
        }
        return moves;
      case PieceType.rook:
        return _slidingMoves(
          from,
          piece,
          const [(0, -1), (0, 1), (-1, 0), (1, 0)],
          hopAlly: piece.hasEffect(AbilityEffect.hopOverAlly),
          allowRookPush: piece.hasEffect(AbilityEffect.rookRam),
          pieceIndex: pieceIndex,
        );
      case PieceType.queen:
        return _queenMoves(from, piece, pieceIndex: pieceIndex);
      case PieceType.king:
        if (piece.moveAsType != null && piece.moveAsType != PieceType.king) {
          return _getPseudoLegalMoves(
            from,
            piece.copyWith(type: piece.moveAsType!, clearMoveAsType: true),
            pieceIndex: pieceIndex,
          );
        }
        return _kingMoves(from, piece, pieceIndex: pieceIndex);
    }
  }

  List<Move> _pawnMoves(Square from, Piece piece, {required int pieceIndex}) {
    if (piece.hasEffect(AbilityEffect.invertedPawnMovement)) {
      return _invertedPawnMoves(from, piece, pieceIndex: pieceIndex);
    }

    final moves = _standardPawnMoves(from, piece, pieceIndex: pieceIndex);
    if (piece.hasEffect(AbilityEffect.sidewaysPawnMovement)) {
      moves.addAll(_sidewaysPawnMoves(from, piece, pieceIndex: pieceIndex));
    }
    return moves;
  }

  List<Move> _standardPawnMoves(
    Square from,
    Piece piece, {
    required int pieceIndex,
  }) {
    final moves = <Move>[];
    final direction = piece.color == PieceColor.white ? 1 : -1;
    final startRank = _pawnStartRank(piece.color);
    final promotionRank = _pawnPromotionRank(piece.color);
    final noDouble = piece.hasEffect(AbilityEffect.pawnNoDoubleStep);
    final pawnRam = piece.hasEffect(AbilityEffect.pawnRam);
    final airborne =
        piece.hasEffect(AbilityEffect.pawnAirborne) && !piece.airborneUsed;

    if (piece.hasEffect(AbilityEffect.pawnFarsight)) {
      final mid = Square(from.file, from.rank + direction);
      final twoForward = Square(from.file, from.rank + 2 * direction);
      final midClear = isOnBoard(mid) &&
          pieceAt(mid) == null &&
          !isBlocked(mid);
      if (midClear &&
          isOnBoard(twoForward) &&
          pieceAt(twoForward) == null &&
          !isBlocked(twoForward) &&
          _isLandingAllowed(twoForward)) {
        if (twoForward.rank == promotionRank) {
          moves.addAll(
            _promotionMoves(from, twoForward, pieceIndex: pieceIndex),
          );
        } else {
          moves.add(Move(from: from, to: twoForward, pieceIndex: pieceIndex));
        }
      }
      if (!pawnRam) {
        for (final fileDelta in [-1, 1]) {
          final midCap = _offsetSquare(from, fileDelta, direction);
          final cap = _offsetSquare(from, fileDelta, 2 * direction);
          if (midCap == null ||
              cap == null ||
              pieceAt(midCap) != null ||
              isBlocked(midCap) ||
              isBlocked(cap) ||
              !_isLandingAllowed(cap)) {
            continue;
          }
          final target = pieceAt(cap);
          if (!_truceActive &&
              target != null &&
              target.color != piece.color &&
              !_isRearingKnight(target)) {
            if (cap.rank == promotionRank) {
              moves.addAll(
                _promotionMoves(from, cap, pieceIndex: pieceIndex),
              );
            } else {
              moves.add(Move(from: from, to: cap, pieceIndex: pieceIndex));
            }
          }
        }
      }
      return moves;
    }

    final oneForward = Square(from.file, from.rank + direction);
    final oneForwardTarget = isOnBoard(oneForward) ? pieceAt(oneForward) : null;
    final pathClearOne =
        isOnBoard(oneForward) &&
        oneForwardTarget == null &&
        !isBlocked(oneForward);

    if (pathClearOne && _isLandingAllowed(oneForward)) {
      if (oneForward.rank == promotionRank) {
        moves.addAll(_promotionMoves(from, oneForward, pieceIndex: pieceIndex));
      } else {
        moves.add(Move(from: from, to: oneForward, pieceIndex: pieceIndex));
      }
    }

    // Длинные шаги: промежуточные клетки должны быть свободны,
    // но ограничение цвета («день»/«ночь») касается только клетки прибытия.
    if (pathClearOne && oneForward.rank != promotionRank) {
      if (!noDouble && from.rank == startRank) {
        final twoForward = Square(from.file, from.rank + 2 * direction);
        if (isOnBoard(twoForward) &&
            pieceAt(twoForward) == null &&
            !isBlocked(twoForward) &&
            _isLandingAllowed(twoForward)) {
          _addPawnMove(moves, from, twoForward, piece, pieceIndex: pieceIndex);
        }
      } else if (!noDouble &&
          piece.hasEffect(AbilityEffect.pawnAlwaysDoubleStep)) {
        final twoForward = Square(from.file, from.rank + 2 * direction);
        if (isOnBoard(twoForward) &&
            pieceAt(twoForward) == null &&
            !isBlocked(twoForward) &&
            _isLandingAllowed(twoForward)) {
          _addPawnMove(moves, from, twoForward, piece, pieceIndex: pieceIndex);
        }
      }

      if (piece.hasEffect(AbilityEffect.pawnTripleStepOnce) &&
          !piece.tripleStepUsed &&
          from.rank == startRank) {
        final twoForward = Square(from.file, from.rank + 2 * direction);
        final threeForward = Square(from.file, from.rank + 3 * direction);
        if (isOnBoard(twoForward) &&
            pieceAt(twoForward) == null &&
            !isBlocked(twoForward) &&
            isOnBoard(threeForward) &&
            pieceAt(threeForward) == null &&
            !isBlocked(threeForward) &&
            _isLandingAllowed(threeForward)) {
          _addPawnMove(
            moves,
            from,
            threeForward,
            piece,
            pieceIndex: pieceIndex,
          );
        }
      }
    }

    if (airborne && oneForwardTarget != null) {
      final jumpTarget = Square(from.file, from.rank + 2 * direction);
      if (isOnBoard(jumpTarget) &&
          pieceAt(jumpTarget) == null &&
          !isBlocked(jumpTarget) &&
          _isLandingAllowed(jumpTarget)) {
        _addPawnMove(
          moves,
          from,
          jumpTarget,
          piece,
          pieceIndex: pieceIndex,
          isAirborne: true,
        );
      }
    }

    if (piece.hasEffect(AbilityEffect.pawnBackwardMovement)) {
      final oneBackward = Square(from.file, from.rank - direction);
      if (isOnBoard(oneBackward) &&
          pieceAt(oneBackward) == null &&
          !isBlocked(oneBackward) &&
          _isLandingAllowed(oneBackward)) {
        _addPawnMove(moves, from, oneBackward, piece, pieceIndex: pieceIndex);
      }
    }

    if (!pawnRam) {
      for (final fileDelta in [-1, 1]) {
        final captureSquare = _offsetSquare(from, fileDelta, direction);
        if (captureSquare == null ||
            isBlocked(captureSquare) ||
            !_isLandingAllowed(captureSquare)) {
          continue;
        }

        final target = pieceAt(captureSquare);
        if (!_truceActive && target != null && target.color != piece.color) {
          if (_isRearingKnight(target)) {
            moves.add(
              Move(
                from: from,
                to: captureSquare,
                isKnightRearSwap: true,
                pieceIndex: pieceIndex,
              ),
            );
          } else if (captureSquare.rank == promotionRank) {
            moves.addAll(
              _promotionMoves(from, captureSquare, pieceIndex: pieceIndex),
            );
          } else {
            moves.add(
              Move(from: from, to: captureSquare, pieceIndex: pieceIndex),
            );
          }
        }

        if (!_truceActive && _enPassantTarget == captureSquare) {
          moves.add(
            Move(
              from: from,
              to: captureSquare,
              isEnPassant: true,
              pieceIndex: pieceIndex,
            ),
          );
        }
      }
    } else {
      final captureSquare = Square(from.file, from.rank + direction);
      if (isOnBoard(captureSquare) &&
          !isBlocked(captureSquare) &&
          _isLandingAllowed(captureSquare)) {
        final target = pieceAt(captureSquare);
        if (!_truceActive && target != null && target.color != piece.color) {
          if (_isRearingKnight(target)) {
            moves.add(
              Move(
                from: from,
                to: captureSquare,
                isKnightRearSwap: true,
                pieceIndex: pieceIndex,
              ),
            );
          } else if (captureSquare.rank == promotionRank) {
            moves.addAll(
              _promotionMoves(from, captureSquare, pieceIndex: pieceIndex),
            );
          } else {
            moves.add(
              Move(from: from, to: captureSquare, pieceIndex: pieceIndex),
            );
          }
        }
      }
    }

    return moves;
  }

  List<Move> _invertedPawnMoves(
    Square from,
    Piece piece, {
    required int pieceIndex,
  }) {
    final moves = <Move>[];
    final direction = piece.color == PieceColor.white ? 1 : -1;
    final promotionRank = _pawnPromotionRank(piece.color);

    for (final fileDelta in [-1, 1]) {
      final moveSquare = _offsetSquare(from, fileDelta, direction);
      if (moveSquare == null ||
          pieceAt(moveSquare) != null ||
          isBlocked(moveSquare) ||
          !_isLandingAllowed(moveSquare)) {
        continue;
      }

      if (moveSquare.rank == promotionRank) {
        moves.addAll(_promotionMoves(from, moveSquare, pieceIndex: pieceIndex));
      } else {
        moves.add(Move(from: from, to: moveSquare, pieceIndex: pieceIndex));
      }
    }

    final captureSquare = Square(from.file, from.rank + direction);
    if (isOnBoard(captureSquare) &&
        !isBlocked(captureSquare) &&
        _isLandingAllowed(captureSquare)) {
      final target = pieceAt(captureSquare);
      if (!_truceActive && target != null && target.color != piece.color) {
        if (_isRearingKnight(target)) {
          moves.add(
            Move(
              from: from,
              to: captureSquare,
              isKnightRearSwap: true,
              pieceIndex: pieceIndex,
            ),
          );
        } else if (captureSquare.rank == promotionRank) {
          moves.addAll(
            _promotionMoves(from, captureSquare, pieceIndex: pieceIndex),
          );
        } else {
          moves.add(
            Move(from: from, to: captureSquare, pieceIndex: pieceIndex),
          );
        }
      }
    }

    if (piece.hasEffect(AbilityEffect.sidewaysPawnMovement)) {
      moves.addAll(_sidewaysPawnMoves(from, piece, pieceIndex: pieceIndex));
    }

    return moves;
  }

  List<Move> _sidewaysPawnMoves(
    Square from,
    Piece piece, {
    required int pieceIndex,
  }) {
    final moves = <Move>[];
    for (final fileDelta in [-1, 1]) {
      final sideways = _offsetSquare(from, fileDelta, 0);
      if (sideways == null ||
          pieceAt(sideways) != null ||
          isBlocked(sideways) ||
          !_isLandingAllowed(sideways)) {
        continue;
      }
      moves.add(Move(from: from, to: sideways, pieceIndex: pieceIndex));
    }
    return moves;
  }

  void _addPawnMove(
    List<Move> moves,
    Square from,
    Square to,
    Piece piece, {
    required int pieceIndex,
    bool isAirborne = false,
    bool isEnPassant = false,
    bool isKnightRearSwap = false,
  }) {
    if (to.rank == _pawnPromotionRank(piece.color) && !isKnightRearSwap) {
      for (final type in const [
        PieceType.queen,
        PieceType.rook,
        PieceType.bishop,
        PieceType.knight,
      ]) {
        moves.add(
          Move(
            from: from,
            to: to,
            promotion: type,
            pieceIndex: pieceIndex,
            isAirborne: isAirborne,
            isEnPassant: isEnPassant,
          ),
        );
      }
      return;
    }
    moves.add(
      Move(
        from: from,
        to: to,
        pieceIndex: pieceIndex,
        isAirborne: isAirborne,
        isEnPassant: isEnPassant,
        isKnightRearSwap: isKnightRearSwap,
      ),
    );
  }

  List<Move> _promotionMoves(
    Square from,
    Square to, {
    required int pieceIndex,
    bool isAirborne = false,
  }) {
    var types = const [
      PieceType.queen,
      PieceType.rook,
      PieceType.bishop,
      PieceType.knight,
    ];
    final mover = pieceAt(from, index: pieceIndex);
    if (mover != null &&
        _rules.hereditaryEdictOwner == mover.color.opponent) {
      final owned = <PieceType>{};
      for (var r = 0; r < _rankCount; r++) {
        for (var f = 0; f < _fileCount; f++) {
          for (final p in piecesAt(Square(f, r))) {
            if (p.color == mover.color && p.type != PieceType.pawn) {
              owned.add(p.type);
            }
          }
        }
      }
      final missing = types.where((t) => !owned.contains(t)).toList();
      if (missing.isNotEmpty) types = missing;
    }
    return [
      for (final type in types)
        Move(
          from: from,
          to: to,
          promotion: type,
          pieceIndex: pieceIndex,
          isAirborne: isAirborne,
        ),
    ];
  }

  List<Move> _knightJumpMoves(
    Square from,
    Piece piece, {
    required int pieceIndex,
  }) {
    final deltas = _hasEffect(piece, AbilityEffect.fifthLeg)
        ? const [
            (2, 2),
            (2, -2),
            (-2, -2),
            (-2, 2),
          ]
        : piece.hasEffect(AbilityEffect.knightLongJump)
        ? const [
            (1, 3),
            (3, 1),
            (3, -1),
            (1, -3),
            (-1, -3),
            (-3, -1),
            (-3, 1),
            (-1, 3),
          ]
        : const [
            (1, 2),
            (2, 1),
            (2, -1),
            (1, -2),
            (-1, -2),
            (-2, -1),
            (-2, 1),
            (-1, 2),
          ];

    final moves = <Move>[];
    for (final (df, dr) in deltas) {
      final to = _offsetSquare(from, df, dr);
      if (to == null) continue;
      _addMoveToSquare(moves, from, to, piece, pieceIndex: pieceIndex);
    }
    return moves;
  }

  List<Move> _knightMoves(Square from, Piece piece, {required int pieceIndex}) {
    final moves = _knightJumpMoves(from, piece, pieceIndex: pieceIndex);

    if (piece.hasEffect(AbilityEffect.centaur)) {
      for (var df = -1; df <= 1; df++) {
        for (var dr = -1; dr <= 1; dr++) {
          if (df == 0 && dr == 0) continue;
          final to = _offsetSquare(from, df, dr);
          if (to == null) continue;
          _addMoveToSquare(moves, from, to, piece, pieceIndex: pieceIndex);
        }
      }
    }

    return moves;
  }

  List<Move> _queenMoves(Square from, Piece piece, {required int pieceIndex}) {
    final moves = _slidingMoves(
      from,
      piece,
      const [
        (0, -1),
        (0, 1),
        (-1, 0),
        (1, 0),
        (-1, -1),
        (-1, 1),
        (1, -1),
        (1, 1),
      ],
      hopAlly: piece.hasEffect(AbilityEffect.hopOverAlly),
      allowRookPush: false,
      pieceIndex: pieceIndex,
    );

    if (piece.hasEffect(AbilityEffect.queenKnightStep)) {
      const knightDeltas = [
        (1, 2),
        (2, 1),
        (2, -1),
        (1, -2),
        (-1, -2),
        (-2, -1),
        (-2, 1),
        (-1, 2),
      ];
      for (final (df, dr) in knightDeltas) {
        final to = _offsetSquare(from, df, dr);
        if (to == null) continue;
        _addMoveToSquare(moves, from, to, piece, pieceIndex: pieceIndex);
      }
    }

    if (piece.hasEffect(AbilityEffect.queenShadowEmpress)) {
      const knightDeltas = [
        (1, 2),
        (2, 1),
        (2, -1),
        (1, -2),
        (-1, -2),
        (-2, -1),
        (-2, 1),
        (-1, 2),
      ];
      for (final (df, dr) in knightDeltas) {
        final to = _offsetSquare(from, df, dr);
        if (to == null) continue;
        _addMoveToSquare(moves, from, to, piece, pieceIndex: pieceIndex);
      }
    }

    return moves;
  }

  List<Move> _slidingMoves(
    Square from,
    Piece piece,
    List<(int, int)> directions, {
    bool hopAlly = false,
    bool allowRookPush = false,
    required int pieceIndex,
  }) {
    final moves = <Move>[];

    for (final (df, dr) in directions) {
      var file = from.file;
      var rank = from.rank;
      var hoppedAlly = false;
      var hoppedEnemy = false;
      var steps = 0;
      final wrapFiles =
          _mirrorActive || _hasEffect(piece, AbilityEffect.ferry);

      while (true) {
        if (wrapFiles && df != 0 && steps >= _fileCount - 1) break;
        steps++;
        rank += dr;
        if (rank < 0 || rank >= _rankCount) break;
        file = wrapFiles && df != 0 ? _wrapFile(file + df) : file + df;
        if (!wrapFiles && (file < 0 || file >= _fileCount)) break;

        final to = Square(file, rank);
        if (_rules.hasWallBetween(
          Square(
            wrapFiles && df != 0 ? _wrapFile(file - df) : file - df,
            rank - dr,
          ),
          to,
        )) {
          break;
        }
        if (isBlocked(to)) break;

        final target = pieceAt(to);

        if (target == null) {
          if (_rangedQuietStepAllowed(piece, steps) &&
              _isLandingAllowed(to, forPiece: piece)) {
            moves.add(Move(from: from, to: to, pieceIndex: pieceIndex));
          }
          if (_rules.myopiaTurnsLeft > 0 && steps >= 2) break;
          if (hoppedEnemy) break;
        } else if (_isRearingKnight(target)) {
          if (!_truceActive && _isLandingAllowed(to, forPiece: piece)) {
            moves.add(
              Move(
                from: from,
                to: to,
                isKnightRearSwap: true,
                pieceIndex: pieceIndex,
              ),
            );
          }
          break;
        } else if (target.color != piece.color) {
          if (_hasEffect(piece, AbilityEffect.glassCeiling) &&
              !hoppedAlly &&
              !hoppedEnemy) {
            hoppedEnemy = true;
            continue;
          }
          if (!_truceActive &&
              !piece.hasEffect(AbilityEffect.queenMatka) &&
              _rangedCaptureStepAllowed(piece, steps) &&
              _captureAllowed(piece, target) &&
              _isLandingAllowed(to, forPiece: piece)) {
            moves.add(Move(from: from, to: to, pieceIndex: pieceIndex));
          }
          break;
        } else if ((hopAlly ||
                (target.type == PieceType.rook &&
                    _hasEffect(target, AbilityEffect.rookDrawbridge))) &&
            !hoppedAlly &&
            target.color == piece.color) {
          hoppedAlly = true;
          continue;
        } else if (allowRookPush &&
            piece.type == PieceType.rook &&
            target.color == piece.color) {
          final beyond = _offsetSquare(to, df, dr);
          if (_isLandingAllowed(to, forPiece: piece) &&
              beyond != null &&
              piecesAt(beyond).isEmpty &&
              !isBlocked(beyond) &&
              _isLandingAllowed(beyond, forPiece: piece)) {
            moves.add(
              Move(
                from: from,
                to: to,
                isRookPush: true,
                pieceIndex: pieceIndex,
              ),
            );
          }
          break;
        } else {
          break;
        }
      }
    }

    return moves;
  }

  List<Move> _kingMoves(Square from, Piece piece, {required int pieceIndex}) {
    if (piece.moveAsType != null && piece.moveAsType != PieceType.king) {
      return _getPseudoLegalMoves(
        from,
        piece.copyWith(type: piece.moveAsType!, clearMoveAsType: true),
        pieceIndex: pieceIndex,
      );
    }
    final moves = <Move>[];
    final maxStep = piece.hasEffect(AbilityEffect.kingExtraStep) ? 2 : 1;

    for (var df = -2; df <= 2; df++) {
      for (var dr = -2; dr <= 2; dr++) {
        if (df == 0 && dr == 0) continue;

        final distance = df.abs() > dr.abs() ? df.abs() : dr.abs();
        if (distance > maxStep) continue;

        final to = _offsetSquare(from, df, dr);
        if (to == null) continue;

        if (distance == 2) {
          // Ray-aligned 2-step: path through the mid square must be clear.
          // (2,1)-style leaps have no single mid cell — treat as a jump.
          final isRay = df == 0 || dr == 0 || df.abs() == dr.abs();
          if (isRay) {
            final mid = _offsetSquare(
              from,
              df == 0 ? 0 : df.sign,
              dr == 0 ? 0 : dr.sign,
            );
            if (mid == null) continue;
            final midPiece = pieceAt(mid);
            if (midPiece != null && !_isRearingKnight(midPiece)) continue;
          }
        }

        _addMoveToSquare(moves, from, to, piece, pieceIndex: pieceIndex);
      }
    }

    // Буцефал: one knight-jump for the king per game after 3 captures.
    final kingColor = piece.color;
    final bucephalReady = _rules.bucephalusCaptures.values.any((n) => n >= 3) &&
        !_rules.bucephalusKingJumpUsed.contains(kingColor.name);
    if (bucephalReady) {
      moves.addAll(_knightJumpMoves(from, piece, pieceIndex: pieceIndex));
    }

    if (piece.hasEffect(AbilityEffect.kingRookSwap)) {
      if (_fogOfWar || !isInCheck(piece.color)) {
        moves.addAll(_swapCastlingMoves(from, piece, pieceIndex: pieceIndex));
      }
    } else if (!piece.hasMoved && (_fogOfWar || !isInCheck(piece.color))) {
      moves.addAll(_castlingMoves(from, piece, pieceIndex: pieceIndex));
    }

    return moves;
  }

  List<Move> _swapCastlingMoves(
    Square from,
    Piece piece, {
    required int pieceIndex,
  }) {
    if (piece.royalDecreeUsed) return const [];

    final moves = <Move>[];
    final rank = from.rank;

    for (var file = 0; file < _fileCount; file++) {
      if (file == from.file) continue;

      final rookSquare = Square(file, rank);
      final rook = pieceAt(rookSquare);
      if (rook?.type != PieceType.rook || rook!.color != piece.color) continue;
      if (isSquareAttacked(rookSquare, piece.opponent)) continue;

      moves.add(
        Move(
          from: from,
          to: rookSquare,
          isCastleSwap: true,
          pieceIndex: pieceIndex,
        ),
      );
    }

    return moves;
  }

  /// King→rook click uses the rook square as [Move.to]; canonicalize to the
  /// king's landing square (g/c-file) before applying.
  Move _normalizeCastleMove(Move move) {
    if (!move.isCastle) return move;
    final rank = move.from.rank;
    if (move.to.file == 7) {
      return Move(
        from: move.from,
        to: Square(6, rank),
        isCastle: true,
        pieceIndex: move.pieceIndex,
      );
    }
    if (move.to.file == 0) {
      return Move(
        from: move.from,
        to: Square(2, rank),
        isCastle: true,
        pieceIndex: move.pieceIndex,
      );
    }
    return move;
  }

  List<Move> _castlingMoves(
    Square from,
    Piece piece, {
    required int pieceIndex,
  }) {
    final moves = <Move>[];
    final rank = from.rank;

    final kingsideRook = pieceAt(Square(7, rank));
    if (kingsideRook?.type == PieceType.rook &&
        kingsideRook!.color == piece.color &&
        !kingsideRook.hasMoved &&
        pieceAt(Square(5, rank)) == null &&
        pieceAt(Square(6, rank)) == null &&
        !isSquareAttacked(Square(4, rank), piece.opponent) &&
        !isSquareAttacked(Square(5, rank), piece.opponent) &&
        !isSquareAttacked(Square(6, rank), piece.opponent)) {
      moves.add(
        Move(
          from: from,
          to: Square(6, rank),
          isCastle: true,
          pieceIndex: pieceIndex,
        ),
      );
      // Also allow selecting the rook square (king → rook click).
      moves.add(
        Move(
          from: from,
          to: Square(7, rank),
          isCastle: true,
          pieceIndex: pieceIndex,
        ),
      );
    }

    final queensideRook = pieceAt(Square(0, rank));
    if (queensideRook?.type == PieceType.rook &&
        queensideRook!.color == piece.color &&
        !queensideRook.hasMoved &&
        pieceAt(Square(1, rank)) == null &&
        pieceAt(Square(2, rank)) == null &&
        pieceAt(Square(3, rank)) == null &&
        !isSquareAttacked(Square(4, rank), piece.opponent) &&
        !isSquareAttacked(Square(3, rank), piece.opponent) &&
        !isSquareAttacked(Square(2, rank), piece.opponent)) {
      moves.add(
        Move(
          from: from,
          to: Square(2, rank),
          isCastle: true,
          pieceIndex: pieceIndex,
        ),
      );
      moves.add(
        Move(
          from: from,
          to: Square(0, rank),
          isCastle: true,
          pieceIndex: pieceIndex,
        ),
      );
    }

    return moves;
  }

  bool _canAttack(Square from, Square to, Piece piece) {
    piece = _effectivePiece(piece);
    if (_silentFile != null && from.file == _silentFile) return false;
    if (_zebrasActive && piece.type == PieceType.knight) return false;
    if (piece.hasEffect(AbilityEffect.queenMatka)) return false;
    if (!_isLandingAllowed(to, forPiece: piece)) return false;
    final target = pieceAt(to);
    if (target != null &&
        target.color != piece.color &&
        !_captureAllowed(piece, target)) {
      return false;
    }

    if (piece.type == PieceType.pawn) {
      final direction = piece.color == PieceColor.white ? 1 : -1;

      if (piece.hasEffect(AbilityEffect.pawnRam)) {
        return to.file == from.file && to.rank == from.rank + direction;
      }

      if (piece.hasEffect(AbilityEffect.invertedPawnMovement)) {
        return to.file == from.file && to.rank == from.rank + direction;
      }

      return _offsetSquare(from, -1, direction) == to ||
          _offsetSquare(from, 1, direction) == to;
    }

    if (piece.type == PieceType.knight) {
      final deltas = piece.hasEffect(AbilityEffect.knightLongJump)
          ? const [
              (1, 3),
              (3, 1),
              (3, -1),
              (1, -3),
              (-1, -3),
              (-3, -1),
              (-3, 1),
              (-1, 3),
            ]
          : const [
              (1, 2),
              (2, 1),
              (2, -1),
              (1, -2),
              (-1, -2),
              (-2, -1),
              (-2, 1),
              (-1, 2),
            ];
      for (final (df, dr) in deltas) {
        if (_offsetSquare(from, df, dr) == to) return true;
      }
      return false;
    }

    if (piece.type == PieceType.king) {
      if (piece.moveAsType != null && piece.moveAsType != PieceType.king) {
        return _canAttack(
          from,
          to,
          piece.copyWith(type: piece.moveAsType!, clearMoveAsType: true),
        );
      }
      final maxStep = piece.hasEffect(AbilityEffect.kingExtraStep) ? 2 : 1;
      for (var df = -maxStep; df <= maxStep; df++) {
        for (var dr = -maxStep; dr <= maxStep; dr++) {
          if (df == 0 && dr == 0) continue;
          final distance = max(df.abs(), dr.abs());
          if (distance > maxStep) continue;
          if (_offsetSquare(from, df, dr) == to) return true;
        }
      }
      return false;
    }

    if (piece.type == PieceType.queen &&
        piece.hasEffect(AbilityEffect.queenKnightStep)) {
      for (final (df, dr) in const [
        (1, 2),
        (2, 1),
        (2, -1),
        (1, -2),
        (-1, -2),
        (-2, -1),
        (-2, 1),
        (-1, 2),
      ]) {
        if (_offsetSquare(from, df, dr) == to) return true;
      }
    }

    final directions = switch (piece.type) {
      PieceType.rook => const [(0, -1), (0, 1), (-1, 0), (1, 0)],
      PieceType.bishop => const [(-1, -1), (-1, 1), (1, -1), (1, 1)],
      PieceType.queen => const [
        (0, -1),
        (0, 1),
        (-1, 0),
        (1, 0),
        (-1, -1),
        (-1, 1),
        (1, -1),
        (1, 1),
      ],
      _ => const <(int, int)>[],
    };

    for (final (stepFile, stepRank) in directions) {
      var file = from.file;
      var rank = from.rank;
      var steps = 0;

      while (true) {
        if (_mirrorActive && stepFile != 0 && steps >= _fileCount - 1) break;
        steps++;
        if (!_rangedCaptureStepAllowed(piece, steps)) break;
        rank += stepRank;
        if (rank < 0 || rank >= _rankCount) break;
        file = _mirrorActive && stepFile != 0
            ? _wrapFile(file + stepFile)
            : file + stepFile;
        if (!_mirrorActive && (file < 0 || file >= _fileCount)) break;

        final current = Square(file, rank);
        if (current == to) {
          return !isBlocked(current);
        }
        if (pieceAt(current) != null || isBlocked(current)) break;
      }
    }
    return false;
  }

  bool _captureAllowed(Piece attacker, Piece target) {
    final attackerPartner = _activeDuelPartner(attacker);
    if (attackerPartner != null && target.pieceId != attackerPartner) {
      return false;
    }
    final targetPartner = _activeDuelPartner(target);
    if (targetPartner != null && attacker.pieceId != targetPartner) {
      return false;
    }
    final forbiddenType = _excommunicationTypes[target.pieceId];
    if (forbiddenType != null &&
        attacker.color != target.color &&
        attacker.type == forbiddenType) {
      return false;
    }
    if (_rules.mightMakesRightActive && _rules.abilityEffectsActive) {
      if (target.type != PieceType.king && attacker.type != PieceType.king) {
        if (BoardCataclysmState.pieceCombatValue(attacker.type) <
            BoardCataclysmState.pieceCombatValue(target.type)) {
          return false;
        }
      }
    }
    // Non-aggression pact
    final link = _rules.nonAggressionLink[attacker.pieceId];
    if (link != null && link == target.pieceId) return false;
    // Layman: bishop ↔ pawn
    if (_hasEffect(attacker, AbilityEffect.bishopLayman) &&
        target.type == PieceType.pawn) {
      return false;
    }
    if (_hasEffect(target, AbilityEffect.bishopLayman) &&
        attacker.type == PieceType.pawn) {
      return false;
    }
    // Infantry shadow: enemy pawns cannot capture a piece standing
    // directly behind (toward owner edge) a living shadow pawn.
    if (attacker.type == PieceType.pawn) {
      final targetRef = _pieceById(target.pieceId);
      if (targetRef != null) {
        for (var r = 0; r < _rankCount; r++) {
          for (var f = 0; f < _fileCount; f++) {
            final sq = Square(f, r);
            for (final p in piecesAt(sq)) {
              if (p.color != target.color) continue;
              if (!_hasEffect(p, AbilityEffect.pawnInfantryShadow)) continue;
              final backDir = p.color == PieceColor.white ? -1 : 1;
              final cover = Square(sq.file, sq.rank + backDir);
              if (cover == targetRef.square) return false;
            }
          }
        }
      }
    }
    return true;
  }

  String? _activeDuelPartner(Piece piece) {
    final partnerId = _duelLinks[piece.pieceId];
    if (partnerId == null) return null;
    final partner = _pieceById(partnerId)?.piece;
    if (partner == null ||
        partner.color == piece.color ||
        _duelLinks[partnerId] != piece.pieceId) {
      return null;
    }
    return partnerId;
  }

  void _clearDuelFor(String pieceId) {
    final partnerId = _duelLinks.remove(pieceId);
    if (partnerId != null) _duelLinks.remove(partnerId);
  }

  int _pawnStartRank(PieceColor color) =>
      color == PieceColor.white ? 1 : _rankCount - 2;

  int _pawnPromotionRank(PieceColor color) {
    if (_rules.brokenPerspectiveActive) {
      // White promotes on rank 7 (index 6), black on rank 2 (index 1).
      return color == PieceColor.white ? _rankCount - 2 : 1;
    }
    return color == PieceColor.white ? _rankCount - 1 : 0;
  }

  int _countArmy(PieceColor color) {
    var n = 0;
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        for (final piece in piecesAt(Square(file, rank))) {
          if (piece.color == color) n++;
        }
      }
    }
    return n;
  }

  String? _lastMoveCapturerId() {
    final move = _lastMove;
    if (move == null) return null;
    return pieceAt(move.to)?.pieceId;
  }

  /// True when the only mating attacks come from a piece under mate-veto ("1").
  bool _mateVetoBlocksMate(PieceColor matedColor) {
    final vetoId = _rules.mateVetoEnemyPieceId[matedColor];
    if (vetoId == null) return false;
    final kingSq = findKing(matedColor);
    if (kingSq == null) return false;
    final attackers = <String>[];
    final by = matedColor.opponent;
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final from = Square(file, rank);
        for (final piece in piecesAt(from)) {
          if (piece.color != by) continue;
          if (_canAttack(from, kingSq, piece)) {
            attackers.add(piece.pieceId);
          }
        }
      }
    }
    return attackers.isNotEmpty && attackers.every((id) => id == vetoId);
  }

  Piece _pieceAfterMove(
    Piece piece,
    Square from,
    Square to, {
    bool isAirborne = false,
    bool isColorChaos = false,
    bool revealedByCapture = false,
  }) {
    final toLava = _lavaRanks.contains(to.rank);
    final fromLava = _lavaRanks.contains(from.rank);
    final streak = toLava && fromLava ? piece.lavaStreak : 0;
    final usedTriple =
        piece.type == PieceType.pawn &&
        piece.hasEffect(AbilityEffect.pawnTripleStepOnce) &&
        (to.rank - from.rank).abs() == 3;
    // Count-down restore (e.g. No Queen). restoreAfterMoves == 0 with
    // restoreAs set is a timer-only marker (e.g. cavalry) — do not revert on move.
    final restoreMoves = piece.restoreAfterMoves > 0
        ? piece.restoreAfterMoves - 1
        : piece.restoreAfterMoves;
    final shouldRestore = piece.restoreAs != null &&
        piece.restoreAfterMoves > 0 &&
        restoreMoves == 0;
    final revealPawn =
        piece.type == PieceType.pawn &&
        (piece.pawnRevealed ||
            revealedByCapture ||
            _pawnShouldBeRevealed(piece, to));
    return piece.copyWith(
      type: shouldRestore ? piece.restoreAs : null,
      hasMoved: true,
      lavaStreak: streak,
      tripleStepUsed: usedTriple ? true : null,
      airborneUsed: isAirborne ? true : null,
      colorChaosUsed: isColorChaos ? true : null,
      previousSquare: from,
      restoreAfterMoves: restoreMoves,
      restoreAs: shouldRestore ? null : piece.restoreAs,
      clearRestoreAs: shouldRestore,
      pawnRevealed: revealPawn ? true : null,
    );
  }

  void _beginSkillChoiceForPiece({
    required PieceColor chooserColor,
    required Square square,
    required int pieceIndex,
    required Piece sourcePiece,
  }) {
    // Legacy entry point for special rewards: use the equal-probability pool.
    _beginPeriodicSkillChoice(chooserColor);
  }

  Set<Square> _captureBlockedSquares() {
    return {
      ..._wormholes,
      ..._ghostCells,
      if (_quarantineMovesLeft > 0 && _quarantineSquare != null)
        _quarantineSquare!,
    };
  }

  // ignore: unused_element
  ({Square square, int index, Piece piece})? _findSkillPiece(
    PieceColor color,
    PieceType type,
  ) {
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        final pieces = piecesAt(square);
        for (var index = 0; index < pieces.length; index++) {
          final piece = pieces[index];
          if (piece.color == color && piece.type == type) {
            return (square: square, index: index, piece: piece);
          }
        }
      }
    }
    final kingSquare = findKing(color);
    return kingSquare == null ? null : _pieceRefAt(kingSquare);
  }

  ({Square square, int index, Piece piece})? _pieceRefAt(
    Square? square, {
    String? pieceId,
  }) {
    if (square == null) return null;
    final pieces = piecesAt(square);
    for (var index = 0; index < pieces.length; index++) {
      final piece = pieces[index];
      if (pieceId == null || piece.pieceId == pieceId) {
        return (square: square, index: index, piece: piece);
      }
    }
    return null;
  }

  ({Square square, int index, Piece piece})? _pieceById(String? pieceId) {
    if (pieceId == null) return null;
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        final pieces = piecesAt(square);
        for (var index = 0; index < pieces.length; index++) {
          if (pieces[index].pieceId == pieceId) {
            return (square: square, index: index, piece: pieces[index]);
          }
        }
      }
    }
    return null;
  }

  void _beginAbilityTarget({
    required GameAbility ability,
    required String sourceId,
    required PieceColor color,
    required AbilityTargetSelection selection,
    bool passesTurn = true,
  }) {
    _pendingTargetAbility = ability;
    _pendingTargetSourceId = sourceId;
    _pendingTargetColor = color;
    _pendingTargetSelection = selection;
    _pendingTargetPassesTurn = passesTurn;
  }

  void _clearPendingTarget() {
    _pendingTargetAbility = null;
    _pendingTargetSourceId = null;
    _pendingTargetColor = null;
    _pendingTargetSelection = null;
    _pendingTargetPassesTurn = true;
    _pendingExchangeOwnSequence = null;
    _pendingRemoveModTargetId = null;
    _pendingSelectOffer = null;
    _pendingSelectPieceType = null;
  }

  Piece _effectivePiece(Piece piece) {
    if (!_rules.abilityEffectsActive) {
      return piece.copyWith(abilities: const {});
    }
    final suppressed = <GameAbility>{};
    for (final byTarget in _titheSuppressions.values) {
      final ability = byTarget[piece.pieceId];
      if (ability != null) suppressed.add(ability);
    }
    if (suppressed.isEmpty) return piece;
    return piece.copyWith(abilities: piece.abilities.difference(suppressed));
  }

  bool hasEffectiveAbility(String pieceId, GameAbility ability) {
    final piece = _pieceById(pieceId)?.piece;
    return piece != null && _effectivePiece(piece).hasAbility(ability);
  }

  bool _hasEffect(Piece piece, AbilityEffect effect) =>
      _effectivePiece(piece).hasEffect(effect);

  ({Square square, int index, Piece piece})? _captureVictim(
    Move move,
    PieceColor moverColor,
  ) {
    if (move.isEnPassant) {
      final rank = moverColor == PieceColor.white
          ? move.to.rank - 1
          : move.to.rank + 1;
      return _pieceRefAt(Square(move.to.file, rank));
    }
    final pieces = piecesAt(move.to);
    for (var index = 0; index < pieces.length; index++) {
      if (pieces[index].color != moverColor) {
        return (square: move.to, index: index, piece: pieces[index]);
      }
    }
    return null;
  }

  bool _interceptProtectedCapture(
    ({Square square, int index, Piece piece}) victim,
  ) {
    final protectors = <({Square square, int index, Piece piece})>[];
    for (final entry in _sanctuaryTargets.entries) {
      if (entry.value != victim.piece.pieceId) continue;
      final protector = _pieceById(entry.key);
      if (protector != null &&
          protector.piece.color == victim.piece.color &&
          _hasEffect(protector.piece, AbilityEffect.bishopSanctuary)) {
        protectors.add(protector);
      }
    }
    protectors.sort((a, b) {
      final distance = _chebyshevDistance(
        a.square,
        victim.square,
      ).compareTo(_chebyshevDistance(b.square, victim.square));
      return distance != 0
          ? distance
          : a.piece.pieceId.compareTo(b.piece.pieceId);
    });
    if (protectors.isNotEmpty) {
      final protector = protectors.first;
      _sanctuaryTargets.remove(protector.piece.pieceId);
      final removed = _takePieceAt(protector.square, protector.index);
      if (removed != null) _onFinalDeath(removed, protector.square);
      return true;
    }
    if (_pilgrimageProtected.remove(victim.piece.pieceId)) return true;
    for (final entry in _rules.witnessProtectedPieceId.entries.toList()) {
      if (entry.value != victim.piece.pieceId) continue;
      if (entry.key != victim.piece.color) continue;
      _rules.witnessProtectedPieceId.remove(entry.key);
      _rules.revealedWitnessPieceId = victim.piece.pieceId;
      return true;
    }
    return false;
  }

  int _quadrantFor(Square square) {
    final right = square.file >= (_fileCount / 2).ceil();
    final top = square.rank >= (_rankCount / 2).ceil();
    return (top ? 2 : 0) + (right ? 1 : 0);
  }

  bool _startQueuedAuctionChoice() {
    final square = _pendingAuctionSquare;
    final color = _pendingAuctionColor;
    if (square == null || color == null) return false;

    _pendingAuctionSquare = null;
    _pendingAuctionColor = null;
    _auctionSquare = null;

    // Stockfish / non-chooser: no reward.
    if (!_abilityChoosingColors.contains(color)) {
      return false;
    }
    // Human gets two mods: this choice + one queued follow-up.
    _rules.queuedSkillChoices = max(_rules.queuedSkillChoices, 1);
    _beginPeriodicSkillChoice(color);
    return isAwaitingSkillChoice;
  }

  bool _startQueuedBonusSkillChoice() {
    final color = _pendingBonusSkillColor;
    if (color == null) return false;
    _pendingBonusSkillColor = null;
    _skillChoiceIsBonus = true;
    _beginPeriodicSkillChoice(color);
    return isAwaitingSkillChoice;
  }

  bool _startQueuedPieceChoice() {
    final pieceId = _queuedSkillPieceId;
    final color = _queuedSkillColor;
    _queuedSkillPieceId = null;
    _queuedSkillColor = null;
    if (pieceId == null || color == null) return false;
    final source = _pieceById(pieceId);
    if (source == null || source.piece.color != color) return false;
    _beginSkillChoiceForPiece(
      chooserColor: color,
      square: source.square,
      pieceIndex: source.index,
      sourcePiece: source.piece,
    );
    return true;
  }

  void _applyMutation(PieceColor color) {
    final pawns = <(Square, int, Piece)>[];
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        final pieces = piecesAt(square);
        for (var i = 0; i < pieces.length; i++) {
          final piece = pieces[i];
          if (piece.color == color && piece.type == PieceType.pawn) {
            pawns.add((square, i, piece));
          }
        }
      }
    }

    if (pawns.isEmpty) return;
    final target = pawns[_random.nextInt(pawns.length)];
    _replacePieceAt(
      target.$1,
      target.$2,
      target.$3.copyWith(
        type: _random.nextBool() ? PieceType.knight : PieceType.bishop,
      ),
    );
  }

  void _explodeTrojanAt(Square square) {
    if (piecesAt(square).isEmpty) return;

    for (var dr = -1; dr <= 1; dr++) {
      for (var df = -1; df <= 1; df++) {
        if (df == 0 && dr == 0) continue;
        final neighbor = _offsetSquare(square, df, dr);
        if (neighbor == null) continue;
        if (piecesAt(neighbor).isEmpty) continue;
        _capturePiecesAt(neighbor);
      }
    }

    _capturePiecesAt(square);
  }

  void _afterVoluntaryMove(
    Move move,
    Piece moverBefore, {
    required bool captured,
  }) {
    final moverId = moverBefore.pieceId;

    // Effects owned by this bishop last until its next voluntary move.
    _excommunicationTypes.remove(moverId);
    _titheSuppressions.remove(moverId);

    if (moverBefore.type == PieceType.bishop &&
        captured &&
        _hasEffect(moverBefore, AbilityEffect.bishopExcommunication)) {
      final victimType = _lastCapturedType;
      if (victimType != null) _excommunicationTypes[moverId] = victimType;
    }

    if (moverBefore.abilities.isNotEmpty) {
      final suppressors = <({Square square, Piece piece})>[];
      for (var rank = 0; rank < _rankCount; rank++) {
        for (var file = 0; file < _fileCount; file++) {
          final square = Square(file, rank);
          for (final bishop in piecesAt(square)) {
            if (bishop.color == moverBefore.color ||
                bishop.type != PieceType.bishop ||
                !_hasEffect(bishop, AbilityEffect.bishopTithe)) {
              continue;
            }
            if (_isUnobstructedDiagonal(square, move.from)) {
              suppressors.add((square: square, piece: bishop));
            }
          }
        }
      }
      final abilities = moverBefore.abilities.toList()
        ..sort((a, b) => a.index.compareTo(b.index));
      if (abilities.isNotEmpty) {
        for (final suppressor in suppressors) {
          _titheSuppressions.putIfAbsent(
            suppressor.piece.pieceId,
            () => {},
          )[moverId] = abilities.first;
        }
      }
    }

    final current = _pieceById(moverId);
    if (current == null) return;
    if (_hasEffect(current.piece, AbilityEffect.knightTour) &&
        !_knightTourRewardUsed.contains(moverId)) {
      final visited = _knightTourVisited.putIfAbsent(
        moverId,
        () => {move.from},
      );
      visited.add(current.square);
      if (visited.length >= 8) {
        _knightTourRewardUsed.add(moverId);
        _pendingSkillSquare = current.square;
        _pendingSkillPieceId = moverId;
        _pendingSkillColor = current.piece.color;
        _pendingCaptureOffers = _catalog.pickKnightTourOffers(current.piece);
      }
    }

    if (_hasEffect(current.piece, AbilityEffect.bishopPilgrimage) &&
        !_pilgrimageCompleted.contains(moverId)) {
      final visited = _pilgrimageQuadrants.putIfAbsent(
        moverId,
        () => {_quadrantFor(move.from)},
      );
      visited.add(_quadrantFor(current.square));
      if (visited.length >= 4) {
        _beginAbilityTarget(
          ability: GameAbility.bishopPilgrimage,
          sourceId: moverId,
          color: current.piece.color,
          selection: AbilityTargetSelection.friendlyPiece,
        );
      }
    }

    if (_hasEffect(current.piece, AbilityEffect.rookCurfew)) {
      _applyCurfewBindings(moverId);
    }

    _resolveBoardRulesAfterMove(move, moverBefore, current, captured: captured);

    // --- Batch mods ---
    if (_hasEffect(moverBefore, AbilityEffect.pawnArchivist)) {
      final visited = _rules.archivistVisited.putIfAbsent(moverId, () => {});
      visited.add(move.from);
      visited.add(current.square);
    }
    if (_hasEffect(moverBefore, AbilityEffect.pawnFuse) && !_isSimulatingLegality) {
      _rules.fuseTimers[move.from] = 4; // 2 full moves ≈ 4 plies
    }
    if (_hasEffect(moverBefore, AbilityEffect.knightDonkey)) {
      _rules.donkeySwampSquares.add(current.square);
    }
    if (_hasEffect(moverBefore, AbilityEffect.knightHoofSmoke)) {
      _rules.hoofSmokeSquares.add(current.square);
    }
    if (captured && _hasEffect(moverBefore, AbilityEffect.knightBucephalus)) {
      _rules.bucephalusCaptures[moverId] =
          (_rules.bucephalusCaptures[moverId] ?? 0) + 1;
    }
    if (_rules.insatiableHungerActive &&
        moverBefore.type == PieceType.queen &&
        captured) {
      _rules.queenHungerPlies[moverId] = 0;
    }
    if (_rules.comeOnActive &&
        !_rules.comeOnConsumed &&
        captured &&
        !_isSimulatingLegality) {
      _rules.comeOnConsumed = true;
      _pendingBonusSkillColor = moverBefore.color;
    }
    if (_rules.blackMarkPieceId != null &&
        captured &&
        _lastCapturedType != null &&
        !_isSimulatingLegality) {
      // Black mark triggers on capturing the marked piece — handled via victim id
    }
    if (_rules.ownHandsOwner == moverBefore.color &&
        moverBefore.type == PieceType.king) {
      final enemyKing = findKing(moverBefore.color.opponent);
      if (enemyKing != null &&
          _chebyshevDistance(current.square, enemyKing) <= 2) {
        _finishGame(
          winner: moverBefore.color,
          reason: GameEndReason.alternativeVictory,
          detail: 'ownHands',
        );
        return;
      }
    }
    if (_rules.restlessKingsPliesLeft > 0 && moverBefore.type == PieceType.king) {
      _rules.restlessKingStart.remove(moverBefore.color);
    }
    if (_hasEffect(moverBefore, AbilityEffect.queenFatherDream) &&
        current.piece.abilities.length >= 5) {
      _finishGame(
        winner: current.piece.color,
        reason: GameEndReason.alternativeVictory,
        detail: 'fatherDream',
      );
      return;
    }
    if (_rules.donkeySwampSquares.contains(current.square) &&
        !_hasEffect(moverBefore, AbilityEffect.knightDonkey)) {
      _replacePieceAt(
        current.square,
        current.index,
        current.piece.copyWith(
          skipTurnsLeft: max(current.piece.skipTurnsLeft, 2),
        ),
      );
    }
    if (_hasEffect(moverBefore, AbilityEffect.bishopInkTrail) &&
        moverBefore.type == PieceType.bishop) {
      final df = (current.square.file - move.from.file).sign;
      final dr = (current.square.rank - move.from.rank).sign;
      if (df != 0 && dr != 0) {
        var f = move.from.file + df;
        var r = move.from.rank + dr;
        while (f != current.square.file || r != current.square.rank) {
          _rules.inkTrailBlocked[Square(f, r)] = 2;
          f += df;
          r += dr;
        }
      }
    }
    if (_rules.gestureMirrorRequiredLight != null &&
        moverBefore.color == _turn) {
      // Constrained move completed — clear.
      _rules.gestureMirrorRequiredLight = null;
    }
    _maybeMaskOrGaneshaSwap(moverBefore, current.square);
    _maybeHolyRandomTransform(current.piece);

    // Seal: moving sealed rook releases victim
    if (_rules.sealRookId == moverId) {
      _rules.sealRookId = null;
      _rules.sealVictimId = null;
    }

    // Bucephalus: detect king knight-jump
    if (moverBefore.type == PieceType.king) {
      final df = (current.square.file - move.from.file).abs();
      final dr = (current.square.rank - move.from.rank).abs();
      if ((df == 1 && dr == 2) || (df == 2 && dr == 1)) {
        _rules.bucephalusKingJumpUsed.add(moverBefore.color.name);
      }
    }

    // Pair step: optional dual forward push
    if (captured == false &&
        moverBefore.type == PieceType.pawn &&
        _hasEffect(moverBefore, AbilityEffect.pawnPairStep)) {
      _tryPairStepCompanion(move, moverId);
    }

    // Gallop contract progress
    final route = _rules.gallopContractRoute[moverId];
    if (route != null && route.isNotEmpty) {
      var progress = _rules.gallopContractProgress[moverId] ?? 0;
      if (progress < route.length && current.square == route[progress]) {
        progress++;
        _rules.gallopContractProgress[moverId] = progress;
        if (progress >= route.length) {
          _killRandomEnemyNonKing(moverBefore.color);
          _rules.gallopContractRoute.remove(moverId);
          _rules.gallopContractProgress.remove(moverId);
        }
      }
    }

    // Ill drive: arm portal on first move, or create portal when leaving end
    if (_rules.illDriveRookId == moverId) {
      if (_rules.illDriveFrom == null) {
        _rules.illDriveFrom = move.from;
        _rules.illDriveTo = current.square;
      } else if (_rules.illDriveTo == move.from) {
        // Leaving the destination — open portal between from and to
        _teleportA = _rules.illDriveFrom;
        _teleportB = _rules.illDriveTo;
        _rules.illDriveRookId = null;
        _rules.illDriveFrom = null;
        _rules.illDriveTo = null;
      }
    }

    // Blinding sacristy on capture
    if (captured && _hasEffect(moverBefore, AbilityEffect.bishopBlindingSacristy)) {
      _rules.blindingSacristy[current.square] = 2;
      _rules.blindingExemptPieceIds.add(moverId);
    }
    if (_rules.blindingSacristy.containsKey(current.square) &&
        !_rules.blindingExemptPieceIds.contains(moverId)) {
      _rules.littleBrotherSkipIds.add(moverId); // reuse skip: no capture 1 turn
      // Better: skip attack — use skipTurnsLeft for "doesn't capture"
      _replacePieceAt(
        current.square,
        current.index,
        current.piece.copyWith(
          skipTurnsLeft: max(current.piece.skipTurnsLeft, 2),
        ),
      );
      _rules.blindingSacristy.remove(current.square);
    }

    // Little brother: enemy ahead skips next turn
    if (moverBefore.type == PieceType.pawn &&
        _hasEffect(moverBefore, AbilityEffect.pawnLittleBrother)) {
      final dir = moverBefore.color == PieceColor.white ? 1 : -1;
      final ahead = Square(current.square.file, current.square.rank + dir);
      if (isOnBoard(ahead)) {
        for (final enemy in piecesAt(ahead)) {
          if (enemy.color == moverBefore.color) continue;
          if (enemy.type == PieceType.king) continue;
          final ref = _pieceById(enemy.pieceId);
          if (ref == null) continue;
          _replacePieceAt(
            ref.square,
            ref.index,
            ref.piece.copyWith(
              skipTurnsLeft: max(ref.piece.skipTurnsLeft, 2),
            ),
          );
        }
      }
    }

    // Double life: after armed move, revert to pawn and mark used
    if (_rules.doubleLifeArmed.contains(moverId)) {
      final refreshed = _pieceById(moverId);
      if (refreshed != null) {
        _replacePieceAt(
          refreshed.square,
          refreshed.index,
          refreshed.piece.copyWith(
            type: PieceType.pawn,
            clearMoveAsType: true,
          ),
        );
      }
      _rules.doubleLifeArmed.remove(moverId);
      _rules.doubleLifeUsed.add(moverId);
    }

    // Starvation reset on capture by that pawn
    if (captured && _rules.starvationPlies.containsKey(moverId)) {
      _rules.starvationPlies[moverId] = 6;
    }

    // Sapper: disarm traps on landing
    if (_hasEffect(moverBefore, AbilityEffect.pawnSapper)) {
      _mines.remove(current.square);
      _rules.quicksandHidden.remove(current.square);
      _rules.quicksandRevealed.remove(current.square);
      _rules.quicksandDuration.remove(current.square);
    }

    // Bucephalus king knight jump unlock
    if ((_rules.bucephalusCaptures[moverId] ?? 0) >= 3 &&
        !_rules.bucephalusKingJumpUsed.contains(moverBefore.color.name)) {
      // Flag checked in king moves via bucephalusKingJumpUsed set when used
    }
  }

  void _tryPairStepCompanion(Move move, String moverId) {
    final partnerId = _rules.pairStepPartner[moverId];
    if (partnerId == null) return;
    final partner = _pieceById(partnerId);
    final mover = _pieceById(moverId);
    if (partner == null || mover == null) return;
    if (partner.piece.type != PieceType.pawn) return;
    final dir = mover.piece.color == PieceColor.white ? 1 : -1;
    // Only when mover stepped exactly 1 forward on same file
    if (move.to.file != move.from.file) return;
    if (move.to.rank - move.from.rank != dir) return;
    final dest = Square(partner.square.file, partner.square.rank + dir);
    if (!isOnBoard(dest) || piecesAt(dest).isNotEmpty || isBlocked(dest)) {
      return;
    }
    // Mid must be clear for partner
    final taken = _takePieceAt(partner.square, partner.index);
    if (taken == null) return;
    _setPrimary(dest, taken.copyWith(hasMoved: true));
  }

  void _killRandomEnemyNonKing(PieceColor color) {
    final candidates = <({Square square, int index, Piece piece})>[];
    for (var r = 0; r < _rankCount; r++) {
      for (var f = 0; f < _fileCount; f++) {
        final sq = Square(f, r);
        final pieces = piecesAt(sq);
        for (var i = 0; i < pieces.length; i++) {
          final p = pieces[i];
          if (p.color == color.opponent && p.type != PieceType.king) {
            candidates.add((square: sq, index: i, piece: p));
          }
        }
      }
    }
    if (candidates.isEmpty) return;
    final pick = candidates[_random.nextInt(candidates.length)];
    final removed = _takePieceAt(pick.square, pick.index);
    if (removed != null) _onFinalDeath(removed, pick.square);
  }

  PieceType? _lastCapturedType;

  bool _isUnobstructedDiagonal(Square from, Square to) {
    final df = to.file - from.file;
    final dr = to.rank - from.rank;
    if (df.abs() != dr.abs() || df == 0) return false;
    final sf = df.sign;
    final sr = dr.sign;
    var current = Square(from.file + sf, from.rank + sr);
    while (current != to) {
      if (piecesAt(current).isNotEmpty || isBlocked(current)) return false;
      current = Square(current.file + sf, current.rank + sr);
    }
    return true;
  }

  void _applyMove(Move move) {
    move = _normalizeCastleMove(move);
    if (move.isInquisitorStrip) {
      final target = pieceAt(move.to);
      if (target != null && target.abilities.isNotEmpty) {
        final abilities = target.abilities.toList();
        if (!_isSimulatingLegality) abilities.shuffle(_random);
        _setPrimary(move.to, target.withoutAbility(abilities.first));
        _refreshDoppelgangerFlags();
      }
      _enPassantTarget = null;
      return;
    }

    if (move.isCastleSwap) {
      final king = pieceAt(move.from, index: move.pieceIndex)!;
      final rook = pieceAt(move.to)!;
      _setPrimary(
        move.to,
        _pieceAfterMove(
          king,
          move.from,
          move.to,
        ).copyWith(royalDecreeUsed: true),
      );
      _setPrimary(move.from, _pieceAfterMove(rook, move.to, move.from));
      _enPassantTarget = null;
      return;
    }

    if (move.isKnightRearSwap) {
      final mover = pieceAt(move.from, index: move.pieceIndex)!;
      final knight = pieceAt(move.to)!;
      _setPrimary(move.to, _pieceAfterMove(mover, move.from, move.to));
      _setPrimary(move.from, _pieceAfterMove(knight, move.to, move.from));
      _enPassantTarget = null;
      return;
    }

    final pieceRaw = _takePieceAt(move.from, move.pieceIndex)!;
    // Opponent moving an unrevealed enemy spy: reveal and flip allegiance.
    var piece = pieceRaw;
    if (_rules.turncoatsActive &&
        !_rules.revealedTurncoats.contains(piece.pieceId) &&
        _rules.turncoatSpyIds[piece.color] == piece.pieceId &&
        piece.color != _turn) {
      _rules.revealedTurncoats.add(piece.pieceId);
      piece = piece.copyWith(color: _turn);
    }
    final pushedAlly = move.isRookPush ? pieceAt(move.to) : null;
    final destinationPieces = piecesAt(move.to);
    final horsemenConvert =
        _fourHorsemenActive &&
        piece.type == PieceType.knight &&
        !piece.horsemenCaptureUsed &&
        destinationPieces.any((p) => p.color != piece.color) &&
        !move.isRookPush &&
        !move.isEnPassant;
    final isCaptureMove =
        !horsemenConvert &&
        ((destinationPieces.isNotEmpty && !move.isRookPush) ||
            move.isEnPassant);
    _lastCapturedType = isCaptureMove
        ? (move.isEnPassant
              ? pieceAt(
                  Square(
                    move.to.file,
                    piece.color == PieceColor.white
                        ? move.to.rank - 1
                        : move.to.rank + 1,
                  ),
                )?.type
              : destinationPieces
                    .where((target) => target.color != piece.color)
                    .firstOrNull
                    ?.type)
        : null;

    // Липота: пометить взявшую фигуру до снятия жертвы.
    Piece? stickyVictimMarker;
    if (isCaptureMove && !move.isEnPassant) {
      for (final victim in destinationPieces) {
        if (_hasEffect(victim, AbilityEffect.stickyPawn)) {
          stickyVictimMarker = piece;
          break;
        }
      }
    }
    if (move.isEnPassant) {
      final capturedRank = piece.color == PieceColor.white
          ? move.to.rank - 1
          : move.to.rank + 1;
      final ep = pieceAt(Square(move.to.file, capturedRank));
      if (ep != null && _hasEffect(ep, AbilityEffect.stickyPawn)) {
        stickyVictimMarker = piece;
      }
    }

    final horsemenVictims = horsemenConvert
        ? destinationPieces.where((victim) => victim.color != piece.color).map((
            victim,
          ) {
            _clearDuelFor(victim.pieceId);
            return victim.copyWith(color: piece.color);
          }).toList()
        : const <Piece>[];

    PieceType? polymorphType;
    if (piece.type == PieceType.pawn &&
        _hasEffect(piece, AbilityEffect.polymorph) &&
        isCaptureMove) {
      if (move.isEnPassant) {
        final capturedRank = piece.color == PieceColor.white
            ? move.to.rank - 1
            : move.to.rank + 1;
        final ep = pieceAt(Square(move.to.file, capturedRank));
        polymorphType = ep?.type;
      } else if (destinationPieces.isNotEmpty) {
        polymorphType = destinationPieces.first.type;
      }
    }

    if (!_suppressCaptureSideEffects && !move.isRookPush && !horsemenConvert) {
      if (move.isEnPassant) {
        final capturedRank = piece.color == PieceColor.white
            ? move.to.rank - 1
            : move.to.rank + 1;
        final captured = pieceAt(Square(move.to.file, capturedRank));
        if (captured != null &&
            captured.color != piece.color &&
            captured.type == PieceType.pawn &&
            ((_goldenThroneWhite && captured.color == PieceColor.white) ||
                (_goldenThroneBlack && captured.color == PieceColor.black))) {
          _pendingGoldenThroneColor = captured.color;
        }
      } else {
        for (final captured in destinationPieces) {
          if (captured.color == piece.color) continue;
          if (captured.type != PieceType.pawn) continue;
          if ((_goldenThroneWhite && captured.color == PieceColor.white) ||
              (_goldenThroneBlack && captured.color == PieceColor.black)) {
            _pendingGoldenThroneColor = captured.color;
            break;
          }
        }
      }
    }

    var triggeredYouShallNotPass = false;
    if (destinationPieces.isNotEmpty && !move.isRookPush && !horsemenConvert) {
      for (final victim in destinationPieces) {
        if (victim.color != piece.color &&
            _hasEffect(victim, AbilityEffect.queenYouShallNotPass)) {
          triggeredYouShallNotPass = true;
          break;
        }
      }
      _capturePiecesAt(move.to, capturingColor: piece.color);
    }

    if (_hasEffect(piece, AbilityEffect.dustTrail)) {
      _dustSquares[move.from] = 2;
    }

    _enPassantTarget = null;

    if (piece.type == PieceType.pawn) {
      final doubleStep = (move.to.rank - move.from.rank).abs() == 2;
      if (doubleStep) {
        final direction = piece.color == PieceColor.white ? 1 : -1;
        _enPassantTarget = Square(move.from.file, move.from.rank + direction);
      }
    }

    if (move.isEnPassant) {
      final capturedRank = piece.color == PieceColor.white
          ? move.to.rank - 1
          : move.to.rank + 1;
      _capturePiecesAt(
        Square(move.to.file, capturedRank),
        capturingColor: piece.color,
      );
    }

    if (move.isRookPush) {
      final df = _stepFileToward(move.from, move.to);
      final dr = (move.to.rank - move.from.rank).sign;
      final beyond = _offsetSquare(move.to, df, dr)!;
      _setPrimary(beyond, _pieceAfterMove(pushedAlly!, move.to, beyond));
    }

    if (move.isCastle) {
      final rank = move.from.rank;
      if (move.to.file == 6) {
        final rook = pieceAt(Square(7, rank))!;
        _setPrimary(
          Square(5, rank),
          _pieceAfterMove(rook, Square(7, rank), Square(5, rank)),
        );
        _clearSquare(Square(7, rank));
      } else if (move.to.file == 2) {
        final rook = pieceAt(Square(0, rank))!;
        _setPrimary(
          Square(3, rank),
          _pieceAfterMove(rook, Square(0, rank), Square(3, rank)),
        );
        _clearSquare(Square(0, rank));
      }
    }

    Piece moved = _pieceAfterMove(
      stickyVictimMarker != null
          // 2: тик в конце хода взятия → 1 на следующий ход фигуры.
          ? piece.copyWith(skipTurnsLeft: 2)
          : piece,
      move.from,
      move.to,
      isAirborne: move.isAirborne,
      isColorChaos: move.isColorChaos,
      revealedByCapture: isCaptureMove,
    );
    if (piece.type == PieceType.king &&
        destinationPieces.isNotEmpty &&
        destinationPieces.first.color == piece.color &&
        piece.hasEffect(AbilityEffect.kingFamilyUnion)) {
      final ally = destinationPieces.firstWhere(
        (p) =>
            p.color == piece.color &&
            (p.type == PieceType.knight || p.type == PieceType.bishop),
        orElse: () => destinationPieces.first,
      );
      if (ally.type == PieceType.knight || ally.type == PieceType.bishop) {
        moved = moved.copyWith(moveAsType: ally.type);
      }
    }
    if (polymorphType != null) {
      moved = moved.copyWith(type: polymorphType, polymorphGrace: true);
    }
    if (horsemenConvert) {
      moved = moved.copyWith(horsemenCaptureUsed: true);
      _clearSquare(move.to);
      _setCell(move.to, [
        moved,
        if (horsemenVictims.isNotEmpty) horsemenVictims.first,
      ]);
    } else {
      _setPrimary(move.to, moved);
    }

    if (triggeredYouShallNotPass) {
      _capturePiecesAt(
        move.to,
        capturingColor: null,
        reason: GraveyardReason.ability,
      );
      return;
    }

    if (move.promotion != null && polymorphType == null) {
      final promoted = pieceAt(move.to)!;
      _setPrimary(
        move.to,
        Piece(
          pieceId: promoted.pieceId,
          type: move.promotion!,
          color: promoted.color,
          hasMoved: true,
          abilities: promoted.abilities,
          lavaStreak: promoted.lavaStreak,
          tripleStepUsed: promoted.tripleStepUsed,
          royalDecreeUsed: promoted.royalDecreeUsed,
          airborneUsed: promoted.airborneUsed,
          colorChaosUsed: promoted.colorChaosUsed,
          kingShieldUsed: promoted.kingShieldUsed,
          previousSquare: promoted.previousSquare,
          restoreAs: promoted.restoreAs,
          restoreAfterMoves: promoted.restoreAfterMoves,
          cosmeticHue: promoted.cosmeticHue,
          pawnRevealed: true,
          skipTurnsLeft: promoted.skipTurnsLeft,
          boundIsLight: promoted.boundIsLight,
          caliphGrace: promoted.caliphGrace,
          polymorphGrace: promoted.polymorphGrace,
          moveAsType: promoted.moveAsType,
          matkaTurns: promoted.matkaTurns,
          plagueTurnsLeft: promoted.plagueTurnsLeft,
          trojanTurnsLeft: promoted.trojanTurnsLeft,
          horsemenCaptureUsed: promoted.horsemenCaptureUsed,
        ),
      );
    }

    if (_resolveGuardInterception(piece.pieceId)) return;
    _resolveTeleportLanding(move.to, moved.color);
    if (_resolveGuardInterception(piece.pieceId)) return;

    var finalSquare = _locateMovedPiece(move, moved.color) ?? move.to;
    final survivedMine = _resolveMineAt(finalSquare);
    if (!survivedMine) return;

    if (isCaptureMove) {
      _resolveBoomerangReturn(move.from, finalSquare, moved.color);
      finalSquare = _pieceSquareAfterMove(move, moved.color) ?? finalSquare;
    }

    _resolveLaserHit(finalSquare, moved.color);
    _checkColorVowAt(finalSquare);

    if (_hasEffect(moved, AbilityEffect.bishopBrothers)) {
      _applyBrothersShift(
        move.from,
        move.to,
        moved.color,
        exclude: finalSquare,
      );
    }
    _resolveAllGuardLandings();
    if (!_isSimulatingLegality) {
      _afterExpandedMoveEffects(move, moved, isCaptureMove, finalSquare);
    }
  }

  void _afterExpandedMoveEffects(
    Move move,
    Piece moved,
    bool wasCapture,
    Square landed,
  ) {
    // Duck: after a move, require relocating the duck (duck chess).
    if (_rules.duckChessActive && !_rules.duckNeedsPlacement) {
      _rules.duckNeedsPlacement = true;
    }
    // Snail trail slime on departure.
    if (_rules.snailTrailPieceId == moved.pieceId) {
      _rules.snailSlimePlies[move.from] = 2;
    }
    // Center tax.
    final centerFiles = {_fileCount ~/ 2 - 1, _fileCount ~/ 2};
    final centerRanks = {_rankCount ~/ 2 - 1, _rankCount ~/ 2};
    if (_rules.centerTaxActive &&
        centerFiles.contains(landed.file) &&
        centerRanks.contains(landed.rank) &&
        moved.type != PieceType.king) {
      _rules.centerTaxSkipNext.add(moved.pieceId);
    }
    // Atomic explosion.
    if (_rules.atomicActive && wasCapture) {
      _resolveAtomicExplosion(landed, moved.color);
    }
    // King of center ("3").
    if (_rules.kingCenterActive && moved.type == PieceType.king) {
      final centers = {
        Square(3, 3),
        Square(3, 4),
        Square(4, 3),
        Square(4, 4),
      };
      if (centers.contains(landed)) {
        _finishGame(
          winner: moved.color,
          reason: GameEndReason.alternativeVictory,
          detail: 'kingCenter',
        );
        return;
      }
    }
    // Priority setup occupation win.
    if (_rules.prioritySetupActive && _rules.priorityCells.isNotEmpty) {
      final owned = _rules.priorityCells.every((s) {
        final p = pieceAt(s);
        return p != null && p.color == moved.color;
      });
      if (owned) {
        _finishGame(
          winner: moved.color,
          reason: GameEndReason.alternativeVictory,
          detail: 'prioritySetup',
        );
        return;
      }
    }
    // Blood feud revenge clears timer.
    if (_rules.bloodFeudActive &&
        wasCapture &&
        _rules.bloodFeudVictimColor == moved.color) {
      _rules.bloodFeudVictimColor = null;
      _rules.bloodFeudPliesLeft = 0;
    }
    // Kansas typhoon landing.
    if (_rules.kansasTyphoon == landed) {
      final dest = _randomEmptyNeighbor(landed) ?? _randomEmptySquare();
      if (dest != null) {
        _clearSquare(landed);
        _setPrimary(dest, moved);
      }
    }
    // Wasteland claims.
    if (_rules.wastelandActive) {
      _rules.wastelandClaims[move.from] = (
        owner: moved.color,
        pliesLeft: 3,
      );
      final claim = _rules.wastelandClaims[landed];
      if (claim != null &&
          claim.owner != moved.color &&
          claim.pliesLeft > 0) {
        _rules.wastelandTollSkip[moved.pieceId] = 1;
      }
      _rules.wastelandClaims.remove(landed);
    }
  }

  void _resolveAtomicExplosion(Square epicenter, PieceColor attacker) {
    var enemyKingHit = false;
    for (var dr = -1; dr <= 1; dr++) {
      for (var df = -1; df <= 1; df++) {
        final s = Square(epicenter.file + df, epicenter.rank + dr);
        if (!isOnBoard(s)) continue;
        final pieces = List<Piece>.from(piecesAt(s));
        for (final p in pieces) {
          if (p.type == PieceType.pawn) continue;
          if (p.type == PieceType.king && p.color != attacker) {
            enemyKingHit = true;
          }
          if (p.type == PieceType.king && p.color == attacker) continue;
          final ref = _pieceById(p.pieceId);
          if (ref == null) continue;
          _clearSquare(ref.square);
          if (p.type == PieceType.king && p.color != attacker) {
            // handled by finish
          } else if (p.type != PieceType.king) {
            _onFinalDeath(
              p,
              s,
              capturingColor: attacker,
              reason: GraveyardReason.explosion,
            );
          }
        }
      }
    }
    // Capturer also dies in atomic (except if pawn — already skipped rules vary;
    // standard atomic: capturer explodes too unless pawns).
    final capturer = pieceAt(epicenter);
    if (capturer != null && capturer.type != PieceType.pawn) {
      _clearSquare(epicenter);
      _onFinalDeath(
        capturer,
        epicenter,
        capturingColor: null,
        reason: GraveyardReason.explosion,
      );
    }
    if (enemyKingHit) {
      _finishGame(
        winner: attacker,
        reason: GameEndReason.kingDestroyed,
      );
    }
  }

  void _resolveAllGuardLandings() {
    final intruderIds = <String>[];
    for (final entry in _guardSquares.entries.toList()) {
      final guard = _pieceById(entry.key);
      if (guard == null) continue;
      for (final occupant in piecesAt(entry.value)) {
        if (occupant.color != guard.piece.color) {
          intruderIds.add(occupant.pieceId);
        }
      }
    }
    intruderIds.sort();
    for (final id in intruderIds) {
      _resolveGuardInterception(id);
    }
  }

  bool _resolveGuardInterception(String movedPieceId) {
    final intruder = _pieceById(movedPieceId);
    if (intruder == null) return false;
    if (intruder.piece.type == PieceType.king) return false;
    final candidates = <({Square square, int index, Piece piece})>[];
    for (final entry in _guardSquares.entries.toList()) {
      if (entry.value != intruder.square ||
          (_guardTurnsLeft[entry.key] ?? 0) <= 0) {
        continue;
      }
      final guard = _pieceById(entry.key);
      if (guard == null ||
          guard.piece.color == intruder.piece.color ||
          !_hasEffect(guard.piece, AbilityEffect.knightGuard) ||
          !_isKnightJump(guard.square, intruder.square, guard.piece) ||
          !_isGuardInterceptionLegal(guard, intruder)) {
        continue;
      }
      candidates.add(guard);
    }
    candidates.sort((a, b) => a.piece.pieceId.compareTo(b.piece.pieceId));
    if (candidates.isEmpty) return false;
    final guard = candidates.first;
    _guardSquares.remove(guard.piece.pieceId);
    _guardTurnsLeft.remove(guard.piece.pieceId);
    _takePieceAt(intruder.square, intruder.index);
    _takePieceAt(guard.square, guard.index);
    _setPrimary(
      intruder.square,
      _pieceAfterMove(guard.piece, guard.square, intruder.square),
    );
    _onFinalDeath(
      intruder.piece,
      intruder.square,
      capturingColor: guard.piece.color,
      reason: GraveyardReason.capture,
    );
    return true;
  }

  bool _isGuardInterceptionLegal(
    ({Square square, int index, Piece piece}) guard,
    ({Square square, int index, Piece piece}) intruder,
  ) {
    final snapshot = createSnapshot();
    try {
      _takePieceAt(intruder.square, intruder.index);
      final currentGuard = _pieceById(guard.piece.pieceId);
      if (currentGuard == null) return false;
      _takePieceAt(currentGuard.square, currentGuard.index);
      _setPrimary(intruder.square, currentGuard.piece);
      return !isInCheck(currentGuard.piece.color);
    } finally {
      restoreSnapshot(snapshot);
    }
  }

  bool _isKnightJump(Square from, Square to, Piece knight) {
    final df = _fileDistance(from.file, to.file);
    final dr = (from.rank - to.rank).abs();
    return _hasEffect(knight, AbilityEffect.knightLongJump)
        ? (df == 1 && dr == 3) || (df == 3 && dr == 1)
        : (df == 1 && dr == 2) || (df == 2 && dr == 1);
  }

  void _resolveLaserHit(Square square, PieceColor moverColor) {
    final left = _laserFiles[square.file] ?? 0;
    if (left <= 0) return;
    final owner = _laserFileOwner[square.file];
    if (owner == null || owner == moverColor) return;
    final piece = pieceAt(square);
    if (piece == null || piece.color == owner) return;
    if (piece.type == PieceType.king) return; // король не должен был встать
    _capturePiecesAt(square);
  }

  void _applyBrothersShift(
    Square from,
    Square to,
    PieceColor color, {
    required Square exclude,
  }) {
    final df = to.file - from.file;
    final dr = to.rank - from.rank;
    if (df == 0 && dr == 0) return;

    final others = <(Square, Piece)>[];
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        if (square == exclude) continue;
        final piece = pieceAt(square);
        if (piece == null) continue;
        if (piece.color != color || piece.type != PieceType.bishop) continue;
        others.add((square, piece));
      }
    }

    for (final (square, piece) in others) {
      if (!canForceMove(square, piece.pieceId)) continue;
      final dest = Square(square.file + df, square.rank + dr);
      if (!isOnBoard(dest)) continue;
      if (piecesAt(dest).isNotEmpty) continue;
      if (isBlocked(dest) || !_isLandingAllowed(dest, forPiece: piece)) {
        continue;
      }
      _clearSquare(square);
      _setPrimary(dest, piece);
      _resolveMineAt(dest);
      _checkColorVowAt(dest);
    }
  }

  Square? _locateMovedPiece(Move move, PieceColor color) {
    if (_teleportA != null && _teleportB != null) {
      if (move.to == _teleportA) {
        final piece = pieceAt(_teleportB!);
        if (piece != null && piece.color == color) return _teleportB;
      }
      if (move.to == _teleportB) {
        final piece = pieceAt(_teleportA!);
        if (piece != null && piece.color == color) return _teleportA;
      }
    }
    final onTo = pieceAt(move.to);
    if (onTo != null && onTo.color == color) return move.to;
    return null;
  }

  /// Returns false if the piece was destroyed by a mine.
  bool _resolveMineAt(Square square) {
    if (!_mines.remove(square)) return true;
    final pieces = piecesAt(square);
    if (pieces.isEmpty) return true;
    final victims = List<Piece>.from(pieces);
    _capturePiecesAt(square);
    for (final victim in victims) {
      if (_hasEffect(victim, AbilityEffect.forTheKing) &&
          !_isSimulatingLegality) {
        if (findKing(victim.color) != null) {
          _beginPeriodicSkillChoice(victim.color);
        }
      }
    }
    return false;
  }

  void _resolveBoomerangReturn(Square from, Square current, PieceColor color) {
    final piece = pieceAt(current);
    if (piece == null || piece.color != color) return;
    if (!_hasEffect(piece, AbilityEffect.boomerangReturn)) return;
    if (current == from) return;
    if (piecesAt(from).isNotEmpty) return;
    if (isBlocked(from) || isGhostCell(from) || !_isLandingAllowed(from)) {
      return;
    }

    var returned = piece;
    for (final ability in piece.abilities.toList()) {
      if (ability.effects.contains(AbilityEffect.boomerangReturn)) {
        returned = returned.withoutAbility(ability);
      }
    }
    _clearSquare(current);
    _setPrimary(from, returned);
  }

  void _resolveTeleportLanding(Square landed, PieceColor color) {
    Square? exit;
    if (_teleportA != null && _teleportB != null) {
      exit = landed == _teleportA
          ? _teleportB
          : landed == _teleportB
          ? _teleportA
          : null;
    }
    if (exit == null &&
        _rules.magicHoovesFrom != null &&
        _rules.magicHoovesTo != null) {
      if (landed == _rules.magicHoovesFrom) {
        exit = _rules.magicHoovesTo;
      }
    }
    if (exit == null) return;
    if (isBlocked(exit) || isGhostCell(exit)) return;

    final occupant = piecesAt(exit);
    if (occupant.isNotEmpty) {
      if (occupant.every((p) => p.color == color)) return;
      _capturePiecesAt(exit, capturingColor: color);
    }

    final piece = pieceAt(landed);
    if (piece == null || piece.color != color) return;
    _clearSquare(landed);
    _setPrimary(exit, piece);
  }

  bool _movesEqual(Move a, Move b) {
    return a == b;
  }


  bool _pieceAllowedToMoveThisTurn(Piece piece) {
    if (_rules.troopFatigueActive && _rules.abilityEffectsActive) {
      final last = piece.color == PieceColor.white
          ? _rules.whiteLastMovedPieceId
          : _rules.blackLastMovedPieceId;
      if (last != null && last == piece.pieceId) return false;
    }
    if (_rules.forcedMovePieceId != null &&
        _rules.forcedMoveOwner == _turn &&
        piece.pieceId != _rules.forcedMovePieceId) {
      return false;
    }
    if (_rules.vetoPieceId != null &&
        _rules.vetoTurnsLeft > 0 &&
        piece.pieceId == _rules.vetoPieceId) {
      return false;
    }
    if (_rules.strikeTurnsLeft > 0 &&
        _rules.strikePieceType != null &&
        piece.type == _rules.strikePieceType) {
      return false;
    }
    if (_rules.symmetryTurnsLeft > 0 &&
        _rules.symmetryVictimColor == _turn &&
        _rules.symmetryRequiredType != null &&
        piece.type != _rules.symmetryRequiredType) {
      return false;
    }
    return true;
  }

  bool _isBoardRuleLegalMove(Move move) {
    final piece = pieceAt(move.from, index: move.pieceIndex);
    if (piece == null) return false;

    if (_rules.architectWalls.isNotEmpty &&
        _moveCrossesArchitectWall(move.from, move.to)) {
      return false;
    }

    if (_requiresMultiAttackToCapture(move)) return false;

    if (_rules.borderClosureTurnsLeft > 0 &&
        _crossesMidRank(move.from, move.to)) {
      return false;
    }

    if (_rules.expeditionaryCorpsActive &&
        _rules.abilityEffectsActive &&
        _onEnemyHalf(piece, move.from) &&
        !_rules.expeditionCaptured.contains(piece.pieceId) &&
        _onOwnHalf(piece, move.to)) {
      return false;
    }

    if (_rules.bonusQuietMoveColor == piece.color) {
      if (_isCapture(move)) return false;
      final snapshot = createSnapshot();
      _turn = piece.color;
      _suppressCaptureSideEffects = true;
      _isSimulatingLegality = true;
      try {
        _applyMove(move);
        if (isInCheck(piece.color.opponent)) return false;
      } finally {
        _suppressCaptureSideEffects = false;
        _isSimulatingLegality = false;
        restoreSnapshot(snapshot);
      }
    }

    if (_rules.sealVictimId == piece.pieceId) return false;

    if (_rules.courtIntrigueVictimId == piece.pieceId &&
        _rules.courtIntrigueQueenId != null &&
        _pieceById(_rules.courtIntrigueQueenId!) != null) {
      final enemyKing = findKing(piece.color);
      if (enemyKing != null) {
        final dist = _chebyshevDistance(move.to, enemyKing);
        if (dist < 2) return false;
      }
    }

    if (_rules.gestureMirrorRequiredLight != null &&
        piece.color == _turn &&
        isSquareLight(move.to) != _rules.gestureMirrorRequiredLight) {
      return false;
    }

    return true;
  }

  bool _requiresMultiAttackToCapture(Move move) {
    if (!_isCapture(move)) return false;
    final attacker = pieceAt(move.from, index: move.pieceIndex);
    final target = pieceAt(move.to);
    if (attacker == null || target == null) return false;
    final needsTwo =
        (_hasEffect(target, AbilityEffect.elusive)) ||
        (_hasEffect(target, AbilityEffect.trench) && target.idleTurns >= 5);
    if (!needsTwo) return false;
    return _countAttackers(move.to, byColor: attacker.color) < 2;
  }

  bool _rangedQuietStepAllowed(Piece piece, int steps) {
    if (!_isRangedSlider(piece.type)) return true;
    if (_rules.myopiaTurnsLeft > 0 && steps > 2) return false;
    if (_rules.collectiveMyopiaActive && steps > 3) return false;
    if (_rules.combatOpticsActive &&
        _rules.abilityEffectsActive &&
        steps > 3) {
      return false;
    }
    return true;
  }

  bool _rangedCaptureStepAllowed(Piece piece, int steps) {
    if (!_isRangedSlider(piece.type)) return true;
    if (_rules.myopiaTurnsLeft > 0 && steps > 2) return false;
    if (_rules.collectiveMyopiaActive && steps > 3) return false;
    // Combat optics: captures unlimited.
    return true;
  }

  bool _isRangedSlider(PieceType type) =>
      type == PieceType.bishop ||
      type == PieceType.rook ||
      type == PieceType.queen;

  bool _crossesMidRank(Square from, Square to) {
    final mid = _rankCount ~/ 2;
    return (from.rank < mid) != (to.rank < mid);
  }

  bool _onEnemyHalf(Piece piece, Square square) {
    final mid = _rankCount / 2;
    return piece.color == PieceColor.white
        ? square.rank >= mid
        : square.rank < mid;
  }

  bool _onOwnHalf(Piece piece, Square square) => !_onEnemyHalf(piece, square);

  int _armyMaterialValue(PieceColor color) {
    var total = 0;
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        for (final piece in piecesAt(Square(file, rank))) {
          if (piece.color != color || piece.type == PieceType.king) continue;
          total += BoardCataclysmState.pieceCombatValue(piece.type);
        }
      }
    }
    return total;
  }

  List<Square> _generateSecretRoute() {
    final route = <Square>[];
    while (route.length < 3) {
      final square = Square(_random.nextInt(_fileCount), _random.nextInt(_rankCount));
      if (!route.contains(square)) route.add(square);
    }
    return route;
  }

  String? _pickRandomNonKing(PieceColor color) {
    final ids = <String>[];
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        for (final piece in piecesAt(Square(file, rank))) {
          if (piece.color == color && piece.type != PieceType.king) {
            ids.add(piece.pieceId);
          }
        }
      }
    }
    if (ids.isEmpty) return null;
    return ids[_random.nextInt(ids.length)];
  }

  void _tickBoardRuleDurations(PieceColor finished) {
    if (_rules.borderClosureTurnsLeft > 0) _rules.borderClosureTurnsLeft--;
    if (_rules.myopiaTurnsLeft > 0) _rules.myopiaTurnsLeft--;
    if (_rules.magicShutdownTurnsLeft > 0) _rules.magicShutdownTurnsLeft--;
    if (_rules.strikeTurnsLeft > 0) {
      _rules.strikeTurnsLeft--;
      if (_rules.strikeTurnsLeft <= 0) _rules.strikePieceType = null;
    }
    if (_rules.symmetryTurnsLeft > 0 &&
        _rules.symmetryVictimColor == finished) {
      _rules.symmetryTurnsLeft--;
      if (_rules.symmetryTurnsLeft <= 0) {
        _rules.symmetryRequiredType = null;
        _rules.symmetryVictimColor = null;
        _rules.symmetryChooserColor = null;
      }
    }
    if (_rules.vetoTurnsLeft > 0 && _rules.vetoOwner == finished) {
      _rules.vetoTurnsLeft--;
      if (_rules.vetoTurnsLeft <= 0) {
        _rules.vetoPieceId = null;
        _rules.vetoOwner = null;
      }
    }
    if (_rules.timeCapsuleRemainingPlies > 0) {
      _rules.timeCapsuleRemainingPlies--;
    }
    if (_rules.meatGrinderTurnsLeft > 0) {
      _rules.meatGrinderTurnsLeft--;
    }
    if (_rules.avengePlyLeft > 0) {
      _rules.avengePlyLeft--;
      if (_rules.avengePlyLeft <= 0) {
        _rules.avengeCaptureSquare = null;
        _rules.avengeVictimColor = null;
      }
    }
    _tickQuicksandSkips(finished);
    _tickFrostMap(finished);
    _tickScorchingSun();
    _tickIdleTurns(finished);
  }

  void _tickQuicksandSkips(PieceColor finished) {
    final ids = _rules.quicksandSkipLeft.keys.toList();
    for (final id in ids) {
      final ref = _pieceById(id);
      if (ref == null) {
        _rules.quicksandSkipLeft.remove(id);
        continue;
      }
      if (ref.piece.color != finished) continue;
      final left = (_rules.quicksandSkipLeft[id] ?? 0) - 1;
      if (left <= 0) {
        _rules.quicksandSkipLeft.remove(id);
      } else {
        _rules.quicksandSkipLeft[id] = left;
      }
    }
  }

  void _tickFrostMap(PieceColor finished) {
    if (!_rules.frostMapActive) return;
    final torchSet = <String>{
      ..._rules.torchPieceIds[PieceColor.white] ?? const {},
      ..._rules.torchPieceIds[PieceColor.black] ?? const {},
    };
    final torchSquares = <Square>{};
    for (final id in torchSet) {
      final ref = _pieceById(id);
      if (ref != null) torchSquares.add(ref.square);
    }

    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        final pieces = piecesAt(square);
        for (var i = 0; i < pieces.length; i++) {
          final piece = pieces[i];
          if (piece.color != finished) continue;
          if (piece.type == PieceType.king) continue;

          var frost = piece.frostLevel.clamp(0, 3);
          if (torchSet.contains(piece.pieceId)) {
            frost = 0;
          } else {
            final nearTorch = torchSquares.any(
              (t) => _chebyshevDistance(t, square) == 1,
            );
            if (nearTorch) {
              frost = (frost - 1).clamp(0, 3);
            } else {
              frost = (frost + 1).clamp(0, 3);
            }
          }

          if (frost != piece.frostLevel) {
            _replacePieceAt(square, i, piece.copyWith(frostLevel: frost));
          }
          if (frost >= 3) {
            _rules.frozenPieceIds.add(piece.pieceId);
          } else {
            _rules.frozenPieceIds.remove(piece.pieceId);
          }
          _rules.frostIdleTurns[piece.pieceId] = frost;
        }
      }
    }
  }

  void _tickScorchingSun() {
    if (!_rules.scorchingSunActive) return;
    final toKillIds = <String>[];
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        final pieces = piecesAt(square);
        final onSun = _rules.sunSquares.contains(square);
        for (var i = 0; i < pieces.length; i++) {
          final piece = pieces[i];
          if (piece.type == PieceType.king) continue;
          var heat = piece.heatLevel;
          if (onSun) {
            heat = (heat + 1).clamp(0, 3);
          } else if (heat > 0) {
            heat = heat - 1;
          }
          if (heat != piece.heatLevel) {
            _replacePieceAt(square, i, piece.copyWith(heatLevel: heat));
          }
          if (heat >= 3) {
            toKillIds.add(piece.pieceId);
          }
        }
      }
    }
    // Remove overheated pieces one by one.
    for (final id in toKillIds) {
      final ref = _pieceById(id);
      if (ref == null) continue;
      if (ref.piece.heatLevel < 3) continue;
      _onFinalDeath(
        ref.piece,
        ref.square,
        reason: GraveyardReason.ability,
      );
      final stack = piecesAt(ref.square).toList();
      stack.removeWhere((p) => p.pieceId == id);
      if (stack.isEmpty) {
        _clearSquare(ref.square);
      } else {
        _setCell(ref.square, stack);
      }
    }

    _rules.sunPliesUntilRotate--;
    if (_rules.sunPliesUntilRotate <= 0) {
      _rules.sunPliesUntilRotate = 10;
      _rotateSunSquares(count: 3 + _random.nextInt(4));
    }
  }

  void _resolvePassiveAggression(
    PieceColor finished, {
    required bool gaveCheck,
  }) {
    if (!_rules.passiveAggressionActive || isGameOver) return;
    if (gaveCheck) {
      if (finished == PieceColor.white) {
        _rules.whitePassiveAggression = 10;
      } else {
        _rules.blackPassiveAggression = 10;
      }
      return;
    }
    if (finished == PieceColor.white) {
      _rules.whitePassiveAggression--;
      if (_rules.whitePassiveAggression <= 0) {
        _finishGame(
          winner: PieceColor.black,
          reason: GameEndReason.alternativeVictory,
          detail: 'passiveAggression',
        );
      }
    } else {
      _rules.blackPassiveAggression--;
      if (_rules.blackPassiveAggression <= 0) {
        _finishGame(
          winner: PieceColor.white,
          reason: GameEndReason.alternativeVictory,
          detail: 'passiveAggression',
        );
      }
    }
  }

  void _maybeRestoreTimeCapsule() {
    if (_rules.timeCapsuleRemainingPlies != 0) return;
    final saved = _rules.timeCapsuleBoard;
    if (saved == null) return;

    final abilityById = <String, Set<GameAbility>>{};
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        for (final piece in piecesAt(Square(file, rank))) {
          abilityById[piece.pieceId] = Set<GameAbility>.from(piece.abilities);
        }
      }
    }
    for (final piece in _stackExtra.values) {
      abilityById[piece.pieceId] = Set<GameAbility>.from(piece.abilities);
    }

    _board = saved.map((row) => List<Piece?>.from(row)).toList();
    _stackExtra
      ..clear()
      ..addAll(_rules.timeCapsuleStackExtra ?? const {});

    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        final pieces = piecesAt(square);
        if (pieces.isEmpty) continue;
        final updated = <Piece>[];
        for (final piece in pieces) {
          final abilities = abilityById[piece.pieceId];
          updated.add(
            abilities == null ? piece : piece.copyWith(abilities: abilities),
          );
        }
        _setCell(square, updated);
      }
    }

    _rules.timeCapsuleBoard = null;
    _rules.timeCapsuleStackExtra = null;
  }

  void _clearForcedMoveIfUnusable() {
    if (_rules.forcedMovePieceId == null || _rules.forcedMoveOwner != _turn) {
      return;
    }
    final ref = _pieceById(_rules.forcedMovePieceId);
    if (ref == null) {
      _rules.forcedMovePieceId = null;
      _rules.forcedMoveOwner = null;
      return;
    }
    final moves = _getPseudoLegalMoves(
      ref.square,
      ref.piece,
      pieceIndex: ref.index,
    ).where(_isLegalMove).where(_isBoardRuleLegalMove).toList();
    if (moves.isEmpty) {
      _rules.forcedMovePieceId = null;
      _rules.forcedMoveOwner = null;
    }
  }

  void _resolveBoardRulesAfterMove(
    Move move,
    Piece moverBefore,
    ({Square square, int index, Piece piece}) current, {
    required bool captured,
  }) {
    final color = current.piece.color;
    final moverId = moverBefore.pieceId;

    if (_rules.troopFatigueActive ||
        _rules.frostMapActive ||
        _rules.swampActive) {
      if (color == PieceColor.white) {
        _rules.whiteLastMovedPieceId = moverId;
      } else {
        _rules.blackLastMovedPieceId = moverId;
      }
    }

    if (_rules.forcedMovePieceId == moverId) {
      _rules.forcedMovePieceId = null;
      _rules.forcedMoveOwner = null;
    }

    if (_rules.symmetryChooserColor == color && _rules.symmetryTurnsLeft > 0) {
      _rules.symmetryRequiredType = moverBefore.type;
    }

    if (_rules.expeditionaryCorpsActive) {
      if (captured && _onEnemyHalf(moverBefore, move.to)) {
        _rules.expeditionCaptured.add(moverId);
      }
      if (_onOwnHalf(current.piece, current.square)) {
        _rules.expeditionCaptured.remove(moverId);
      }
    }

    if (_rules.kingOfHillActive && !isGameOver) {
      _rules.territory[current.square] = color;
      var owned = 0;
      for (final owner in _rules.territory.values) {
        if (owner == color) owned++;
      }
      if (owned > 48) {
        _finishGame(
          winner: color,
          reason: GameEndReason.alternativeVictory,
          detail: 'kingOfHill',
        );
        return;
      }
    }

    final route = _rules.secretRoutes[color];
    if (route != null && route.isNotEmpty && !isGameOver) {
      final progress = _rules.secretRouteProgress[color] ?? 0;
      if (progress < route.length && current.square == route[progress]) {
        final next = progress + 1;
        _rules.secretRouteProgress[color] = next;
        if (next >= route.length) {
          _finishGame(
            winner: color,
            reason: GameEndReason.alternativeVictory,
            detail: 'secretRoute',
          );
          return;
        }
      }
    }

    if (_rules.royalPilgrimageActive &&
        moverBefore.type == PieceType.king &&
        !isGameOver) {
      final backRank =
          color == PieceColor.white ? _rankCount - 1 : 0;
      if (current.square.rank == backRank && !isInCheck(color)) {
        _finishGame(
          winner: color,
          reason: GameEndReason.alternativeVictory,
          detail: 'royalPilgrimage',
        );
        return;
      }
    }

    if (_rules.wordOfHonorColor == color &&
        _rules.wordOfHonorSquare != null &&
        !_isSimulatingLegality) {
      final pledged = _rules.wordOfHonorSquare!;
      _rules.wordOfHonorSquare = null;
      _rules.wordOfHonorColor = null;
      if (current.square == pledged) {
        if (!isAwaitingSkillChoice) {
          _beginPeriodicSkillChoice(color);
        }
      } else {
        _stripRandomAbilityFrom(color);
      }
    }

    _resolveExpansionAfterMove(move, moverBefore, current, captured: captured);
  }

  void _resolveExpansionAfterMove(
    Move move,
    Piece moverBefore,
    ({Square square, int index, Piece piece}) current, {
    required bool captured,
  }) {
    if (_isSimulatingLegality || isGameOver) return;
    final color = moverBefore.color;
    final moverId = moverBefore.pieceId;

    // Re-read mover: board rules may have mutated abilities already.
    final live = _pieceById(moverId) ?? current;
    _replacePieceAt(
      live.square,
      live.index,
      live.piece.copyWith(idleTurns: 0),
    );

    if (captured && _rules.onlyEqualsKillActive && _lastCapturedType != null) {
      if (_lastCapturedType == moverBefore.type) {
        final next = (_rules.sameTypeCaptureCounts[color] ?? 0) + 1;
        _rules.sameTypeCaptureCounts[color] = next;
        if (next >= 5) {
          _finishGame(
            winner: color,
            reason: GameEndReason.alternativeVictory,
            detail: 'onlyEqualsKill',
          );
          return;
        }
      }
    }

    if (_rules.desertersActive &&
        moverBefore.type == PieceType.pawn &&
        _rules.deserterPawnIds[color] == moverId &&
        !_rules.revealedDeserters.contains(moverId) &&
        _onEnemyHalf(moverBefore, current.square)) {
      _rules.revealedDeserters.add(moverId);
      _replacePieceAt(
        current.square,
        current.index,
        current.piece.copyWith(color: color.opponent),
      );
    }

    if (_hasEffect(moverBefore, AbilityEffect.doppelgangers) ||
        (_hasEffect(moverBefore, AbilityEffect.doppelgangerOnce) &&
            !moverBefore.doppelgangerOnceUsed)) {
      _rules.knightIllusions.add((square: move.from, color: color));
      if (_hasEffect(moverBefore, AbilityEffect.doppelgangerOnce)) {
        final refreshed = _pieceById(moverId);
        if (refreshed != null) {
          _replacePieceAt(
            refreshed.square,
            refreshed.index,
            refreshed.piece.copyWith(doppelgangerOnceUsed: true),
          );
        }
      }
    }

    if (moverBefore.stompPending ||
        (_hasEffect(moverBefore, AbilityEffect.stomp) &&
            moverBefore.stompPending)) {
      _applyStompAway(current.square, color);
      final refreshed = _pieceById(moverId);
      if (refreshed != null) {
        _replacePieceAt(
          refreshed.square,
          refreshed.index,
          refreshed.piece.copyWith(stompPending: false),
        );
      }
    }

    if (_hasEffect(moverBefore, AbilityEffect.surveyor)) {
      _rules.surveyorSafeSquares
          .putIfAbsent(moverId, () => {})
          .add(current.square);
    }

    if (moverBefore.type == PieceType.knight &&
        _sideHasCornerQuest(color)) {
      final corners = _cornerSquares();
      if (corners.contains(current.square)) {
        final key = color == PieceColor.white ? 'white' : 'black';
        final visits = _rules.cornerQuestVisits.putIfAbsent(key, () => {});
        visits.add(current.square);
        if (visits.length >= 3) {
          _finishGame(
            winner: color,
            reason: GameEndReason.alternativeVictory,
            detail: 'cornerQuest',
          );
          return;
        }
      }
    }

    if (_rules.fullCircleActive && moverBefore.type == PieceType.rook) {
      final corners = _cornerSquares();
      if (corners.contains(current.square)) {
        final visits = _rules.rookCornerVisits.putIfAbsent(moverId, () => {});
        visits.add(current.square);
        if (corners.every(visits.contains)) {
          _finishGame(
            winner: color,
            reason: GameEndReason.alternativeVictory,
            detail: 'fullCircle',
          );
          return;
        }
      }
    }

    if (_rules.swampActive) {
      final refreshed = _pieceById(moverId);
      if (refreshed != null) {
        // sticky-style: tick at end of this turn → skip next owner turn.
        _replacePieceAt(
          refreshed.square,
          refreshed.index,
          refreshed.piece.copyWith(
            skipTurnsLeft: max(refreshed.piece.skipTurnsLeft, 2),
          ),
        );
      }
    }

    if (_rules.quicksandHidden.contains(current.square) ||
        _rules.quicksandRevealed.contains(current.square)) {
      if (_rules.quicksandHidden.remove(current.square)) {
        _rules.quicksandRevealed.add(current.square);
      }
      final duration = _rules.quicksandDuration[current.square] ?? 3;
      // +1 because end-of-turn tick runs after this move.
      _rules.quicksandSkipLeft[moverId] = max(
        _rules.quicksandSkipLeft[moverId] ?? 0,
        duration + 1,
      );
    }

    if (moverBefore.magicHoovesPending ||
        (_hasEffect(moverBefore, AbilityEffect.magicHooves) &&
            moverBefore.magicHoovesPending)) {
      _rules.magicHoovesFrom = move.from;
      _rules.magicHoovesTo = current.square;
      final refreshed = _pieceById(moverId);
      if (refreshed != null) {
        _replacePieceAt(
          refreshed.square,
          refreshed.index,
          refreshed.piece.copyWith(magicHoovesPending: false),
        );
      }
    }

    if (_rules.pendingRideKnightId == moverId &&
        _rules.pendingRidePawnId != null) {
      _applyRidePassenger(move, moverId, _rules.pendingRidePawnId!);
      _rules.pendingRideKnightId = null;
      _rules.pendingRidePawnId = null;
    }

    if (_hasEffect(moverBefore, AbilityEffect.crusade) && captured) {
      final n = (_rules.crusadeCaptureCounts[moverId] ?? 0) + 1;
      _rules.crusadeCaptureCounts[moverId] = n;
      if (n == 2) {
        final pool = List<GameAbility>.from(AbilityCatalog.randomAbilities)
          ..shuffle(_random);
        if (pool.isNotEmpty) {
          _applyOffer(
            color,
            AbilityOffer(
              ability: pool.first,
              applyMode: AbilityApplyMode.boardWide,
            ),
            null,
          );
        }
      }
    }

    if (_hasEffect(moverBefore, AbilityEffect.post)) {
      if (captured) {
        _rules.postQuietMoveCounts[moverId] = 0;
      } else {
        final n = (_rules.postQuietMoveCounts[moverId] ?? 0) + 1;
        _rules.postQuietMoveCounts[moverId] = n;
        if (n >= 3 && !isAwaitingSkillChoice) {
          _rules.postQuietMoveCounts[moverId] = 0;
          _rules.queuedSkillChoices = 2;
          _beginPeriodicSkillChoice(color);
        }
      }
    }

    if (_rules.letterHActive) {
      _checkLetterHVictory(color);
    }

    if (_hasEffect(moverBefore, AbilityEffect.caravan) &&
        !captured &&
        moverBefore.type == PieceType.pawn &&
        current.square.file == move.from.file) {
      _applyCaravanFollow(move.from, current.square, color);
    }

    if (_hasEffect(moverBefore, AbilityEffect.glassCeiling) && !captured) {
      final df = (current.square.file - move.from.file).sign;
      final dr = (current.square.rank - move.from.rank).sign;
      if (df != 0 && dr != 0) {
        var f = move.from.file + df;
        var r = move.from.rank + dr;
        while (f != current.square.file || r != current.square.rank) {
          final mid = Square(f, r);
          final pieces = piecesAt(mid);
          for (var i = 0; i < pieces.length; i++) {
            final enemy = pieces[i];
            if (enemy.color != color) {
              _replacePieceAt(
                mid,
                i,
                enemy.copyWith(skipTurnsLeft: max(enemy.skipTurnsLeft, 1)),
              );
            }
          }
          f += df;
          r += dr;
        }
      }
    }
  }

  bool _sideHasCornerQuest(PieceColor color) {
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        for (final piece in piecesAt(Square(file, rank))) {
          if (piece.color == color &&
              _hasEffect(piece, AbilityEffect.cornerQuest)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  void _stripRandomAbilityFrom(PieceColor color) {
    final candidates = <({Square square, int index, Piece piece})>[];
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        final pieces = piecesAt(square);
        for (var index = 0; index < pieces.length; index++) {
          final piece = pieces[index];
          if (piece.color == color && piece.abilities.isNotEmpty) {
            candidates.add((square: square, index: index, piece: piece));
          }
        }
      }
    }
    if (candidates.isEmpty) return;
    final target = candidates[_random.nextInt(candidates.length)];
    final abilities = target.piece.abilities.toList();
    abilities.shuffle(_random);
    _replacePieceAt(
      target.square,
      target.index,
      target.piece.withoutAbility(abilities.first),
    );
    _refreshDoppelgangerFlags();
  }

  void _applyCaravanFollow(Square from, Square to, PieceColor color) {
    final dir = to.rank - from.rank;
    if (dir == 0 || to.file != from.file) return;
    final step = dir.sign;
    var behindRank = from.rank - step;
    while (behindRank >= 0 && behindRank < _rankCount) {
      final square = Square(from.file, behindRank);
      final pieces = piecesAt(square);
      final pawn = pieces.cast<Piece?>().firstWhere(
        (p) => p!.color == color && p.type == PieceType.pawn,
        orElse: () => null,
      );
      if (pawn == null) break;
      final dest = Square(from.file, behindRank + step);
      if (piecesAt(dest).isNotEmpty || isBlocked(dest)) break;
      _clearSquare(square);
      _setPrimary(dest, pawn.copyWith(hasMoved: true, idleTurns: 0));
      behindRank -= step;
    }
  }

  void _activateDeserters() {
    _rules.desertersActive = true;
    for (final color in PieceColor.values) {
      final pawns = <String>[];
      for (var rank = 0; rank < _rankCount; rank++) {
        for (var file = 0; file < _fileCount; file++) {
          for (final piece in piecesAt(Square(file, rank))) {
            if (piece.color == color && piece.type == PieceType.pawn) {
              pawns.add(piece.pieceId);
            }
          }
        }
      }
      if (pawns.isNotEmpty) {
        _rules.deserterPawnIds[color] = pawns[_random.nextInt(pawns.length)];
      }
    }
  }

  void _activateQuicksand({required int cellCount, required int duration}) {
    final candidates = <Square>[];
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        if (piecesAt(square).isNotEmpty) continue;
        if (isGhostCell(square) || isBlocked(square)) continue;
        candidates.add(square);
      }
    }
    candidates.shuffle(_random);
    final picked = candidates.take(cellCount.clamp(2, 5)).toList();
    _rules.quicksandHidden
      ..clear()
      ..addAll(picked);
    for (final square in picked) {
      _rules.quicksandDuration[square] = duration.clamp(2, 5);
    }
  }

  void _activateFrostMap() {
    _rules.frostMapActive = true;
    _rules.frostIdleTurns.clear();
    _rules.frozenPieceIds.clear();
    // All pieces start at frost stage 0.
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        final pieces = piecesAt(square);
        for (var i = 0; i < pieces.length; i++) {
          final piece = pieces[i];
          if (piece.frostLevel != 0) {
            _replacePieceAt(square, i, piece.copyWith(frostLevel: 0));
          }
        }
      }
    }
    for (final color in PieceColor.values) {
      final eligible = <String>[];
      for (var rank = 0; rank < _rankCount; rank++) {
        for (var file = 0; file < _fileCount; file++) {
          final square = Square(file, rank);
          for (final piece in piecesAt(square)) {
            if (piece.color != color || piece.type == PieceType.king) continue;
            // Exclude edge starting pawns a2/h2 / a7/h7 (and shifted equivalents).
            if (piece.type == PieceType.pawn) {
              final homeRank = color == PieceColor.white ? 1 : _rankCount - 2;
              final edgeFiles = {0, _fileCount - 1};
              if (square.rank == homeRank && edgeFiles.contains(square.file)) {
                continue;
              }
            }
            eligible.add(piece.pieceId);
          }
        }
      }
      eligible.shuffle(_random);
      _rules.torchPieceIds[color] = eligible.take(3).toSet();
    }
  }

  void _transferTorchOnDeath(Piece dead, Square deathSquare) {
    if (!_rules.frostMapActive) return;
    final ownerTorches = _rules.torchPieceIds[dead.color];
    if (ownerTorches == null || !ownerTorches.remove(dead.pieceId)) return;

    final candidates = <({String id, int dist})>[];
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        for (final piece in piecesAt(square)) {
          if (piece.color != dead.color) continue;
          if (piece.pieceId == dead.pieceId) continue;
          if (piece.type == PieceType.king) continue;
          if (ownerTorches.contains(piece.pieceId)) continue;
          candidates.add((
            id: piece.pieceId,
            dist: _chebyshevDistance(deathSquare, square),
          ));
        }
      }
    }
    if (candidates.isEmpty) return;
    candidates.sort((a, b) => a.dist.compareTo(b.dist));
    final nearestDist = candidates.first.dist;
    final nearest = candidates.where((c) => c.dist == nearestDist).toList();
    ownerTorches.add(nearest[_random.nextInt(nearest.length)].id);
  }

  void _activateScorchingSun() {
    _rules.scorchingSunActive = true;
    _rules.sunPliesUntilRotate = 10;
    _rotateSunSquares(count: 3 + _random.nextInt(4));
  }

  void _rotateSunSquares({required int count}) {
    final all = <Square>[];
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        all.add(Square(file, rank));
      }
    }
    all.shuffle(_random);
    _rules.sunSquares
      ..clear()
      ..addAll(all.take(count.clamp(3, 6)));
  }

  void _activateTurncoats() {
    _rules.turncoatsActive = true;
    _rules.turncoatSpyIds.clear();
    _rules.revealedTurncoats.clear();
    for (final color in PieceColor.values) {
      final light = <String>[];
      for (var rank = 0; rank < _rankCount; rank++) {
        for (var file = 0; file < _fileCount; file++) {
          for (final piece in piecesAt(Square(file, rank))) {
            if (piece.color != color) continue;
            if (piece.type == PieceType.knight ||
                piece.type == PieceType.bishop) {
              light.add(piece.pieceId);
            }
          }
        }
      }
      if (light.isEmpty) continue;
      _rules.turncoatSpyIds[color] = light[_random.nextInt(light.length)];
    }
  }

  void _applyExpandedModOffer(PieceColor color, AbilityOffer offer) {
    switch (offer.ability) {
      case GameAbility.modeTimeZone:
        _rules.timeZoneActive = true;
        // Secret: chooser gets odd hour if rng even, else even — both get opposite.
        final whiteOdd = _random.nextBool();
        _rules.timeZoneOddHour[PieceColor.white] = whiteOdd;
        _rules.timeZoneOddHour[PieceColor.black] = !whiteOdd;
      case GameAbility.modeMateVeto:
        final enemyPieces = <String>[];
        for (var r = 0; r < _rankCount; r++) {
          for (var f = 0; f < _fileCount; f++) {
            for (final p in piecesAt(Square(f, r))) {
              if (p.color == color.opponent && p.type != PieceType.king) {
                enemyPieces.add(p.pieceId);
              }
            }
          }
        }
        if (enemyPieces.isNotEmpty) {
          _rules.mateVetoEnemyPieceId[color] =
              enemyPieces[_random.nextInt(enemyPieces.length)];
        }
      case GameAbility.modeDebtPit:
        _rules.debtPitActive = true;
        _rules.whiteDebt = 0;
        _rules.blackDebt = 0;
      case GameAbility.modeWasteland:
        _rules.wastelandActive = true;
      case GameAbility.modeBus:
        _rules.busActive = true;
      case GameAbility.modeShopToken:
        _rules.shopTokenActive = true;
      case GameAbility.modeSeasons:
        _rules.seasonsActive = true;
        _rules.seasonIndex = 0;
        _rules.seasonFullMoves = 0;
      case GameAbility.modeBloodFeud:
        _rules.bloodFeudActive = true;
        _rules.bloodFeudBanner =
            'Кровная вражда — если не отомстить за фигуру за 2 хода, соперник получит мод';
      case GameAbility.modePrioritySetup:
        _activatePrioritySetup(offer);
      case GameAbility.modeBrokenPerspective:
        _rules.brokenPerspectiveActive = true;
      case GameAbility.modeCallOf22:
        _activateCallOf22();
      case GameAbility.modeKriegspiel:
        _rules.kriegspielActive = true;
      case GameAbility.modeKingCenter:
        _rules.kingCenterActive = true;
      case GameAbility.modeAtomic:
        _rules.atomicActive = true;
      case GameAbility.modeCrazyhouse:
        _rules.crazyhouseActive = true;
      case GameAbility.modeDuckChess:
        _rules.duckChessActive = true;
        _rules.duckNeedsPlacement = true;
      case GameAbility.boardInkBlot:
        _rules.inkBlotActive = true;
      case GameAbility.boardGravityWell:
        final cell = offer.targetCell ?? _randomEmptySquare();
        if (cell != null) _rules.gravityWellSquare = cell;
      case GameAbility.boardIdealSymmetry:
        _applyIdealSymmetry();
      case GameAbility.boardShadowRight:
        final id = offer.hiddenData['pieceId'] as String? ??
            _pickRandomNonKing(color);
        if (id != null) {
          _rules.shadowPieceId = id;
          _rules.shadowJumpAvailable = true;
        }
      case GameAbility.boardCenterTax:
        _rules.centerTaxActive = true;
      case GameAbility.boardWalkingCastle:
        _rules.walkingCastleActive = true;
      case GameAbility.boardInvisibleHand:
        _rules.invisibleHandPlies = 0;
      case GameAbility.boardRiver:
        _rules.riverRank = offer.quakeRank ?? (2 + _random.nextInt(_rankCount - 4));
        _rules.riverDirection = _random.nextBool() ? 1 : -1;
      case GameAbility.boardForbiddenLetter:
        _rules.forbiddenFile =
            offer.silentFile ?? _random.nextInt(_fileCount.clamp(1, 8));
        _rules.forbiddenFilePlies = (offer.durationMoves ?? 6) * 2;
      case GameAbility.boardEarnedRest:
        _rules.earnedRestSquare =
            offer.targetCell ?? _randomEmptySquare();
      case GameAbility.randomMoveSteal:
        _rules.moveStealPending = true;
      case GameAbility.randomSerialManiac:
        _resolveSerialManiac();
      case GameAbility.randomSnailTrail:
        _rules.snailTrailPieceId =
            offer.hiddenData['pieceId'] as String? ?? _pickRandomNonKing(color);
      case GameAbility.randomDisinfo:
        _activateDisinfo();
      case GameAbility.randomFamilyContract:
        final types = PieceType.values
            .where((t) => t != PieceType.king)
            .toList();
        _rules.familyContractType = types[_random.nextInt(types.length)];
        _rules.familyContractOwner = color;
        _rules.familyContractMoves = 0;
      case GameAbility.randomKansasHurricanes:
        _rules.kansasTyphoon = _randomEmptySquare();
        _rules.kansasPlies = 0;
        _advanceKansasNext();
      case GameAbility.randomLoneWarrior:
        _rules.loneWarriorPieceId =
            offer.hiddenData['pieceId'] as String? ?? _pickRandomNonKing(color);
      case GameAbility.randomTwentyOne:
        // Resolved via UI; mark active for HUD.
        _rules.twentyOneResolved = false;
      case GameAbility.modeHolyRandom:
        _rules.holyRandomActive = true;
      case GameAbility.modeZooShuffle:
        _applyZooShuffle();
      case GameAbility.modeInsatiableHunger:
        _rules.insatiableHungerActive = true;
        _initQueenHungerCounters();
      case GameAbility.modeComeOn:
        _rules.comeOnActive = true;
        _rules.comeOnConsumed = false;
      case GameAbility.modeVolcano:
        _rules.volcanoActive = true;
        _rules.volcanoPliesLeft = 4;
        _rerollVolcanoSquares();
      case GameAbility.boardRestlessKings:
        _rules.restlessKingsPliesLeft = 3;
        for (final c in PieceColor.values) {
          final k = findKing(c);
          if (k != null) _rules.restlessKingStart[c] = k;
        }
      case GameAbility.randomWarehouse:
        _rules.warehouseActive = true;
      case GameAbility.randomTwilightEclipse:
        _activateTwilightEclipse(color);
      case GameAbility.randomGestureMirror:
        _rules.gestureMirrorPending = true;
      case GameAbility.randomBlackMark:
        final id = _pickRandomNonKing(color.opponent);
        if (id != null) {
          _rules.blackMarkPieceId = id;
          _rules.blackMarkChooser = color;
        }
      default:
        break;
    }
  }

  void _applyZooShuffle() {
    if (_rules.zooShuffleApplied) return;
    _rules.zooShuffleApplied = true;
    for (final color in PieceColor.values) {
      final back = color == PieceColor.white ? 0 : _rankCount - 1;
      // Classic: b=1 bishop, c=2 knight, f=5 knight, g=6 bishop → swap to
      // knights on c/f (already) wait user wants: knights on c&f, bishops on b&g
      // Standard start already has that. Zoo shuffle means CURRENT knights and
      // bishops swap places: N↔B on those files.
      final pairs = <(int, int)>[(1, 2), (6, 5)]; // (bishopFile, knightFile)
      for (final (bFile, nFile) in pairs) {
        final bSq = Square(bFile, back);
        final nSq = Square(nFile, back);
        final b = pieceAt(bSq);
        final n = pieceAt(nSq);
        if (b == null || n == null) continue;
        if (b.color != color || n.color != color) continue;
        // Swap contents regardless of current types (handles already-moved).
        _setPrimary(bSq, n);
        _setPrimary(nSq, b);
      }
      // Also swap any knight/bishop that are still on each other's classic files
      // if the above didn't catch mid-game pieces — for start this is enough.
    }
  }

  void _initQueenHungerCounters() {
    for (var r = 0; r < _rankCount; r++) {
      for (var f = 0; f < _fileCount; f++) {
        for (final p in piecesAt(Square(f, r))) {
          if (p.type == PieceType.queen) {
            _rules.queenHungerPlies[p.pieceId] = 0;
          }
        }
      }
    }
  }

  void _rerollVolcanoSquares() {
    _rules.volcanoSquares.clear();
    final empties = <Square>[];
    final all = <Square>[];
    for (var r = 0; r < _rankCount; r++) {
      for (var f = 0; f < _fileCount; f++) {
        final s = Square(f, r);
        all.add(s);
        if (piecesAt(s).isEmpty) empties.add(s);
      }
    }
    final pool = List<Square>.from(all)..shuffle(_random);
    for (final s in pool) {
      if (_rules.volcanoSquares.length >= 2) break;
      _rules.volcanoSquares.add(s);
    }
  }

  void _activateTwilightEclipse(PieceColor color) {
    _rules.twilightOwner = color;
    _rules.twilightOwnerPliesLeft = 10;
    _rules.twilightInvisibleUntilPly.clear();
    final candidates = <String>[];
    for (var r = 0; r < _rankCount; r++) {
      for (var f = 0; f < _fileCount; f++) {
        for (final p in piecesAt(Square(f, r))) {
          if (p.color == color) candidates.add(p.pieceId);
        }
      }
    }
    candidates.shuffle(_random);
    for (final id in candidates.take(4)) {
      _rules.twilightInvisibleUntilPly[id] = _rules.globalPlyIndex + 20;
    }
  }

  void _maybeHolyRandomTransform(Piece mover) {
    if (!_rules.holyRandomActive || _isSimulatingLegality) return;
    if (mover.type == PieceType.king) return;
    if (_random.nextDouble() >= 0.25) return;
    final ref = _pieceById(mover.pieceId);
    if (ref == null) return;
    final options = PieceType.values
        .where((t) => t != PieceType.king && t != ref.piece.type)
        .toList();
    if (options.isEmpty) return;
    final next = options[_random.nextInt(options.length)];
    _replacePieceAt(
      ref.square,
      ref.index,
      ref.piece.copyWith(type: next),
    );
  }

  void _maybeMaskOrGaneshaSwap(Piece moverBefore, Square at) {
    PieceType? nextType;
    if (_hasEffect(moverBefore, AbilityEffect.maskSwap)) {
      nextType = moverBefore.type == PieceType.knight
          ? PieceType.bishop
          : (moverBefore.type == PieceType.bishop ? PieceType.knight : null);
    } else if (_hasEffect(moverBefore, AbilityEffect.bishopGanesha)) {
      nextType = moverBefore.type == PieceType.bishop
          ? PieceType.rook
          : (moverBefore.type == PieceType.rook ? PieceType.bishop : null);
    }
    if (nextType == null) return;
    final ref = _pieceById(moverBefore.pieceId);
    if (ref == null) return;
    _replacePieceAt(
      ref.square,
      ref.index,
      ref.piece.copyWith(type: nextType),
    );
  }

  void _activatePrioritySetup(AbilityOffer offer) {
    _rules.prioritySetupActive = true;
    final fromOffer = offer.route;
    if (fromOffer.length >= 4) {
      _rules.priorityCells
        ..clear()
        ..addAll(fromOffer.take(4));
      return;
    }
    final left = <Square>[];
    final right = <Square>[];
    for (var r = 0; r < _rankCount; r++) {
      for (var f = 0; f < _fileCount; f++) {
        final s = Square(f, r);
        if (piecesAt(s).isNotEmpty) continue;
        if (f <= 3) {
          left.add(s);
        } else if (f >= 4) {
          right.add(s);
        }
      }
    }
    left.shuffle(_random);
    right.shuffle(_random);
    _rules.priorityCells
      ..clear()
      ..addAll([...left.take(2), ...right.take(2)]);
  }

  void _activateCallOf22() {
    if (_fileCount < 10) {
      if (_extraFileOnLeft != true) _insertExtraFileLeft();
      if (_fileCount < 10) {
        for (var rank = 0; rank < _rankCount; rank++) {
          _board[rank].add(null);
        }
        _fileCount += 1;
        _shiftSpecialSquaresFile(insertOnLeft: false);
      }
    }
    // z-file = 0, i-file = fileCount-1; pawns on ranks 1 and 6.
    void place(int file, int rank, PieceColor color) {
      final sq = Square(file, rank);
      if (piecesAt(sq).isNotEmpty) return;
      _setPrimary(
        sq,
        Piece(
          pieceId: 'call22-${color.name}-$file-$rank',
          type: PieceType.pawn,
          color: color,
        ),
      );
    }

    place(0, 1, PieceColor.white);
    place(_fileCount - 1, 1, PieceColor.white);
    place(0, _rankCount - 2, PieceColor.black);
    place(_fileCount - 1, _rankCount - 2, PieceColor.black);
  }

  void _applyIdealSymmetry() {
    final mid = (_fileCount - 1) / 2.0;
    final snapshot = <Square, List<Piece>>{};
    for (var r = 0; r < _rankCount; r++) {
      for (var f = 0; f < _fileCount; f++) {
        final sq = Square(f, r);
        final pieces = piecesAt(sq);
        if (pieces.isNotEmpty) snapshot[sq] = List<Piece>.from(pieces);
      }
    }
    for (final sq in snapshot.keys) {
      _clearSquare(sq);
    }
    for (final entry in snapshot.entries) {
      final mirroredFile = (2 * mid - entry.key.file).round();
      final dest = Square(mirroredFile, entry.key.rank);
      if (!isOnBoard(dest)) continue;
      _setCell(dest, entry.value);
    }
  }

  Square? _randomEmptySquare() {
    final empty = <Square>[];
    for (var r = 0; r < _rankCount; r++) {
      for (var f = 0; f < _fileCount; f++) {
        final s = Square(f, r);
        if (piecesAt(s).isEmpty && !isBlocked(s)) empty.add(s);
      }
    }
    if (empty.isEmpty) return null;
    return empty[_random.nextInt(empty.length)];
  }

  void _activateDisinfo() {
    final picks = <Square>[];
    for (var i = 0; i < 24 && picks.length < 3; i++) {
      final s = _randomEmptySquare();
      if (s != null && !picks.contains(s)) picks.add(s);
    }
    _rules.disinfoFakeSquares
      ..clear()
      ..addAll(picks);
  }

  void _advanceKansasNext() {
    final cur = _rules.kansasTyphoon;
    if (cur == null) return;
    final neighbors = <Square>[];
    for (var dr = -1; dr <= 1; dr++) {
      for (var df = -1; df <= 1; df++) {
        if (df == 0 && dr == 0) continue;
        final s = Square(cur.file + df, cur.rank + dr);
        if (isOnBoard(s) && piecesAt(s).isEmpty) neighbors.add(s);
      }
    }
    if (neighbors.isEmpty) {
      for (var dr = -1; dr <= 1; dr++) {
        for (var df = -1; df <= 1; df++) {
          if (df == 0 && dr == 0) continue;
          final s = Square(cur.file + df, cur.rank + dr);
          if (isOnBoard(s)) neighbors.add(s);
        }
      }
    }
    _rules.kansasTyphoonNext = neighbors.isEmpty
        ? null
        : neighbors[_random.nextInt(neighbors.length)];
  }

  void _resolveSerialManiac() {
    String? bestId;
    var best = 0;
    for (final e in _rules.serialCaptureCounts.entries) {
      if (e.value > best) {
        best = e.value;
        bestId = e.key;
      }
    }
    if (bestId == null || best <= 0) return;
    final ref = _pieceById(bestId);
    if (ref == null || ref.piece.type == PieceType.pawn) return;
    _replacePieceAt(
      ref.square,
      ref.index,
      ref.piece.copyWith(type: PieceType.pawn),
    );
  }

  void _tickExpandedModsAfterPass(PieceColor finished) {
    _rules.globalPlyIndex++;
    // Ink blots
    final blotKeys = _rules.inkBlotPlies.keys.toList();
    for (final s in blotKeys) {
      final left = (_rules.inkBlotPlies[s] ?? 0) - 1;
      if (left <= 0) {
        _rules.inkBlotPlies.remove(s);
      } else {
        _rules.inkBlotPlies[s] = left;
      }
    }
    // Wasteland claim decay
    if (_rules.wastelandActive) {
      final keys = _rules.wastelandClaims.keys.toList();
      for (final s in keys) {
        final claim = _rules.wastelandClaims[s]!;
        final left = claim.pliesLeft - 1;
        if (left <= 0) {
          _rules.wastelandClaims.remove(s);
        } else {
          _rules.wastelandClaims[s] = (owner: claim.owner, pliesLeft: left);
        }
      }
    }
    // Forbidden file
    if (_rules.forbiddenFilePlies > 0) {
      _rules.forbiddenFilePlies--;
      if (_rules.forbiddenFilePlies <= 0) _rules.forbiddenFile = null;
    }
    // Snail slime
    final slimeKeys = _rules.snailSlimePlies.keys.toList();
    for (final s in slimeKeys) {
      final left = (_rules.snailSlimePlies[s] ?? 0) - 1;
      if (left <= 0) {
        _rules.snailSlimePlies.remove(s);
      } else {
        _rules.snailSlimePlies[s] = left;
      }
    }
    // Blood feud timer (victim's plies)
    if (_rules.bloodFeudActive &&
        _rules.bloodFeudVictimColor == finished &&
        _rules.bloodFeudPliesLeft > 0) {
      _rules.bloodFeudPliesLeft--;
      if (_rules.bloodFeudPliesLeft == 0) {
        _rules.queuedSkillChoices += 1;
        _rules.bloodFeudBanner =
            'Кровная вражда: месть не состоялась — соперник получает мод';
        _rules.bloodFeudVictimColor = null;
      }
    }
    // Seasons: every black completed move = half of full move; 6 full = season
    if (_rules.seasonsActive && finished == PieceColor.black) {
      _rules.seasonFullMoves++;
      if (_rules.seasonFullMoves >= 6) {
        _rules.seasonFullMoves = 0;
        _rules.seasonIndex = (_rules.seasonIndex + 1) % 4;
        _rules.springDoubleUsedThisSeason.clear();
      }
    }
    // Gravity well every 6 plies
    if (_rules.gravityWellSquare != null) {
      _rules.gravityWellPlies++;
      if (_rules.gravityWellPlies >= 6) {
        _rules.gravityWellPlies = 0;
        _pulseGravityWell();
      }
    }
    // Kansas every 4 plies
    if (_rules.kansasTyphoon != null) {
      _rules.kansasPlies++;
      if (_rules.kansasPlies >= 4) {
        _rules.kansasPlies = 0;
        _moveKansasTyphoon();
      }
    }
    // River flow for pieces that stayed
    if (_rules.riverRank != null) {
      _flowRiver(finished);
    }
    // Clear one-turn taxes for the side that just finished their turn.
    _rules.centerTaxSkipNext.removeWhere((id) {
      final ref = _pieceById(id);
      return ref?.piece.color == finished;
    });
    final tollKeys = _rules.wastelandTollSkip.keys.toList();
    for (final id in tollKeys) {
      final ref = _pieceById(id);
      if (ref?.piece.color != finished) continue;
      final left = (_rules.wastelandTollSkip[id] ?? 0) - 1;
      if (left <= 0) {
        _rules.wastelandTollSkip.remove(id);
      } else {
        _rules.wastelandTollSkip[id] = left;
      }
    }

    // Volcano
    if (_rules.volcanoActive) {
      _rules.volcanoPliesLeft--;
      if (_rules.volcanoPliesLeft <= 0) {
        for (final s in _rules.volcanoSquares.toList()) {
          for (final p in List<Piece>.from(piecesAt(s))) {
            if (p.type == PieceType.king) continue;
            final ref = _pieceById(p.pieceId);
            if (ref == null) continue;
            final removed = _takePieceAt(ref.square, ref.index);
            if (removed != null) _onFinalDeath(removed, ref.square);
          }
        }
        _rules.volcanoPliesLeft = 4;
        _rerollVolcanoSquares();
      }
    }

    // Restless kings
    if (_rules.restlessKingsPliesLeft > 0) {
      _rules.restlessKingsPliesLeft--;
      if (_rules.restlessKingsPliesLeft <= 0) {
        for (final e in _rules.restlessKingStart.entries) {
          final k = findKing(e.key);
          if (k == e.value) {
            _finishGame(
              winner: e.key.opponent,
              reason: GameEndReason.alternativeVictory,
              detail: 'restlessKings',
            );
            return;
          }
        }
        _rules.restlessKingStart.clear();
      }
    }

    // Queen hunger (finished player's queens)
    if (_rules.insatiableHungerActive) {
      for (var r = 0; r < _rankCount; r++) {
        for (var f = 0; f < _fileCount; f++) {
          for (final p in List<Piece>.from(piecesAt(Square(f, r)))) {
            if (p.type != PieceType.queen || p.color != finished) continue;
            final n = (_rules.queenHungerPlies[p.pieceId] ?? 0) + 1;
            _rules.queenHungerPlies[p.pieceId] = n;
            if (n >= 5) {
              final ref = _pieceById(p.pieceId);
              if (ref != null) {
                final removed = _takePieceAt(ref.square, ref.index);
                if (removed != null) _onFinalDeath(removed, ref.square);
              }
            }
          }
        }
      }
    }

    // Fuse timers
    final fuseKeys = _rules.fuseTimers.keys.toList();
    for (final s in fuseKeys) {
      final left = (_rules.fuseTimers[s] ?? 0) - 1;
      if (left <= 0) {
        _rules.fuseTimers.remove(s);
        for (final p in List<Piece>.from(piecesAt(s))) {
          if (p.type == PieceType.king) continue;
          final ref = _pieceById(p.pieceId);
          if (ref == null) continue;
          final removed = _takePieceAt(ref.square, ref.index);
          if (removed != null) _onFinalDeath(removed, ref.square);
        }
      } else {
        _rules.fuseTimers[s] = left;
      }
    }

    // Ink trail decay
    final inkKeys = _rules.inkTrailBlocked.keys.toList();
    for (final s in inkKeys) {
      final left = (_rules.inkTrailBlocked[s] ?? 0) - 1;
      if (left <= 0) {
        _rules.inkTrailBlocked.remove(s);
      } else {
        _rules.inkTrailBlocked[s] = left;
      }
    }

    // Mortar: every 3 owner plies fire
    for (var r = 0; r < _rankCount; r++) {
      for (var f = 0; f < _fileCount; f++) {
        final sq = Square(f, r);
        for (final p in piecesAt(sq)) {
          if (!_hasEffect(p, AbilityEffect.pawnMortar)) continue;
          if (p.color != finished) continue;
          final cd = (_rules.mortarCooldown[p.pieceId] ?? 2) - 1;
          if (cd <= 0) {
            _rules.mortarCooldown[p.pieceId] = 3;
            final dir = p.color == PieceColor.white ? 1 : -1;
            final target = Square(sq.file, sq.rank + 2 * dir);
            if (isOnBoard(target)) {
              for (final victim in List<Piece>.from(piecesAt(target))) {
                final ref = _pieceById(victim.pieceId);
                if (ref == null) continue;
                final removed = _takePieceAt(ref.square, ref.index);
                if (removed != null) _onFinalDeath(removed, ref.square);
              }
            }
          } else {
            _rules.mortarCooldown[p.pieceId] = cd;
          }
        }
      }
    }

    // Starvation
    final starveKeys = _rules.starvationPlies.keys.toList();
    for (final id in starveKeys) {
      final ref = _pieceById(id);
      if (ref == null) {
        _rules.starvationPlies.remove(id);
        continue;
      }
      if (ref.piece.color != finished) continue;
      final left = (_rules.starvationPlies[id] ?? 0) - 1;
      if (left <= 0) {
        final removed = _takePieceAt(ref.square, ref.index);
        if (removed != null) _onFinalDeath(removed, ref.square);
        _rules.starvationPlies.remove(id);
      } else {
        _rules.starvationPlies[id] = left;
      }
    }

    // Seeds: tick on full moves (both finished black)
    if (finished == PieceColor.black) {
      final seedKeys = _rules.pawnSeeds.keys.toList();
      for (final s in seedKeys) {
        final data = _rules.pawnSeeds[s]!;
        final left = data.fullMovesLeft - 1;
        if (left <= 0) {
          _rules.pawnSeeds.remove(s);
          if (piecesAt(s).isEmpty && !isBlocked(s)) {
            _setPrimary(
              s,
              Piece(
                pieceId: 'seed-${data.color.name}-${s.file}-${s.rank}',
                type: PieceType.pawn,
                color: data.color,
                hasMoved: true,
              ),
            );
          }
        } else {
          _rules.pawnSeeds[s] = (color: data.color, fullMovesLeft: left);
        }
      }
    }

    // Twilight owner plies
    if (_rules.twilightOwner == finished && _rules.twilightOwnerPliesLeft > 0) {
      _rules.twilightOwnerPliesLeft--;
      if (_rules.twilightOwnerPliesLeft <= 0) {
        _rules.twilightInvisibleUntilPly.clear();
        _rules.twilightOwner = null;
      }
    }

    // Gesture mirror arm on finished move landing color
    if (_rules.gestureMirrorPending && _lastMove != null) {
      final light = isSquareLight(_lastMove!.to);
      _rules.gestureMirrorRequiredLight = light;
      _rules.gestureMirrorPending = false;
    }
  }

  int _countAlliesNear(Square square, PieceColor color) {
    var n = 0;
    for (var dr = -2; dr <= 2; dr++) {
      for (var df = -2; df <= 2; df++) {
        if (df == 0 && dr == 0) continue;
        final s = Square(square.file + df, square.rank + dr);
        if (!isOnBoard(s)) continue;
        if (piecesAt(s).any((p) => p.color == color)) n++;
      }
    }
    return n;
  }

  int _countAttackersOf(Square square, PieceColor byColor) {
    var n = 0;
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final from = Square(file, rank);
        for (final piece in piecesAt(from)) {
          if (piece.color != byColor) continue;
          if (_canAttack(from, square, piece)) n++;
        }
      }
    }
    return n;
  }

  void _pulseGravityWell() {
    final well = _rules.gravityWellSquare;
    if (well == null) return;
    final movers = <({Square from, Square to, Piece piece, int index})>[];
    for (var r = 0; r < _rankCount; r++) {
      for (var f = 0; f < _fileCount; f++) {
        final s = Square(f, r);
        final df = well.file - f;
        final dr = well.rank - r;
        if (df.abs() > 2 || dr.abs() > 2 || (df == 0 && dr == 0)) continue;
        final pieces = piecesAt(s);
        for (var i = 0; i < pieces.length; i++) {
          final p = pieces[i];
          if (p.type == PieceType.king) continue;
          final step = Square(f + df.sign, r + dr.sign);
          if (!isOnBoard(step) || piecesAt(step).isNotEmpty) continue;
          movers.add((from: s, to: step, piece: p, index: i));
        }
      }
    }
    for (final m in movers) {
      _clearSquare(m.from);
      _setPrimary(m.to, m.piece);
    }
  }

  void _moveKansasTyphoon() {
    final next = _rules.kansasTyphoonNext ?? _randomEmptySquare();
    if (next == null) return;
    final victims = piecesAt(next);
    _rules.kansasTyphoon = next;
    for (final v in List<Piece>.from(victims)) {
      final dest = _randomEmptyNeighbor(next) ?? _randomEmptySquare();
      if (dest == null) continue;
      final ref = _pieceById(v.pieceId);
      if (ref == null) continue;
      _clearSquare(ref.square);
      _setPrimary(dest, v);
    }
    _advanceKansasNext();
  }

  Square? _randomEmptyNeighbor(Square origin) {
    final opts = <Square>[];
    for (var dr = -1; dr <= 1; dr++) {
      for (var df = -1; df <= 1; df++) {
        if (df == 0 && dr == 0) continue;
        final s = Square(origin.file + df, origin.rank + dr);
        if (isOnBoard(s) && piecesAt(s).isEmpty) opts.add(s);
      }
    }
    if (opts.isEmpty) return null;
    return opts[_random.nextInt(opts.length)];
  }

  void _flowRiver(PieceColor finished) {
    final rank = _rules.riverRank;
    if (rank == null) return;
    final dir = _rules.riverDirection;
    // Move from downstream end so pieces don't collide incorrectly.
    final files = List<int>.generate(_fileCount, (i) => i);
    if (dir > 0) files.sort((a, b) => b.compareTo(a));
    for (final f in files) {
      if ((dir > 0 && f >= _fileCount - 1) || (dir < 0 && f <= 0)) continue;
      final s = Square(f, rank);
      final pieces = piecesAt(s);
      if (pieces.isEmpty) continue;
      // Only flow pieces of the side that just finished if they stayed >1 ply — simplify: always try flow once per pass.
      final dest = Square(f + dir, rank);
      if (!isOnBoard(dest) || piecesAt(dest).isNotEmpty) continue;
      final p = pieces.first;
      if (p.color != finished) continue;
      _clearSquare(s);
      _setPrimary(dest, p);
    }
  }

  bool get kriegspielActive => _rules.kriegspielActive;
  bool get duckChessActive => _rules.duckChessActive;
  bool get kingCenterActive => _rules.kingCenterActive;
  bool get atomicActive => _rules.atomicActive;
  bool get debtPitActive => _rules.debtPitActive;
  int debtFor(PieceColor c) =>
      c == PieceColor.white ? _rules.whiteDebt : _rules.blackDebt;
  bool get shopTokenActive => _rules.shopTokenActive;
  bool shopAvailableFor(PieceColor c) => _rules.shopAvailable[c] ?? false;
  bool shopTokenHeldBy(PieceColor c) => _rules.shopTokenHeld[c] ?? false;
  Set<Square> get priorityCells => Set.unmodifiable(_rules.priorityCells);
  Square? get duckSquare => _rules.duckSquare;
  bool get duckNeedsPlacement => _rules.duckNeedsPlacement;
  bool get crazyhouseActive => _rules.crazyhouseActive;
  List<PieceType> crazyhouseHandFor(PieceColor c) =>
      List.unmodifiable(_rules.crazyhouseHand[c] ?? const []);
  String? get bloodFeudBanner => _rules.bloodFeudBanner;
  void clearBloodFeudBanner() => _rules.bloodFeudBanner = null;
  Square? get kansasTyphoon => _rules.kansasTyphoon;
  Square? get kansasTyphoonNext => _rules.kansasTyphoonNext;
  int? get forbiddenFile => _rules.forbiddenFile;
  int? get riverRank => _rules.riverRank;
  Set<Square> get inkBlotSquares => _rules.inkBlotPlies.keys.toSet();

  bool tryPlaceDuck(Square square) {
    if (!_rules.duckChessActive || !_rules.duckNeedsPlacement) return false;
    if (!isOnBoard(square) || piecesAt(square).isNotEmpty) return false;
    if (_rules.duckSquare == square) return false;
    _rules.duckSquare = square;
    _rules.duckNeedsPlacement = false;
    _passTurn();
    _updateStatus();
    return true;
  }

  void _passTurnUnlessDuckPending({bool? gaveCheck}) {
    if (_rules.duckChessActive && _rules.duckNeedsPlacement) {
      _updateStatus();
      return;
    }
    if (gaveCheck != null) {
      _passTurn(gaveCheck: gaveCheck);
    } else {
      _passTurn();
    }
  }

  bool tryCrazyhouseDrop(PieceColor color, PieceType type, Square to) {
    if (!_rules.crazyhouseActive) return false;
    if (_turn != color || enginePhase != GameEnginePhase.play) return false;
    final hand = _rules.crazyhouseHand[color]!;
    final idx = hand.indexOf(type);
    if (idx < 0) return false;
    if (!isOnBoard(to) || piecesAt(to).isNotEmpty) return false;
    if (_rules.duckSquare == to) return false;
    if (type == PieceType.pawn &&
        (to.rank == 0 || to.rank == _rankCount - 1)) {
      return false;
    }
    hand.removeAt(idx);
    _setPrimary(
      to,
      Piece(
        pieceId: 'drop-${color.name}-${_nextPieceId++}',
        type: type,
        color: color,
        hasMoved: true,
      ),
    );
    _passTurn();
    _updateStatus();
    return true;
  }

  bool trySpendShopToken(PieceColor color) {
    if (!_rules.shopTokenActive) return false;
    if (!(_rules.shopTokenHeld[color] ?? false)) return false;
    if (!_gameCanTakebackForShop()) return false;
    _rules.shopTokenHeld[color] = false;
    takeback();
    return true;
  }

  bool _gameCanTakebackForShop() => canTakeback;

  bool trySellToShop(PieceColor color, String pieceId) {
    if (!_rules.shopTokenActive) return false;
    if (!(_rules.shopAvailable[color] ?? false)) return false;
    final ref = _pieceById(pieceId);
    if (ref == null ||
        ref.piece.color != color ||
        ref.piece.type == PieceType.king) {
      return false;
    }
    _clearSquare(ref.square);
    _rules.shopAvailable[color] = false;
    _rules.shopTokenHeld[color] = true;
    _updateStatus();
    return true;
  }

  void _activateArchitectWalls(int count) {
    final candidates = <String>[];
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final a = Square(file, rank);
        if (file + 1 < _fileCount) {
          candidates.add(BoardCataclysmState.wallKey(a, Square(file + 1, rank)));
        }
        if (rank + 1 < _rankCount) {
          candidates.add(BoardCataclysmState.wallKey(a, Square(file, rank + 1)));
        }
      }
    }
    candidates.shuffle(_random);
    _rules.architectWalls.addAll(candidates.take(count.clamp(3, 8)));
  }

  bool _moveCrossesArchitectWall(Square from, Square to) {
    if (_rules.architectWalls.isEmpty) return false;
    final df = to.file - from.file;
    final dr = to.rank - from.rank;
    // Only sliding rays (rook / bishop / queen). Knights etc. never cross walls.
    final ortho = df == 0 || dr == 0;
    final diag = df.abs() == dr.abs();
    if ((!ortho && !diag) || (df == 0 && dr == 0)) return false;

    final stepF = df.sign;
    final stepR = dr.sign;
    var f = from.file;
    var r = from.rank;
    // Walk cell-by-cell until we reach [to]; walls sit between adjacent cells.
    while (f != to.file || r != to.rank) {
      final nextF = f + stepF;
      final nextR = r + stepR;
      final next = Square(nextF, nextR);
      if (_rules.hasWallBetween(Square(f, r), next)) return true;
      f = nextF;
      r = nextR;
    }
    return false;
  }

  List<Move> _avengeMoves() {
    final target = _rules.avengeCaptureSquare;
    final color = _rules.avengeVictimColor;
    if (target == null || color == null || color != _turn) return const [];
    final occupant = pieceAt(target);
    if (occupant == null || occupant.color == color) return const [];
    final moves = <Move>[];
    for (var dr = -1; dr <= 1; dr++) {
      for (var df = -1; df <= 1; df++) {
        if (df == 0 && dr == 0) continue;
        final from = _offsetSquare(target, df, dr);
        if (from == null) continue;
        final pieces = piecesAt(from);
        for (var i = 0; i < pieces.length; i++) {
          final pawn = pieces[i];
          if (pawn.color != color || pawn.type != PieceType.pawn) continue;
          moves.add(Move(from: from, to: target, pieceIndex: i));
        }
      }
    }
    return moves;
  }

  bool _isFaceControlled(Piece piece, Square square) {
    if (!_rules.abilityEffectsActive) return false;
    final behindRank =
        piece.color == PieceColor.white ? square.rank - 1 : square.rank + 1;
    if (behindRank < 0 || behindRank >= _rankCount) return false;
    for (final pawn in piecesAt(Square(square.file, behindRank))) {
      if (pawn.color == piece.color.opponent &&
          pawn.type == PieceType.pawn &&
          _hasEffect(pawn, AbilityEffect.faceControl)) {
        return true;
      }
    }
    return false;
  }

  int _countAttackers(Square square, {required PieceColor byColor}) {
    var count = 0;
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final from = Square(file, rank);
        final pieces = piecesAt(from);
        for (var i = 0; i < pieces.length; i++) {
          final piece = pieces[i];
          if (piece.color != byColor) continue;
          for (final move in _getPseudoLegalMoves(
            from,
            piece,
            pieceIndex: i,
          )) {
            if (move.to == square && _isCapture(move)) {
              count++;
              break;
            }
          }
        }
      }
    }
    return count;
  }

  Set<Square> _cornerSquares() => {
        Square(0, 0),
        Square(_fileCount - 1, 0),
        Square(0, _rankCount - 1),
        Square(_fileCount - 1, _rankCount - 1),
      };

  Set<Square> _allSurveyorSafeSquares() {
    final out = <Square>{};
    for (final set in _rules.surveyorSafeSquares.values) {
      out.addAll(set);
    }
    return out;
  }

  bool _isAssemblyProtectedSquare(Square square) {
    for (var dr = -1; dr <= 1; dr++) {
      for (var df = -1; df <= 1; df++) {
        final n = Square(square.file + df, square.rank + dr);
        if (!isOnBoard(n)) continue;
        for (final piece in piecesAt(n)) {
          if (piece.type == PieceType.king &&
              _hasEffect(piece, AbilityEffect.assemblyHall)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  void _applyStompAway(Square knightSquare, PieceColor knightColor) {
    final enemy = knightColor.opponent;
    for (var dr = -1; dr <= 1; dr++) {
      for (var df = -1; df <= 1; df++) {
        if (df == 0 && dr == 0) continue;
        final from = _offsetSquare(knightSquare, df, dr);
        if (from == null) continue;
        final pieces = piecesAt(from);
        for (var i = 0; i < pieces.length; i++) {
          final pawn = pieces[i];
          if (pawn.color != enemy || pawn.type != PieceType.pawn) continue;
          final away = _bestFleeSquare(from, knightSquare, pawn);
          if (away == null) continue;
          _clearSquare(from);
          _setPrimary(away, pawn.copyWith(hasMoved: true, idleTurns: 0));
        }
      }
    }
  }

  Square? _bestFleeSquare(Square from, Square threat, Piece pawn) {
    Square? best;
    var bestDist = _chebyshevDistance(from, threat);
    final forward = pawn.color == PieceColor.white ? 1 : -1;
    final candidates = <Square?>[
      _offsetSquare(from, 0, forward),
      _offsetSquare(from, 1, forward),
      _offsetSquare(from, -1, forward),
      _offsetSquare(from, 1, 0),
      _offsetSquare(from, -1, 0),
      _offsetSquare(from, 0, -forward),
    ];
    for (final to in candidates) {
      if (to == null || !isOnBoard(to)) continue;
      if (piecesAt(to).isNotEmpty || isBlocked(to)) continue;
      final dist = _chebyshevDistance(to, threat);
      if (dist > bestDist) {
        bestDist = dist;
        best = to;
      }
    }
    return best;
  }

  void _applyRidePassenger(Move move, String knightId, String pawnId) {
    final pawnRef = _pieceById(pawnId);
    final knightRef = _pieceById(knightId);
    if (pawnRef == null || knightRef == null) return;
    final relFile = pawnRef.square.file - move.from.file;
    final relRank = pawnRef.square.rank - move.from.rank;
    final dest = Square(
      knightRef.square.file + relFile,
      knightRef.square.rank + relRank,
    );
    if (!isOnBoard(dest)) return;
    if (isBlocked(dest)) return;
    final occupants = piecesAt(dest);
    if (occupants.any((p) => p.color == pawnRef.piece.color)) return;
    if (occupants.isNotEmpty) {
      _capturePiecesAt(dest, capturingColor: pawnRef.piece.color);
    }
    _clearSquare(pawnRef.square);
    _setPrimary(dest, pawnRef.piece.copyWith(hasMoved: true, idleTurns: 0));
  }

  void _checkLetterHVictory(PieceColor color) {
    final occupied = <Square>{};
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        if (piecesAt(square).any((p) => p.color == color)) {
          occupied.add(square);
        }
      }
    }
    for (var rank = 0; rank + 2 < _rankCount; rank++) {
      for (var file = 0; file + 2 < _fileCount; file++) {
        final cells = <Square>[
          Square(file, rank),
          Square(file, rank + 1),
          Square(file, rank + 2),
          Square(file + 1, rank + 1),
          Square(file + 2, rank),
          Square(file + 2, rank + 1),
          Square(file + 2, rank + 2),
        ];
        if (cells.every(occupied.contains)) {
          _finishGame(
            winner: color,
            reason: GameEndReason.alternativeVictory,
            detail: 'letterH',
          );
          return;
        }
      }
    }
  }

  void _revealSignalFire(PieceColor color) {
    final candidates = <Square>[];
    final visible = visibleSquaresFor(color);
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        if (!visible.contains(square)) candidates.add(square);
      }
    }
    if (candidates.isEmpty) {
      for (var rank = 0; rank < _rankCount; rank++) {
        for (var file = 0; file < _fileCount; file++) {
          candidates.add(Square(file, rank));
        }
      }
    }
    if (candidates.isEmpty) return;
    final picked = candidates[_random.nextInt(candidates.length)];
    _rules.permanentFogReveals
        .putIfAbsent(color, () => {})
        .add(picked);
  }

  void _tickIdleTurns(PieceColor finished) {
    for (var rank = 0; rank < _rankCount; rank++) {
      for (var file = 0; file < _fileCount; file++) {
        final square = Square(file, rank);
        final pieces = piecesAt(square);
        for (var i = 0; i < pieces.length; i++) {
          final piece = pieces[i];
          if (piece.color != finished) continue;
          if (!_hasEffect(piece, AbilityEffect.trench)) continue;
          // Movers already reset idleTurns to 0 in expansion hook.
          if (piece.idleTurns == 0 &&
              (_rules.whiteLastMovedPieceId == piece.pieceId ||
                  _rules.blackLastMovedPieceId == piece.pieceId)) {
            continue;
          }
          // Always increment trench pawns that didn't just move.
          final last = finished == PieceColor.white
              ? _rules.whiteLastMovedPieceId
              : _rules.blackLastMovedPieceId;
          if (last == piece.pieceId) continue;
          _replacePieceAt(
            square,
            i,
            piece.copyWith(idleTurns: piece.idleTurns + 1),
          );
        }
      }
    }
  }

  GameSnapshot createSnapshot() {
    return GameSnapshot._(
      board: _board.map((row) => List<Piece?>.from(row)).toList(),
      stackExtra: Map<String, Piece>.from(_stackExtra),
      nextPieceId: _nextPieceId,
      fileCount: _fileCount,
      rankCount: _rankCount,
      extraFileOnLeft: _extraFileOnLeft,
      turn: _turn,
      enPassantTarget: _enPassantTarget,
      status: _status,
      winnerColor: _winnerColor,
      endReason: _endReason,
      endDetail: _endDetail,
      whiteStartChosen: _whiteStartChosen,
      blackStartChosen: _blackStartChosen,
      whiteStartOffers: List<AbilityOffer>.from(_whiteStartOffers),
      blackStartOffers: List<AbilityOffer>.from(_blackStartOffers),
      pendingSkillSquare: _pendingSkillSquare,
      pendingSkillPieceId: _pendingSkillPieceId,
      pendingSkillColor: _pendingSkillColor,
      pendingCaptureOffers: List<AbilityOffer>.from(_pendingCaptureOffers),
      auctionSquare: _auctionSquare,
      pendingAuctionSquare: _pendingAuctionSquare,
      pendingAuctionColor: _pendingAuctionColor,
      pendingBonusSkillColor: _pendingBonusSkillColor,
      skillChoiceIsBonus: _skillChoiceIsBonus,
      whiteBoardAbility: _whiteBoardAbility,
      blackBoardAbility: _blackBoardAbility,
      bloodOathActive: _bloodOathActive,
      baskervilleActive: _baskervilleActive,
      whiteBaskervilleChecks: _whiteBaskervilleChecks,
      blackBaskervilleChecks: _blackBaskervilleChecks,
      goldenThroneWhite: _goldenThroneWhite,
      goldenThroneBlack: _goldenThroneBlack,
      pendingGoldenThroneColor: _pendingGoldenThroneColor,
      exterminatusPliesLeft: _exterminatusPliesLeft,
      silentFile: _silentFile,
      whiteStartAbilityInfo: _whiteStartAbilityInfo,
      blackStartAbilityInfo: _blackStartAbilityInfo,
      whiteChosenAbilities: List<ChosenAbilityInfo>.from(_whiteChosenAbilities),
      blackChosenAbilities: List<ChosenAbilityInfo>.from(_blackChosenAbilities),
      whiteOneShotReroll: _whiteOneShotReroll,
      blackOneShotReroll: _blackOneShotReroll,
      whitePermanentReroll: _whitePermanentReroll,
      blackPermanentReroll: _blackPermanentReroll,
      lavaRanks: Set<int>.from(_lavaRanks),
      pendingLavaDeaths: List<LavaDeathEvent>.from(_pendingLavaDeaths),
      fogOfWar: _fogOfWar,
      sprintActive: _sprintActive,
      quarantineSquare: _quarantineSquare,
      quarantineMovesLeft: _quarantineMovesLeft,
      wormholes: Set<Square>.from(_wormholes),
      zebrasActive: _zebrasActive,
      whiteDoppelganger: _whiteDoppelganger,
      blackDoppelganger: _blackDoppelganger,
      squareColorLockIsLight: switch (_squareColorLock) {
        _SquareColorLock.light => true,
        _SquareColorLock.dark => false,
        null => null,
      },
      squareColorLockMovesLeft: _squareColorLockMovesLeft,
      truceMovesLeft: _truceMovesLeft,
      mirrorActive: _mirrorActive,
      whiteCavalryMovesLeft: _whiteCavalryMovesLeft,
      blackCavalryMovesLeft: _blackCavalryMovesLeft,
      whiteThrone: _whiteThrone,
      blackThrone: _blackThrone,
      plagueActive: _plagueActive,
      fourHorsemenActive: _fourHorsemenActive,
      ghostCells: Set<Square>.from(_ghostCells),
      attractionActive: _attractionActive,
      attractionMoveCounter: _attractionMoveCounter,
      virusActive: _virusActive,
      invisibleRegiment: _invisibleRegiment,
      shuffledSquareLight: _shuffledSquareLight
          ?.map((row) => List<bool>.from(row))
          .toList(),
      teleportA: _teleportA,
      teleportB: _teleportB,
      mines: Set<Square>.from(_mines),
      golcondaActive: _golcondaActive,
      unbridledHorse: _unbridledHorse,
      dustSquares: Map<Square, int>.from(_dustSquares),
      laserFiles: Map<int, int>.from(_laserFiles),
      laserFileOwner: Map<int, PieceColor>.from(_laserFileOwner),
      awaitingGallopFrom: _awaitingGallopFrom,
      awaitingGallopIndex: _awaitingGallopIndex,
      pendingTargetSelection: _pendingTargetSelection,
      pendingTargetAbility: _pendingTargetAbility,
      pendingTargetSourceId: _pendingTargetSourceId,
      pendingTargetColor: _pendingTargetColor,
      pendingTargetPassesTurn: _pendingTargetPassesTurn,
      pendingReactionMove: _pendingReactionMove,
      pendingRansomPawnId: _pendingRansomPawnId,
      queuedSkillPieceId: _queuedSkillPieceId,
      queuedSkillColor: _queuedSkillColor,
      duelLinks: Map<String, String>.from(_duelLinks),
      guardSquares: Map<String, Square>.from(_guardSquares),
      guardTurnsLeft: Map<String, int>.from(_guardTurnsLeft),
      knightTourVisited: {
        for (final entry in _knightTourVisited.entries)
          entry.key: Set<Square>.from(entry.value),
      },
      knightTourRewardUsed: Set<String>.from(_knightTourRewardUsed),
      sanctuaryTargets: Map<String, String>.from(_sanctuaryTargets),
      excommunicationTypes: Map<String, PieceType>.from(_excommunicationTypes),
      titheSuppressions: {
        for (final entry in _titheSuppressions.entries)
          entry.key: Map<String, GameAbility>.from(entry.value),
      },
      pilgrimageQuadrants: {
        for (final entry in _pilgrimageQuadrants.entries)
          entry.key: Set<int>.from(entry.value),
      },
      pilgrimageCompleted: Set<String>.from(_pilgrimageCompleted),
      pilgrimageProtected: Set<String>.from(_pilgrimageProtected),
      customsStates: {
        for (final entry in _customsStates.entries)
          entry.key: entry.value.copyWith(
            exemptPieceIds: Set<String>.from(entry.value.exemptPieceIds),
          ),
      },
      curfewBindings: Map<String, RookCurfewState>.from(_curfewBindings),
      siegeStates: Map<String, SiegeInternalState>.from(_siegeStates),
      delayedSentences: Map<String, DelayedSentenceState>.from(
        _delayedSentences,
      ),
      graveyard: List<GraveyardRecord>.from(_graveyard),
      graveyardSequence: _graveyardSequence,
      pendingExchangeOwnSequence: _pendingExchangeOwnSequence,
      pendingRemoveModTargetId: _pendingRemoveModTargetId,
      boardRules: _rules.copy(),
    );
  }

  void restoreSnapshot(GameSnapshot snapshot) {
    _board = snapshot.board.map((row) => List<Piece?>.from(row)).toList();
    _stackExtra
      ..clear()
      ..addAll(snapshot.stackExtra);
    _nextPieceId = snapshot.nextPieceId;
    _fileCount = snapshot.fileCount;
    _rankCount = snapshot.rankCount;
    _extraFileOnLeft = snapshot.extraFileOnLeft;
    _turn = snapshot.turn;
    _enPassantTarget = snapshot.enPassantTarget;
    _status = snapshot.status;
    _winnerColor = snapshot.winnerColor;
    _endReason = snapshot.endReason;
    _endDetail = snapshot.endDetail;
    _whiteStartChosen = snapshot.whiteStartChosen;
    _blackStartChosen = snapshot.blackStartChosen;
    _whiteStartOffers = List<AbilityOffer>.from(snapshot.whiteStartOffers);
    _blackStartOffers = List<AbilityOffer>.from(snapshot.blackStartOffers);
    _pendingSkillSquare = snapshot.pendingSkillSquare;
    _pendingSkillPieceId = snapshot.pendingSkillPieceId;
    _pendingSkillColor = snapshot.pendingSkillColor;
    _pendingCaptureOffers = List<AbilityOffer>.from(
      snapshot.pendingCaptureOffers,
    );
    _auctionSquare = snapshot.auctionSquare;
    _pendingAuctionSquare = snapshot.pendingAuctionSquare;
    _pendingAuctionColor = snapshot.pendingAuctionColor;
    _pendingBonusSkillColor = snapshot.pendingBonusSkillColor;
    _skillChoiceIsBonus = snapshot.skillChoiceIsBonus;
    _whiteBoardAbility = snapshot.whiteBoardAbility;
    _blackBoardAbility = snapshot.blackBoardAbility;
    _bloodOathActive = snapshot.bloodOathActive;
    _baskervilleActive = snapshot.baskervilleActive;
    _whiteBaskervilleChecks = snapshot.whiteBaskervilleChecks;
    _blackBaskervilleChecks = snapshot.blackBaskervilleChecks;
    _goldenThroneWhite = snapshot.goldenThroneWhite;
    _goldenThroneBlack = snapshot.goldenThroneBlack;
    _pendingGoldenThroneColor = snapshot.pendingGoldenThroneColor;
    _exterminatusPliesLeft = snapshot.exterminatusPliesLeft;
    _silentFile = snapshot.silentFile;
    _whiteStartAbilityInfo = snapshot.whiteStartAbilityInfo;
    _blackStartAbilityInfo = snapshot.blackStartAbilityInfo;
    _whiteChosenAbilities
      ..clear()
      ..addAll(snapshot.whiteChosenAbilities);
    _blackChosenAbilities
      ..clear()
      ..addAll(snapshot.blackChosenAbilities);
    _whiteOneShotReroll = snapshot.whiteOneShotReroll;
    _blackOneShotReroll = snapshot.blackOneShotReroll;
    _whitePermanentReroll = snapshot.whitePermanentReroll;
    _blackPermanentReroll = snapshot.blackPermanentReroll;
    _lavaRanks
      ..clear()
      ..addAll(snapshot.lavaRanks);
    _pendingLavaDeaths
      ..clear()
      ..addAll(snapshot.pendingLavaDeaths);
    _fogOfWar = snapshot.fogOfWar;
    _sprintActive = snapshot.sprintActive;
    _quarantineSquare = snapshot.quarantineSquare;
    _quarantineMovesLeft = snapshot.quarantineMovesLeft;
    _wormholes
      ..clear()
      ..addAll(snapshot.wormholes);
    _zebrasActive = snapshot.zebrasActive;
    _whiteDoppelganger = snapshot.whiteDoppelganger;
    _blackDoppelganger = snapshot.blackDoppelganger;
    _squareColorLock = switch (snapshot.squareColorLockIsLight) {
      true => _SquareColorLock.light,
      false => _SquareColorLock.dark,
      null => null,
    };
    _squareColorLockMovesLeft = snapshot.squareColorLockMovesLeft;
    _truceMovesLeft = snapshot.truceMovesLeft;
    _mirrorActive = snapshot.mirrorActive;
    _whiteCavalryMovesLeft = snapshot.whiteCavalryMovesLeft;
    _blackCavalryMovesLeft = snapshot.blackCavalryMovesLeft;
    _whiteThrone = snapshot.whiteThrone;
    _blackThrone = snapshot.blackThrone;
    _plagueActive = snapshot.plagueActive;
    _fourHorsemenActive = snapshot.fourHorsemenActive;
    _ghostCells
      ..clear()
      ..addAll(snapshot.ghostCells);
    _attractionActive = snapshot.attractionActive;
    _attractionMoveCounter = snapshot.attractionMoveCounter;
    _virusActive = snapshot.virusActive;
    _invisibleRegiment = snapshot.invisibleRegiment;
    _shuffledSquareLight = snapshot.shuffledSquareLight
        ?.map((row) => List<bool>.from(row))
        .toList();
    _teleportA = snapshot.teleportA;
    _teleportB = snapshot.teleportB;
    _mines
      ..clear()
      ..addAll(snapshot.mines);
    _golcondaActive = snapshot.golcondaActive;
    _unbridledHorse = snapshot.unbridledHorse;
    _dustSquares
      ..clear()
      ..addAll(snapshot.dustSquares);
    _laserFiles
      ..clear()
      ..addAll(snapshot.laserFiles);
    _laserFileOwner
      ..clear()
      ..addAll(snapshot.laserFileOwner);
    _awaitingGallopFrom = snapshot.awaitingGallopFrom;
    _awaitingGallopIndex = snapshot.awaitingGallopIndex;
    _pendingTargetSelection = snapshot.pendingTargetSelection;
    _pendingTargetAbility = snapshot.pendingTargetAbility;
    _pendingTargetSourceId = snapshot.pendingTargetSourceId;
    _pendingTargetColor = snapshot.pendingTargetColor;
    _pendingTargetPassesTurn = snapshot.pendingTargetPassesTurn;
    _pendingReactionMove = snapshot.pendingReactionMove;
    _pendingRansomPawnId = snapshot.pendingRansomPawnId;
    _queuedSkillPieceId = snapshot.queuedSkillPieceId;
    _queuedSkillColor = snapshot.queuedSkillColor;
    _duelLinks
      ..clear()
      ..addAll(snapshot.duelLinks);
    _guardSquares
      ..clear()
      ..addAll(snapshot.guardSquares);
    _guardTurnsLeft
      ..clear()
      ..addAll(snapshot.guardTurnsLeft);
    _knightTourVisited
      ..clear()
      ..addAll({
        for (final entry in snapshot.knightTourVisited.entries)
          entry.key: Set<Square>.from(entry.value),
      });
    _knightTourRewardUsed
      ..clear()
      ..addAll(snapshot.knightTourRewardUsed);
    _sanctuaryTargets
      ..clear()
      ..addAll(snapshot.sanctuaryTargets);
    _excommunicationTypes
      ..clear()
      ..addAll(snapshot.excommunicationTypes);
    _titheSuppressions
      ..clear()
      ..addAll({
        for (final entry in snapshot.titheSuppressions.entries)
          entry.key: Map<String, GameAbility>.from(entry.value),
      });
    _pilgrimageQuadrants
      ..clear()
      ..addAll({
        for (final entry in snapshot.pilgrimageQuadrants.entries)
          entry.key: Set<int>.from(entry.value),
      });
    _pilgrimageCompleted
      ..clear()
      ..addAll(snapshot.pilgrimageCompleted);
    _pilgrimageProtected
      ..clear()
      ..addAll(snapshot.pilgrimageProtected);
    _customsStates
      ..clear()
      ..addAll({
        for (final entry in snapshot.customsStates.entries)
          entry.key: entry.value.copyWith(
            exemptPieceIds: Set<String>.from(entry.value.exemptPieceIds),
          ),
      });
    _curfewBindings
      ..clear()
      ..addAll(snapshot.curfewBindings);
    _siegeStates
      ..clear()
      ..addAll(snapshot.siegeStates);
    _delayedSentences
      ..clear()
      ..addAll(snapshot.delayedSentences);
    _graveyard
      ..clear()
      ..addAll(snapshot.graveyard);
    _graveyardSequence = snapshot.graveyardSequence;
    _pendingExchangeOwnSequence = snapshot.pendingExchangeOwnSequence;
    _pendingRemoveModTargetId = snapshot.pendingRemoveModTargetId;
    _rules.restoreFrom(snapshot.boardRules);
  }

  static List<List<Piece?>> _createInitialBoard() {
    var nextId = 0;
    Piece piece(PieceType type, PieceColor color) =>
        Piece(pieceId: 'piece-${nextId++}', type: type, color: color);

    List<Piece?> mutableRow(List<Piece?> row) => List<Piece?>.from(row);

    return [
      mutableRow([
        piece(PieceType.rook, PieceColor.white),
        piece(PieceType.knight, PieceColor.white),
        piece(PieceType.bishop, PieceColor.white),
        piece(PieceType.queen, PieceColor.white),
        piece(PieceType.king, PieceColor.white),
        piece(PieceType.bishop, PieceColor.white),
        piece(PieceType.knight, PieceColor.white),
        piece(PieceType.rook, PieceColor.white),
      ]),
      mutableRow(
        List.generate(8, (_) => piece(PieceType.pawn, PieceColor.white)),
      ),
      mutableRow(List.filled(8, null)),
      mutableRow(List.filled(8, null)),
      mutableRow(List.filled(8, null)),
      mutableRow(List.filled(8, null)),
      mutableRow(
        List.generate(8, (_) => piece(PieceType.pawn, PieceColor.black)),
      ),
      mutableRow([
        piece(PieceType.rook, PieceColor.black),
        piece(PieceType.knight, PieceColor.black),
        piece(PieceType.bishop, PieceColor.black),
        piece(PieceType.queen, PieceColor.black),
        piece(PieceType.king, PieceColor.black),
        piece(PieceType.bishop, PieceColor.black),
        piece(PieceType.knight, PieceColor.black),
        piece(PieceType.rook, PieceColor.black),
      ]),
    ];
  }
  // ---------------------------------------------------------------------------
  // Interactive batch mods (RPS, multi-cell, tangled, customs, passives)
  // ---------------------------------------------------------------------------

  bool get isAwaitingRps =>
      _rules.rpsSessionActive && !_rules.rpsResolved && _rules.rpsPairIndex != null;

  bool get isAwaitingCustomsPath => _rules.awaitingCustomsPath;

  bool get isAwaitingTangledKeep => _rules.tangledAwaitingKeep;

  bool get isAwaitingSpotlightPromo => _rules.spotlightPromoId != null;

  bool get isAwaitingMultiCell =>
      _rules.multiCellNeeded > 0 &&
      _rules.multiCellAbility != null &&
      _rules.multiCellPicks.length < _rules.multiCellNeeded;

  List<(Square, Square)> get rpsPairs => List<(Square, Square)>.from(_rules.rpsPairs);

  int? get rpsPairIndex => _rules.rpsPairIndex;

  String? get rpsLastA => _rules.rpsLastA;

  String? get rpsLastB => _rules.rpsLastB;

  int get rpsRound => _rules.rpsRound;

  List<List<Square>> get customsPathOptions =>
      _rules.customsPaths.map((p) => List<Square>.from(p)).toList();

  List<Square> get multiCellPicks => List<Square>.from(_rules.multiCellPicks);

  int get multiCellNeeded => _rules.multiCellNeeded;

  GameAbility? get multiCellAbility => _rules.multiCellAbility;

  String? get spotlightPromoPieceId => _rules.spotlightPromoId;

  List<Square> get tangledKeepSquares {
    if (!_rules.tangledAwaitingKeep) return const [];
    final out = <Square>[];
    final a = _pieceById(_rules.tangledKnightBaseId ?? '');
    final b = _pieceById(_rules.tangledCloneId ?? '');
    if (a != null) out.add(a.square);
    if (b != null) out.add(b.square);
    return out;
  }

  void _beginMultiCellTarget({
    required GameAbility ability,
    required String sourceId,
    required PieceColor color,
    required int needed,
  }) {
    _rules.multiCellPicks.clear();
    _rules.multiCellNeeded = needed;
    _rules.multiCellAbility = ability;
    _rules.multiCellSourceId = sourceId;
    _rules.multiCellColor = color;
    _beginAbilityTarget(
      ability: ability,
      sourceId: sourceId,
      color: color,
      selection: AbilityTargetSelection.cell,
      passesTurn: true,
    );
  }

  void _clearMultiCell() {
    _rules.multiCellPicks.clear();
    _rules.multiCellNeeded = 0;
    _rules.multiCellAbility = null;
    _rules.multiCellSourceId = null;
    _rules.multiCellColor = null;
  }

  List<Square> _legalMultiCellSquares() {
    final ability = _rules.multiCellAbility;
    final sourceId = _rules.multiCellSourceId;
    final color = _rules.multiCellColor;
    if (ability == null || color == null) return const [];
    final picked = _rules.multiCellPicks.toSet();
    final out = <Square>[];
    if (ability == GameAbility.knightGallopContract) {
      for (var r = 0; r < _rankCount; r++) {
        for (var f = 0; f < _fileCount; f++) {
          final s = Square(f, r);
          if (!picked.contains(s)) out.add(s);
        }
      }
      return out;
    }
    if (ability == GameAbility.bishopHeretic) {
      final halfMax = color == PieceColor.white ? (_rankCount ~/ 2) - 1 : _rankCount - 1;
      final halfMin = color == PieceColor.white ? 0 : _rankCount ~/ 2;
      for (var r = halfMin; r <= halfMax; r++) {
        for (var f = 0; f < _fileCount; f++) {
          final s = Square(f, r);
          if (picked.contains(s)) continue;
          if (piecesAt(s).isNotEmpty || isBlocked(s)) continue;
          out.add(s);
        }
      }
      return out;
    }
    if (ability == GameAbility.bishopCartographer) {
      final source = _pieceById(sourceId ?? '');
      if (source == null) return const [];
      for (final (df, dr) in const [(-1, -1), (-1, 1), (1, -1), (1, 1)]) {
        var f = source.square.file + df;
        var r = source.square.rank + dr;
        while (f >= 0 && f < _fileCount && r >= 0 && r < _rankCount) {
          final s = Square(f, r);
          if (!picked.contains(s)) out.add(s);
          f += df;
          r += dr;
        }
      }
      return out;
    }
    if (ability == GameAbility.pawnArchivist) {
      final visited = _rules.archivistVisited[sourceId] ?? {};
      for (final s in visited) {
        if (picked.contains(s)) continue;
        if (piecesAt(s).isNotEmpty || isBlocked(s)) continue;
        out.add(s);
      }
      return out;
    }
    return out;
  }

  bool _acceptMultiCellPick(Square square) {
    final ability = _rules.multiCellAbility;
    final sourceId = _rules.multiCellSourceId;
    if (ability == null || sourceId == null) return false;
    if (!_legalMultiCellSquares().contains(square)) return false;
    _rules.multiCellPicks.add(square);
    if (_rules.multiCellPicks.length < _rules.multiCellNeeded) {
      _updateStatus();
      return true;
    }
    final picks = List<Square>.from(_rules.multiCellPicks);
    final color = _rules.multiCellColor ?? PieceColor.white;
    _clearPendingTarget();
    switch (ability) {
      case GameAbility.knightGallopContract:
        _rules.gallopContractRoute[sourceId] = picks;
        _rules.gallopContractProgress[sourceId] = 0;
      case GameAbility.bishopHeretic:
        _applyHereticSplit(sourceId, picks);
      case GameAbility.bishopCartographer:
        _rules.permanentFogReveals.putIfAbsent(color, () => {}).add(picks.first);
      case GameAbility.pawnArchivist:
        _applyArchivistRecall(sourceId, picks.first);
      default:
        break;
    }
    _clearMultiCell();
    return _finishAbilityTargetSelection();
  }

  void _applyHereticSplit(String bishopId, List<Square> cells) {
    final ref = _pieceById(bishopId);
    if (ref == null) return;
    final color = ref.piece.color;
    final removed = _takePieceAt(ref.square, ref.index);
    if (removed != null) {
      // Consume bishop without graveyard inheritance noise during sim.
    }
    for (var i = 0; i < cells.length && i < 4; i++) {
      final s = cells[i];
      if (piecesAt(s).isNotEmpty) continue;
      _setPrimary(
        s,
        Piece(
          pieceId: 'heretic-$bishopId-$i',
          type: PieceType.pawn,
          color: color,
          hasMoved: true,
        ),
      );
    }
  }

  void _applyArchivistRecall(String pawnId, Square to) {
    final ref = _pieceById(pawnId);
    if (ref == null) return;
    if (_rules.archivistRecallUsed.contains(pawnId)) return;
    if (piecesAt(to).isNotEmpty) return;
    final piece = ref.piece;
    _takePieceAt(ref.square, ref.index);
    _setPrimary(to, piece);
    _rules.archivistRecallUsed.add(pawnId);
    _rules.archivistRecallArmed.remove(pawnId);
  }

  void _startRpsSession(PieceColor chooser) {
    _rules.rpsPairs
      ..clear()
      ..addAll(_findBlockingPawnPairs());
    if (_rules.rpsPairs.isEmpty) return;
    _rules.rpsSessionActive = true;
    _rules.rpsResolved = false;
    _rules.rpsChooser = chooser;
    _rules.rpsPairIndex = _rules.rpsPairs.length == 1 ? 0 : null;
    _rules.rpsLastA = null;
    _rules.rpsLastB = null;
    _rules.rpsRound = 0;
    if (_rules.rpsPairIndex != null) {
      _runRpsUntilWinner();
    }
  }

  List<(Square, Square)> _findBlockingPawnPairs() {
    final pairs = <(Square, Square)>[];
    for (var file = 0; file < _fileCount; file++) {
      for (var rank = 0; rank < _rankCount - 1; rank++) {
        final a = Square(file, rank);
        final b = Square(file, rank + 1);
        final pa = pieceAt(a);
        final pb = pieceAt(b);
        if (pa == null || pb == null) continue;
        if (pa.type != PieceType.pawn || pb.type != PieceType.pawn) continue;
        if (pa.color == pb.color) continue;
        pairs.add((a, b));
      }
    }
    return pairs;
  }

  bool chooseRpsPair(int index) {
    if (!_rules.rpsSessionActive || _rules.rpsPairIndex != null) return false;
    if (index < 0 || index >= _rules.rpsPairs.length) return false;
    _rules.rpsPairIndex = index;
    _runRpsUntilWinner();
    if (isAwaitingAbilityTarget &&
        _pendingTargetAbility == GameAbility.pawnRockPaperScissors) {
      _finishAbilityTargetSelection();
    }
    _updateStatus();
    return true;
  }

  void _runRpsUntilWinner() {
    final idx = _rules.rpsPairIndex;
    if (idx == null || idx < 0 || idx >= _rules.rpsPairs.length) return;
    final (aSq, bSq) = _rules.rpsPairs[idx];
    const gestures = ['rock', 'paper', 'scissors'];
    for (var round = 0; round < 32; round++) {
      final ga = gestures[_random.nextInt(3)];
      final gb = gestures[_random.nextInt(3)];
      _rules.rpsLastA = ga;
      _rules.rpsLastB = gb;
      _rules.rpsRound = round + 1;
      final winner = _rpsWinner(ga, gb);
      if (winner == 0) continue;
      final loserSq = winner > 0 ? bSq : aSq;
      final loser = pieceAt(loserSq);
      if (loser != null) {
        final removed = _takePieceAt(loserSq, 0);
        if (removed != null) _onFinalDeath(removed, loserSq);
      }
      break;
    }
    _rules.rpsResolved = true;
    _rules.rpsSessionActive = false;
    final chooser = _rules.rpsChooser;
    if (chooser != null && isAwaitingAbilityTarget) {
      _finishAbilityTargetSelection();
    } else if (chooser != null && isAwaitingSkillChoice) {
      // boardWide RPS applied during skill choice — resolution continues normally
    }
  }

  /// Returns 1 if A wins, -1 if B wins, 0 draw.
  int _rpsWinner(String a, String b) {
    if (a == b) return 0;
    if ((a == 'rock' && b == 'scissors') ||
        (a == 'scissors' && b == 'paper') ||
        (a == 'paper' && b == 'rock')) {
      return 1;
    }
    return -1;
  }

  List<(Square from, Square via1, Square via2, Square to)> _knightPathOptions(
    Square from,
    Square to,
  ) {
    final df = to.file - from.file;
    final dr = to.rank - from.rank;
    final adf = df.abs();
    final adr = dr.abs();
    if (!((adf == 1 && adr == 2) || (adf == 2 && adr == 1))) {
      return const [];
    }
    // Two Manhattan 3-step routes (2+1).
    final paths = <(Square, Square, Square, Square)>[];
    if (adf == 2 && adr == 1) {
      final mid1 = Square(from.file + df.sign, from.rank);
      final mid2 = Square(from.file + 2 * df.sign, from.rank);
      final midAlt1 = Square(from.file, from.rank + dr.sign);
      final midAlt2 = Square(from.file + df.sign, from.rank + dr.sign);
      if (isOnBoard(mid1) && isOnBoard(mid2)) {
        paths.add((from, mid1, mid2, to));
      }
      if (isOnBoard(midAlt1) && isOnBoard(midAlt2)) {
        paths.add((from, midAlt1, midAlt2, to));
      }
    } else {
      final mid1 = Square(from.file, from.rank + dr.sign);
      final mid2 = Square(from.file, from.rank + 2 * dr.sign);
      final midAlt1 = Square(from.file + df.sign, from.rank);
      final midAlt2 = Square(from.file + df.sign, from.rank + dr.sign);
      if (isOnBoard(mid1) && isOnBoard(mid2)) {
        paths.add((from, mid1, mid2, to));
      }
      if (isOnBoard(midAlt1) && isOnBoard(midAlt2)) {
        paths.add((from, midAlt1, midAlt2, to));
      }
    }
    return paths;
  }

  bool chooseCustomsPath(int index) {
    if (!_rules.awaitingCustomsPath) return false;
    if (index < 0 || index >= _rules.customsPaths.length) return false;
    final path = _rules.customsPaths[index];
    final from = _rules.customsFrom;
    final to = _rules.customsTo;
    final knightId = _rules.customsKnightId;
    final knightColor = _pieceById(knightId ?? '')?.piece.color;
    for (var i = 1; i < path.length - 1; i++) {
      final s = path[i];
      for (final p in List<Piece>.from(piecesAt(s))) {
        if (knightColor != null && p.color == knightColor) continue;
        if (p.abilities.isEmpty) continue;
        final mods = p.abilities.toList()..shuffle(_random);
        final ref = _pieceById(p.pieceId);
        if (ref == null) continue;
        _replacePieceAt(
          ref.square,
          ref.index,
          ref.piece.withoutAbility(mods.first),
        );
        _refreshDoppelgangerFlags();
        break;
      }
    }
    _rules.awaitingCustomsPath = false;
    _rules.customsPaths.clear();
    _rules.customsFrom = null;
    _rules.customsTo = null;
    _rules.customsKnightId = null;
    if (from == null || to == null || knightId == null) return false;
    final ref = _pieceById(knightId);
    if (ref == null) return false;
    _rules.customsPathResolvedSkip = true;
    final result = makeMove(Move(from: from, to: to, pieceIndex: ref.index));
    return result != null;
  }

  bool chooseTangledKeep(Square square) {
    if (!_rules.tangledAwaitingKeep) return false;
    final base = _pieceById(_rules.tangledKnightBaseId ?? '');
    final clone = _pieceById(_rules.tangledCloneId ?? '');
    if (base == null && clone == null) {
      _rules.tangledAwaitingKeep = false;
      return false;
    }
    final keepBase = base != null && base.square == square;
    final keepClone = clone != null && clone.square == square;
    if (!keepBase && !keepClone) return false;
    if (keepBase && clone != null) {
      final removed = _takePieceAt(clone.square, clone.index);
      if (removed != null) {
        // Vanish without graveyard reward — temporary clone.
      }
    } else if (keepClone && base != null) {
      final removed = _takePieceAt(base.square, base.index);
      if (removed != null) {}
      // Promote clone identity? keep clone as-is.
    }
    _rules.tangledAwaitingKeep = false;
    _rules.tangledCloneId = null;
    _rules.tangledKnightBaseId = null;
    _rules.tangledFrom = null;
    _rules.tangledFirstDest = null;
    _updateStatus();
    return true;
  }

  bool activateDoubleLife(String pieceId) {
    final ref = _pieceById(pieceId);
    if (ref == null) return false;
    if (!_hasEffect(ref.piece, AbilityEffect.pawnDoubleLife)) return false;
    if (_rules.doubleLifeUsed.contains(pieceId)) return false;
    final hidden = _rules.doubleLifeHidden[pieceId];
    if (hidden == null) return false;
    _rules.doubleLifeArmed.add(pieceId);
    _replacePieceAt(
      ref.square,
      ref.index,
      ref.piece.copyWith(moveAsType: hidden),
    );
    _updateStatus();
    return true;
  }

  bool activateArchivistRecall(String pieceId) {
    final ref = _pieceById(pieceId);
    if (ref == null) return false;
    if (!_hasEffect(ref.piece, AbilityEffect.pawnArchivist)) return false;
    if (_rules.archivistRecallUsed.contains(pieceId)) return false;
    _rules.archivistRecallArmed.add(pieceId);
    _beginMultiCellTarget(
      ability: GameAbility.pawnArchivist,
      sourceId: pieceId,
      color: ref.piece.color,
      needed: 1,
    );
    _updateStatus();
    return true;
  }

  bool completeSpotlightPromo(PieceType type) {
    final id = _rules.spotlightPromoId;
    if (id == null) return false;
    if (type != PieceType.knight && type != PieceType.bishop) return false;
    final ref = _pieceById(id);
    if (ref == null) {
      _rules.spotlightPromoId = null;
      return false;
    }
    _replacePieceAt(
      ref.square,
      ref.index,
      ref.piece.copyWith(type: type),
    );
    _rules.spotlightPromoId = null;
    _rules.spotlightUnderFire.remove(id);
    _updateStatus();
    return true;
  }

  void _applySchismSplit(String bishopId) {
    final ref = _pieceById(bishopId);
    if (ref == null) return;
    final color = ref.piece.color;
    final origin = ref.square;
    // Two half-bishops: diag signs +1 and -1 (file-rank parity of direction).
    _rules.schismDiagSign[bishopId] = 1;
    final cloneId = '$bishopId-schism';
    // Place clone on adjacent free diagonal cell if possible, else same file+1.
    Square? dest;
    for (final (df, dr) in const [(1, 1), (1, -1), (-1, 1), (-1, -1), (1, 0), (-1, 0)]) {
      final s = Square(origin.file + df, origin.rank + dr);
      if (!isOnBoard(s)) continue;
      if (piecesAt(s).isNotEmpty || isBlocked(s)) continue;
      dest = s;
      break;
    }
    if (dest == null) return;
    _setPrimary(
      dest,
      Piece(
        pieceId: cloneId,
        type: PieceType.bishop,
        color: color,
        hasMoved: true,
        abilities: {GameAbility.bishopSchism},
      ),
    );
    _rules.schismDiagSign[cloneId] = -1;
  }

  void _tickRelicAndSpotlight(PieceColor finished) {
    // Relic: countdown; revive if square empty while timer remains.
    final relicKeys = _rules.relicPliesLeft.keys.toList();
    for (final id in relicKeys) {
      final left = (_rules.relicPliesLeft[id] ?? 0) - 1;
      final death = _rules.relicDeathSquare[id];
      if (death == null) {
        _rules.relicPliesLeft.remove(id);
        continue;
      }
      // If death square empty now and was occupied last by finished color...
      // Simpler rule: if square empty at tick end, revive for the color that
      // had the bishop — encoded in id prefix? We stored only pieceId.
      // Revive for whoever can: check if any ally of either color just left.
      if (piecesAt(death).isEmpty && left >= 0) {
        // Determine color from graveyard
        PieceColor? color;
        for (final g in _graveyard.reversed) {
          if (g.piece.pieceId == id) {
            color = g.originalOwner;
            break;
          }
        }
        if (color != null && color == finished) {
          // Only revive after the owner finished a ply with square empty
          // (they stood and left earlier this turn sequence).
          _setPrimary(
            death,
            Piece(
              pieceId: '$id-revived',
              type: PieceType.bishop,
              color: color,
              hasMoved: true,
            ),
          );
          _rules.relicPliesLeft.remove(id);
          _rules.relicDeathSquare.remove(id);
          continue;
        }
      }
      if (left <= 0) {
        _rules.relicPliesLeft.remove(id);
        _rules.relicDeathSquare.remove(id);
      } else {
        _rules.relicPliesLeft[id] = left;
      }
    }

    // Spotlight: pawn under enemy pawn attack for 6 owner plies
    for (var r = 0; r < _rankCount; r++) {
      for (var f = 0; f < _fileCount; f++) {
        final sq = Square(f, r);
        for (final p in piecesAt(sq)) {
          if (!_hasEffect(p, AbilityEffect.pawnSpotlight)) continue;
          if (p.color != finished) continue;
          final under = _isAttackedByEnemyPawns(sq, p.color);
          if (under) {
            final n = (_rules.spotlightUnderFire[p.pieceId] ?? 0) + 1;
            _rules.spotlightUnderFire[p.pieceId] = n;
            if (n >= 6) {
              _rules.spotlightPromoId = p.pieceId;
            }
          } else {
            _rules.spotlightUnderFire[p.pieceId] = 0;
          }
        }
      }
    }
  }

  bool _isAttackedByEnemyPawns(Square square, PieceColor defender) {
    final dir = defender == PieceColor.white ? 1 : -1;
    // Enemy pawns attack from behind relative to defender forward.
    for (final df in [-1, 1]) {
      final from = Square(square.file + df, square.rank - dir);
      if (!isOnBoard(from)) continue;
      final p = pieceAt(from);
      if (p != null &&
          p.color == defender.opponent &&
          p.type == PieceType.pawn) {
        return true;
      }
    }
    return false;
  }

  void _tryKingGuardAuto(PieceColor checkedColor) {
    if (!isInCheck(checkedColor)) return;
    final guards = <({Square square, int index, Piece piece})>[];
    for (var r = 0; r < _rankCount; r++) {
      for (var f = 0; f < _fileCount; f++) {
        final sq = Square(f, r);
        for (var i = 0; i < piecesAt(sq).length; i++) {
          final p = piecesAt(sq)[i];
          if (p.color != checkedColor) continue;
          if (!_hasEffect(p, AbilityEffect.kingGuardAuto) &&
              !_rules.kingGuardPieceIds.contains(p.pieceId)) {
            continue;
          }
          guards.add((square: sq, index: i, piece: p));
        }
      }
    }
    if (guards.isEmpty) return;
    final kingSq = findKing(checkedColor);
    if (kingSq == null) return;
    // Find checkers
    final checkers = <({Square square, Piece piece})>[];
    for (var r = 0; r < _rankCount; r++) {
      for (var f = 0; f < _fileCount; f++) {
        final from = Square(f, r);
        for (final p in piecesAt(from)) {
          if (p.color != checkedColor.opponent) continue;
          if (_canAttack(from, kingSq, p)) {
            checkers.add((square: from, piece: p));
          }
        }
      }
    }
    if (checkers.isEmpty) return;
    for (final guard in guards) {
      // Prefer capture of checker
      for (final c in checkers) {
        if (_canAttack(guard.square, c.square, guard.piece) &&
            _captureAllowed(guard.piece, c.piece)) {
          final snapshot = createSnapshot();
          _isSimulatingLegality = true;
          try {
            _applyMove(
              Move(
                from: guard.square,
                to: c.square,
                pieceIndex: guard.index,
              ),
            );
            if (!isInCheck(checkedColor)) {
              _isSimulatingLegality = false;
              // Apply for real
              restoreSnapshot(snapshot);
              _applyMove(
                Move(
                  from: guard.square,
                  to: c.square,
                  pieceIndex: guard.index,
                ),
              );
              return;
            }
          } finally {
            _isSimulatingLegality = false;
            restoreSnapshot(snapshot);
          }
        }
      }
      // Interpose on sliding check
      if (checkers.length == 1) {
        final c = checkers.first;
        final blockSquares = _squaresBetween(c.square, kingSq);
        for (final block in blockSquares) {
          if (piecesAt(block).isNotEmpty) continue;
          if (!_canAttack(guard.square, block, guard.piece) &&
              !_pseudoCanMoveTo(guard.square, block, guard.piece, guard.index)) {
            // Use legal move list
          }
          final moves = _getPseudoLegalMoves(
            guard.square,
            guard.piece,
            pieceIndex: guard.index,
          );
          if (!moves.any((m) => m.to == block)) continue;
          final snapshot = createSnapshot();
          try {
            _isSimulatingLegality = true;
            _applyMove(
              Move(from: guard.square, to: block, pieceIndex: guard.index),
            );
            if (!isInCheck(checkedColor)) {
              _isSimulatingLegality = false;
              restoreSnapshot(snapshot);
              _applyMove(
                Move(from: guard.square, to: block, pieceIndex: guard.index),
              );
              return;
            }
          } finally {
            _isSimulatingLegality = false;
            restoreSnapshot(snapshot);
          }
        }
      }
    }
  }

  List<Square> _squaresBetween(Square a, Square b) {
    final df = (b.file - a.file).sign;
    final dr = (b.rank - a.rank).sign;
    final adf = (b.file - a.file).abs();
    final adr = (b.rank - a.rank).abs();
    if (df != 0 && dr != 0 && adf != adr) return const [];
    if (df == 0 && dr == 0) return const [];
    final out = <Square>[];
    var f = a.file + df;
    var r = a.rank + dr;
    while (f != b.file || r != b.rank) {
      out.add(Square(f, r));
      f += df;
      r += dr;
    }
    return out;
  }

  bool _pseudoCanMoveTo(
    Square from,
    Square to,
    Piece piece,
    int pieceIndex,
  ) {
    return _getPseudoLegalMoves(
      from,
      piece,
      pieceIndex: pieceIndex,
    ).any((m) => m.to == to);
  }



}

/// Complete restorable gameplay state.
///
/// Random generator state and the ability catalog are intentionally not part
/// of the snapshot; random outcomes must be resolved before a future network
/// snapshot is distributed.

class GameSnapshot {
  GameSnapshot._({
    required this.board,
    required this.stackExtra,
    required this.nextPieceId,
    required this.fileCount,
    required this.rankCount,
    required this.extraFileOnLeft,
    required this.turn,
    required this.enPassantTarget,
    required this.status,
    required this.winnerColor,
    required this.endReason,
    required this.endDetail,
    required this.whiteStartChosen,
    required this.blackStartChosen,
    required this.whiteStartOffers,
    required this.blackStartOffers,
    required this.pendingSkillSquare,
    required this.pendingSkillPieceId,
    required this.pendingSkillColor,
    required this.pendingCaptureOffers,
    required this.auctionSquare,
    required this.pendingAuctionSquare,
    required this.pendingAuctionColor,
    required this.pendingBonusSkillColor,
    required this.skillChoiceIsBonus,
    required this.whiteBoardAbility,
    required this.blackBoardAbility,
    required this.bloodOathActive,
    required this.baskervilleActive,
    required this.whiteBaskervilleChecks,
    required this.blackBaskervilleChecks,
    required this.goldenThroneWhite,
    required this.goldenThroneBlack,
    required this.pendingGoldenThroneColor,
    required this.exterminatusPliesLeft,
    required this.silentFile,
    required this.whiteStartAbilityInfo,
    required this.blackStartAbilityInfo,
    required this.whiteChosenAbilities,
    required this.blackChosenAbilities,
    required this.whiteOneShotReroll,
    required this.blackOneShotReroll,
    required this.whitePermanentReroll,
    required this.blackPermanentReroll,
    required this.lavaRanks,
    required this.pendingLavaDeaths,
    required this.fogOfWar,
    required this.sprintActive,
    required this.quarantineSquare,
    required this.quarantineMovesLeft,
    required this.wormholes,
    required this.zebrasActive,
    required this.whiteDoppelganger,
    required this.blackDoppelganger,
    required this.squareColorLockIsLight,
    required this.squareColorLockMovesLeft,
    required this.truceMovesLeft,
    required this.mirrorActive,
    required this.whiteCavalryMovesLeft,
    required this.blackCavalryMovesLeft,
    required this.whiteThrone,
    required this.blackThrone,
    required this.plagueActive,
    required this.fourHorsemenActive,
    required this.ghostCells,
    required this.attractionActive,
    required this.attractionMoveCounter,
    required this.virusActive,
    required this.invisibleRegiment,
    required this.shuffledSquareLight,
    required this.teleportA,
    required this.teleportB,
    required this.mines,
    required this.golcondaActive,
    required this.unbridledHorse,
    required this.dustSquares,
    required this.laserFiles,
    required this.laserFileOwner,
    required this.awaitingGallopFrom,
    required this.awaitingGallopIndex,
    required this.pendingTargetSelection,
    required this.pendingTargetAbility,
    required this.pendingTargetSourceId,
    required this.pendingTargetColor,
    required this.pendingTargetPassesTurn,
    required this.pendingReactionMove,
    required this.pendingRansomPawnId,
    required this.queuedSkillPieceId,
    required this.queuedSkillColor,
    required this.duelLinks,
    required this.guardSquares,
    required this.guardTurnsLeft,
    required this.knightTourVisited,
    required this.knightTourRewardUsed,
    required this.sanctuaryTargets,
    required this.excommunicationTypes,
    required this.titheSuppressions,
    required this.pilgrimageQuadrants,
    required this.pilgrimageCompleted,
    required this.pilgrimageProtected,
    required this.customsStates,
    required this.curfewBindings,
    required this.siegeStates,
    required this.delayedSentences,
    required this.graveyard,
    required this.graveyardSequence,
    required this.pendingExchangeOwnSequence,
    required this.pendingRemoveModTargetId,
    required this.boardRules,
  });

  final List<List<Piece?>> board;
  final Map<String, Piece> stackExtra;
  final int nextPieceId;
  final int fileCount;
  final int rankCount;
  final bool? extraFileOnLeft;
  final PieceColor turn;
  final Square? enPassantTarget;
  final GameStatus status;
  final PieceColor? winnerColor;
  final GameEndReason? endReason;
  final String? endDetail;
  final bool whiteStartChosen;
  final bool blackStartChosen;
  final List<AbilityOffer> whiteStartOffers;
  final List<AbilityOffer> blackStartOffers;
  final Square? pendingSkillSquare;
  final String? pendingSkillPieceId;
  final PieceColor? pendingSkillColor;
  final List<AbilityOffer> pendingCaptureOffers;
  final Square? auctionSquare;
  final Square? pendingAuctionSquare;
  final PieceColor? pendingAuctionColor;
  final PieceColor? pendingBonusSkillColor;
  final bool skillChoiceIsBonus;
  final GameAbility? whiteBoardAbility;
  final GameAbility? blackBoardAbility;
  final bool bloodOathActive;
  final bool baskervilleActive;
  final int whiteBaskervilleChecks;
  final int blackBaskervilleChecks;
  final bool goldenThroneWhite;
  final bool goldenThroneBlack;
  final PieceColor? pendingGoldenThroneColor;
  final int exterminatusPliesLeft;
  final int? silentFile;
  final ChosenAbilityInfo? whiteStartAbilityInfo;
  final ChosenAbilityInfo? blackStartAbilityInfo;
  final List<ChosenAbilityInfo> whiteChosenAbilities;
  final List<ChosenAbilityInfo> blackChosenAbilities;
  final bool whiteOneShotReroll;
  final bool blackOneShotReroll;
  final bool whitePermanentReroll;
  final bool blackPermanentReroll;
  final Set<int> lavaRanks;
  final List<LavaDeathEvent> pendingLavaDeaths;
  final bool fogOfWar;
  final bool sprintActive;
  final Square? quarantineSquare;
  final int quarantineMovesLeft;
  final Set<Square> wormholes;
  final bool zebrasActive;
  final bool whiteDoppelganger;
  final bool blackDoppelganger;
  final bool? squareColorLockIsLight;
  final int squareColorLockMovesLeft;
  final int truceMovesLeft;
  final bool mirrorActive;
  final int whiteCavalryMovesLeft;
  final int blackCavalryMovesLeft;
  final Square whiteThrone;
  final Square blackThrone;
  final bool plagueActive;
  final bool fourHorsemenActive;
  final Set<Square> ghostCells;
  final bool attractionActive;
  final int attractionMoveCounter;
  final bool virusActive;
  final bool invisibleRegiment;
  final List<List<bool>>? shuffledSquareLight;
  final Square? teleportA;
  final Square? teleportB;
  final Set<Square> mines;
  final bool golcondaActive;
  final bool unbridledHorse;
  final Map<Square, int> dustSquares;
  final Map<int, int> laserFiles;
  final Map<int, PieceColor> laserFileOwner;
  final Square? awaitingGallopFrom;
  final int awaitingGallopIndex;
  final AbilityTargetSelection? pendingTargetSelection;
  final GameAbility? pendingTargetAbility;
  final String? pendingTargetSourceId;
  final PieceColor? pendingTargetColor;
  final bool pendingTargetPassesTurn;
  final Move? pendingReactionMove;
  final String? pendingRansomPawnId;
  final String? queuedSkillPieceId;
  final PieceColor? queuedSkillColor;
  final Map<String, String> duelLinks;
  final Map<String, Square> guardSquares;
  final Map<String, int> guardTurnsLeft;
  final Map<String, Set<Square>> knightTourVisited;
  final Set<String> knightTourRewardUsed;
  final Map<String, String> sanctuaryTargets;
  final Map<String, PieceType> excommunicationTypes;
  final Map<String, Map<String, GameAbility>> titheSuppressions;
  final Map<String, Set<int>> pilgrimageQuadrants;
  final Set<String> pilgrimageCompleted;
  final Set<String> pilgrimageProtected;
  final Map<String, CustomsState> customsStates;
  final Map<String, RookCurfewState> curfewBindings;
  final Map<String, SiegeInternalState> siegeStates;
  final Map<String, DelayedSentenceState> delayedSentences;
  final List<GraveyardRecord> graveyard;
  final int graveyardSequence;
  final int? pendingExchangeOwnSequence;
  final String? pendingRemoveModTargetId;
  final BoardCataclysmState boardRules;
}

extension on PieceColor {
  PieceColor get opponent =>
      this == PieceColor.white ? PieceColor.black : PieceColor.white;
}
