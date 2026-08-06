import 'dart:math';

import '../../chess/board_labels.dart';
import 'ability_effects.dart';
import 'ability_group.dart';
import 'game_ability.dart';
import 'piece.dart';
import 'square.dart';

class AbilityCatalog {
  AbilityCatalog({Random? random}) : _random = random ?? Random();

  final Random _random;

  static const modeAbilities = [
    GameAbility.boardTide,
    GameAbility.boardMarseillesChess,
    GameAbility.boardTurncoats,
    GameAbility.boardFrostMap,
  ];

  static const boardAbilities = [
    GameAbility.boardPawnsSideways,
    GameAbility.boardPawnsDiagonal,
    GameAbility.boardPawnsBackward,
    GameAbility.boardKingSwap,
    GameAbility.boardLavaRank,
    GameAbility.boardExtraRank,
    GameAbility.boardExtraFile,
    GameAbility.boardFogOfWar,
    GameAbility.boardDoubleStart,
    GameAbility.boardSprint,
    GameAbility.boardZebras,
    GameAbility.boardFisher,
    GameAbility.boardFisherMadness,
    GameAbility.boardNight,
    GameAbility.boardDay,
    GameAbility.boardColorblind,
    GameAbility.boardPawnFront,
    GameAbility.boardCavalry,
    GameAbility.boardMirror,
    GameAbility.boardGhostCells,
    GameAbility.boardAttraction,
    GameAbility.boardVirus,
    GameAbility.boardInvisibleRegiment,
    GameAbility.boardShuffle,
    GameAbility.boardTeleport,
    GameAbility.boardVanityFair,
    GameAbility.boardMinefield,
    GameAbility.boardGolconda,
    GameAbility.boardUnbridledHorse,
    GameAbility.boardBaskerville,
    GameAbility.boardBloodOath,
    GameAbility.boardSilentFile,
    GameAbility.boardFourHorsemen,
    GameAbility.boardReroll,
    GameAbility.boardPassiveAggression,
    GameAbility.boardSkipTurn,
    GameAbility.boardTroopFatigue,
    GameAbility.boardCombatOptics,
    GameAbility.boardKingOfHill,
    GameAbility.boardSecretRoute,
    GameAbility.boardRoyalPilgrimage,
    GameAbility.boardMightMakesRight,
    GameAbility.boardExpeditionaryCorps,
    GameAbility.boardWitnessProtection,
    GameAbility.boardDeserters,
    GameAbility.boardLetterH,
    GameAbility.boardFullCircle,
    GameAbility.boardArchitect,
    GameAbility.boardBigAssortment,
    GameAbility.boardBlindSpot,
    GameAbility.boardOnlyEqualsKill,
    GameAbility.boardInitiativeFear,
    GameAbility.boardSwamp,
    GameAbility.boardCollectiveMyopia,
    GameAbility.boardTerritoryExpand,
    GameAbility.boardScorchingSun,
  ];

  static const randomAbilities = [
    GameAbility.randomShift,
    GameAbility.randomCalm,
    GameAbility.randomQuarantine,
    GameAbility.randomEarthquake,
    GameAbility.randomTyphoon,
    GameAbility.randomWormhole,
    GameAbility.randomClone,
    GameAbility.randomNoQueen,
    GameAbility.randomTruce,
    GameAbility.randomMeteorRain,
    GameAbility.randomCensus,
    GameAbility.randomExterminatus,
    GameAbility.randomGoldenThrone,
    GameAbility.randomLottery,
    GameAbility.randomPlague,
    GameAbility.randomMutation,
    GameAbility.randomAuction,
    GameAbility.randomRightToMove,
    GameAbility.randomFurtherMore,
    GameAbility.randomWordOfHonor,
    GameAbility.randomSymmetry,
    GameAbility.randomVeto,
    GameAbility.randomInitiativeIntercept,
    GameAbility.randomStrike,
    GameAbility.randomBorderClosure,
    GameAbility.randomMyopia,
    GameAbility.randomMagicShutdown,
    GameAbility.randomTimeCapsule,
    GameAbility.randomSuicideCapture,
    GameAbility.randomMeatGrinder,
    GameAbility.randomQuicksand,
  ];

  static const pawnAbilities = [
    GameAbility.pawnSideways,
    GameAbility.pawnInverted,
    GameAbility.pawnAlwaysDoubleStep,
    GameAbility.pawnRam,
    GameAbility.pawnAirborne,
    GameAbility.pawnBoomerang,
    GameAbility.pawnKamikaze,
    GameAbility.pawnCaliph,
    GameAbility.pawnSticky,
    GameAbility.pawnPolymorph,
    GameAbility.pawnInheritance,
    GameAbility.pawnRansom,
    GameAbility.pawnForTheKing,
    GameAbility.pawnCamouflageNet,
    GameAbility.pawnTrench,
    GameAbility.pawnSignalFire,
    GameAbility.pawnAvengeMe,
    GameAbility.pawnCaravan,
    GameAbility.pawnFaceControl,
  ];

  static const knightAbilities = [
    GameAbility.knightRearing,
    GameAbility.knightLongJump,
    GameAbility.knightSecondChance,
    GameAbility.knightBoomerang,
    GameAbility.knightGallop,
    GameAbility.knightDust,
    GameAbility.knightCentaur,
    GameAbility.knightTrojan,
    GameAbility.knightDuel,
    GameAbility.knightGuard,
    GameAbility.knightTour,
    GameAbility.knightDoppelgangerOnce,
    GameAbility.knightDoppelgangers,
    GameAbility.knightFifthLeg,
    GameAbility.knightElusive,
    GameAbility.knightStomp,
    GameAbility.knightSurveyor,
    GameAbility.knightCornerQuest,
    GameAbility.knightRideMe,
    GameAbility.knightMagicHooves,
    GameAbility.knightSignalFire,
  ];

  static const bishopAbilities = [
    GameAbility.bishopHopAlly,
    GameAbility.bishopColorChaos,
    GameAbility.bishopBoomerang,
    GameAbility.bishopInquisitor,
    GameAbility.bishopColorVow,
    GameAbility.bishopBrothers,
    GameAbility.bishopSanctuary,
    GameAbility.bishopExcommunication,
    GameAbility.bishopTithe,
    GameAbility.bishopPilgrimage,
    GameAbility.bishopCrusade,
    GameAbility.bishopPost,
    GameAbility.bishopParallelWorlds,
    GameAbility.bishopAlcove,
    GameAbility.bishopGlassCeiling,
    GameAbility.bishopElusive,
    GameAbility.bishopSignalFire,
  ];

