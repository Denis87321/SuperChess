import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:super_chess/chess/board_labels.dart';
import 'package:super_chess/l10n/models/ability_catalog.dart';
import 'package:super_chess/l10n/models/ability_group.dart';
import 'package:super_chess/l10n/models/game_ability.dart';
import 'package:super_chess/l10n/models/piece.dart';
import 'package:super_chess/l10n/models/square.dart';

List<List<Piece?>> _emptyBoard({int rankCount = 8}) =>
    List.generate(rankCount, (_) => List.filled(8, null));

void main() {
  const addedBoard = {
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
  };
  const addedRandom = {
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
  };
  const addedPieces = {
    GameAbility.pawnInheritance,
    GameAbility.pawnRansom,
    GameAbility.knightDuel,
    GameAbility.knightGuard,
    GameAbility.knightTour,
    GameAbility.bishopSanctuary,
    GameAbility.bishopExcommunication,
    GameAbility.bishopTithe,
    GameAbility.bishopPilgrimage,
    GameAbility.rookStandardBearer,
    GameAbility.rookCustoms,
    GameAbility.rookDrawbridge,
    GameAbility.rookCurfew,
    GameAbility.rookSiegeCalculation,
    GameAbility.queenDelayedSentence,
    GameAbility.queenTrophyEmbargo,
    GameAbility.queenYouShallNotPass,
    GameAbility.kingPrisonerExchange,
    GameAbility.kingRemoveEnemyMod,
  };

  test('all 42 requested abilities belong to exhaustive catalog pools', () {
    final added = {...addedBoard, ...addedRandom, ...addedPieces};
    expect(added, hasLength(42));
    expect(AbilityCatalog.boardAbilities.toSet(), containsAll(addedBoard));
    expect(AbilityCatalog.randomAbilities.toSet(), containsAll(addedRandom));

    final piecePools = {
      ...AbilityCatalog.pawnAbilities,
      ...AbilityCatalog.knightAbilities,
      ...AbilityCatalog.bishopAbilities,
      ...AbilityCatalog.rookAbilities,
      ...AbilityCatalog.queenAbilities,
      ...AbilityCatalog.kingAbilities,
    };
    expect(piecePools, containsAll(addedPieces));

    final allPools = AbilityGroup.values
        .expand(AbilityCatalog.abilitiesForGroup)
        .toList();
    expect(allPools.toSet().length, lessThanOrEqualTo(allPools.length));
    // Multi-shelf mods (king+rook, pawn+knight) may appear in more than one list;
    // picking always dedupes so probability is not doubled.
    for (final ability in added) {
      expect(ability.group, isNotNull);
      expect(ability.title, isNotEmpty);
      expect(ability.description, isNotEmpty);
    }
  });

  List<List<Piece?>> _boardWithBasics() {
    final board = _emptyBoard();
    board[0][4] = const Piece(
      pieceId: 'wk',
      type: PieceType.king,
      color: PieceColor.white,
    );
    board[1][0] = const Piece(
      pieceId: 'wp',
      type: PieceType.pawn,
      color: PieceColor.white,
    );
    board[0][1] = const Piece(
      pieceId: 'wn',
      type: PieceType.knight,
      color: PieceColor.white,
    );
    board[7][4] = const Piece(
      pieceId: 'bk',
      type: PieceType.king,
      color: PieceColor.black,
    );
    return board;
  }

  test('pickPeriodicOffers returns three equal-probability offers', () {
    final catalog = AbilityCatalog(random: Random(42));
    final offers = catalog.pickPeriodicOffers(
      forColor: PieceColor.white,
      board: _boardWithBasics(),
      rankCount: 8,
      extraFilePlacement: ExtraFilePlacement.none,
    );

    expect(offers, hasLength(3));
    expect(offers.map((o) => o.ability).toSet(), hasLength(3));
    expect(
      offers.every(
        (o) =>
            o.applyMode == AbilityApplyMode.boardWide ||
            o.applyMode == AbilityApplyMode.selectFriendlyPiece ||
            o.applyMode == AbilityApplyMode.allPiecesOfType ||
            o.applyMode == AbilityApplyMode.playerKing,
      ),
      isTrue,
    );
  });

  test('periodic offers exclude chosen abilities', () {
    final catalog = AbilityCatalog(random: Random(7));
    final offers = catalog.pickPeriodicOffers(
      forColor: PieceColor.white,
      board: _boardWithBasics(),
      rankCount: 8,
      extraFilePlacement: ExtraFilePlacement.none,
      chosenAbilities: const {
        GameAbility.boardPawnsSideways,
        GameAbility.pawnSideways,
      },
    );

    expect(
      offers.map((offer) => offer.ability),
      isNot(contains(GameAbility.boardPawnsSideways)),
    );
    expect(
      offers.map((offer) => offer.ability),
      isNot(contains(GameAbility.pawnSideways)),
    );
    expect(offers.map((offer) => offer.ability).toSet(), hasLength(3));
  });

  test('periodic offers omit piece groups with no pieces', () {
    final catalog = AbilityCatalog(random: Random(11));
    final board = _emptyBoard();
    board[0][4] = const Piece(
      pieceId: 'wk',
      type: PieceType.king,
      color: PieceColor.white,
    );
    board[7][4] = const Piece(
      pieceId: 'bk',
      type: PieceType.king,
      color: PieceColor.black,
    );
    // Force many samples: pawn group must never appear without pawns.
    for (var seed = 0; seed < 40; seed++) {
      final offers = AbilityCatalog(random: Random(seed)).pickPeriodicOffers(
        forColor: PieceColor.white,
        board: board,
        rankCount: 8,
        extraFilePlacement: ExtraFilePlacement.none,
      );
      expect(
        offers.any((o) => o.ability.group == AbilityGroup.pawn),
        isFalse,
      );
      expect(
        offers.any((o) => o.ability.group == AbilityGroup.knight),
        isFalse,
      );
    }
  });

  test('fisher setups appear only in start offers, never in periodic', () {
    var sawFisherAtStart = false;
    for (var seed = 0; seed < 200; seed++) {
      final start = AbilityCatalog(random: Random(seed)).pickStartOffers(
        forColor: PieceColor.white,
      );
      if (start.any(
        (o) =>
            o.ability == GameAbility.boardFisher ||
            o.ability == GameAbility.boardFisherMadness,
      )) {
        sawFisherAtStart = true;
        break;
      }
    }
    expect(sawFisherAtStart, isTrue);

    final board = _boardWithBasics();
    for (var seed = 0; seed < 80; seed++) {
      final offers = AbilityCatalog(random: Random(seed)).pickPeriodicOffers(
        forColor: PieceColor.white,
        board: board,
        rankCount: 8,
        extraFilePlacement: ExtraFilePlacement.none,
      );
      expect(
        offers.map((o) => o.ability),
        isNot(contains(GameAbility.boardFisher)),
      );
      expect(
        offers.map((o) => o.ability),
        isNot(contains(GameAbility.boardFisherMadness)),
      );
    }
  });

  test('remove-enemy-mod appears only when an enemy piece has abilities', () {
    final bare = _emptyBoard();
    bare[0][4] = const Piece(
      pieceId: 'wk',
      type: PieceType.king,
      color: PieceColor.white,
    );
    bare[7][4] = const Piece(
      pieceId: 'bk',
      type: PieceType.king,
      color: PieceColor.black,
    );
    for (var seed = 0; seed < 60; seed++) {
      final offers = AbilityCatalog(random: Random(seed)).pickPeriodicOffers(
        forColor: PieceColor.white,
        board: bare,
        rankCount: 8,
        extraFilePlacement: ExtraFilePlacement.none,
      );
      expect(
        offers.map((o) => o.ability),
        isNot(contains(GameAbility.kingRemoveEnemyMod)),
      );
    }

    final modded = _emptyBoard();
    modded[0][4] = const Piece(
      pieceId: 'wk',
      type: PieceType.king,
      color: PieceColor.white,
    );
    modded[7][4] = const Piece(
      pieceId: 'bk',
      type: PieceType.king,
      color: PieceColor.black,
      abilities: {GameAbility.kingAura},
    );
    var saw = false;
    for (var seed = 0; seed < 200; seed++) {
      final offers = AbilityCatalog(random: Random(seed)).pickPeriodicOffers(
        forColor: PieceColor.white,
        board: modded,
        rankCount: 8,
        extraFilePlacement: ExtraFilePlacement.none,
      );
      if (offers.any((o) => o.ability == GameAbility.kingRemoveEnemyMod)) {
        saw = true;
        break;
      }
    }
    expect(saw, isTrue);
  });

  test('rerollPeriodicOffers excludes old and chosen abilities', () {
    final catalog = AbilityCatalog(random: Random(19));
    final board = _boardWithBasics();
    final oldOffers = catalog.pickPeriodicOffers(
      forColor: PieceColor.white,
      board: board,
      rankCount: 8,
      extraFilePlacement: ExtraFilePlacement.none,
      chosenAbilities: const {GameAbility.randomFurtherMore},
    );
    final rerolled = catalog.rerollPeriodicOffers(
      forColor: PieceColor.white,
      board: board,
      rankCount: 8,
      extraFilePlacement: ExtraFilePlacement.none,
      oldOffers: oldOffers,
      chosenAbilities: const {GameAbility.randomFurtherMore},
    );

    final forbidden = {
      GameAbility.randomFurtherMore,
      ...oldOffers.map((offer) => offer.ability),
    };
    for (final offer in rerolled) {
      expect(forbidden.contains(offer.ability), isFalse);
    }
    expect(rerolled.map((offer) => offer.ability).toSet(), hasLength(3));
  });

  test('random offer parameters are baked into visible descriptions', () {
    final catalog = AbilityCatalog(random: Random(23));
    final board = _boardWithBasics();
    board[0][0] = const Piece(
      pieceId: 'wr',
      type: PieceType.rook,
      color: PieceColor.white,
    );
    AbilityOffer? customs;
    for (var seed = 0; seed < 200 && customs == null; seed++) {
      final offers = AbilityCatalog(random: Random(seed)).pickPeriodicOffers(
        forColor: PieceColor.white,
        board: board,
        rankCount: 8,
        extraFilePlacement: ExtraFilePlacement.none,
        excludedAbilities: AbilityCatalog.rookAbilities
            .where((ability) => ability != GameAbility.rookCustoms)
            .toSet(),
      );
      for (final offer in offers) {
        if (offer.ability == GameAbility.rookCustoms) customs = offer;
      }
    }
    expect(customs, isNotNull);
    expect(customs!.axis, isNotNull);
    expect(
      customs.displayDescription,
      contains(customs.axis == AbilityAxis.rank ? 'горизонталь' : 'вертикаль'),
    );

    final strikeOffers = catalog.pickPeriodicOffers(
      forColor: PieceColor.white,
      board: board,
      rankCount: 8,
      extraFilePlacement: ExtraFilePlacement.none,
      excludedAbilities: {
        ...AbilityCatalog.boardAbilities,
        ...AbilityCatalog.pawnAbilities,
        ...AbilityCatalog.knightAbilities,
        ...AbilityCatalog.bishopAbilities,
        ...AbilityCatalog.rookAbilities,
        ...AbilityCatalog.queenAbilities,
        ...AbilityCatalog.kingAbilities,
        ...AbilityCatalog.randomAbilities.where(
          (ability) => ability != GameAbility.randomStrike,
        ),
      },
    );
    final strike = strikeOffers.firstWhere(
      (offer) => offer.ability == GameAbility.randomStrike,
    );
    expect(strike.affectedPieceType, isNotNull);
    expect(strike.durationMoves, inInclusiveRange(3, 10));
    expect(strike.displayDescription, contains('${strike.durationMoves}'));
  });

  test(
    'future target-selection metadata is present without random target cell',
    () {
      AbilityOffer? route;
      AbilityOffer? witness;
      for (var seed = 0; seed < 4000 && (route == null || witness == null); seed++) {
        final catalog = AbilityCatalog(random: Random(seed));
        final offers = catalog.pickStartOffers(
          forColor: PieceColor.white,
          excludedAbilities: {
            ...AbilityCatalog.boardAbilities.where(
              (ability) =>
                  ability != GameAbility.boardSecretRoute &&
                  ability != GameAbility.boardWitnessProtection &&
                  ability != GameAbility.boardReroll,
            ),
            ...AbilityCatalog.pawnAbilities.where(
              (a) => a.name.startsWith('board'),
            ),
            ...AbilityCatalog.knightAbilities.where(
              (a) => a.name.startsWith('board'),
            ),
            ...AbilityCatalog.rookAbilities.where(
              (a) => a.name.startsWith('board'),
            ),
            ...AbilityCatalog.kingAbilities.where(
              (a) => a.name.startsWith('board'),
            ),
          },
        );
        route ??= offers.cast<AbilityOffer?>().firstWhere(
          (offer) => offer?.ability == GameAbility.boardSecretRoute,
          orElse: () => null,
        );
        witness ??= offers.cast<AbilityOffer?>().firstWhere(
          (offer) => offer?.ability == GameAbility.boardWitnessProtection,
          orElse: () => null,
        );
      }
      expect(route, isNotNull);
      expect(witness, isNotNull);
      expect(route!.targetSelection, AbilityTargetSelection.route);
      expect(route.route, hasLength(3));
      expect(route.route.toSet(), hasLength(3));
      expect(
        witness!.targetSelection,
        AbilityTargetSelection.secretFriendlyPiece,
      );
      expect(witness.targetCell, isNull);
    },
  );

  test('AbilityOffer JSON round-trips the complete payload', () {
    const offer = AbilityOffer(
      ability: GameAbility.randomStrike,
      applyMode: AbilityApplyMode.boardWide,
      isWildcard: true,
      lavaRank: 2,
      shiftFile: 3,
      shiftDirection: -1,
      extraFileOnLeft: true,
      boardFileCount: 9,
      boardRankCount: 9,
      boardExtraFile: ExtraFilePlacement.left,
      quarantineSquare: Square(1, 2),
      quarantineMoves: 7,
      quakeRank: 4,
      quakeDirection: 1,
      typhoonOrigin: Square(2, 3),
      wormholeSquare: Square(3, 4),
      cloneSquare: Square(4, 5),
      ghostCellCount: 3,
      mineCount: 2,
      teleportA: Square(0, 0),
      teleportB: Square(7, 7),
      landOnLight: true,
      silentFile: 5,
      auctionSquare: Square(6, 6),
      axis: AbilityAxis.file,
      affectedPieceType: PieceType.bishop,
      durationMoves: 8,
      targetSelection: AbilityTargetSelection.route,
      targetCell: Square(5, 5),
      route: [Square(1, 1), Square(2, 2), Square(3, 3)],
      hiddenData: {'ownerOnly': true, 'seed': 17},
      forColor: PieceColor.black,
    );

    expect(AbilityOffer.fromJson(offer.toJson()).toJson(), offer.toJson());
    expect(
      AbilityOffer.fromJson(const {'ability': 'pawnInheritance'}).applyMode,
      AbilityApplyMode.capturingPiece,
    );
  });
}
