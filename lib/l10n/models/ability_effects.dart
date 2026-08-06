import 'game_ability.dart';

enum AbilityEffect {
  sidewaysPawnMovement,
  invertedPawnMovement,
  pawnBackwardMovement,
  pawnAlwaysDoubleStep,
  pawnNoDoubleStep,
  pawnTripleStepOnce,
  pawnRam,
  pawnAirborne,
  kamikaze,
  caliph,
  stickyPawn,
  polymorph,
  kingRookSwap,
  kingExtraStep,
  kingShield,
  kingAura,
  kingDoppelganger,
  kingThrone,
  kingFamilyUnion,
  knightLongJump,
  knightRearing,
  knightSecondChance,
  gallop,
  dustTrail,
  centaur,
  knightTrojan,
  hopOverAlly,
  queenKnightStep,
  queenMatka,
  queenShadowEmpress,
  queenEscape,
  bishopColorChaos,
  inquisitor,
  colorVow,
  bishopBrothers,
  rookRam,
  astronomicon,
  fortress,
  queenSplit,
  boomerangReturn,
  pawnInheritance,
  pawnRansom,
  knightDuel,
  knightGuard,
  knightTour,
  bishopSanctuary,
  bishopExcommunication,
  bishopTithe,
  bishopPilgrimage,
  rookStandardBearer,
  rookCustoms,
  rookDrawbridge,
  rookCurfew,
  rookSiegeCalculation,
  queenDelayedSentence,
  queenTrophyEmbargo,
  queenYouShallNotPass,
  kingPrisonerExchange,
  kingRemoveEnemyMod,
  troopFatigue,
  rangedMoveLimit,
  mightMakesRight,
  expeditionaryCorps,
  witnessProtection,
  forcedPieceMove,
  mirroredPieceType,
  vetoedPiece,
  strikePieceType,
  borderClosure,
  myopia,
  camouflageNet,
  trench,
  avengeMe,
  caravan,
  faceControl,
  forTheKing,
  signalFire,
  doppelgangerOnce,
  doppelgangers,
  fifthLeg,
  elusive,
  stomp,
  surveyor,
  cornerQuest,
  rideMe,
  magicHooves,
  crusade,
  post,
  parallelWorlds,
  alcove,
  glassCeiling,
  ferry,
  signalTower,
  assemblyHall,
}