  static const rookAbilities = [
    GameAbility.rookHopAlly,
    GameAbility.rookRam,
    GameAbility.rookAstronomicon,
    GameAbility.rookFortress,
    GameAbility.rookStandardBearer,
    GameAbility.rookCustoms,
    GameAbility.rookDrawbridge,
    GameAbility.rookCurfew,
    GameAbility.rookSiegeCalculation,
    GameAbility.rookFerry,
    GameAbility.rookSignalTower,
    GameAbility.rookSignalFire,
  ];

  static const queenAbilities = [
    GameAbility.queenKnightStep,
    GameAbility.queenHopAlly,
    GameAbility.queenSplit,
    GameAbility.queenMatka,
    GameAbility.queenShadowEmpress,
    GameAbility.queenEscape,
    GameAbility.queenDelayedSentence,
    GameAbility.queenTrophyEmbargo,
    GameAbility.queenYouShallNotPass,
  ];

  static const kingAbilities = [
    GameAbility.kingRoyalDecree,
    GameAbility.kingExtraStep,
    GameAbility.kingShield,
    GameAbility.kingAura,
    GameAbility.kingDoppelganger,
    GameAbility.kingThrone,
    GameAbility.kingFamilyUnion,
    GameAbility.kingPrisonerExchange,
    GameAbility.kingRemoveEnemyMod,
    GameAbility.kingAssemblyHall,
  ];

  static List<GameAbility> abilitiesForGroup(AbilityGroup group) {
    switch (group) {
      case AbilityGroup.mode:
        return modeAbilities;
      case AbilityGroup.board:
        return boardAbilities;
      case AbilityGroup.random:
        return randomAbilities;
      case AbilityGroup.pawn:
        return pawnAbilities;
      case AbilityGroup.knight:
        return knightAbilities;
      case AbilityGroup.bishop:
        return bishopAbilities;
      case AbilityGroup.rook:
        return rookAbilities;
      case AbilityGroup.queen:
        return queenAbilities;
      case AbilityGroup.king:
        return kingAbilities;
    }
  }

  List<AbilityOffer> pickStartOffers({
    required PieceColor forColor,
    Set<GameAbility> excludedAbilities = const {},
  }) {
    // Start pool: Режим (start-only) + Доска.
    final available = [
      ...modeAbilities,
      ...boardAbilities,
    ].where((ability) => !excludedAbilities.contains(ability)).toList();
    final picked = _pickUnique(available, 3);
    return picked
        .map(_offerForStart)
        .map((offer) => offer.withChooser(forColor))
        .toList();
  }

  /// Mid-game wave: all groups with equal probability, filtered by available
  /// piece types and already-chosen abilities for [forColor].
  List<AbilityOffer> pickPeriodicOffers({
    required PieceColor forColor,
    required List<List<Piece?>> board,
    required int rankCount,
    required ExtraFilePlacement extraFilePlacement,
    Set<Square> blockedSquares = const {},
    Set<GameAbility> chosenAbilities = const {},
    Set<GameAbility> excludedAbilities = const {},
    bool fogOfWarActive = false,
    bool minesActive = false,
    bool mirrorActive = false,
    bool offerFourChoices = false,
    bool chooserDeliversCheck = false,
    bool hasFriendlyPrisoners = false,
  }) {
    final fileCount = board.isEmpty ? 8 : board.first.length;
    final availableTypes = <PieceType>{};
    for (final type in PieceType.values) {
      if (_countPieces(board, rankCount, fileCount, forColor, type) > 0) {
        availableTypes.add(type);
      }
    }

    final blocked = {...chosenAbilities, ...excludedAbilities};
    var pool = <GameAbility>[
      ...boardAbilities,
      ...randomAbilities,
      ...pawnAbilities,
      ...knightAbilities,
      ...bishopAbilities,
      ...rookAbilities,
      ...queenAbilities,
      ...kingAbilities,
    ];

    pool = pool.where((ability) {
      if (blocked.contains(ability)) return false;
      final type = switch (ability.group) {
        AbilityGroup.mode ||
        AbilityGroup.board ||
        AbilityGroup.random => null,
        AbilityGroup.pawn => PieceType.pawn,
        AbilityGroup.knight => PieceType.knight,
        AbilityGroup.bishop => PieceType.bishop,
        AbilityGroup.rook => PieceType.rook,
        AbilityGroup.queen => PieceType.queen,
        AbilityGroup.king => PieceType.king,
      };
      if (type == null) return true;
      return availableTypes.contains(type);
    }).toList();

    if (!minesActive) {
      pool.remove(GameAbility.pawnForTheKing);
    }
    if (!fogOfWarActive) {
      pool
        ..remove(GameAbility.pawnSignalFire)
        ..remove(GameAbility.knightSignalFire)
        ..remove(GameAbility.bishopSignalFire)
        ..remove(GameAbility.rookSignalFire)
        ..remove(GameAbility.rookSignalTower);
    }
    if (mirrorActive) {
      pool.remove(GameAbility.rookFerry);
    }
    if (_countPieces(
          board,
          rankCount,
          fileCount,
          forColor,
          PieceType.bishop,
        ) <
        2) {
      pool.remove(GameAbility.bishopBrothers);
    }
    if (!_hasEnemyAbilityPiece(board, rankCount, fileCount, forColor)) {
      pool.remove(GameAbility.kingRemoveEnemyMod);
    }
    if (!_bishopHasAllyOnDiagonal(board, rankCount, fileCount, forColor)) {
      pool.remove(GameAbility.bishopParallelWorlds);
    }
    if (chooserDeliversCheck) {
      pool.remove(GameAbility.randomRightToMove);
    }
    if (!hasFriendlyPrisoners) {
      pool.remove(GameAbility.kingPrisonerExchange);
    }
    // Setup rearrangements only make sense before the first move.
    pool
      ..remove(GameAbility.boardFisher)
      ..remove(GameAbility.boardFisherMadness);

    final count = offerFourChoices ? 4 : 3;
    final picked = _pickUnique(pool, count);
    while (picked.length < count) {
      // Fallback: any remaining non-blocked board/random ability.
      final fallbackPool = [
        ...boardAbilities,
        ...randomAbilities,
      ]
          .where((a) => !blocked.contains(a) && !picked.contains(a))
          .where(
            (a) =>
                a != GameAbility.boardFisher &&
                a != GameAbility.boardFisherMadness,
          )
          .toList();
      if (fallbackPool.isEmpty) break;
      picked.add(fallbackPool[_random.nextInt(fallbackPool.length)]);
    }

    if (offerFourChoices &&
        picked.length >= 4 &&
        picked[3].group != AbilityGroup.random) {
      final cataclysms = randomAbilities
          .where((a) => !blocked.contains(a) && !picked.contains(a))
          .toList();
      if (cataclysms.isNotEmpty) {
        picked[3] = cataclysms[_random.nextInt(cataclysms.length)];
      }
    }

    return picked
        .map(
          (ability) => _offerForPeriodic(
            ability,
            forColor: forColor,
            board: board,
            rankCount: rankCount,
            fileCount: fileCount,
            extraFilePlacement: extraFilePlacement,
            blockedSquares: blockedSquares,
          ),
        )
        .map((offer) => offer.withChooser(forColor, rankCount: rankCount))
        .toList();
  }

  List<AbilityOffer> rerollPeriodicOffers({
    required PieceColor forColor,
    required List<List<Piece?>> board,
    required int rankCount,
    required ExtraFilePlacement extraFilePlacement,
    required Iterable<AbilityOffer> oldOffers,
    Set<Square> blockedSquares = const {},
    Set<GameAbility> chosenAbilities = const {},
    bool fogOfWarActive = false,
    bool minesActive = false,
    bool mirrorActive = false,
    bool offerFourChoices = false,
  }) {
    return pickPeriodicOffers(
      forColor: forColor,
      board: board,
      rankCount: rankCount,
      extraFilePlacement: extraFilePlacement,
      blockedSquares: blockedSquares,
      chosenAbilities: chosenAbilities,
      excludedAbilities: oldOffers.map((offer) => offer.ability).toSet(),
      fogOfWarActive: fogOfWarActive,
      minesActive: minesActive,
      mirrorActive: mirrorActive,
      offerFourChoices: offerFourChoices,
    );
  }

  AbilityOffer _offerForPeriodic(
    GameAbility ability, {
    required PieceColor forColor,
    required List<List<Piece?>> board,
    required int rankCount,
    required int fileCount,
    required ExtraFilePlacement extraFilePlacement,
    required Set<Square> blockedSquares,
  }) {
    final group = ability.group;
    if (group == AbilityGroup.board) {
      return _offerForStart(ability);
    }
    if (group == AbilityGroup.random) {
      return _bakeRandomOffer(
        ability,
        board,
        rankCount,
        fileCount,
        forColor,
        extraFilePlacement,
        blockedSquares,
      );
    }
    if (group == AbilityGroup.king) {
      return AbilityOffer(
        ability: ability,
        applyMode: AbilityApplyMode.selectFriendlyPiece,
        landOnLight: ability == GameAbility.queenShadowEmpress
            ? _random.nextBool()
            : null,
        axis: ability == GameAbility.rookCustoms
            ? (_random.nextBool() ? AbilityAxis.rank : AbilityAxis.file)
            : null,
        targetSelection: _targetSelectionFor(ability),
      );
    }
    return AbilityOffer(
      ability: ability,
      applyMode: AbilityApplyMode.selectFriendlyPiece,
      landOnLight: ability == GameAbility.queenShadowEmpress
          ? _random.nextBool()
          : null,
      axis: ability == GameAbility.rookCustoms
          ? (_random.nextBool() ? AbilityAxis.rank : AbilityAxis.file)
          : null,
      targetSelection: _targetSelectionFor(ability),
    );
  }