extension GameAbilityEffects on GameAbility {
  Set<AbilityEffect> get effects {
    switch (this) {
      case GameAbility.boardPawnsSideways:
      case GameAbility.pawnSideways:
        return {AbilityEffect.sidewaysPawnMovement};
      case GameAbility.boardPawnsDiagonal:
      case GameAbility.pawnInverted:
        return {AbilityEffect.invertedPawnMovement};
      case GameAbility.boardPawnsBackward:
        return {AbilityEffect.pawnBackwardMovement};
      case GameAbility.pawnAlwaysDoubleStep:
        return {AbilityEffect.pawnAlwaysDoubleStep};
      case GameAbility.boardTide:
        return {AbilityEffect.pawnNoDoubleStep};
      case GameAbility.boardDoubleStart:
        return {AbilityEffect.pawnTripleStepOnce};
      case GameAbility.pawnRam:
        return {AbilityEffect.pawnRam};
      case GameAbility.pawnAirborne:
        return {AbilityEffect.pawnAirborne};
      case GameAbility.pawnKamikaze:
        return {AbilityEffect.kamikaze};
      case GameAbility.pawnCaliph:
        return {AbilityEffect.caliph};
      case GameAbility.pawnSticky:
        return {AbilityEffect.stickyPawn};
      case GameAbility.pawnPolymorph:
        return {AbilityEffect.polymorph};
      case GameAbility.pawnBoomerang:
      case GameAbility.knightBoomerang:
      case GameAbility.bishopBoomerang:
        return {AbilityEffect.boomerangReturn};
      case GameAbility.boardKingSwap:
      case GameAbility.kingRoyalDecree:
        return {AbilityEffect.kingRookSwap};
      case GameAbility.kingExtraStep:
        return {AbilityEffect.kingExtraStep};
      case GameAbility.kingShield:
        return {AbilityEffect.kingShield};
      case GameAbility.kingAura:
        return {AbilityEffect.kingAura};
      case GameAbility.kingDoppelganger:
        return {AbilityEffect.kingDoppelganger};
      case GameAbility.kingThrone:
        return {AbilityEffect.kingThrone};
      case GameAbility.kingFamilyUnion:
        return {AbilityEffect.kingFamilyUnion};
      case GameAbility.knightLongJump:
        return {AbilityEffect.knightLongJump};
      case GameAbility.knightRearing:
        return {AbilityEffect.knightRearing};
      case GameAbility.knightSecondChance:
        return {AbilityEffect.knightSecondChance};
      case GameAbility.knightGallop:
        return {AbilityEffect.gallop};
      case GameAbility.knightDust:
        return {AbilityEffect.dustTrail};
      case GameAbility.knightCentaur:
        return {AbilityEffect.centaur};
      case GameAbility.knightTrojan:
        return {AbilityEffect.knightTrojan};
      case GameAbility.bishopHopAlly:
      case GameAbility.rookHopAlly:
      case GameAbility.queenHopAlly:
        return {AbilityEffect.hopOverAlly};
      case GameAbility.bishopColorChaos:
        return {AbilityEffect.bishopColorChaos};
      case GameAbility.bishopInquisitor:
        return {AbilityEffect.inquisitor};
      case GameAbility.bishopColorVow:
        return {AbilityEffect.colorVow};
      case GameAbility.bishopBrothers:
        return {AbilityEffect.bishopBrothers};
      case GameAbility.rookRam:
        return {AbilityEffect.rookRam};
      case GameAbility.rookAstronomicon:
        return {AbilityEffect.astronomicon};
      case GameAbility.rookFortress:
        return {AbilityEffect.fortress};
      case GameAbility.queenKnightStep:
        return {AbilityEffect.queenKnightStep};
      case GameAbility.queenMatka:
        return {AbilityEffect.queenMatka};
      case GameAbility.queenShadowEmpress:
        return {AbilityEffect.queenShadowEmpress};
      case GameAbility.queenEscape:
        return {AbilityEffect.queenEscape};
      case GameAbility.queenSplit:
        return {AbilityEffect.queenSplit};
      case GameAbility.pawnInheritance:
        return {AbilityEffect.pawnInheritance};
      case GameAbility.pawnRansom:
        return {AbilityEffect.pawnRansom};
      case GameAbility.knightDuel:
        return {AbilityEffect.knightDuel};
      case GameAbility.knightGuard:
        return {AbilityEffect.knightGuard};
      case GameAbility.knightTour:
        return {AbilityEffect.knightTour};
      case GameAbility.bishopSanctuary:
        return {AbilityEffect.bishopSanctuary};
      case GameAbility.bishopExcommunication:
        return {AbilityEffect.bishopExcommunication};
      case GameAbility.bishopTithe:
        return {AbilityEffect.bishopTithe};
      case GameAbility.bishopPilgrimage:
        return {AbilityEffect.bishopPilgrimage};
      case GameAbility.rookStandardBearer:
        return {AbilityEffect.rookStandardBearer};
      case GameAbility.rookCustoms:
        return {AbilityEffect.rookCustoms};
      case GameAbility.rookDrawbridge:
        return {AbilityEffect.rookDrawbridge};
      case GameAbility.rookCurfew:
        return {AbilityEffect.rookCurfew};
      case GameAbility.rookSiegeCalculation:
        return {AbilityEffect.rookSiegeCalculation};
      case GameAbility.queenDelayedSentence:
        return {AbilityEffect.queenDelayedSentence};
      case GameAbility.queenTrophyEmbargo:
        return {AbilityEffect.queenTrophyEmbargo};
      case GameAbility.queenYouShallNotPass:
        return {AbilityEffect.queenYouShallNotPass};
      case GameAbility.kingPrisonerExchange:
        return {AbilityEffect.kingPrisonerExchange};
      case GameAbility.kingRemoveEnemyMod:
        return {AbilityEffect.kingRemoveEnemyMod};
      case GameAbility.pawnForTheKing:
        return {AbilityEffect.forTheKing};
      case GameAbility.pawnCamouflageNet:
        return {AbilityEffect.camouflageNet};
      case GameAbility.pawnTrench:
        return {AbilityEffect.trench};
      case GameAbility.pawnSignalFire:
      case GameAbility.knightSignalFire:
      case GameAbility.bishopSignalFire:
      case GameAbility.rookSignalFire:
        return {AbilityEffect.signalFire};
      case GameAbility.pawnAvengeMe:
        return {AbilityEffect.avengeMe};
      case GameAbility.pawnCaravan:
        return {AbilityEffect.caravan};
      case GameAbility.pawnFaceControl:
        return {AbilityEffect.faceControl};
      case GameAbility.knightDoppelgangerOnce:
        return {AbilityEffect.doppelgangerOnce};
      case GameAbility.knightDoppelgangers:
        return {AbilityEffect.doppelgangers};
      case GameAbility.knightFifthLeg:
        return {AbilityEffect.fifthLeg};
      case GameAbility.knightElusive:
      case GameAbility.bishopElusive:
        return {AbilityEffect.elusive};
      case GameAbility.knightStomp:
        return {AbilityEffect.stomp};
      case GameAbility.knightSurveyor:
        return {AbilityEffect.surveyor};
      case GameAbility.knightCornerQuest:
        return {AbilityEffect.cornerQuest};
      case GameAbility.knightRideMe:
        return {AbilityEffect.rideMe};
      case GameAbility.knightMagicHooves:
        return {AbilityEffect.magicHooves};
      case GameAbility.bishopCrusade:
        return {AbilityEffect.crusade};
      case GameAbility.bishopPost:
        return {AbilityEffect.post};
      case GameAbility.bishopParallelWorlds:
        return {AbilityEffect.parallelWorlds};
      case GameAbility.bishopAlcove:
        return {AbilityEffect.alcove};
      case GameAbility.bishopGlassCeiling:
        return {AbilityEffect.glassCeiling};
      case GameAbility.rookFerry:
        return {AbilityEffect.ferry};
      case GameAbility.rookSignalTower:
        return {AbilityEffect.signalTower};
      case GameAbility.kingAssemblyHall:
        return {AbilityEffect.assemblyHall};
      case GameAbility.boardTroopFatigue:
        return {AbilityEffect.troopFatigue};
      case GameAbility.boardCombatOptics:
        return {AbilityEffect.rangedMoveLimit};
      case GameAbility.boardMightMakesRight:
        return {AbilityEffect.mightMakesRight};
      case GameAbility.boardExpeditionaryCorps:
        return {AbilityEffect.expeditionaryCorps};
      case GameAbility.boardWitnessProtection:
        return {AbilityEffect.witnessProtection};
      case GameAbility.randomRightToMove:
        return {AbilityEffect.forcedPieceMove};
      case GameAbility.randomSymmetry:
        return {AbilityEffect.mirroredPieceType};
      case GameAbility.randomVeto:
        return {AbilityEffect.vetoedPiece};
      case GameAbility.randomStrike:
        return {AbilityEffect.strikePieceType};
      case GameAbility.randomBorderClosure:
        return {AbilityEffect.borderClosure};
      case GameAbility.randomMyopia:
        return {AbilityEffect.myopia};
      case GameAbility.boardLavaRank:
      case GameAbility.boardExtraRank:
      case GameAbility.boardExtraFile:
      case GameAbility.boardFogOfWar:
      case GameAbility.boardNight:
      case GameAbility.boardDay:
      case GameAbility.boardColorblind:
      case GameAbility.boardPawnFront:
      case GameAbility.boardCavalry:
      case GameAbility.boardMirror:
      case GameAbility.boardGhostCells:
      case GameAbility.boardAttraction:
      case GameAbility.boardVirus:
      case GameAbility.boardInvisibleRegiment:
      case GameAbility.boardShuffle:
      case GameAbility.boardTeleport:
      case GameAbility.boardVanityFair:
      case GameAbility.boardMinefield:
      case GameAbility.boardGolconda:
      case GameAbility.boardUnbridledHorse:
      case GameAbility.boardBaskerville:
      case GameAbility.boardBloodOath:
      case GameAbility.boardSilentFile:
      case GameAbility.boardFourHorsemen:
      case GameAbility.boardReroll:
      case GameAbility.boardPassiveAggression:
      case GameAbility.boardSkipTurn:
      case GameAbility.boardKingOfHill:
      case GameAbility.boardSecretRoute:
      case GameAbility.boardRoyalPilgrimage:
      case GameAbility.boardSprint:
      case GameAbility.boardZebras:
      case GameAbility.boardFisher:
      case GameAbility.boardFisherMadness:
      case GameAbility.boardDeserters:
      case GameAbility.boardLetterH:
      case GameAbility.boardFullCircle:
      case GameAbility.boardArchitect:
      case GameAbility.boardBigAssortment:
      case GameAbility.boardBlindSpot:
      case GameAbility.boardOnlyEqualsKill:
      case GameAbility.boardMarseillesChess:
      case GameAbility.boardInitiativeFear:
      case GameAbility.boardSwamp:
      case GameAbility.boardCollectiveMyopia:
      case GameAbility.boardTerritoryExpand:
      case GameAbility.boardFrostMap:
      case GameAbility.boardScorchingSun:
      case GameAbility.boardTurncoats:
      case GameAbility.randomQuicksand:
      case GameAbility.randomShift:
      case GameAbility.randomCalm:
      case GameAbility.randomQuarantine:
      case GameAbility.randomEarthquake:
      case GameAbility.randomTyphoon:
      case GameAbility.randomWormhole:
      case GameAbility.randomClone:
      case GameAbility.randomNoQueen:
      case GameAbility.randomTruce:
      case GameAbility.randomMeteorRain:
      case GameAbility.randomCensus:
      case GameAbility.randomExterminatus:
      case GameAbility.randomGoldenThrone:
      case GameAbility.randomLottery:
      case GameAbility.randomPlague:
      case GameAbility.randomMutation:
      case GameAbility.randomAuction:
      case GameAbility.randomFurtherMore:
      case GameAbility.randomWordOfHonor:
      case GameAbility.randomInitiativeIntercept:
      case GameAbility.randomMagicShutdown:
      case GameAbility.randomTimeCapsule:
      case GameAbility.randomSuicideCapture:
      case GameAbility.randomMeatGrinder:
        return {};
    }
  }
}