  /// Bake parameters for a specific random/cataclysm ability.
  AbilityOffer _bakeRandomOffer(
    GameAbility ability,
    List<List<Piece?>> board,
    int rankCount,
    int fileCount,
    PieceColor forColor,
    ExtraFilePlacement extraFilePlacement,
    Set<Square> blockedSquares,
  ) {
    AbilityOffer pickOrPlain(List<AbilityOffer> options) {
      if (options.isNotEmpty) {
        return options[_random.nextInt(options.length)];
      }
      return AbilityOffer(
        ability: ability,
        applyMode: AbilityApplyMode.boardWide,
        targetSelection: _targetSelectionFor(ability),
      );
    }

    if (ability == GameAbility.randomQuicksand) {
      return AbilityOffer(
        ability: ability,
        applyMode: AbilityApplyMode.boardWide,
        mineCount: 2 + _random.nextInt(4),
        durationMoves: 2 + _random.nextInt(4),
      );
    }
    if (ability == GameAbility.randomShift) {
      final options = <AbilityOffer>[];
      for (var file = 0; file < fileCount; file++) {
        for (final direction in [1, -1]) {
          if (canShiftFile(board, rankCount, file, direction)) {
            options.add(
              AbilityOffer(
                ability: ability,
                applyMode: AbilityApplyMode.boardWide,
                shiftFile: file,
                shiftDirection: direction,
                boardFileCount: fileCount,
                boardExtraFile: extraFilePlacement,
              ),
            );
          }
        }
      }
      return pickOrPlain(options);
    }
    if (ability == GameAbility.randomEarthquake) {
      final options = <AbilityOffer>[];
      for (var rank = 0; rank < rankCount; rank++) {
        for (final direction in [1, -1]) {
          if (canShiftRank(board, fileCount, rank, direction)) {
            options.add(
              AbilityOffer(
                ability: ability,
                applyMode: AbilityApplyMode.boardWide,
                quakeRank: rank,
                quakeDirection: direction,
                boardFileCount: fileCount,
                boardExtraFile: extraFilePlacement,
              ),
            );
          }
        }
      }
      return pickOrPlain(options);
    }
    if (ability == GameAbility.randomTyphoon) {
      final options = <AbilityOffer>[];
      for (var rank = 0; rank < rankCount - 1; rank++) {
        for (var file = 0; file < fileCount - 1; file++) {
          options.add(
            AbilityOffer(
              ability: ability,
              applyMode: AbilityApplyMode.boardWide,
              typhoonOrigin: Square(file, rank),
              boardFileCount: fileCount,
              boardExtraFile: extraFilePlacement,
            ),
          );
        }
      }
      return pickOrPlain(options);
    }
    if (ability == GameAbility.randomQuarantine ||
        ability == GameAbility.randomWormhole ||
        ability == GameAbility.randomAuction ||
        ability == GameAbility.randomClone) {
      final options = <AbilityOffer>[];
      final halfMin = forColor == PieceColor.white ? 0 : rankCount ~/ 2;
      final halfMax = forColor == PieceColor.white
          ? rankCount ~/ 2
          : rankCount;
      for (var rank = 0; rank < rankCount; rank++) {
        for (var file = 0; file < fileCount; file++) {
          final square = Square(file, rank);
          if (board[rank][file] != null) continue;
          if (blockedSquares.contains(square)) continue;
          if (ability == GameAbility.randomQuarantine) {
            options.add(
              AbilityOffer(
                ability: ability,
                applyMode: AbilityApplyMode.boardWide,
                boardFileCount: fileCount,
                boardExtraFile: extraFilePlacement,
                quarantineSquare: square,
                quarantineMoves: 3 + _random.nextInt(8),
              ),
            );
          } else if (ability == GameAbility.randomWormhole) {
            options.add(
              AbilityOffer(
                ability: ability,
                applyMode: AbilityApplyMode.boardWide,
                boardFileCount: fileCount,
                boardExtraFile: extraFilePlacement,
                wormholeSquare: square,
              ),
            );
          } else if (ability == GameAbility.randomAuction) {
            options.add(
              AbilityOffer(
                ability: ability,
                applyMode: AbilityApplyMode.boardWide,
                boardFileCount: fileCount,
                boardExtraFile: extraFilePlacement,
                auctionSquare: square,
              ),
            );
          } else if (rank >= halfMin && rank < halfMax) {
            options.add(
              AbilityOffer(
                ability: ability,
                applyMode: AbilityApplyMode.boardWide,
                boardFileCount: fileCount,
                boardExtraFile: extraFilePlacement,
                cloneSquare: square,
              ),
            );
          }
        }
      }
      return pickOrPlain(options);
    }
    if (ability == GameAbility.randomStrike) {
      return AbilityOffer(
        ability: ability,
        applyMode: AbilityApplyMode.boardWide,
        affectedPieceType: const [
          PieceType.pawn,
          PieceType.bishop,
          PieceType.rook,
          PieceType.knight,
          PieceType.queen,
        ][_random.nextInt(5)],
        durationMoves: 3 + _random.nextInt(8),
      );
    }
    if (ability == GameAbility.randomMyopia) {
      return AbilityOffer(
        ability: ability,
        applyMode: AbilityApplyMode.boardWide,
        durationMoves: 3 + _random.nextInt(3),
      );
    }
    if (ability == GameAbility.randomMagicShutdown) {
      return AbilityOffer(
        ability: ability,
        applyMode: AbilityApplyMode.boardWide,
        durationMoves: 3 + _random.nextInt(8),
      );
    }
    if (ability == GameAbility.randomBorderClosure) {
      return const AbilityOffer(
        ability: GameAbility.randomBorderClosure,
        applyMode: AbilityApplyMode.boardWide,
        durationMoves: 2,
      );
    }
    if (ability == GameAbility.randomSymmetry) {
      return const AbilityOffer(
        ability: GameAbility.randomSymmetry,
        applyMode: AbilityApplyMode.boardWide,
        durationMoves: 3,
      );
    }
    if (ability == GameAbility.randomVeto) {
      return const AbilityOffer(
        ability: GameAbility.randomVeto,
        applyMode: AbilityApplyMode.boardWide,
        durationMoves: 3,
        targetSelection: AbilityTargetSelection.enemyPiece,
      );
    }
    if (ability == GameAbility.randomRightToMove) {
      return const AbilityOffer(
        ability: GameAbility.randomRightToMove,
        applyMode: AbilityApplyMode.boardWide,
        targetSelection: AbilityTargetSelection.enemyPiece,
      );
    }
    if (ability == GameAbility.randomWordOfHonor) {
      return const AbilityOffer(
        ability: GameAbility.randomWordOfHonor,
        applyMode: AbilityApplyMode.boardWide,
        targetSelection: AbilityTargetSelection.cell,
      );
    }
    if (ability == GameAbility.randomTimeCapsule) {
      return const AbilityOffer(
        ability: GameAbility.randomTimeCapsule,
        applyMode: AbilityApplyMode.boardWide,
        durationMoves: 4,
      );
    }
    return AbilityOffer(
      ability: ability,
      applyMode: AbilityApplyMode.boardWide,
      targetSelection: _targetSelectionFor(ability),
    );
  }

  List<AbilityOffer> pickKingOffers({
    required Piece king,
    required List<List<Piece?>> board,
    required int rankCount,
    required ExtraFilePlacement extraFilePlacement,
    Set<Square> blockedSquares = const {},
    Square? kingSquare,
    Set<GameAbility> chosenAbilities = const {},
    Set<GameAbility> excludedAbilities = const {},
  }) {
    return pickCaptureOffers(
      king,
      board: board,
      rankCount: rankCount,
      extraFilePlacement: extraFilePlacement,
      blockedSquares: blockedSquares,
      capturingSquare: kingSquare,
      chosenAbilities: chosenAbilities,
      excludedAbilities: excludedAbilities,
    ).map((offer) {
      if (offer.ability.group != AbilityGroup.king) return offer;
      final json = offer.toJson();
      json['applyMode'] = AbilityApplyMode.playerKing.name;
      return AbilityOffer.fromJson(json);
    }).toList();
  }

  List<AbilityOffer> rerollStartOffers({
    required PieceColor forColor,
    required Iterable<AbilityOffer> oldOffers,
    Set<GameAbility> chosenAbilities = const {},
  }) {
    return pickStartOffers(
      forColor: forColor,
      excludedAbilities: {
        ...chosenAbilities,
        ...oldOffers.map((offer) => offer.ability),
      },
    );
  }

  AbilityOffer _offerForStart(GameAbility ability) {
    if (ability == GameAbility.boardSecretRoute) {
      final route = <Square>[];
      while (route.length < 3) {
        final square = Square(_random.nextInt(8), _random.nextInt(8));
        if (!route.contains(square)) route.add(square);
      }
      return AbilityOffer(
        ability: ability,
        applyMode: AbilityApplyMode.boardWide,
        targetSelection: AbilityTargetSelection.route,
        route: route,
      );
    }
    if (ability == GameAbility.boardWitnessProtection) {
      return AbilityOffer(
        ability: ability,
        applyMode: AbilityApplyMode.boardWide,
        targetSelection: AbilityTargetSelection.secretFriendlyPiece,
      );
    }
    if (ability == GameAbility.boardLavaRank) {
      return AbilityOffer(
        ability: ability,
        applyMode: AbilityApplyMode.boardWide,
        lavaRank: pickLavaRank(),
      );
    }
    if (ability == GameAbility.boardExtraFile) {
      return AbilityOffer(
        ability: ability,
        applyMode: AbilityApplyMode.boardWide,
        extraFileOnLeft: _random.nextBool(),
      );
    }
    if (ability == GameAbility.boardGhostCells) {
      return AbilityOffer(
        ability: ability,
        applyMode: AbilityApplyMode.boardWide,
        ghostCellCount: 2 + _random.nextInt(4), // 2..5
      );
    }
    if (ability == GameAbility.boardMinefield) {
      return AbilityOffer(
        ability: ability,
        applyMode: AbilityApplyMode.boardWide,
        mineCount: 1 + _random.nextInt(3), // 1..3
      );
    }
    if (ability == GameAbility.boardTeleport) {
      final a = Square(_random.nextInt(8), _random.nextInt(8));
      Square b;
      do {
        b = Square(_random.nextInt(8), _random.nextInt(8));
      } while (b == a);
      return AbilityOffer(
        ability: ability,
        applyMode: AbilityApplyMode.boardWide,
        boardFileCount: 8,
        teleportA: a,
        teleportB: b,
      );
    }
    if (ability == GameAbility.boardSilentFile) {
      return AbilityOffer(
        ability: ability,
        applyMode: AbilityApplyMode.boardWide,
        silentFile: _random.nextInt(8),
        boardFileCount: 8,
      );
    }
    if (ability == GameAbility.boardArchitect) {
      return AbilityOffer(
        ability: ability,
        applyMode: AbilityApplyMode.boardWide,
        durationMoves: 3 + _random.nextInt(6), // 3..8 walls
      );
    }
    if (ability.isBoardWide ||
        ability == GameAbility.boardExtraRank ||
        ability == GameAbility.boardFogOfWar ||
        ability == GameAbility.boardTide ||
        ability == GameAbility.boardSprint ||
        ability == GameAbility.boardZebras ||
        ability == GameAbility.boardFisher ||
        ability == GameAbility.boardFisherMadness ||
        ability == GameAbility.boardNight ||
        ability == GameAbility.boardDay ||
        ability == GameAbility.boardColorblind ||
        ability == GameAbility.boardPawnFront ||
        ability == GameAbility.boardCavalry ||
        ability == GameAbility.boardMirror ||
        ability == GameAbility.boardGhostCells ||
        ability == GameAbility.boardAttraction ||
        ability == GameAbility.boardVirus ||
        ability == GameAbility.boardInvisibleRegiment ||
        ability == GameAbility.boardShuffle ||
        ability == GameAbility.boardTeleport ||
        ability == GameAbility.boardVanityFair ||
        ability == GameAbility.boardMinefield ||
        ability == GameAbility.boardGolconda ||
        ability == GameAbility.boardUnbridledHorse ||
        ability == GameAbility.boardBaskerville ||
        ability == GameAbility.boardBloodOath ||
        ability == GameAbility.boardSilentFile ||
        ability == GameAbility.boardFourHorsemen) {
      final needsSeed =
          ability == GameAbility.boardFisher ||
          ability == GameAbility.boardFisherMadness ||
          ability == GameAbility.boardShuffle ||
          ability == GameAbility.boardTeleport ||
          ability == GameAbility.boardGhostCells ||
          ability == GameAbility.boardMinefield;
      return AbilityOffer(
        ability: ability,
        applyMode: AbilityApplyMode.boardWide,
        rngSeed: needsSeed ? _random.nextInt(1 << 30) : null,
      );
    }
    return AbilityOffer(
      ability: ability,
      applyMode: AbilityApplyMode.allPiecesOfType,
    );
  }

  List<AbilityOffer> pickCaptureOffers(
    Piece capturingPiece, {
    required List<List<Piece?>> board,
    required int rankCount,
    required ExtraFilePlacement extraFilePlacement,
    Set<Square> blockedSquares = const {},
    Square? capturingSquare,
    Set<GameAbility> chosenAbilities = const {},
    Set<GameAbility> excludedAbilities = const {},
    bool fogOfWarActive = false,
    bool minesActive = false,
    bool mirrorActive = false,
    bool offerFourChoices = false,
  }) {
    final capturingType = capturingPiece.type;
    final capturingColor = capturingPiece.color;
    final fileCount = board.isEmpty ? 8 : board.first.length;
    final pieceGroup = AbilityGroupInfo.forPieceType(capturingType);
    var pool = List<GameAbility>.from(abilitiesForGroup(pieceGroup));
    final blockedAbilities = {
      ...capturingPiece.abilities,
      ...chosenAbilities,
      ...excludedAbilities,
    };
    final ownedEffects = capturingPiece.abilities
        .expand((ability) => ability.effects)
        .toSet();
    pool = pool
        .where((ability) => !blockedAbilities.contains(ability))
        .where((ability) => ability.effects.intersection(ownedEffects).isEmpty)
        .toList();

    if (capturingType == PieceType.rook && capturingSquare != null) {
      final fileClear = _isFileClearExcept(
        board,
        rankCount,
        fileCount,
        capturingSquare.file,
        capturingSquare,
      );
      if (!fileClear) {
        pool.remove(GameAbility.rookAstronomicon);
      }
    }
    if (capturingType == PieceType.bishop) {
      final bishops = _countPieces(
        board,
        rankCount,
        fileCount,
        capturingColor,
        PieceType.bishop,
      );
      if (bishops < 2) {
        pool.remove(GameAbility.bishopBrothers);
      }
    }

    if (!minesActive) {
      pool.remove(GameAbility.pawnForTheKing);
    }
    if (!fogOfWarActive) {
      pool
        ..remove(GameAbility.pawnSignalFire)
        ..remove(GameAbility.knightSignalFire)
        ..remove(GameAbility.bishopSignalFire)
        ..remove(GameAbility.rookSignalFire)
        ..remove(GameAbility.rookSignalTower);
    }
    if (mirrorActive) {
      pool.remove(GameAbility.rookFerry);
    }
    if (!_hasEnemyAbilityPiece(board, rankCount, fileCount, capturingColor)) {
      pool.remove(GameAbility.kingRemoveEnemyMod);
    }

    final primary = _pickUnique(pool, 2).map((a) {
      if (a == GameAbility.queenShadowEmpress) {
        return AbilityOffer(
          ability: a,
          applyMode: AbilityApplyMode.capturingPiece,
          landOnLight: _random.nextBool(),
        );
      }
      return AbilityOffer(
        ability: a,
        applyMode: AbilityApplyMode.capturingPiece,
        axis: a == GameAbility.rookCustoms
            ? (_random.nextBool() ? AbilityAxis.rank : AbilityAxis.file)
            : null,
        targetSelection: _targetSelectionFor(a),
      );
    }).toList();

    while (primary.length < 2) {
      final fallback = _pickRandomWildcardOffer(
        board,
        rankCount,
        fileCount,
        capturingColor,
        extraFilePlacement,
        blockedSquares,
        excludedAbilities: {
          ...blockedAbilities,
          ...primary.map((offer) => offer.ability),
        },
      );
      primary.add(_withWildcard(fallback, false));
    }

    final wildOffer = _pickRandomWildcardOffer(
      board,
      rankCount,
      fileCount,
      capturingColor,
      extraFilePlacement,
      blockedSquares,
      excludedAbilities: {
        ...blockedAbilities,
        ...primary.map((offer) => offer.ability),
      },
    );

    final offers = <AbilityOffer>[...primary, wildOffer];
    if (offerFourChoices) {
      final bonus = _pickRandomWildcardOffer(
        board,
        rankCount,
        fileCount,
        capturingColor,
        extraFilePlacement,
        blockedSquares,
        excludedAbilities: {
          ...blockedAbilities,
          ...offers.map((offer) => offer.ability),
        },
      );
      offers.add(bonus);
    }

    return offers
        .map((offer) => offer.withChooser(capturingColor, rankCount: rankCount))
        .toList();
  }

  /// Three knight-only offers used by the one-time Knight Tour reward.
  List<AbilityOffer> pickKnightTourOffers(Piece knight) {
    final pool = knightAbilities
        .where((ability) => !knight.abilities.contains(ability))
        .toList();
    return _pickUnique(pool, 3)
        .map(
          (ability) => AbilityOffer(
            ability: ability,
            applyMode: AbilityApplyMode.selectFriendlyPiece,
            targetSelection: _targetSelectionFor(ability),
            forColor: knight.color,
          ),
        )
        .toList();
  }

  List<AbilityOffer> rerollCaptureOffers(
    Piece capturingPiece, {
    required List<List<Piece?>> board,
    required int rankCount,
    required ExtraFilePlacement extraFilePlacement,
    required Iterable<AbilityOffer> oldOffers,
    Set<Square> blockedSquares = const {},
    Square? capturingSquare,
    Set<GameAbility> chosenAbilities = const {},
    bool fogOfWarActive = false,
    bool minesActive = false,
    bool mirrorActive = false,
    bool offerFourChoices = false,
  }) {
    return pickCaptureOffers(
      capturingPiece,
      board: board,
      rankCount: rankCount,
      extraFilePlacement: extraFilePlacement,
      blockedSquares: blockedSquares,
      capturingSquare: capturingSquare,
      chosenAbilities: chosenAbilities,
      excludedAbilities: oldOffers.map((offer) => offer.ability).toSet(),
      fogOfWarActive: fogOfWarActive,
      minesActive: minesActive,
      mirrorActive: mirrorActive,
      offerFourChoices: offerFourChoices,
    );
  }

  static bool _isFileClearExcept(
    List<List<Piece?>> board,
    int rankCount,
    int fileCount,
    int file,
    Square except,
  ) {
    for (var rank = 0; rank < rankCount; rank++) {
      if (file >= (board[rank].length)) continue;
      if (board[rank][file] == null) continue;
      if (except.file == file && except.rank == rank) continue;
      return false;
    }
    return true;
  }

  static int _countPieces(
    List<List<Piece?>> board,
    int rankCount,
    int fileCount,
    PieceColor color,
    PieceType type,
  ) {
    var n = 0;
    for (var rank = 0; rank < rankCount; rank++) {
      for (var file = 0; file < board[rank].length; file++) {
        final p = board[rank][file];
        if (p != null && p.color == color && p.type == type) n++;
      }
    }
    return n;
  }

  AbilityOffer _pickRandomWildcardOffer(
    List<List<Piece?>> board,
    int rankCount,
    int fileCount,
    PieceColor capturingColor,
    ExtraFilePlacement extraFilePlacement,
    Set<Square> blockedSquares, {
    Set<GameAbility> excludedAbilities = const {},
  }) {
    final options = <AbilityOffer>[];

    for (var file = 0; file < fileCount; file++) {
      for (final direction in [1, -1]) {
        if (canShiftFile(board, rankCount, file, direction)) {
          options.add(
            AbilityOffer(
              ability: GameAbility.randomShift,
              applyMode: AbilityApplyMode.boardWide,
              isWildcard: true,
              shiftFile: file,
              shiftDirection: direction,
              boardFileCount: fileCount,
              boardExtraFile: extraFilePlacement,
            ),
          );
        }
      }
    }

    for (var rank = 0; rank < rankCount; rank++) {
      for (final direction in [1, -1]) {
        if (canShiftRank(board, fileCount, rank, direction)) {
          options.add(
            AbilityOffer(
              ability: GameAbility.randomEarthquake,
              applyMode: AbilityApplyMode.boardWide,
              isWildcard: true,
              quakeRank: rank,
              quakeDirection: direction,
              boardFileCount: fileCount,
              boardExtraFile: extraFilePlacement,
            ),
          );
        }
      }
    }

    for (var rank = 0; rank < rankCount - 1; rank++) {
      for (var file = 0; file < fileCount - 1; file++) {
        options.add(
          AbilityOffer(
            ability: GameAbility.randomTyphoon,
            applyMode: AbilityApplyMode.boardWide,
            isWildcard: true,
            typhoonOrigin: Square(file, rank),
            boardFileCount: fileCount,
            boardExtraFile: extraFilePlacement,
          ),
        );
      }
    }

    final emptySquares = <Square>[];
    for (var rank = 0; rank < rankCount; rank++) {
      for (var file = 0; file < fileCount; file++) {
        final square = Square(file, rank);
        if (board[rank][file] != null) continue;
        if (blockedSquares.contains(square)) continue;
        emptySquares.add(square);
        options.add(
          AbilityOffer(
            ability: GameAbility.randomQuarantine,
            applyMode: AbilityApplyMode.boardWide,
            isWildcard: true,
            boardFileCount: fileCount,
            boardExtraFile: extraFilePlacement,
            quarantineSquare: square,
            quarantineMoves: 3 + _random.nextInt(8), // 3..10
          ),
        );
        options.add(
          AbilityOffer(
            ability: GameAbility.randomWormhole,
            applyMode: AbilityApplyMode.boardWide,
            isWildcard: true,
            boardFileCount: fileCount,
            boardExtraFile: extraFilePlacement,
            wormholeSquare: square,
          ),
        );
      }
    }

    final halfMin = capturingColor == PieceColor.white ? 0 : rankCount ~/ 2;
    final halfMax = capturingColor == PieceColor.white
        ? rankCount ~/ 2
        : rankCount;
    final cloneSquares = emptySquares
        .where((s) => s.rank >= halfMin && s.rank < halfMax)
        .toList();
    for (final square in cloneSquares) {
      options.add(
        AbilityOffer(
          ability: GameAbility.randomClone,
          applyMode: AbilityApplyMode.boardWide,
          isWildcard: true,
          boardFileCount: fileCount,
          boardExtraFile: extraFilePlacement,
          cloneSquare: square,
        ),
      );
    }

    if (_hasEnemyQueen(board, rankCount, fileCount, capturingColor)) {
      options.add(
        const AbilityOffer(
          ability: GameAbility.randomNoQueen,
          applyMode: AbilityApplyMode.boardWide,
          isWildcard: true,
        ),
      );
    }

    options.add(
      const AbilityOffer(
        ability: GameAbility.randomTruce,
        applyMode: AbilityApplyMode.boardWide,
        isWildcard: true,
      ),
    );

    options.add(
      const AbilityOffer(
        ability: GameAbility.randomMeteorRain,
        applyMode: AbilityApplyMode.boardWide,
        isWildcard: true,
      ),
    );

    if (_hasEnemyAbilityPiece(board, rankCount, fileCount, capturingColor)) {
      options.add(
        const AbilityOffer(
          ability: GameAbility.randomCensus,
          applyMode: AbilityApplyMode.boardWide,
          isWildcard: true,
        ),
      );
    }

    options.add(
      const AbilityOffer(
        ability: GameAbility.randomExterminatus,
        applyMode: AbilityApplyMode.boardWide,
        isWildcard: true,
      ),
    );

    options.add(
      const AbilityOffer(
        ability: GameAbility.randomGoldenThrone,
        applyMode: AbilityApplyMode.boardWide,
        isWildcard: true,
      ),
    );

    if (_countNonKings(board, rankCount, fileCount, capturingColor) >= 2) {
      options.add(
        const AbilityOffer(
          ability: GameAbility.randomLottery,
          applyMode: AbilityApplyMode.boardWide,
          isWildcard: true,
        ),
      );
    }

    options.add(
      const AbilityOffer(
        ability: GameAbility.randomPlague,
        applyMode: AbilityApplyMode.boardWide,
        isWildcard: true,
      ),
    );

    if (_countPieces(
          board,
          rankCount,
          fileCount,
          capturingColor,
          PieceType.pawn,
        ) >
        0) {
      options.add(
        const AbilityOffer(
          ability: GameAbility.randomMutation,
          applyMode: AbilityApplyMode.boardWide,
          isWildcard: true,
        ),
      );
    }

    for (final square in emptySquares) {
      options.add(
        AbilityOffer(
          ability: GameAbility.randomAuction,
          applyMode: AbilityApplyMode.boardWide,
          isWildcard: true,
          boardFileCount: fileCount,
          boardExtraFile: extraFilePlacement,
          auctionSquare: square,
        ),
      );
    }

    options.addAll([
      const AbilityOffer(
        ability: GameAbility.randomCalm,
        applyMode: AbilityApplyMode.boardWide,
        isWildcard: true,
      ),
      const AbilityOffer(
        ability: GameAbility.randomRightToMove,
        applyMode: AbilityApplyMode.boardWide,
        isWildcard: true,
        targetSelection: AbilityTargetSelection.enemyPiece,
      ),
      const AbilityOffer(
        ability: GameAbility.randomFurtherMore,
        applyMode: AbilityApplyMode.boardWide,
        isWildcard: true,
      ),
      const AbilityOffer(
        ability: GameAbility.randomWordOfHonor,
        applyMode: AbilityApplyMode.boardWide,
        isWildcard: true,
        targetSelection: AbilityTargetSelection.cell,
      ),
      const AbilityOffer(
        ability: GameAbility.randomSymmetry,
        applyMode: AbilityApplyMode.boardWide,
        isWildcard: true,
        durationMoves: 3,
      ),
      const AbilityOffer(
        ability: GameAbility.randomVeto,
        applyMode: AbilityApplyMode.boardWide,
        isWildcard: true,
        durationMoves: 3,
        targetSelection: AbilityTargetSelection.enemyPiece,
      ),
      const AbilityOffer(
        ability: GameAbility.randomInitiativeIntercept,
        applyMode: AbilityApplyMode.boardWide,
        isWildcard: true,
      ),
      AbilityOffer(
        ability: GameAbility.randomStrike,
        applyMode: AbilityApplyMode.boardWide,
        isWildcard: true,
        affectedPieceType: const [
          PieceType.pawn,
          PieceType.bishop,
          PieceType.rook,
          PieceType.knight,
          PieceType.queen,
        ][_random.nextInt(5)],
        durationMoves: 3 + _random.nextInt(8),
      ),
      const AbilityOffer(
        ability: GameAbility.randomBorderClosure,
        applyMode: AbilityApplyMode.boardWide,
        isWildcard: true,
        durationMoves: 2,
      ),
      AbilityOffer(
        ability: GameAbility.randomMyopia,
        applyMode: AbilityApplyMode.boardWide,
        isWildcard: true,
        durationMoves: 3 + _random.nextInt(3),
      ),
      AbilityOffer(
        ability: GameAbility.randomMagicShutdown,
        applyMode: AbilityApplyMode.boardWide,
        isWildcard: true,
        durationMoves: 3 + _random.nextInt(8),
      ),
      const AbilityOffer(
        ability: GameAbility.randomTimeCapsule,
        applyMode: AbilityApplyMode.boardWide,
        isWildcard: true,
        durationMoves: 4,
      ),
      const AbilityOffer(
        ability: GameAbility.randomSuicideCapture,
        applyMode: AbilityApplyMode.boardWide,
        isWildcard: true,
      ),
    ]);

    final allowed = options
        .where((offer) => !excludedAbilities.contains(offer.ability))
        .toList();
    if (allowed.isNotEmpty) {
      return allowed[_random.nextInt(allowed.length)];
    }

    throw StateError('No unique Cataclysm ability is available');
  }

  static AbilityTargetSelection _targetSelectionFor(GameAbility ability) {
    switch (ability) {
      case GameAbility.knightDuel:
      case GameAbility.queenDelayedSentence:
        return AbilityTargetSelection.enemyPiece;
      case GameAbility.knightGuard:
        return AbilityTargetSelection.cell;
      case GameAbility.bishopSanctuary:
      case GameAbility.bishopPilgrimage:
      case GameAbility.bishopParallelWorlds:
        return AbilityTargetSelection.friendlyPiece;
      case GameAbility.kingPrisonerExchange:
        return AbilityTargetSelection.capturedFriendlyPiece;
      case GameAbility.kingRemoveEnemyMod:
        return AbilityTargetSelection.enemyAbility;
      default:
        return AbilityTargetSelection.none;
    }
  }

  static AbilityOffer _withWildcard(AbilityOffer offer, bool isWildcard) {
    final json = offer.toJson();
    json['isWildcard'] = isWildcard;
    return AbilityOffer.fromJson(json);
  }

  static int _countNonKings(
    List<List<Piece?>> board,
    int rankCount,
    int fileCount,
    PieceColor color,
  ) {
    var n = 0;
    for (var rank = 0; rank < rankCount; rank++) {
      for (var file = 0; file < board[rank].length; file++) {
        final p = board[rank][file];
        if (p != null && p.color == color && p.type != PieceType.king) n++;
      }
    }
    return n;
  }

  static bool canShiftFile(
    List<List<Piece?>> board,
    int rankCount,
    int file,
    int direction,
  ) {
    for (var rank = 0; rank < rankCount; rank++) {
      if (board[rank][file] == null) continue;
      final newRank = rank + direction;
      if (newRank < 0 || newRank >= rankCount) return false;
    }
    return true;
  }

  static bool canShiftRank(
    List<List<Piece?>> board,
    int fileCount,
    int rank,
    int direction,
  ) {
    for (var file = 0; file < fileCount; file++) {
      if (board[rank][file] == null) continue;
      final newFile = file + direction;
      if (newFile < 0 || newFile >= fileCount) return false;
    }
    return true;
  }

  int pickLavaRank() => 2 + _random.nextInt(4);

  List<GameAbility> _pickUnique(List<GameAbility> pool, int count) {
    final copy = List<GameAbility>.from(pool)..shuffle(_random);
    return copy.take(count.clamp(0, copy.length)).toList();
  }

  bool _hasEnemyQueen(
    List<List<Piece?>> board,
    int rankCount,
    int fileCount,
    PieceColor capturingColor,
  ) {
    for (var rank = 0; rank < rankCount; rank++) {
      for (var file = 0; file < fileCount; file++) {
        final piece = board[rank][file];
        if (piece == null) continue;
        if (piece.color == capturingColor) continue;
        if (piece.type == PieceType.queen) return true;
      }
    }
    return false;
  }

  bool _hasEnemyAbilityPiece(
    List<List<Piece?>> board,
    int rankCount,
    int fileCount,
    PieceColor capturingColor,
  ) {
    for (var rank = 0; rank < rankCount; rank++) {
      for (var file = 0; file < fileCount; file++) {
        final piece = board[rank][file];
        if (piece == null) continue;
        if (piece.color == capturingColor) continue;
        if (piece.abilities.isNotEmpty) return true;
      }
    }
    return false;
  }

  /// True if [forColor] has a bishop that sees an allied non-king on a diagonal.
  bool _bishopHasAllyOnDiagonal(
    List<List<Piece?>> board,
    int rankCount,
    int fileCount,
    PieceColor forColor,
  ) {
    for (var rank = 0; rank < rankCount; rank++) {
      for (var file = 0; file < fileCount; file++) {
        final bishop = board[rank][file];
        if (bishop == null ||
            bishop.color != forColor ||
            bishop.type != PieceType.bishop) {
          continue;
        }
        for (final df in const [-1, 1]) {
          for (final dr in const [-1, 1]) {
            var f = file + df;
            var r = rank + dr;
            while (f >= 0 && f < fileCount && r >= 0 && r < rankCount) {
              final other = board[r][f];
              if (other != null) {
                if (other.color == forColor && other.type != PieceType.king) {
                  return true;
                }
                break;
              }
              f += df;
              r += dr;
            }
          }
        }
      }
    }
    return false;
  }
}
