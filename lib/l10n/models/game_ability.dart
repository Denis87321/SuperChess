import '../../chess/board_labels.dart';
import 'ability_group.dart';
import 'piece.dart';
import 'square.dart';

enum GameAbility {
  boardPawnsSideways,
  boardPawnsDiagonal,
  boardPawnsBackward,
  boardKingSwap,
  boardLavaRank,
  boardExtraRank,
  boardExtraFile,
  boardFogOfWar,
  boardTide,
  boardDoubleStart,
  boardSprint,
  boardZebras,
  boardFisher,
  boardFisherMadness,
  boardNight,
  boardDay,
  boardColorblind,
  boardPawnFront,
  boardCavalry,
  boardMirror,
  boardGhostCells,
  boardAttraction,
  boardVirus,
  boardInvisibleRegiment,
  boardShuffle,
  boardTeleport,
  boardVanityFair,
  boardMinefield,
  boardGolconda,
  boardUnbridledHorse,
  boardBaskerville,
  boardBloodOath,
  boardSilentFile,
  boardFourHorsemen,
  boardReroll,
  boardPassiveAggression,
  boardSkipTurn,
  boardTroopFatigue,
  boardCombatOptics,
  boardKingOfHill,
  boardSecretRoute,
  boardRoyalPilgrimage,
  boardMightMakesRight,
  boardExpeditionaryCorps,
  boardWitnessProtection,
  boardDeserters,
  boardLetterH,
  boardFullCircle,
  boardArchitect,
  boardBigAssortment,
  boardBlindSpot,
  boardOnlyEqualsKill,
  boardMarseillesChess,
  boardInitiativeFear,
  boardSwamp,
  boardCollectiveMyopia,
  boardTerritoryExpand,
  boardFrostMap,
  boardScorchingSun,
  boardTurncoats,

  pawnSideways,
  pawnInverted,
  pawnAlwaysDoubleStep,
  pawnRam,
  pawnAirborne,
  pawnBoomerang,
  pawnKamikaze,
  pawnCaliph,
  pawnSticky,
  pawnPolymorph,
  pawnInheritance,
  pawnRansom,
  pawnForTheKing,
  pawnCamouflageNet,
  pawnTrench,
  pawnSignalFire,
  pawnAvengeMe,
  pawnCaravan,
  pawnFaceControl,

  knightRearing,
  knightLongJump,
  knightSecondChance,
  knightBoomerang,
  knightGallop,
  knightDust,
  knightCentaur,
  knightTrojan,
  knightDuel,
  knightGuard,
  knightTour,
  knightDoppelgangerOnce,
  knightDoppelgangers,
  knightFifthLeg,
  knightElusive,
  knightStomp,
  knightSurveyor,
  knightCornerQuest,
  knightRideMe,
  knightMagicHooves,
  knightSignalFire,

  bishopHopAlly,
  bishopColorChaos,
  bishopBoomerang,
  bishopInquisitor,
  bishopColorVow,
  bishopBrothers,
  bishopSanctuary,
  bishopExcommunication,
  bishopTithe,
  bishopPilgrimage,
  bishopCrusade,
  bishopPost,
  bishopParallelWorlds,
  bishopAlcove,
  bishopGlassCeiling,
  bishopElusive,
  bishopSignalFire,

  rookHopAlly,
  rookRam,
  rookAstronomicon,
  rookFortress,
  rookStandardBearer,
  rookCustoms,
  rookDrawbridge,
  rookCurfew,
  rookSiegeCalculation,
  rookFerry,
  rookSignalTower,
  rookSignalFire,

  queenKnightStep,
  queenHopAlly,
  queenSplit,
  queenMatka,
  queenShadowEmpress,
  queenEscape,
  queenDelayedSentence,
  queenTrophyEmbargo,
  queenYouShallNotPass,

  kingRoyalDecree,
  kingExtraStep,
  kingShield,
  kingAura,
  kingDoppelganger,
  kingThrone,
  kingFamilyUnion,
  kingPrisonerExchange,
  kingRemoveEnemyMod,
  kingAssemblyHall,

  randomShift,
  randomCalm,
  randomQuarantine,
  randomEarthquake,
  randomTyphoon,
  randomWormhole,
  randomClone,
  randomNoQueen,
  randomTruce,
  randomMeteorRain,
  randomCensus,
  randomExterminatus,
  randomGoldenThrone,
  randomLottery,
  randomPlague,
  randomMutation,
  randomAuction,
  randomRightToMove,
  randomFurtherMore,
  randomWordOfHonor,
  randomSymmetry,
  randomVeto,
  randomInitiativeIntercept,
  randomStrike,
  randomBorderClosure,
  randomMyopia,
  randomMagicShutdown,
  randomTimeCapsule,
  randomSuicideCapture,
  randomMeatGrinder,
  randomQuicksand,
}

extension GameAbilityInfo on GameAbility {
  AbilityGroup get group {
    switch (this) {
      case GameAbility.boardPawnsSideways:
      case GameAbility.boardPawnsDiagonal:
      case GameAbility.boardPawnsBackward:
      case GameAbility.boardKingSwap:
      case GameAbility.boardLavaRank:
      case GameAbility.boardExtraRank:
      case GameAbility.boardExtraFile:
      case GameAbility.boardFogOfWar:
      case GameAbility.boardDoubleStart:
      case GameAbility.boardSprint:
      case GameAbility.boardZebras:
      case GameAbility.boardFisher:
      case GameAbility.boardFisherMadness:
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
      case GameAbility.boardTroopFatigue:
      case GameAbility.boardCombatOptics:
      case GameAbility.boardKingOfHill:
      case GameAbility.boardSecretRoute:
      case GameAbility.boardRoyalPilgrimage:
      case GameAbility.boardMightMakesRight:
      case GameAbility.boardExpeditionaryCorps:
      case GameAbility.boardWitnessProtection:
      case GameAbility.boardDeserters:
      case GameAbility.boardLetterH:
      case GameAbility.boardFullCircle:
      case GameAbility.boardArchitect:
      case GameAbility.boardBigAssortment:
      case GameAbility.boardBlindSpot:
      case GameAbility.boardOnlyEqualsKill:
      case GameAbility.boardInitiativeFear:
      case GameAbility.boardSwamp:
      case GameAbility.boardCollectiveMyopia:
      case GameAbility.boardTerritoryExpand:
      case GameAbility.boardFrostMap:
      case GameAbility.boardScorchingSun:
        return AbilityGroup.board;
      case GameAbility.boardTide:
      case GameAbility.boardMarseillesChess:
      case GameAbility.boardTurncoats:
        return AbilityGroup.mode;
      case GameAbility.pawnSideways:
      case GameAbility.pawnInverted:
      case GameAbility.pawnAlwaysDoubleStep:
      case GameAbility.pawnRam:
      case GameAbility.pawnAirborne:
      case GameAbility.pawnBoomerang:
      case GameAbility.pawnKamikaze:
      case GameAbility.pawnCaliph:
      case GameAbility.pawnSticky:
      case GameAbility.pawnPolymorph:
      case GameAbility.pawnInheritance:
      case GameAbility.pawnRansom:
      case GameAbility.pawnForTheKing:
      case GameAbility.pawnCamouflageNet:
      case GameAbility.pawnTrench:
      case GameAbility.pawnSignalFire:
      case GameAbility.pawnAvengeMe:
      case GameAbility.pawnCaravan:
      case GameAbility.pawnFaceControl:
        return AbilityGroup.pawn;
      case GameAbility.knightRearing:
      case GameAbility.knightLongJump:
      case GameAbility.knightSecondChance:
      case GameAbility.knightBoomerang:
      case GameAbility.knightGallop:
      case GameAbility.knightDust:
      case GameAbility.knightCentaur:
      case GameAbility.knightTrojan:
      case GameAbility.knightDuel:
      case GameAbility.knightGuard:
      case GameAbility.knightTour:
      case GameAbility.knightDoppelgangerOnce:
      case GameAbility.knightDoppelgangers:
      case GameAbility.knightFifthLeg:
      case GameAbility.knightElusive:
      case GameAbility.knightStomp:
      case GameAbility.knightSurveyor:
      case GameAbility.knightCornerQuest:
      case GameAbility.knightRideMe:
      case GameAbility.knightMagicHooves:
      case GameAbility.knightSignalFire:
        return AbilityGroup.knight;
      case GameAbility.bishopHopAlly:
      case GameAbility.bishopColorChaos:
      case GameAbility.bishopBoomerang:
      case GameAbility.bishopInquisitor:
      case GameAbility.bishopColorVow:
      case GameAbility.bishopBrothers:
      case GameAbility.bishopSanctuary:
      case GameAbility.bishopExcommunication:
      case GameAbility.bishopTithe:
      case GameAbility.bishopPilgrimage:
      case GameAbility.bishopCrusade:
      case GameAbility.bishopPost:
      case GameAbility.bishopParallelWorlds:
      case GameAbility.bishopAlcove:
      case GameAbility.bishopGlassCeiling:
      case GameAbility.bishopElusive:
      case GameAbility.bishopSignalFire:
        return AbilityGroup.bishop;
      case GameAbility.rookHopAlly:
      case GameAbility.rookRam:
      case GameAbility.rookAstronomicon:
      case GameAbility.rookFortress:
      case GameAbility.rookStandardBearer:
      case GameAbility.rookCustoms:
      case GameAbility.rookDrawbridge:
      case GameAbility.rookCurfew:
      case GameAbility.rookSiegeCalculation:
      case GameAbility.rookFerry:
      case GameAbility.rookSignalTower:
      case GameAbility.rookSignalFire:
        return AbilityGroup.rook;
      case GameAbility.queenKnightStep:
      case GameAbility.queenHopAlly:
      case GameAbility.queenSplit:
      case GameAbility.queenMatka:
      case GameAbility.queenShadowEmpress:
      case GameAbility.queenEscape:
      case GameAbility.queenDelayedSentence:
      case GameAbility.queenTrophyEmbargo:
      case GameAbility.queenYouShallNotPass:
        return AbilityGroup.queen;
      case GameAbility.kingRoyalDecree:
      case GameAbility.kingExtraStep:
      case GameAbility.kingShield:
      case GameAbility.kingAura:
      case GameAbility.kingDoppelganger:
      case GameAbility.kingThrone:
      case GameAbility.kingFamilyUnion:
      case GameAbility.kingPrisonerExchange:
      case GameAbility.kingRemoveEnemyMod:
      case GameAbility.kingAssemblyHall:
        return AbilityGroup.king;
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
      case GameAbility.randomRightToMove:
      case GameAbility.randomFurtherMore:
      case GameAbility.randomWordOfHonor:
      case GameAbility.randomSymmetry:
      case GameAbility.randomVeto:
      case GameAbility.randomInitiativeIntercept:
      case GameAbility.randomStrike:
      case GameAbility.randomBorderClosure:
      case GameAbility.randomMyopia:
      case GameAbility.randomMagicShutdown:
      case GameAbility.randomTimeCapsule:
      case GameAbility.randomSuicideCapture:
      case GameAbility.randomMeatGrinder:
      case GameAbility.randomQuicksand:
        return AbilityGroup.random;
    }
  }

  String get title {
    switch (this) {
      case GameAbility.boardPawnsSideways:
        return 'РќР° СЂР°СЃРїСѓС‚СЊРµ';
      case GameAbility.boardPawnsDiagonal:
        return 'РџР°СЂС‚РёР·Р°РЅС‹';
      case GameAbility.boardPawnsBackward:
        return 'РЁР°РіСѓ РЅР°Р·Р°Рґ';
      case GameAbility.boardKingSwap:
        return 'РљРѕСЂРѕР»РµРІСЃРєРёР№ СѓРєР°Р·';
      case GameAbility.boardLavaRank:
        return 'РџРѕР» вЂ” СЌС‚Рѕ Р»Р°РІР°';
      case GameAbility.boardExtraRank:
        return 'РќРѕРІС‹Р№ СЌС‚Р°Р¶';
      case GameAbility.boardExtraFile:
        return 'РќРѕРІР°СЏ РІРµСЂС‚РёРєР°Р»СЊ';
      case GameAbility.boardFogOfWar:
        return 'РўСѓРјР°РЅ РІРѕР№РЅС‹';
      case GameAbility.boardTide:
        return 'РџСЂРёР»РёРІ';
      case GameAbility.boardDoubleStart:
        return 'Р”РІРѕР№РЅРѕР№ СЃС‚Р°СЂС‚';
      case GameAbility.boardSprint:
        return 'РЎРїСЂРёРЅС‚';
      case GameAbility.boardZebras:
        return 'Р—РµР±СЂС‹';
      case GameAbility.boardFisher:
        return 'РЁР°С…РјР°С‚С‹ Р¤РёС€РµСЂР°';
      case GameAbility.boardFisherMadness:
        return 'Р‘РµР·СѓРјРёРµ Р¤РёС€РµСЂР°';
      case GameAbility.boardNight:
        return 'Р’Рѕ С‚СЊРјРµ РЅРѕС‡РЅРѕР№';
      case GameAbility.boardDay:
        return 'РџСЂРё СЃРІРµС‚Рµ РґРЅСЏ';
      case GameAbility.boardColorblind:
        return 'Р”Р°Р»СЊС‚РѕРЅРёРє';
      case GameAbility.boardPawnFront:
        return 'РџРµС€РµС‡РЅС‹Р№ С„СЂРѕРЅС‚';
      case GameAbility.boardCavalry:
        return 'РџРѕ РєРѕРЅСЏРј';
      case GameAbility.boardMirror:
        return 'Р—РµСЂРєР°Р»Рѕ';
      case GameAbility.boardGhostCells:
        return 'РџСЂРёР·СЂР°С‡РЅС‹Рµ РєР»РµС‚РєРё';
      case GameAbility.boardAttraction:
        return 'РџСЂРёС‚СЏР¶РµРЅРёРµ';
      case GameAbility.boardVirus:
        return 'РЁР°С…РјР°С‚РЅС‹Р№ РІРёСЂСѓСЃ';
      case GameAbility.boardInvisibleRegiment:
        return 'РќРµРІРёРґРёРјС‹Р№ РїРѕР»Рє';
      case GameAbility.boardShuffle:
        return 'РџРµСЂРµС‚Р°СЃРѕРІРєР°';
      case GameAbility.boardTeleport:
        return 'РўРµР»РµРїРѕСЂС‚';
      case GameAbility.boardVanityFair:
        return 'РЇСЂРјР°СЂРєР° С‚С‰РµСЃР»Р°РІРёСЏ';
      case GameAbility.boardMinefield:
        return 'РњРёРЅРЅРѕРµ РїРѕР»Рµ';
      case GameAbility.boardGolconda:
        return 'Р“РѕР»РєРѕРЅРґР°';
      case GameAbility.boardUnbridledHorse:
        return 'РЎРєР°РєСѓРЅ Р±РµР· СѓР·РґС‹';
      case GameAbility.boardBaskerville:
        return 'Р­С„С„РµРєС‚ Р‘Р°СЃРєРµСЂРІРёР»РµР№';
      case GameAbility.boardBloodOath:
        return 'РљР»СЏС‚РІР° РєСЂРѕРІРё';
      case GameAbility.boardSilentFile:
        return 'РќРµРјР°СЏ РІРµСЂС‚РёРєР°Р»СЊ';
      case GameAbility.boardFourHorsemen:
        return '4 РІСЃР°РґРЅРёРєР°';
      case GameAbility.boardReroll:
        return 'РџРµСЂРµРІС‹Р±РѕСЂ';
      case GameAbility.boardPassiveAggression:
        return 'РџР°СЃСЃРёРІРЅР°СЏ Р°РіСЂРµСЃСЃРёСЏ';
      case GameAbility.boardSkipTurn:
        return 'РЇ РµС‰С‘ РґСѓРјР°СЋ';
      case GameAbility.boardTroopFatigue:
        return 'РЈСЃС‚Р°Р»РѕСЃС‚СЊ РІРѕР№СЃРє';
      case GameAbility.boardCombatOptics:
        return 'Р‘РѕРµРІР°СЏ РѕРїС‚РёРєР°';
      case GameAbility.boardKingOfHill:
        return 'Р¦Р°СЂСЊ РіРѕСЂС‹';
      case GameAbility.boardSecretRoute:
        return 'РўР°Р№РЅС‹Р№ РјР°СЂС€СЂСѓС‚';
      case GameAbility.boardRoyalPilgrimage:
        return 'РљРѕСЂРѕР»РµРІСЃРєРѕРµ РїР°Р»РѕРјРЅРёС‡РµСЃС‚РІРѕ';
      case GameAbility.boardMightMakesRight:
        return 'РџСЂР°РІРѕ СЃРёР»СЊРЅРѕРіРѕ';
      case GameAbility.boardExpeditionaryCorps:
        return 'Р Р°Р·РІРµРґРєРѕСЂРїСѓСЃ';
      case GameAbility.boardWitnessProtection:
        return 'РџСЂРѕРіСЂР°РјРјР° Р·Р°С‰РёС‚С‹ СЃРІРёРґРµС‚РµР»РµР№';
      case GameAbility.boardDeserters:
        return 'Р”РµР·РµСЂС‚РёСЂС‹';
      case GameAbility.boardLetterH:
        return 'H';
      case GameAbility.boardFullCircle:
        return 'РџРѕР»РЅС‹Р№ РєСЂСѓРі';
      case GameAbility.boardArchitect:
        return 'РђСЂС…РёС‚РµРєС‚РѕСЂ';
      case GameAbility.boardBigAssortment:
        return 'Р‘РѕР»СЊС€РѕР№ Р°СЃСЃРѕСЂС‚РёРјРµРЅС‚';
      case GameAbility.boardBlindSpot:
        return 'РЎР»РµРїР°СЏ Р·РѕРЅР°';
      case GameAbility.boardOnlyEqualsKill:
        return 'РўРѕР»СЊРєРѕ СЂР°РІРЅС‹Р№ СѓР±СЊС‘С‚';
      case GameAbility.boardMarseillesChess:
        return 'РњР°СЂСЃРµР»СЊСЃРєРёРµ С€Р°С…РјР°С‚С‹';
      case GameAbility.boardInitiativeFear:
        return 'Р‘РѕСЏР·РЅСЊ РёРЅРёС†РёР°С‚РёРІС‹';
      case GameAbility.boardSwamp:
        return 'What are you doing in my swamp';
      case GameAbility.boardCollectiveMyopia:
        return 'РљРѕР»Р»РµРєС‚РёРІРЅРѕРµ Р±Р»РёР·РѕСЂСѓРєРѕРµ';
      case GameAbility.boardTerritoryExpand:
        return 'Р Р°СЃС€РёСЂРµРЅРёРµ С‚РµСЂСЂРёС‚РѕСЂРёРё';
      case GameAbility.boardFrostMap:
        return 'РњРѕСЂРѕР·РЅР°СЏ РєР°СЂС‚Р°';
      case GameAbility.boardScorchingSun:
        return 'РџР°Р»СЏС‰РµРµ СЃРѕР»РЅС†Рµ';
      case GameAbility.boardTurncoats:
        return 'РћС‚СЃС‚СѓРїРЅРёРєРё';
      case GameAbility.pawnSideways:
        return 'РљР°СЂС†РёРЅРёР·Р°С†РёСЏ';
      case GameAbility.pawnInverted:
        return 'Р”РёР°РіРѕРЅР°Р»СЊРЅС‹Р№ С…РѕРґ';
      case GameAbility.pawnAlwaysDoubleStep:
        return 'Р”Р»РёРЅРЅС‹Р№ С€Р°Рі';
      case GameAbility.pawnRam:
        return 'РќР° С‚Р°СЂР°РЅ';
      case GameAbility.pawnAirborne:
        return 'Р”РµСЃР°РЅС‚';
      case GameAbility.pawnBoomerang:
      case GameAbility.knightBoomerang:
      case GameAbility.bishopBoomerang:
        return 'Р‘СѓРјРµСЂР°РЅРі';
      case GameAbility.pawnKamikaze:
        return 'РљР°РјРёРєР°РґР·Рµ';
      case GameAbility.pawnCaliph:
        return 'РҐР°Р»РёС„ РЅР° С‡Р°СЃ';
      case GameAbility.pawnSticky:
        return 'Р›РёРїРѕС‚Р°';
      case GameAbility.pawnPolymorph:
        return 'РџРѕР»РёРјРѕСЂС„';
      case GameAbility.pawnInheritance:
        return 'РќР°СЃР»РµРґСЃС‚РІРѕ';
      case GameAbility.pawnRansom:
        return 'Р’С‹РєСѓРї';
      case GameAbility.pawnForTheKing:
        return 'Р’Рѕ РёРјСЏ РљРѕСЂРѕР»СЏ';
      case GameAbility.pawnCamouflageNet:
        return 'РњР°СЃРєРёСЂРѕРІРѕС‡РЅР°СЏ СЃРµС‚СЊ';
      case GameAbility.pawnTrench:
        return 'РћРєРѕРї';
      case GameAbility.pawnSignalFire:
      case GameAbility.knightSignalFire:
      case GameAbility.bishopSignalFire:
      case GameAbility.rookSignalFire:
        return 'РЎРёРіРЅР°Р»СЊРЅС‹Р№ РєРѕСЃС‚РµСЂ';
      case GameAbility.pawnAvengeMe:
        return 'РћС‚РѕРјСЃС‚Рё Р·Р° РјРµРЅСЏ';
      case GameAbility.pawnCaravan:
        return 'РљР°СЂР°РІР°РЅ';
      case GameAbility.pawnFaceControl:
        return 'Р¤РµР№СЃРєРѕРЅС‚СЂРѕР»СЊ';
      case GameAbility.knightRearing:
        return 'Р’СЃС‚Р°С‚СЊ РЅР° РґС‹Р±С‹';
      case GameAbility.knightLongJump:
        return 'РџРµРіР°СЃ';
      case GameAbility.knightSecondChance:
        return 'Р’С‚РѕСЂРѕР№ С€Р°РЅСЃ';
      case GameAbility.knightGallop:
        return 'Р“Р°Р»РѕРї';
      case GameAbility.knightDust:
        return 'РџС‹Р»СЊ РёР·-РїРѕРґ РєРѕРїС‹С‚';
      case GameAbility.knightCentaur:
        return 'РљРµРЅС‚Р°РІСЂ';
      case GameAbility.knightTrojan:
        return 'РўСЂРѕСЏРЅСЃРєРёР№ РєРѕРЅСЊ';
      case GameAbility.knightDuel:
        return 'Р’С‹Р·РѕРІ РЅР° РґСѓСЌР»СЊ';
      case GameAbility.knightGuard:
        return 'РљР°СЂР°СѓР»';
      case GameAbility.knightTour:
        return 'РљРѕРЅРЅС‹Р№ С‚СѓСЂ';
      case GameAbility.knightDoppelgangerOnce:
        return 'Р”РІРѕР№РЅРёРє';
      case GameAbility.knightDoppelgangers:
        return 'Р”РІРѕР№РЅРёРєРё';
      case GameAbility.knightFifthLeg:
        return 'РџСЏС‚Р°СЏ РЅРѕРіР°';
      case GameAbility.knightElusive:
      case GameAbility.bishopElusive:
        return 'РќРµСѓР»РѕРІРёРјС‹Р№';
      case GameAbility.knightStomp:
        return 'РўРѕРїРѕС‚';
      case GameAbility.knightSurveyor:
        return 'Р“РµРѕРґРµР·РёСЃС‚';
      case GameAbility.knightCornerQuest:
        return 'Р—Р°РґР°С‡Р° РЅРµ РёР· Р»С‘РіРєРёС…';
      case GameAbility.knightRideMe:
        return 'РЎР°РґРёСЃСЊ РЅР° РјРµРЅСЏ';
      case GameAbility.knightMagicHooves:
        return 'Р’РѕР»С€РµР±РЅС‹Рµ РєРѕРїС‹С‚Р°';
      case GameAbility.bishopHopAlly:
        return 'РџСЂС‹Р¶РѕРє С‡РµСЂРµР· СЃРІРѕРµРіРѕ';
      case GameAbility.bishopColorChaos:
        return 'Р¦РІРµС‚РЅРѕР№ С…Р°РѕСЃ';
      case GameAbility.bishopInquisitor:
        return 'РРЅРєРІРёР·РёС‚РѕСЂ';
      case GameAbility.bishopColorVow:
        return 'Р¦РІРµС‚РЅР°СЏ РєР»СЏС‚РІР°';
      case GameAbility.bishopBrothers:
        return 'Р‘СЂР°С‚СЊСЏ РїРѕ СЂР°Р·СѓРјСѓ';
      case GameAbility.bishopSanctuary:
        return 'РЎРІСЏС‚РёР»РёС‰Рµ';
      case GameAbility.bishopExcommunication:
        return 'РћС‚Р»СѓС‡РµРЅРёРµ';
      case GameAbility.bishopTithe:
        return 'Р”РµСЃСЏС‚РёРЅР°';
      case GameAbility.bishopPilgrimage:
        return 'РџР°Р»РѕРјРЅРёС‡РµСЃС‚РІРѕ';
      case GameAbility.bishopCrusade:
        return 'РљСЂРµСЃС‚РѕРІС‹Р№ РїРѕС…РѕРґ';
      case GameAbility.bishopPost:
        return 'РџРѕСЃС‚';
      case GameAbility.bishopParallelWorlds:
        return 'РџР°СЂР°Р»Р»РµР»СЊРЅС‹Рµ РјРёСЂС‹';
      case GameAbility.bishopAlcove:
        return 'РђР»СЊРєРѕРІ';
      case GameAbility.bishopGlassCeiling:
        return 'РЎС‚РµРєР»СЏРЅРЅС‹Р№ РїРѕС‚РѕР»РѕРє';
      case GameAbility.rookHopAlly:
        return 'РџСЂС‹Р¶РѕРє С‡РµСЂРµР· СЃРІРѕРµРіРѕ';
      case GameAbility.rookRam:
        return 'РќР° С‚Р°СЂР°РЅ';
      case GameAbility.rookAstronomicon:
        return 'РђСЃС‚СЂРѕРЅРѕРјРёРєРѕРЅ';
      case GameAbility.rookFortress:
        return 'РљСЂРµРїРѕСЃС‚СЊ';
      case GameAbility.rookStandardBearer:
        return 'Р—РЅР°РјРµРЅРѕСЃРµС†';
      case GameAbility.rookCustoms:
        return 'РўР°РјРѕР¶РЅСЏ';
      case GameAbility.rookDrawbridge:
        return 'РџРѕРґСЉС‘РјРЅС‹Р№ РјРѕСЃС‚';
      case GameAbility.rookCurfew:
        return 'РљРѕРјРµРЅРґР°РЅС‚СЃРєРёР№ С‡Р°СЃ';
      case GameAbility.rookSiegeCalculation:
        return 'РћСЃР°РґРЅС‹Р№ СЂР°СЃС‡С‘С‚';
      case GameAbility.rookFerry:
        return 'РџРµСЂРµРїСЂР°РІР°';
      case GameAbility.rookSignalTower:
        return 'РЎРёРіРЅР°Р»СЊРЅР°СЏ Р±Р°С€РЅСЏ';
      case GameAbility.queenKnightStep:
        return 'РљРѕРЅСЃРєРёР№ С…РѕРґ';
      case GameAbility.queenHopAlly:
        return 'РџСЂС‹Р¶РѕРє С‡РµСЂРµР· СЃРІРѕРµРіРѕ';
      case GameAbility.queenSplit:
        return 'Р Р°Р·РґРµР»РµРЅРёРµ';
      case GameAbility.queenMatka:
        return 'РњР°С‚РєР°';
      case GameAbility.queenShadowEmpress:
        return 'РРјРїРµСЂР°С‚СЂРёС†Р° С‚РµРЅРµР№';
      case GameAbility.queenEscape:
        return 'Р‘РµРіСЃС‚РІРѕ';
      case GameAbility.queenDelayedSentence:
        return 'РћС‚Р»РѕР¶РµРЅРЅС‹Р№ РїСЂРёРіРѕРІРѕСЂ';
      case GameAbility.queenTrophyEmbargo:
        return 'Р­РјР±Р°СЂРіРѕ РЅР° С‚СЂРѕС„РµРё';
      case GameAbility.queenYouShallNotPass:
        return 'РўС‹ РЅРµ РїСЂРѕР№РґС‘С€СЊ!';
      case GameAbility.kingRoyalDecree:
        return 'РљРѕСЂРѕР»РµРІСЃРєРёР№ СѓРєР°Р·';
      case GameAbility.kingExtraStep:
        return 'Р”Р»РёРЅРЅС‹Р№ С€Р°Рі';
      case GameAbility.kingShield:
        return 'Р©РёС‚ РєРѕСЂРѕР»СЏ';
      case GameAbility.kingAura:
        return 'РђСѓСЂР°';
      case GameAbility.kingDoppelganger:
        return 'Р”РѕРїРїРµР»СЊРіР°РЅРіРµСЂ';
      case GameAbility.kingThrone:
        return 'РЎРёР»Р° РўСЂРѕРЅР°';
      case GameAbility.kingFamilyUnion:
        return 'РћР±СЉРµРґРёРЅРµРЅРёРµ СЃРµРјРµР№';
      case GameAbility.kingPrisonerExchange:
        return 'РћР±РјРµРЅ РїР»РµРЅРЅС‹РјРё';
      case GameAbility.kingRemoveEnemyMod:
        return 'РќРµ РїСЂРµР¶РґРµ С‡РµРј РёС… РїРѕРІРµСЃСЏС‚';
      case GameAbility.kingAssemblyHall:
        return 'Р—Р°Р» Р·Р°СЃРµРґР°РЅРёР№';
      case GameAbility.randomShift:
        return 'РЎРґРІРёРі';
      case GameAbility.randomCalm:
        return 'Р—Р°С‚РёС€СЊРµ';
      case GameAbility.randomQuarantine:
        return 'РљР°СЂР°РЅС‚РёРЅ';
      case GameAbility.randomEarthquake:
        return 'Р—РµРјР»РµС‚СЂСЏСЃРµРЅРёРµ';
      case GameAbility.randomTyphoon:
        return 'РўР°Р№С„СѓРЅ';
      case GameAbility.randomWormhole:
        return 'Р§РµСЂРІРѕС‚РѕС‡РёРЅР°';
      case GameAbility.randomClone:
        return 'РљР»РѕРЅ';
      case GameAbility.randomNoQueen:
        return 'Р‘РµР· С„РµСЂР·СЏ';
      case GameAbility.randomTruce:
        return 'РџРµСЂРµРјРёСЂРёРµ';
      case GameAbility.randomMeteorRain:
        return 'РњРµС‚РµРѕСЂРёС‚РЅС‹Р№ РґРѕР¶РґСЊ';
      case GameAbility.randomCensus:
        return 'РџРµСЂРµРїРёСЃСЊ';
      case GameAbility.randomExterminatus:
        return 'Р­РєСЃС‚РµСЂРјРёРЅР°С‚СѓСЃ';
      case GameAbility.randomGoldenThrone:
        return 'Р—РѕР»РѕС‚РѕР№ С‚СЂРѕРЅ';
      case GameAbility.randomLottery:
        return 'Р›РѕС‚РµСЂРµСЏ';
      case GameAbility.randomPlague:
        return 'Р§СѓРјР°';
      case GameAbility.randomMutation:
        return 'РњСѓС‚Р°С†РёСЏ';
      case GameAbility.randomAuction:
        return 'РђСѓРєС†РёРѕРЅ';
      case GameAbility.randomRightToMove:
        return 'РџСЂР°РІРѕ С…РѕРґР°';
      case GameAbility.randomFurtherMore:
        return 'Р”Р°Р»СЊС€Рµ вЂ” Р±РѕР»СЊС€Рµ';
      case GameAbility.randomWordOfHonor:
        return 'РЎР»РѕРІРѕ РїР°С†Р°РЅР°';
      case GameAbility.randomSymmetry:
        return 'РЎРёРјРјРµС‚СЂРёСЏ';
      case GameAbility.randomVeto:
        return 'РџСЂР°РІРѕ РІРµС‚Рѕ';
      case GameAbility.randomInitiativeIntercept:
        return 'РџРµСЂРµС…РІР°С‚ РёРЅРёС†РёР°С‚РёРІС‹';
      case GameAbility.randomStrike:
        return 'Р—Р°Р±Р°СЃС‚РѕРІРєР°';
      case GameAbility.randomBorderClosure:
        return 'Р—Р°РєСЂС‹С‚РёРµ РіСЂР°РЅРёС†';
      case GameAbility.randomMyopia:
        return 'Р‘Р»РёР·РѕСЂСѓРєРѕСЃС‚СЊ';
      case GameAbility.randomMagicShutdown:
        return 'РћС‚РєР»СЋС‡РµРЅРёРµ РјР°РіРёРё';
      case GameAbility.randomTimeCapsule:
        return 'РљР°РїСЃСѓР»Р° РІСЂРµРјРµРЅРё';
      case GameAbility.randomSuicideCapture:
        return 'РЎРјРµСЂС‚РЅРёРє';
      case GameAbility.randomMeatGrinder:
        return 'РњСЏСЃРѕСЂСѓР±РєР°';
      case GameAbility.randomQuicksand:
        return 'Р—С‹Р±СѓС‡РёРµ РїРµСЃРєРё';
    }
  }

  String get description {
    switch (this) {
      case GameAbility.boardPawnsSideways:
        return 'Р’Р°С€Рё РїРµС€РєРё РјРѕРіСѓС‚ С…РѕРґРёС‚СЊ РїСЂСЏРјРѕ, РЅР°Р»РµРІРѕ Рё РЅР°РїСЂР°РІРѕ';
      case GameAbility.boardPawnsDiagonal:
        return 'Р’Р°С€Рё РїРµС€РєРё: С…РѕРґ РїРѕ РґРёР°РіРѕРЅР°Р»Рё, РІР·СЏС‚РёРµ РїРѕ РїСЂСЏРјРѕР№';
      case GameAbility.boardPawnsBackward:
        return 'Р’Р°С€Рё РїРµС€РєРё РјРѕРіСѓС‚ С…РѕРґРёС‚СЊ РЅР° РЅР°Р·Р°Рґ';
      case GameAbility.boardKingSwap:
        return 'Р’РјРµСЃС‚Рѕ СЂРѕРєРёСЂРѕРІРєРё РєРѕСЂРѕР»СЊ Рё Р»Р°РґСЊСЏ РјРµРЅСЏСЋС‚СЃСЏ РјРµСЃС‚Р°РјРё, РґР°Р¶Рµ РµСЃР»Рё РјРµР¶РґСѓ РЅРёРјРё РµСЃС‚СЊ С„РёРіСѓСЂС‹';
      case GameAbility.boardLavaRank:
        return 'Р“РѕСЂРёР·РѕРЅС‚Р°Р»СЊ ? РїРѕРєСЂС‹РІР°РµС‚СЃСЏ Р»Р°РІРѕР№';
      case GameAbility.boardExtraRank:
        return 'РњРµР¶РґСѓ РіРѕСЂРёР·РѕРЅС‚Р°Р»СЏРјРё 4 Рё 5 РїРѕСЏРІР»СЏРµС‚СЃСЏ РЅРѕРІР°СЏ РїСѓСЃС‚Р°СЏ РіРѕСЂРёР·РѕРЅС‚Р°Р»СЊ';
      case GameAbility.boardExtraFile:
        return 'РџРѕСЏРІР»СЏРµС‚СЃСЏ РЅРѕРІР°СЏ РІРµСЂС‚РёРєР°Р»СЊ ?';
      case GameAbility.boardFogOfWar:
        return 'Р’РёРґРЅС‹ С‚РѕР»СЊРєРѕ РєР»РµС‚РєРё РІРѕРєСЂСѓРі РІР°С€РёС… С„РёРіСѓСЂ Рё РєР»РµС‚РєРё, РЅР° РєРѕС‚РѕСЂС‹Рµ РѕРЅРё РјРѕРіСѓС‚ СЃС…РѕРґРёС‚СЊ';
      case GameAbility.boardTide:
        return 'Р’Р°С€Рё РїРµС€РєРё РІС‹РґРІРёРіР°СЋС‚СЃСЏ РІРїРµСЂС‘Рґ Рё С…РѕРґСЏС‚ С‚РѕР»СЊРєРѕ РЅР° 1 РєР»РµС‚РєСѓ РІРїРµСЂС‘Рґ';
      case GameAbility.boardDoubleStart:
        return 'РџРµС€РєРё СЃ РЅР°С‡Р°Р»СЊРЅРѕР№ Р»РёРЅРёРё РѕРґРёРЅ СЂР°Р· Р·Р° РїР°СЂС‚РёСЋ РјРѕРіСѓС‚ РїСЂРѕР№С‚Рё 3 РєР»РµС‚РєРё РІРїРµСЂС‘Рґ';
      case GameAbility.boardSprint:
        return 'РќР° РІС‹Р±РѕСЂ РјРѕРґР° РґР°С‘С‚СЃСЏ 10 СЃРµРєСѓРЅРґ РІРјРµСЃС‚Рѕ 30';
      case GameAbility.boardZebras:
        return 'Р’СЃРµ РєРѕРЅРё СЃС‚Р°РЅРѕРІСЏС‚СЃСЏ РѕР±С‰РёРјРё: РѕР±Р° РёРіСЂРѕРєР° С…РѕРґСЏС‚ РёРјРё РІ СЃРІРѕР№ С…РѕРґ. Р­С‚РёРјРё РєРѕРЅСЏРјРё РЅРµР»СЊР·СЏ РґР°С‚СЊ С€Р°С… РёР»Рё РјР°С‚';
      case GameAbility.boardFisher:
        return 'РўРѕР»СЊРєРѕ РЅР° СЃС‚Р°СЂС‚Рµ: СЂР°СЃСЃС‚Р°РЅРѕРІРєР° РѕР±РѕРёС… РёРіСЂРѕРєРѕРІ РїРѕ РїСЂР°РІРёР»Р°Рј С€Р°С…РјР°С‚ Р¤РёС€РµСЂР°: '
            'РїРµС€РєРё РЅР° РјРµСЃС‚Рµ, СЃР»РѕРЅС‹ РЅР° СЂР°Р·РЅС‹С… С†РІРµС‚Р°С…, РєРѕСЂРѕР»СЊ РјРµР¶РґСѓ Р»Р°РґСЊСЏРјРё, '
            'СЃС‚РѕСЂРѕРЅС‹ Р·РµСЂРєР°Р»СЊРЅС‹ РґСЂСѓРі РґСЂСѓРіСѓ';
      case GameAbility.boardFisherMadness:
        return 'РўРѕР»СЊРєРѕ РЅР° СЃС‚Р°СЂС‚Рµ: РІСЃРµ С„РёРіСѓСЂС‹ РѕР±РѕРёС… РёРіСЂРѕРєРѕРІ РїРµСЂРµРјРµС€РёРІР°СЋС‚СЃСЏ РјРµР¶РґСѓ СЃРѕР±РѕР№. РЎР»РѕРЅС‹ РЅР° СЂР°Р·РЅС‹С… С†РІРµС‚Р°С…, Р±РµР· СЂРѕРєРёСЂРѕРІРєРё';
      case GameAbility.boardNight:
        return 'РЎР»РµРґСѓСЋС‰РёРµ 3 С…РѕРґР° С„РёРіСѓСЂС‹ РјРѕРіСѓС‚ РІСЃС‚Р°РІР°С‚СЊ С‚РѕР»СЊРєРѕ РЅР° С‚С‘РјРЅС‹Рµ РєР»РµС‚РєРё';
      case GameAbility.boardDay:
        return 'РЎР»РµРґСѓСЋС‰РёРµ 3 С…РѕРґР° С„РёРіСѓСЂС‹ РјРѕРіСѓС‚ РІСЃС‚Р°РІР°С‚СЊ С‚РѕР»СЊРєРѕ РЅР° СЃРІРµС‚Р»С‹Рµ РєР»РµС‚РєРё';
      case GameAbility.boardColorblind:
        return 'Р’СЃРµ С„РёРіСѓСЂС‹ РїРµСЂРµР»РёРІР°СЋС‚СЃСЏ СЃР»СѓС‡Р°Р№РЅС‹РјРё С†РІРµС‚Р°РјРё. РџРѕ С†РІРµС‚Сѓ РЅРµР»СЊР·СЏ РїРѕРЅСЏС‚СЊ, РєРѕРјСѓ РїСЂРёРЅР°РґР»РµР¶РёС‚ С„РёРіСѓСЂР°';
      case GameAbility.boardPawnFront:
        return 'Р’СЃРµ РІР°С€Рё РїРµС€РєРё РїСЂРѕРґРІРёРіР°СЋС‚СЃСЏ РЅР° 1 РєР»РµС‚РєСѓ РІРїРµСЂС‘Рґ, РµСЃР»Рё РїСѓС‚СЊ СЃРІРѕР±РѕРґРµРЅ';
      case GameAbility.boardCavalry:
        return 'Р’СЃРµ РІР°С€Рё РїРµС€РєРё РЅР° 3 С…РѕРґР° СЃС‚Р°РЅРѕРІСЏС‚СЃСЏ РєРѕРЅСЏРјРё, Р·Р°С‚РµРј СЃРЅРѕРІР° РїСЂРµРІСЂР°С‰Р°СЋС‚СЃСЏ РІ РїРµС€РєРё';
      case GameAbility.boardMirror:
        return 'Р›РµРІР°СЏ Рё РїСЂР°РІР°СЏ РіСЂР°РЅРёС†С‹ РґРѕСЃРєРё СЃРѕРµРґРёРЅСЏСЋС‚СЃСЏ';
      case GameAbility.boardGhostCells:
        return 'РќРµСЃРєРѕР»СЊРєРѕ СЃР»СѓС‡Р°Р№РЅС‹С… РєР»РµС‚РѕРє СЃС‚Р°РЅРѕРІСЏС‚СЃСЏ РїСЂРёР·СЂР°С‡РЅС‹РјРё: С‡РµСЂРµР· РЅРёС… РјРѕР¶РЅРѕ С…РѕРґРёС‚СЊ, РЅРѕ СЃС‚РѕСЏС‚СЊ РЅРµР»СЊР·СЏ';
      case GameAbility.boardAttraction:
        return 'РљР°Р¶РґС‹Рµ 10 С…РѕРґРѕРІ РІСЃРµ С„РёРіСѓСЂС‹ СЃРґРІРёРіР°СЋС‚СЃСЏ РЅР° 1 РєР»РµС‚РєСѓ Рє С†РµРЅС‚СЂСѓ РґРѕСЃРєРё (d4, d5, e4, e5), РµСЃР»Рё СЌС‚Рѕ РІРѕР·РјРѕР¶РЅРѕ';
      case GameAbility.boardVirus:
        return 'РџРѕСЃР»Рµ РІР·СЏС‚РёСЏ С„РёРіСѓСЂР° Р·Р°СЂР°Р¶Р°РµС‚ СЃРѕСЃРµРґРЅСЋСЋ РІСЂР°Р¶РµСЃРєСѓСЋ: С‚Р° С‚РµСЂСЏРµС‚ РѕРґРЅСѓ РјРѕРґ';
      case GameAbility.boardInvisibleRegiment:
        return 'РћР±Р° РёРіСЂРѕРєР° РЅРµ РІРёРґСЏС‚ РїРµС€РєРё СЃРѕРїРµСЂРЅРёРєР°, РїРѕРєР° С‚Рµ РЅРµ СЃРґРµР»Р°СЋС‚ РІР·СЏС‚РёРµ РёР»Рё РЅРµ РґРѕР№РґСѓС‚ РґРѕ 4-Р№ Р»РёРЅРёРё (РґР»СЏ С‡С‘СЂРЅС‹С… вЂ” РґРѕ 5-Р№)';
      case GameAbility.boardShuffle:
        return 'РљР°Р¶РґР°СЏ РєР»РµС‚РєР° РґРѕСЃРєРё СЃР»СѓС‡Р°Р№РЅРѕ СЃС‚Р°РЅРѕРІРёС‚СЃСЏ СЃРІРµС‚Р»РѕР№ РёР»Рё С‚С‘РјРЅРѕР№ вЂ” С‡РµСЂРµРґРѕРІР°РЅРёРµ С†РІРµС‚РѕРІ РїСЂРѕРїР°РґР°РµС‚';
      case GameAbility.boardTeleport:
        return 'Р”РІРµ СЃР»СѓС‡Р°Р№РЅС‹Рµ РєР»РµС‚РєРё СЃРІСЏР·Р°РЅС‹: РІС…РѕРґ РЅР° РѕРґРЅСѓ = РІС‹С…РѕРґ РЅР° РґСЂСѓРіСѓСЋ';
      case GameAbility.boardVanityFair:
        return 'РљР°Р¶РґР°СЏ РІР°С€Р° Р»С‘РіРєР°СЏ С„РёРіСѓСЂР° (РєРѕРЅСЊ РёР»Рё СЃР»РѕРЅ) СЃ РІРµСЂРѕСЏС‚РЅРѕСЃС‚СЊСЋ 50% СЃС‚Р°РЅРѕРІРёС‚СЃСЏ РґСЂСѓРіРѕР№ Р»С‘РіРєРѕР№ С„РёРіСѓСЂРѕР№';
      case GameAbility.boardMinefield:
        return 'РќР° 1вЂ“3 СЃР»СѓС‡Р°Р№РЅС‹Рµ СЃРІРѕР±РѕРґРЅС‹Рµ РєР»РµС‚РєРё СЃС‚Р°РІСЏС‚СЃСЏ РЅРµРІРёРґРёРјС‹Рµ РјРёРЅС‹: СЃР»РµРґСѓСЋС‰Р°СЏ С„РёРіСѓСЂР° РЅР° РјРёРЅРµ СѓРЅРёС‡С‚РѕР¶Р°РµС‚СЃСЏ';
      case GameAbility.boardGolconda:
        return 'Р’ РЅР°С‡Р°Р»Рµ РєР°Р¶РґРѕРіРѕ С…РѕРґР° СЃ РІРµСЂРѕСЏС‚РЅРѕСЃС‚СЊСЋ 1% РЅР° СЃРІРѕР±РѕРґРЅСѓСЋ РєР»РµС‚РєСѓ РїР°РґР°РµС‚ РїРµС€РєР°, РєРѕРЅСЊ РёР»Рё СЃР»РѕРЅ РёРіСЂРѕРєР°, С‡РµР№ СЃРµР№С‡Р°СЃ С…РѕРґ';
      case GameAbility.boardUnbridledHorse:
        return 'Р’ РЅР°С‡Р°Р»Рµ С…РѕРґР° СЃ РІРµСЂРѕСЏС‚РЅРѕСЃС‚СЊСЋ 5% СЃР»СѓС‡Р°Р№РЅС‹Р№ РІР°С€ РєРѕРЅСЊ СЃР°Рј РґРµР»Р°РµС‚ С…РѕРґ РЅР° СЃР»СѓС‡Р°Р№РЅСѓСЋ РґРѕСЃС‚СѓРїРЅСѓСЋ РєР»РµС‚РєСѓ';
      case GameAbility.boardBaskerville:
        return 'Р”Р»СЏ РѕР±РѕРёС… РёРіСЂРѕРєРѕРІ: РµСЃР»Рё РёРіСЂРѕРє РїРѕСЃС‚Р°РІРёС‚ РІСЂР°Р¶РµСЃРєРѕРјСѓ РєРѕСЂРѕР»СЋ 2 С€Р°С…Р° Р·Р° РїР°СЂС‚РёСЋ, РєРѕСЂРѕР»СЊ СѓРјСЂС‘С‚ РѕС‚ СЃС‚СЂР°С…Р°';
      case GameAbility.boardBloodOath:
        return 'РџСЂРё РјР°С‚Рµ РєРѕСЂРѕР»СЊ РјРѕР¶РµС‚ СЃСЉРµСЃС‚СЊ СЃРІРѕСЋ С„РёРіСѓСЂСѓ СЂСЏРґРѕРј Рё РІСЃС‚Р°С‚СЊ РЅР° РµС‘ РјРµСЃС‚Рѕ, С‡С‚РѕР±С‹ РёР·Р±РµР¶Р°С‚СЊ РјР°С‚Р°';
      case GameAbility.boardSilentFile:
        return 'Р¤РёРіСѓСЂС‹ РЅР° РІС‹Р±СЂР°РЅРЅРѕР№ РІРµСЂС‚РёРєР°Р»Рё РЅРµ РјРѕРіСѓС‚ РґР°С‚СЊ С€Р°С… РёР»Рё РјР°С‚';
      case GameAbility.boardFourHorsemen:
        return 'РџРµСЂРІРѕРµ РІР·СЏС‚РёРµ РєР°Р¶РґРѕРіРѕ РєРѕРЅСЏ РїСЂРµРІСЂР°С‰Р°РµС‚ Р¶РµСЂС‚РІСѓ РІ РІР°С€Сѓ С„РёРіСѓСЂСѓ: РѕР±Р° РѕСЃС‚Р°СЋС‚СЃСЏ РЅР° РєР»РµС‚РєРµ, РїРѕРєР° РєС‚Рѕ-С‚Рѕ РЅРµ СѓР№РґС‘С‚';
      case GameAbility.boardReroll:
        return 'Р’СЃРµ РёРіСЂРѕРєРё РґРѕ РєРѕРЅС†Р° РёРіСЂС‹ РјРѕРіСѓС‚ РѕР±РЅРѕРІР»СЏС‚СЊ РїСЂРµРґР»РѕР¶РµРЅРЅС‹Рµ РјРѕРґС‹';
      case GameAbility.boardPassiveAggression:
        return 'РљР°Р¶РґС‹Р№ РёРіСЂРѕРє РґРѕР»Р¶РµРЅ РїРѕСЃС‚Р°РІРёС‚СЊ С€Р°С… С…РѕС‚СЏ Р±С‹ СЂР°Р· Р·Р° 10 СЃРІРѕРёС… С…РѕРґРѕРІ, РёРЅР°С‡Рµ РѕРЅ РїСЂРѕРёРіСЂС‹РІР°РµС‚; РїРѕСЃР»Рµ С€Р°С…Р° СЃС‡С‘С‚С‡РёРє СЃРЅРѕРІР° СЂР°РІРµРЅ 10';
      case GameAbility.boardSkipTurn:
        return 'РћР±Р° РёРіСЂРѕРєР° РјРѕРіСѓС‚ РїСЂРѕРїСѓСЃС‚РёС‚СЊ С…РѕРґ Рё РїРµСЂРµРґР°С‚СЊ РµРіРѕ СЃРѕРїРµСЂРЅРёРєСѓ';
      case GameAbility.boardTroopFatigue:
        return 'РћРґРЅРѕР№ С„РёРіСѓСЂРѕР№ РЅРµР»СЊР·СЏ С…РѕРґРёС‚СЊ РґРІР° СЃРІРѕРёС… С…РѕРґР° РїРѕРґСЂСЏРґ';
      case GameAbility.boardCombatOptics:
        return 'РЎР»РѕРЅ, Р»Р°РґСЊСЏ Рё С„РµСЂР·СЊ Р±РµР· РІР·СЏС‚РёСЏ С…РѕРґСЏС‚ РЅРµ РґР°Р»СЊС€Рµ 3 РєР»РµС‚РѕРє, Р° РїСЂРё РІР·СЏС‚РёРё вЂ” Р±РµР· РѕРіСЂР°РЅРёС‡РµРЅРёСЏ';
      case GameAbility.boardKingOfHill:
        return 'РџРѕСЃРµС‰С‘РЅРЅС‹Рµ РєР»РµС‚РєРё РѕРєСЂР°С€РёРІР°СЋС‚СЃСЏ РІ С†РІРµС‚ РёРіСЂРѕРєР°; РѕРєСЂР°С€РёРІР°РЅРёРµ Р±РѕР»РµРµ 48 РєР»РµС‚РѕРє РёР· 64 РїСЂРёРЅРѕСЃРёС‚ РїРѕР±РµРґСѓ';
      case GameAbility.boardSecretRoute:
        return 'РљР°Р¶РґС‹Р№ РёРіСЂРѕРє РїРѕР»СѓС‡Р°РµС‚ СЃРєСЂС‹С‚С‹Р№ РјР°СЂС€СЂСѓС‚ РёР· С‚СЂС‘С… РєР»РµС‚РѕРє; РїРѕСЃРµС‰РµРЅРёРµ РІСЃРµС… С‚СЂС‘С… РїСЂРёРЅРѕСЃРёС‚ РїРѕР±РµРґСѓ';
      case GameAbility.boardRoyalPilgrimage:
        return 'РљРѕСЂРѕР»СЊ, РґРѕСЃС‚РёРіС€РёР№ РєСЂР°Р№РЅРµР№ РіРѕСЂРёР·РѕРЅС‚Р°Р»Рё СЃРѕРїРµСЂРЅРёРєР° Р±РµР· С€Р°С…Р°, РїСЂРёРЅРѕСЃРёС‚ СЃРІРѕРµРјСѓ РёРіСЂРѕРєСѓ РїРѕР±РµРґСѓ';
      case GameAbility.boardMightMakesRight:
        return 'Р¤РёРіСѓСЂР° РјРѕР¶РµС‚ Р±СЂР°С‚СЊ С‚РѕР»СЊРєРѕ С„РёРіСѓСЂС‹ РЅРµ РґРѕСЂРѕР¶Рµ СЃРµР±СЏ; РєРѕСЂРѕР»СЊ РјРѕР¶РµС‚ Р±СЂР°С‚СЊ РІСЃРµС…, Рё РІСЃРµ РјРѕРіСѓС‚ Р°С‚Р°РєРѕРІР°С‚СЊ РєРѕСЂРѕР»СЏ';
      case GameAbility.boardExpeditionaryCorps:
        return 'Р¤РёРіСѓСЂР° РЅР° РїРѕР»РѕРІРёРЅРµ СЃРѕРїРµСЂРЅРёРєР° РЅРµ РјРѕР¶РµС‚ РІРµСЂРЅСѓС‚СЊСЃСЏ РЅР° СЃРІРѕСЋ РїРѕР»РѕРІРёРЅСѓ, РїРѕРєР° РЅРµ СЃРґРµР»Р°РµС‚ С…РѕС‚СЏ Р±С‹ РѕРґРЅРѕ РІР·СЏС‚РёРµ';
      case GameAbility.boardWitnessProtection:
        return 'РћР±Р° РёРіСЂРѕРєР° С‚Р°Р№РЅРѕ РІС‹Р±РёСЂР°СЋС‚ РѕРґРЅСѓ СЃРІРѕСЋ С„РёРіСѓСЂСѓ, РєСЂРѕРјРµ РєРѕСЂРѕР»СЏ; РµС‘ РїРµСЂРІРѕРµ РІР·СЏС‚РёРµ РѕС‚РјРµРЅСЏРµС‚СЃСЏ';
      case GameAbility.boardDeserters:
        return 'РЈ РєР°Р¶РґРѕРіРѕ РёРіСЂРѕРєР° С‚Р°Р№РЅРѕ РµСЃС‚СЊ РїРµС€РєР°-РґРµР·РµСЂС‚РёСЂ; РЅР° РІСЂР°Р¶РµСЃРєРѕР№ РїРѕР»РѕРІРёРЅРµ РѕРЅР° РјРµРЅСЏРµС‚ С†РІРµС‚';
      case GameAbility.boardLetterH:
        return 'РЎРѕСЃС‚Р°РІСЊС‚Рµ Р±СѓРєРІСѓ H РёР· 7 СЃРІРѕРёС… С„РёРіСѓСЂ вЂ” РїРѕР±РµРґР°';
      case GameAbility.boardFullCircle:
        return 'Р›Р°РґСЊСЏ, РїРѕСЃРµС‚РёРІС€Р°СЏ РІСЃРµ 4 СѓРіР»РѕРІС‹Рµ РєР»РµС‚РєРё, РїСЂРёРЅРѕСЃРёС‚ РїРѕР±РµРґСѓ';
      case GameAbility.boardArchitect:
        return 'РњРµР¶РґСѓ СЃР»СѓС‡Р°Р№РЅС‹РјРё СЃРѕСЃРµРґРЅРёРјРё РєР»РµС‚РєР°РјРё РїРѕСЏРІР»СЏСЋС‚СЃСЏ 3вЂ“8 СЃС‚РµРЅ: С‡РµСЂРµР· РЅРёС… РЅРµР»СЊР·СЏ С…РѕРґРёС‚СЊ Рё Р°С‚Р°РєРѕРІР°С‚СЊ';
      case GameAbility.boardBigAssortment:
        return 'Р”Рѕ РєРѕРЅС†Р° РёРіСЂС‹ РІС‹ РІС‹Р±РёСЂР°РµС‚Рµ РёР· 4 РјРѕРґРѕРІ';
      case GameAbility.boardBlindSpot:
        return 'РњРѕРґС‹ СЃРѕРїРµСЂРЅРёРєР° СЃРєСЂС‹С‚С‹ Р·РЅР°РєР°РјРё РІРѕРїСЂРѕСЃР°; СЃРІРѕРё РІРёРґРЅС‹ РєР°Рє РѕР±С‹С‡РЅРѕ';
      case GameAbility.boardOnlyEqualsKill:
        return 'РџСЏС‚СЊ РІР·СЏС‚РёР№ С„РёРіСѓСЂ С‚РѕРіРѕ Р¶Рµ С‚РёРїР°, С‡С‚Рѕ Рё РІР·СЏРІС€Р°СЏ, РїСЂРёРЅРѕСЃСЏС‚ РїРѕР±РµРґСѓ';
      case GameAbility.boardMarseillesChess:
        return 'Р—Р° РѕРґРёРЅ С…РѕРґ РёРіСЂРѕРє РґРµР»Р°РµС‚ РґРІР° РїРѕСЃР»РµРґРѕРІР°С‚РµР»СЊРЅС‹С… РґРІРёР¶РµРЅРёСЏ. Р’ СЃР±Р°Р»Р°РЅСЃРёСЂРѕРІР°РЅРЅРѕРј РІР°СЂРёР°РЅС‚Рµ Р±РµР»С‹Рµ РЅР° РїРµСЂРІРѕРј С…РѕРґСѓ РґРµР»Р°СЋС‚ С‚РѕР»СЊРєРѕ РѕРґРЅРѕ РґРІРёР¶РµРЅРёРµ';
      case GameAbility.boardInitiativeFear:
        return 'РџРµСЂРІС‹Р№ РёРіСЂРѕРє, С‡СЊСЏ С„РёРіСѓСЂР° Р±СѓРґРµС‚ СЃСЉРµРґРµРЅР°, РґРѕРїРѕР»РЅРёС‚РµР»СЊРЅРѕ РІС‹Р±РёСЂР°РµС‚ РјРѕРґ РІРЅРµ РѕР±С‹С‡РЅРѕР№ РІРѕР»РЅС‹ СЂР°Р· РІ 3 С…РѕРґР°';
      case GameAbility.boardSwamp:
        return 'Р¤РёРіСѓСЂР° СѓРІСЏР·Р°РµС‚ РїРѕСЃР»Рµ С…РѕРґР°: СЃР»РµРґСѓСЋС‰РёРј СЃРІРѕРёРј С…РѕРґРѕРј РµСЋ С…РѕРґРёС‚СЊ РЅРµР»СЊР·СЏ (РґСЂСѓРіРёРјРё вЂ” РјРѕР¶РЅРѕ)';
      case GameAbility.boardCollectiveMyopia:
        return 'РЎР»РѕРЅС‹, Р»Р°РґСЊРё Рё С„РµСЂР·Рё РЅРµ РјРѕРіСѓС‚ С…РѕРґРёС‚СЊ РґР°Р»СЊС€Рµ 3 РєР»РµС‚РѕРє';
      case GameAbility.boardTerritoryExpand:
        return 'РќР° РґРѕСЃРєРµ РїРѕСЏРІР»СЏСЋС‚СЃСЏ РІРµСЂС‚РёРєР°Р»Рё Z Рё I СЃСЂР°Р·Сѓ';
      case GameAbility.boardFrostMap:
        return 'Р¤РёРіСѓСЂС‹ Р·Р°РјРµСЂР·Р°СЋС‚ РїРѕСЃР»Рµ 3 С…РѕРґРѕРІ РЅР° РјРѕСЂРѕР·Рµ. РЈ РєР°Р¶РґРѕРіРѕ РёРіСЂРѕРєР° 3 С„Р°РєРµР»Р°: РѕРЅРё РЅРµ РјС‘СЂР·РЅСѓС‚ Рё СЃРѕРіСЂРµРІР°СЋС‚ СЃРѕСЃРµРґРµР№. РЎСЉРµРґРµРЅРЅС‹Р№ С„Р°РєРµР» РїРµСЂРµРґР°С‘С‚СЃСЏ Р±Р»РёР¶Р°Р№С€РµРјСѓ СЃРѕСЋР·РЅРёРєСѓ';
      case GameAbility.boardScorchingSun:
        return 'РЎРѕР»РЅС†Рµ РїР°Р»РёС‚ 3вЂ“6 РєР»РµС‚РѕРє (РјРµРЅСЏРµС‚ РєР°Р¶РґС‹Рµ 5 С…РѕРґРѕРІ). РќР°РіСЂРµРІ 0в†’3: РЅР° 3 С„РёРіСѓСЂР° РїРѕРіРёР±Р°РµС‚. Р’РЅРµ СЃРѕР»РЅС†Р° РЅР°РіСЂРµРІ РїР°РґР°РµС‚';
      case GameAbility.boardTurncoats:
        return 'РЈ РєР°Р¶РґРѕРіРѕ РёРіСЂРѕРєР° РѕРґРёРЅ С€РїРёРѕРЅ СЃСЂРµРґРё Р»С‘РіРєРёС… С„РёРіСѓСЂ. Р’С‹ РІРёРґРёС‚Рµ РІСЂР°Р¶РµСЃРєРѕРіРѕ С€РїРёРѕРЅР° Рё РјРѕР¶РµС‚Рµ СЃС…РѕРґРёС‚СЊ РёРј, СЂР°СЃРєСЂС‹РІ РµРіРѕ РЅР° СЃРІРѕСЋ СЃС‚РѕСЂРѕРЅСѓ. РЁРїРёРѕРЅ РЅРµ РјРѕР¶РµС‚ РїРѕСЃС‚Р°РІРёС‚СЊ РјР°С‚ В«СЃРІРѕРµРјСѓВ» РєРѕСЂРѕР»СЋ';
      case GameAbility.pawnSideways:
        return 'Р’С‹Р±СЂР°РЅРЅР°СЏ РїРµС€РєР° РјРѕР¶РµС‚ СЃС…РѕРґРёС‚СЊ РЅР° 1 РєР»РµС‚РєСѓ РІР±РѕРє';
      case GameAbility.pawnInverted:
        return 'Р’С‹Р±СЂР°РЅРЅР°СЏ РїРµС€РєР° С…РѕРґРёС‚ РїРѕ РґРёР°РіРѕРЅР°Р»Рё Рё РµСЃС‚ РїРѕ РїСЂСЏРјРѕР№';
      case GameAbility.pawnAlwaysDoubleStep:
        return 'Р’С‹Р±СЂР°РЅРЅР°СЏ РїРµС€РєР° РІСЃРµРіРґР° РјРѕР¶РµС‚ РїСЂРѕР№С‚Рё 2 РєР»РµС‚РєРё РІРїРµСЂС‘Рґ';
      case GameAbility.pawnRam:
        return 'Р’С‹Р±СЂР°РЅРЅР°СЏ РїРµС€РєР° С…РѕРґРёС‚ Рё РµСЃС‚ С‚РѕР»СЊРєРѕ РІРїРµСЂС‘Рґ, РЅРµ РїРѕ РґРёР°РіРѕРЅР°Р»Рё';
      case GameAbility.pawnAirborne:
        return 'Р’С‹Р±СЂР°РЅРЅР°СЏ РїРµС€РєР° РѕРґРёРЅ СЂР°Р· РјРѕР¶РµС‚ РїРµСЂРµРїСЂС‹РіРЅСѓС‚СЊ С„РёРіСѓСЂСѓ РїСЂСЏРјРѕ РїРµСЂРµРґ СЃРѕР±РѕР№';
      case GameAbility.pawnBoomerang:
      case GameAbility.knightBoomerang:
      case GameAbility.bishopBoomerang:
        return 'РџРѕСЃР»Рµ СЃР»РµРґСѓСЋС‰РµРіРѕ РІР·СЏС‚РёСЏ РІС‹Р±СЂР°РЅРЅР°СЏ С„РёРіСѓСЂР° СЃСЂР°Р·Сѓ РІРѕР·РІСЂР°С‰Р°РµС‚СЃСЏ РЅР° РєР»РµС‚РєСѓ, СЃ РєРѕС‚РѕСЂРѕР№ С…РѕРґРёР»Р°';
      case GameAbility.pawnKamikaze:
        return 'Р’ РІР°С€ СЃР»РµРґСѓСЋС‰РёР№ С…РѕРґ РІС‹Р±СЂР°РЅРЅР°СЏ РїРµС€РєР° РІР·СЂС‹РІР°РµС‚СЃСЏ Рё РѕС‚Р±СЂР°СЃС‹РІР°РµС‚ СЃРѕСЃРµРґРЅРёРµ С„РёРіСѓСЂС‹ РЅР° 1 РєР»РµС‚РєСѓ РѕС‚ СЃРµР±СЏ, РµСЃР»Рё РІРѕР·РјРѕР¶РЅРѕ';
      case GameAbility.pawnCaliph:
        return 'РќР° 1 РІР°С€ С…РѕРґ РІС‹Р±СЂР°РЅРЅР°СЏ РїРµС€РєР° СЃС‚Р°РЅРѕРІРёС‚СЃСЏ С„РµСЂР·РµРј, Р·Р°С‚РµРј СЃРЅРѕРІР° РїРµС€РєРѕР№';
      case GameAbility.pawnSticky:
        return 'Р’СЂР°Р¶РµСЃРєР°СЏ С„РёРіСѓСЂР°, СЃСЉРµРІС€Р°СЏ РІС‹Р±СЂР°РЅРЅСѓСЋ РїРµС€РєСѓ, РЅР° СЃРІРѕР№ СЃР»РµРґСѓСЋС‰РёР№ С…РѕРґ РЅРµ СЃРјРѕР¶РµС‚ С…РѕРґРёС‚СЊ';
      case GameAbility.pawnPolymorph:
        return 'РџРѕСЃР»Рµ РІР·СЏС‚РёСЏ РІС‹Р±СЂР°РЅРЅР°СЏ РїРµС€РєР° РЅР° 1 СЃР»РµРґСѓСЋС‰РёР№ С…РѕРґ СЃС‚Р°РЅРѕРІРёС‚СЃСЏ С‚РёРїРѕРј СЃСЉРµРґРµРЅРЅРѕР№ С„РёРіСѓСЂС‹ Рё С…РѕРґРёС‚ РєР°Рє РѕРЅР°';
      case GameAbility.pawnInheritance:
        return 'РџРѕСЃР»Рµ РіРёР±РµР»Рё РІС‹Р±СЂР°РЅРЅРѕР№ РїРµС€РєРё РІСЃРµ РµС‘ РјРѕРґС‹ РїРµСЂРµС…РѕРґСЏС‚ Р±Р»РёР¶Р°Р№С€РµР№ СЃРІРѕРµР№ РїРµС€РєРµ';
      case GameAbility.pawnRansom:
        return 'РџСЂРё РїРѕРїС‹С‚РєРµ РІР·СЏС‚СЊ РІС‹Р±СЂР°РЅРЅСѓСЋ РїРµС€РєСѓ РјРѕР¶РЅРѕ СѓРЅРёС‡С‚РѕР¶РёС‚СЊ РѕРґРЅСѓ РµС‘ РјРѕРґ Рё РѕС‚РјРµРЅРёС‚СЊ РІР·СЏС‚РёРµ';
      case GameAbility.pawnForTheKing:
        return 'Р•СЃР»Рё РІС‹Р±СЂР°РЅРЅР°СЏ РїРµС€РєР° РїРѕРіРёР±Р°РµС‚ РЅР° РјРёРЅРµ, РІР°С€ РєРѕСЂРѕР»СЊ РїРѕР»СѓС‡Р°РµС‚ РІС‹Р±РѕСЂ РјРѕРґР°';
      case GameAbility.pawnCamouflageNet:
        return 'Р¤РёРіСѓСЂР°, РѕРєСЂСѓР¶С‘РЅРЅР°СЏ С‚СЂРµРјСЏ РёР»Рё Р±РѕР»РµРµ РІР°С€РёРјРё РїРµС€РєР°РјРё, РЅРµРІРёРґРёРјР° РґР»СЏ СЃРѕРїРµСЂРЅРёРєР°';
      case GameAbility.pawnTrench:
        return 'Р•СЃР»Рё РІС‹Р±СЂР°РЅРЅР°СЏ РїРµС€РєР° РЅРµ С…РѕРґРёР»Р° 5 Рё Р±РѕР»РµРµ СЃРІРѕРёС… С…РѕРґРѕРІ, РµС‘ РјРѕР¶РЅРѕ РІР·СЏС‚СЊ С‚РѕР»СЊРєРѕ РїСЂРё РґРІСѓС… Рё Р±РѕР»РµРµ Р°С‚Р°РєР°С…';
      case GameAbility.pawnSignalFire:
      case GameAbility.knightSignalFire:
      case GameAbility.bishopSignalFire:
      case GameAbility.rookSignalFire:
        return 'РЎР»СѓС‡Р°Р№РЅР°СЏ РєР»РµС‚РєР° РїРѕРґ С‚СѓРјР°РЅРѕРј РІРѕР№РЅС‹ РЅР°РІСЃРµРіРґР° РѕС‚РєСЂС‹РІР°РµС‚СЃСЏ РґР»СЏ РІР°СЃ';
      case GameAbility.pawnAvengeMe:
        return 'Р•СЃР»Рё РІС‹Р±СЂР°РЅРЅСѓСЋ РїРµС€РєСѓ РІР·СЏР»Рё, Р»СЋР±Р°СЏ СЃРѕСЃРµРґРЅСЏСЏ СЃРѕСЋР·РЅР°СЏ РїРµС€РєР° РјРѕР¶РµС‚ РІР·СЏС‚СЊ РІР·СЏРІС€СѓСЋ С„РёРіСѓСЂСѓ РґР°Р¶Рµ РЅРµРѕР±С‹С‡РЅС‹Рј С…РѕРґРѕРј';
      case GameAbility.pawnCaravan:
        return 'РЎРґРІРѕРµРЅРЅС‹Рµ РёР»Рё СЃС‚СЂРѕРµРЅРЅС‹Рµ РїРµС€РєРё СЃ РІС‹Р±СЂР°РЅРЅРѕР№ РЅР° РѕРґРЅРѕР№ РІРµСЂС‚РёРєР°Р»Рё С…РѕРґСЏС‚ РІРїРµСЂС‘Рґ РѕРґРЅРѕРІСЂРµРјРµРЅРЅРѕ';
      case GameAbility.pawnFaceControl:
        return 'Р’СЂР°Р¶РµСЃРєР°СЏ С„РёРіСѓСЂР° РїСЂСЏРјРѕ РїРµСЂРµРґ РІС‹Р±СЂР°РЅРЅРѕР№ РїРµС€РєРѕР№ РїСЂРѕРїСѓСЃРєР°РµС‚ СЃР»РµРґСѓСЋС‰РёР№ СЃРІРѕР№ С…РѕРґ';
      case GameAbility.knightRearing:
        return 'РќР° РєР»РµС‚РєСѓ РІС‹Р±СЂР°РЅРЅРѕРіРѕ РєРѕРЅСЏ РјРѕРіСѓС‚ РІСЃС‚Р°РІР°С‚СЊ РґСЂСѓРіРёРµ С„РёРіСѓСЂС‹; СЌС‚РѕРіРѕ РєРѕРЅСЏ РЅРµР»СЊР·СЏ СЃСЉРµСЃС‚СЊ';
      case GameAbility.knightLongJump:
        return 'Р’С‹Р±СЂР°РЅРЅС‹Р№ РєРѕРЅСЊ РїСЂС‹РіР°РµС‚ С‚РѕР»СЊРєРѕ РЅР° 3+1, Р° РЅРµ РЅР° 2+1';
      case GameAbility.knightSecondChance:
        return 'РџСЂРё РІР·СЏС‚РёРё РІС‹Р±СЂР°РЅРЅС‹Р№ РєРѕРЅСЊ РІРѕР·РІСЂР°С‰Р°РµС‚СЃСЏ РЅР° РїСЂРµРґС‹РґСѓС‰СѓСЋ РєР»РµС‚РєСѓ, РµСЃР»Рё РѕРЅР° СЃРІРѕР±РѕРґРЅР°';
      case GameAbility.knightGallop:
        return 'РџРѕСЃР»Рµ С…РѕРґР° РІС‹Р±СЂР°РЅРЅС‹Р№ РєРѕРЅСЊ РјРѕР¶РµС‚ СЃСЂР°Р·Сѓ СЃРґРµР»Р°С‚СЊ РІС‚РѕСЂРѕР№ РїСЂС‹Р¶РѕРє РЅР° СЃРІРѕР±РѕРґРЅСѓСЋ РєР»РµС‚РєСѓ';
      case GameAbility.knightDust:
        return 'РљР»РµС‚РєР°, СЃ РєРѕС‚РѕСЂРѕР№ СѓС€С‘Р» РІС‹Р±СЂР°РЅРЅС‹Р№ РєРѕРЅСЊ, РЅР° 1 С…РѕРґ РЅРµРґРѕСЃС‚СѓРїРЅР° РЅРёРєРѕРјСѓ';
      case GameAbility.knightCentaur:
        return 'Р’С‹Р±СЂР°РЅРЅС‹Р№ РєРѕРЅСЊ С‚Р°РєР¶Рµ РјРѕР¶РµС‚ С…РѕРґРёС‚СЊ РєР°Рє РєРѕСЂРѕР»СЊ РЅР° 1 РєР»РµС‚РєСѓ';
      case GameAbility.knightTrojan:
        return 'Р§РµСЂРµР· 3 С…РѕРґР° РІС‹Р±СЂР°РЅРЅС‹Р№ РєРѕРЅСЊ РІР·СЂС‹РІР°РµС‚СЃСЏ Рё СѓРЅРёС‡С‚РѕР¶Р°РµС‚ РІСЃРµ РѕРєСЂСѓР¶Р°СЋС‰РёРµ С„РёРіСѓСЂС‹; РѕС‚СЃС‡С‘С‚ РІРёРґРµРЅ Сѓ РєРѕРЅСЏ';
      case GameAbility.knightDuel:
        return 'Р’С‹Р±СЂР°РЅРЅС‹Р№ РєРѕРЅСЊ РІС‹Р±РёСЂР°РµС‚ РІСЂР°Р¶РµСЃРєСѓСЋ С„РёРіСѓСЂСѓ; РїРѕРєР° РѕРґРёРЅ РёР· РґСѓСЌР»СЏРЅС‚РѕРІ РЅРµ РїРѕРіРёР±РЅРµС‚, РѕРЅРё РјРѕРіСѓС‚ Р±СЂР°С‚СЊ С‚РѕР»СЊРєРѕ РґСЂСѓРі РґСЂСѓРіР°';
      case GameAbility.knightGuard:
        return 'Р’С‹Р±СЂР°РЅРЅС‹Р№ РєРѕРЅСЊ РІС‹Р±РёСЂР°РµС‚ РґРѕСЃС‚СѓРїРЅСѓСЋ РєР»РµС‚РєСѓ Рё 3 С…РѕРґР° Р·Р°С‰РёС‰Р°РµС‚ РµС‘: РІСЃС‚Р°РІС€СѓСЋ С‚СѓРґР° РІСЂР°Р¶РµСЃРєСѓСЋ С„РёРіСѓСЂСѓ РѕРЅ СЃСЂР°Р·Сѓ Р±РµСЂС‘С‚ РІРЅРµ С…РѕРґР°';
      case GameAbility.knightTour:
        return 'РџРѕСЃРµС‚РёРІ 8 СЂР°Р·РЅС‹С… РєР»РµС‚РѕРє, РІС‹Р±СЂР°РЅРЅС‹Р№ РєРѕРЅСЊ РїРѕР»СѓС‡Р°РµС‚ РґРѕРїРѕР»РЅРёС‚РµР»СЊРЅСѓСЋ РјРѕРґ';
      case GameAbility.knightDoppelgangerOnce:
        return 'РџРѕСЃР»Рµ С…РѕРґР° РІС‹Р±СЂР°РЅРЅС‹Р№ РєРѕРЅСЊ РѕРґРёРЅ СЂР°Р· РѕСЃС‚Р°РІР»СЏРµС‚ РёР»Р»СЋР·РёСЋ РЅР° СЃС‚Р°СЂС‚РѕРІРѕР№ РєР»РµС‚РєРµ; РµС‘ РІРёРґРёС‚ С‚РѕР»СЊРєРѕ СЃРѕРїРµСЂРЅРёРє';
      case GameAbility.knightDoppelgangers:
        return 'РџРѕСЃР»Рµ РєР°Р¶РґРѕРіРѕ С…РѕРґР° РІС‹Р±СЂР°РЅРЅС‹Р№ РєРѕРЅСЊ РѕСЃС‚Р°РІР»СЏРµС‚ РёР»Р»СЋР·РёСЋ РЅР° СЃС‚Р°СЂС‚Рµ; РёС… РІРёРґРёС‚ С‚РѕР»СЊРєРѕ СЃРѕРїРµСЂРЅРёРє';
      case GameAbility.knightFifthLeg:
        return 'Р’С‹Р±СЂР°РЅРЅС‹Р№ РєРѕРЅСЊ С…РѕРґРёС‚ РЅР° 2+2 РєР»РµС‚РєРё РІРјРµСЃС‚Рѕ 2+1';
      case GameAbility.knightElusive:
      case GameAbility.bishopElusive:
        return 'Р’С‹Р±СЂР°РЅРЅСѓСЋ С„РёРіСѓСЂСѓ РјРѕР¶РЅРѕ РІР·СЏС‚СЊ С‚РѕР»СЊРєРѕ РµСЃР»Рё РµС‘ Р°С‚Р°РєСѓСЋС‚ РЅРµ РјРµРЅРµРµ РґРІСѓС… РІСЂР°Р¶РµСЃРєРёС… С„РёРіСѓСЂ';
      case GameAbility.knightStomp:
        return 'РџРѕСЃР»Рµ СЃР»РµРґСѓСЋС‰РµРіРѕ С…РѕРґР° РІС‹Р±СЂР°РЅРЅРѕРіРѕ РєРѕРЅСЏ СЃРѕСЃРµРґРЅРёРµ РІСЂР°Р¶РµСЃРєРёРµ РїРµС€РєРё РїРѕ РІРѕР·РјРѕР¶РЅРѕСЃС‚Рё РѕС‚С…РѕРґСЏС‚ РѕС‚ РЅРµРіРѕ';
      case GameAbility.knightSurveyor:
        return 'РљР»РµС‚РєРё, РїРѕСЃРµС‰С‘РЅРЅС‹Рµ РІС‹Р±СЂР°РЅРЅС‹Рј РєРѕРЅС‘Рј, Р·Р°С‰РёС‰РµРЅС‹ РѕС‚ СЃР»СѓС‡Р°Р№РЅС‹С… РєР°С‚Р°РєР»РёР·РјРѕРІ';
      case GameAbility.knightCornerQuest:
        return 'Р•СЃР»Рё РєРѕРЅРё РёРіСЂРѕРєР° РІРјРµСЃС‚Рµ РїРѕСЃРµС‚РёР»Рё Р»СЋР±С‹Рµ 3 РёР· 4 СѓРіР»РѕРІС‹С… РєР»РµС‚РѕРє вЂ” РїРѕР±РµРґР°';
      case GameAbility.knightRideMe:
        return 'РџРµСЂРµРґ С…РѕРґРѕРј РІС‹Р±СЂР°РЅРЅРѕРіРѕ РєРѕРЅСЏ РІС‹Р±РµСЂРёС‚Рµ СЃРѕСЃРµРґРЅСЋСЋ РїРµС€РєСѓ: РѕРЅР° РїРѕРµРґРµС‚ СЃ РЅРёРј, СЃРѕС…СЂР°РЅСЏСЏ РѕС‚РЅРѕСЃРёС‚РµР»СЊРЅСѓСЋ РїРѕР·РёС†РёСЋ';
      case GameAbility.knightMagicHooves:
        return 'РЎР»РµРґСѓСЋС‰РёР№ С…РѕРґ РІС‹Р±СЂР°РЅРЅРѕРіРѕ РєРѕРЅСЏ СЃРѕР·РґР°С‘С‚ РїРѕСЂС‚Р°Р» СЃРѕ СЃС‚Р°СЂС‚РѕРІРѕР№ РєР»РµС‚РєРё РЅР° РєРѕРЅРµС‡РЅСѓСЋ';
      case GameAbility.bishopHopAlly:
        return 'Р’С‹Р±СЂР°РЅРЅС‹Р№ СЃР»РѕРЅ РјРѕР¶РµС‚ РїРµСЂРµРїСЂС‹РіРЅСѓС‚СЊ РѕРґРЅСѓ СЃРІРѕСЋ С„РёРіСѓСЂСѓ';
      case GameAbility.bishopColorChaos:
        return 'РћРґРёРЅ СЂР°Р· РІС‹Р±СЂР°РЅРЅС‹Р№ СЃР»РѕРЅ РјРѕР¶РµС‚ РІСЃС‚Р°С‚СЊ РЅР° СЃРѕСЃРµРґРЅСЋСЋ РїСѓСЃС‚СѓСЋ РєР»РµС‚РєСѓ, СЃРјРµРЅРёРІ С†РІРµС‚ РїРѕР»СЏ';
      case GameAbility.bishopInquisitor:
        return 'Р’РјРµСЃС‚Рѕ РІР·СЏС‚РёСЏ РІС‹Р±СЂР°РЅРЅС‹Р№ СЃР»РѕРЅ РјРѕР¶РµС‚ СЃРЅСЏС‚СЊ РѕРґРЅСѓ РјРѕРґ СЃ Р°С‚Р°РєСѓРµРјРѕР№ РІСЂР°Р¶РµСЃРєРѕР№ С„РёРіСѓСЂС‹, РѕСЃС‚Р°РІР°СЏСЃСЊ РЅР° РјРµСЃС‚Рµ';
      case GameAbility.bishopColorVow:
        return 'Р’С‹Р±СЂР°РЅРЅС‹Р№ СЃР»РѕРЅ РїСЂРёРІСЏР·Р°РЅ Рє С†РІРµС‚Сѓ СЃРІРѕРµР№ РєР»РµС‚РєРё Рё РїРѕРіРёР±Р°РµС‚ РЅР° РґСЂСѓРіРѕРј С†РІРµС‚Рµ; Р·Р°С‚Рѕ РјРѕР¶РµС‚ СЂРёРєРѕС€РµС‚РёС‚СЊ РЅР° 1 РєР»РµС‚РєСѓ РѕС‚ РєСЂР°СЏ РґРѕСЃРєРё';
      case GameAbility.bishopBrothers:
        return 'Р•СЃР»Рё Сѓ РІР°СЃ 2+ СЃР»РѕРЅР°, С…РѕРґ РІС‹Р±СЂР°РЅРЅРѕРіРѕ СЃРґРІРёРіР°РµС‚ РІСЃРµС… РІР°С€РёС… СЃР»РѕРЅРѕРІ С‚РµРј Р¶Рµ РІРµРєС‚РѕСЂРѕРј, РіРґРµ СЌС‚Рѕ РІРѕР·РјРѕР¶РЅРѕ';
      case GameAbility.bishopSanctuary:
        return 'Р’С‹Р±СЂР°РЅРЅС‹Р№ СЃР»РѕРЅ РІС‹Р±РёСЂР°РµС‚ СЃРѕСЋР·РЅРёРєР°, РєСЂРѕРјРµ РєРѕСЂРѕР»СЏ; РїСЂРё СЃР»РµРґСѓСЋС‰РµРј РІР·СЏС‚РёРё РїРѕРґР·Р°С‰РёС‚РЅРѕРіРѕ РІРјРµСЃС‚Рѕ РЅРµРіРѕ РїРѕРіРёР±Р°РµС‚ СЃР»РѕРЅ';
      case GameAbility.bishopExcommunication:
        return 'РџРѕСЃР»Рµ РІР·СЏС‚РёСЏ С„РёРіСѓСЂС‹ РІС‹Р±СЂР°РЅРЅС‹Рј СЃР»РѕРЅРѕРј РґСЂСѓРіРёРµ РІСЂР°РіРё С‚РѕРіРѕ Р¶Рµ С‚РёРїР° РґРѕ СЃР»РµРґСѓСЋС‰РµРіРѕ С…РѕРґР° СЌС‚РѕРіРѕ СЃР»РѕРЅР° РЅРµ РјРѕРіСѓС‚ Р±СЂР°С‚СЊ РµРіРѕ';
      case GameAbility.bishopTithe:
        return 'РњРѕРґРёС„РёС†РёСЂРѕРІР°РЅРЅС‹Р№ РІСЂР°Рі, РїРѕРєРёРЅСѓРІС€РёР№ РґРёР°РіРѕРЅР°Р»СЊ РІС‹Р±СЂР°РЅРЅРѕРіРѕ СЃР»РѕРЅР°, РґРѕ СЃР»РµРґСѓСЋС‰РµРіРѕ С…РѕРґР° СЌС‚РѕРіРѕ СЃР»РѕРЅР° С‚РµСЂСЏРµС‚ РѕРґРЅСѓ РјРѕРґ';
      case GameAbility.bishopPilgrimage:
        return 'РџРѕСЃРµС‚РёРІ РІСЃРµ С‡РµС‚С‹СЂРµ С‡РµС‚РІРµСЂС‚Рё РґРѕСЃРєРё, РІС‹Р±СЂР°РЅРЅС‹Р№ СЃР»РѕРЅ РІС‹Р±РёСЂР°РµС‚ СЃРѕСЋР·РЅРёРєР° Рё Р·Р°С‰РёС‰Р°РµС‚ РµРіРѕ РѕС‚ СЃР»РµРґСѓСЋС‰РµРіРѕ РІР·СЏС‚РёСЏ';
      case GameAbility.bishopCrusade:
        return 'РџРѕСЃР»Рµ РґРІСѓС… РІР·СЏС‚РёР№ РІС‹Р±СЂР°РЅРЅС‹Рј СЃР»РѕРЅРѕРј РЅР° РґРѕСЃРєРµ СЃСЂР°Р±Р°С‚С‹РІР°РµС‚ СЃР»СѓС‡Р°Р№РЅС‹Р№ РєР°С‚Р°РєР»РёР·Рј';
      case GameAbility.bishopPost:
        return 'РўСЂРё С…РѕРґР° РІС‹Р±СЂР°РЅРЅРѕРіРѕ СЃР»РѕРЅР° Р±РµР· РІР·СЏС‚РёР№ РґР°СЋС‚ РґРІР° РІС‹Р±РѕСЂР° РјРѕРґРѕРІ РїРѕРґСЂСЏРґ';
      case GameAbility.bishopParallelWorlds:
        return 'Р’С‹Р±СЂР°РЅРЅС‹Р№ СЃР»РѕРЅ РѕРґРёРЅ СЂР°Р· РјРµРЅСЏРµС‚СЃСЏ РјРµСЃС‚Р°РјРё СЃ СЃРѕСЋР·РЅРѕР№ С„РёРіСѓСЂРѕР№ РЅР° С‚РѕР№ Р¶Рµ РґРёР°РіРѕРЅР°Р»Рё';
      case GameAbility.bishopAlcove:
        return 'Р’С‹Р±СЂР°РЅРЅС‹Р№ СЃР»РѕРЅ РѕРґРёРЅ СЂР°Р· РјРѕР¶РµС‚ СЃРѕР·РґР°С‚СЊ РѕРґРЅСѓ РєР»РµС‚РєСѓ Р·Р° РєСЂР°РµРј РґРѕСЃРєРё Рё РІСЃС‚Р°С‚СЊ РЅР° РЅРµС‘';
      case GameAbility.bishopGlassCeiling:
        return 'Р’С‹Р±СЂР°РЅРЅС‹Р№ СЃР»РѕРЅ РјРѕР¶РµС‚ РїРµСЂРµРїСЂС‹РіРЅСѓС‚СЊ С‡РµСЂРµР· РѕРґРЅСѓ РІСЂР°Р¶РµСЃРєСѓСЋ С„РёРіСѓСЂСѓ РІРјРµСЃС‚Рѕ РІР·СЏС‚РёСЏ; С‚Р° РїСЂРѕРїСѓСЃРєР°РµС‚ С…РѕРґ';
      case GameAbility.rookHopAlly:
        return 'Р’С‹Р±СЂР°РЅРЅР°СЏ Р»Р°РґСЊСЏ РјРѕР¶РµС‚ РїРµСЂРµРїСЂС‹РіРЅСѓС‚СЊ РѕРґРЅСѓ СЃРІРѕСЋ С„РёРіСѓСЂСѓ';
      case GameAbility.rookRam:
        return 'Р’С‹Р±СЂР°РЅРЅР°СЏ Р»Р°РґСЊСЏ РјРѕР¶РµС‚ С‚РѕР»РєРЅСѓС‚СЊ СЃРІРѕСЋ С„РёРіСѓСЂСѓ РЅР° 1 РєР»РµС‚РєСѓ РґР°Р»СЊС€Рµ Рё Р·Р°РЅСЏС‚СЊ РµС‘ РјРµСЃС‚Рѕ';
      case GameAbility.rookAstronomicon:
        return 'Р•СЃР»Рё РІРµСЂС‚РёРєР°Р»СЊ РІС‹Р±СЂР°РЅРЅРѕР№ Р»Р°РґСЊРё РїСѓСЃС‚Р° РєСЂРѕРјРµ РЅРµС‘, Р»Р°РґСЊСЏ РїСЂРѕР¶РёРіР°РµС‚ РµС‘ РЅР° 3 С…РѕРґР°: РІСЂР°Рі РЅР° РІРµСЂС‚РёРєР°Р»Рё СѓРЅРёС‡С‚РѕР¶Р°РµС‚СЃСЏ, РєРѕСЂРѕР»СЊ РЅРµ РјРѕР¶РµС‚ С‚СѓРґР° РІСЃС‚Р°С‚СЊ';
      case GameAbility.rookFortress:
        return 'РљР»РµС‚РєР° РїРµСЂРµРґ РІС‹Р±СЂР°РЅРЅРѕР№ Р»Р°РґСЊС‘Р№ вЂ” СѓРєСЂРµРїР»РµРЅРёРµ: РІСЂР°Р¶РµСЃРєРёРµ РїРµС€РєРё Рё Р»С‘РіРєРёРµ С„РёРіСѓСЂС‹ РЅРµ РјРѕРіСѓС‚ СЃСЉРµСЃС‚СЊ С„РёРіСѓСЂСѓ РЅР° РЅРµР№';
      case GameAbility.rookStandardBearer:
        return 'Р¤РёРіСѓСЂС‹ РЅР° РІРѕСЃСЊРјРё РєР»РµС‚РєР°С… РІРѕРєСЂСѓРі РІС‹Р±СЂР°РЅРЅРѕР№ Р»Р°РґСЊРё РЅРµР»СЊР·СЏ РїРµСЂРµРјРµС‰Р°С‚СЊ РїСЂРёРЅСѓРґРёС‚РµР»СЊРЅС‹РјРё СЌС„С„РµРєС‚Р°РјРё РјРѕРґРѕРІ';
      case GameAbility.rookCustoms:
        return 'РЎР»РµРґСѓСЋС‰РёРµ 3 С…РѕРґР° РІСЂР°РіРё РЅРµ РјРѕРіСѓС‚ РІСЃС‚Р°РІР°С‚СЊ РЅР° РІС‹Р±СЂР°РЅРЅСѓСЋ СЃР»СѓС‡Р°Р№РЅРѕ РіРѕСЂРёР·РѕРЅС‚Р°Р»СЊ РёР»Рё РІРµСЂС‚РёРєР°Р»СЊ Р»Р°РґСЊРё, РµСЃР»Рё СѓР¶Рµ РЅРµ РЅР°С…РѕРґСЏС‚СЃСЏ РЅР° РЅРµР№';
      case GameAbility.rookDrawbridge:
        return 'РЎРѕСЋР·РЅС‹Рµ С„РёРіСѓСЂС‹ РјРѕРіСѓС‚ РїСЂРѕС…РѕРґРёС‚СЊ СЃРєРІРѕР·СЊ РІС‹Р±СЂР°РЅРЅСѓСЋ Р»Р°РґСЊСЋ';
      case GameAbility.rookCurfew:
        return 'Р’СЂР°Рі СЂСЏРґРѕРј СЃ РІС‹Р±СЂР°РЅРЅРѕР№ Р»Р°РґСЊС‘Р№ РЅРµ РјРѕР¶РµС‚ РѕС‚РѕР№С‚Рё РѕС‚ РЅРµС‘ 3 СЃРІРѕРёС… С…РѕРґР°, РїРѕРєР° Р»Р°РґСЊСЏ СЃР°РјР° РЅРµ РѕС‚РѕР№РґС‘С‚';
      case GameAbility.rookSiegeCalculation:
        return 'Р•СЃР»Рё РІС‹Р±СЂР°РЅРЅР°СЏ Р»Р°РґСЊСЏ 3 С…РѕРґР° РїРѕРґСЂСЏРґ РјРѕР¶РµС‚ РІР·СЏС‚СЊ РѕРґРЅСѓ Рё С‚Сѓ Р¶Рµ РІСЂР°Р¶РµСЃРєСѓСЋ С„РёРіСѓСЂСѓ, РЅРѕ РЅРµ Р±РµСЂС‘С‚ РµС‘, СЌС‚Р° С„РёРіСѓСЂР° РёСЃС‡РµР·Р°РµС‚';
      case GameAbility.rookFerry:
        return 'Р”Р»СЏ РІС‹Р±СЂР°РЅРЅРѕР№ Р»Р°РґСЊРё Р»РµРІР°СЏ Рё РїСЂР°РІР°СЏ РіСЂР°РЅРёС†С‹ РґРѕСЃРєРё СЃРѕРµРґРёРЅСЏСЋС‚СЃСЏ, РєР°Рє Сѓ Р—РµСЂРєР°Р»Р°';
      case GameAbility.rookSignalTower:
        return 'Р’С‹Р±СЂР°РЅРЅР°СЏ Р»Р°РґСЊСЏ СЂР°СЃРєСЂС‹РІР°РµС‚ С‚СѓРјР°РЅ РІРѕР№РЅС‹ РЅР° СЃРІРѕРµР№ РІРµСЂС‚РёРєР°Р»Рё Рё РіРѕСЂРёР·РѕРЅС‚Р°Р»Рё';
      case GameAbility.queenKnightStep:
        return 'Р’С‹Р±СЂР°РЅРЅС‹Р№ С„РµСЂР·СЊ РґРѕРїРѕР»РЅРёС‚РµР»СЊРЅРѕ С…РѕРґРёС‚ РєР°Рє РєРѕРЅСЊ';
      case GameAbility.queenHopAlly:
        return 'Р’С‹Р±СЂР°РЅРЅС‹Р№ С„РµСЂР·СЊ РјРѕР¶РµС‚ РїРµСЂРµРїСЂС‹РіРЅСѓС‚СЊ РѕРґРЅСѓ СЃРІРѕСЋ С„РёРіСѓСЂСѓ';
      case GameAbility.queenSplit:
        return 'Р’С‹Р±СЂР°РЅРЅС‹Р№ С„РµСЂР·СЊ РёСЃС‡РµР·Р°РµС‚: РЅР° РєР»РµС‚РєРµ РѕСЃС‚Р°СЋС‚СЃСЏ СЃР»РѕРЅ Рё Р»Р°РґСЊСЏ РѕРґРЅРѕРІСЂРµРјРµРЅРЅРѕ';
      case GameAbility.queenMatka:
        return 'Р’С‹Р±СЂР°РЅРЅС‹Р№ С„РµСЂР·СЊ РЅРµ РјРѕР¶РµС‚ РЅРёРєРѕРіРѕ СЃСЉРµСЃС‚СЊ, РЅРѕ РєР°Р¶РґС‹Рµ 3 РІР°С€РёС… С…РѕРґР° РІРѕРєСЂСѓРі РЅРµРіРѕ РЅР° СЃР»СѓС‡Р°Р№РЅРѕР№ СЃРІРѕР±РѕРґРЅРѕР№ РєР»РµС‚РєРµ РїРѕСЏРІР»СЏРµС‚СЃСЏ РїРµС€РєР°';
      case GameAbility.queenShadowEmpress:
        return 'Р’С‹Р±СЂР°РЅРЅС‹Р№ С„РµСЂР·СЊ РґРѕРїРѕР»РЅРёС‚РµР»СЊРЅРѕ С…РѕРґРёС‚ РєР°Рє РєРѕРЅСЊ (2+1), РЅРѕ РјРѕР¶РµС‚ РІСЃС‚Р°РІР°С‚СЊ С‚РѕР»СЊРєРѕ РЅР° РєР»РµС‚РєРё РѕРґРЅРѕРіРѕ С†РІРµС‚Р° (РІС‹Р±РёСЂР°РµС‚СЃСЏ СЃР»СѓС‡Р°Р№РЅРѕ)';
      case GameAbility.queenEscape:
        return 'Р•СЃР»Рё РІС‹Р±СЂР°РЅРЅРѕРіРѕ С„РµСЂР·СЏ СЃСЉРµРґСЏС‚, РЅР° СЃР»СѓС‡Р°Р№РЅРѕР№ СЃРІРѕР±РѕРґРЅРѕР№ РєР»РµС‚РєРµ РїРѕСЏРІРёС‚СЃСЏ РІР°С€ СЃР»РѕРЅ РёР»Рё Р»Р°РґСЊСЏ (50%), Р±РµР· С€Р°С…Р° Рё РјР°С‚Р° РІСЂР°Р¶РµСЃРєРѕРјСѓ РєРѕСЂРѕР»СЋ';
      case GameAbility.queenDelayedSentence:
        return 'Р’С‹Р±СЂР°РЅРЅС‹Р№ С„РµСЂР·СЊ РѕС‚РјРµС‡Р°РµС‚ Р°С‚Р°РєСѓРµРјРѕРіРѕ РІСЂР°РіР°; РїРѕСЃР»Рµ С…РѕРґР° СЃРѕРїРµСЂРЅРёРєР° С‚РѕС‚ РїРѕРіРёР±Р°РµС‚, РµСЃР»Рё РІСЃС‘ РµС‰С‘ РЅР°С…РѕРґРёС‚СЃСЏ РїРѕРґ Р°С‚Р°РєРѕР№ С„РµСЂР·СЏ';
      case GameAbility.queenTrophyEmbargo:
        return 'Р’Р·СЏС‚РёРµ РЅР° РєР»РµС‚РєРµ РїРѕРґ РєРѕРЅС‚СЂРѕР»РµРј РІС‹Р±СЂР°РЅРЅРѕРіРѕ С„РµСЂР·СЏ Р±РѕР»СЊС€Рµ РЅРµ РґР°С‘С‚ РЅР°РіСЂР°РґС‹ (РїСЂР°РІРёР»Рѕ СЃРѕРІРјРµСЃС‚РёРјРѕСЃС‚Рё; РІРѕР»РЅС‹ РјРѕРґРѕРІ РѕС‚ РІР·СЏС‚РёР№ РЅРµ Р·Р°РІРёСЃСЏС‚)';
      case GameAbility.queenYouShallNotPass:
        return 'Р’СЂР°Р¶РµСЃРєР°СЏ С„РёРіСѓСЂР°, РІР·СЏРІС€Р°СЏ РІС‹Р±СЂР°РЅРЅРѕРіРѕ С„РµСЂР·СЏ, С‚РѕР¶Рµ СѓРЅРёС‡С‚РѕР¶Р°РµС‚СЃСЏ';
      case GameAbility.kingRoyalDecree:
        return 'Р’С‹Р±СЂР°РЅРЅС‹Р№ РєРѕСЂРѕР»СЊ Рё Р»Р°РґСЊСЏ РјРµРЅСЏСЋС‚СЃСЏ РјРµСЃС‚Р°РјРё, РґР°Р¶Рµ РµСЃР»Рё РјРµР¶РґСѓ РЅРёРјРё РµСЃС‚СЊ С„РёРіСѓСЂС‹';
      case GameAbility.kingExtraStep:
        return 'Р’С‹Р±СЂР°РЅРЅС‹Р№ РєРѕСЂРѕР»СЊ РјРѕР¶РµС‚ С…РѕРґРёС‚СЊ РЅР° 2 РєР»РµС‚РєРё РІ Р»СЋР±СѓСЋ СЃС‚РѕСЂРѕРЅСѓ';
      case GameAbility.kingShield:
        return 'РћРґРёРЅ СЂР°Р· РІС‹Р±СЂР°РЅРЅС‹Р№ РєРѕСЂРѕР»СЊ РёР·Р±РµРіР°РµС‚ РјР°С‚Р°, С‚РµР»РµРїРѕСЂС‚РёСЂСѓСЏСЃСЊ РЅР° СЃР»СѓС‡Р°Р№РЅСѓСЋ СЃРІРѕР±РѕРґРЅСѓСЋ РєР»РµС‚РєСѓ';
      case GameAbility.kingAura:
        return 'Р’С‹Р±СЂР°РЅРЅРѕРјСѓ РєРѕСЂРѕР»СЋ РЅРµР»СЊР·СЏ РїРѕСЃС‚Р°РІРёС‚СЊ РјР°С‚ РїРµС€РєРѕР№';
      case GameAbility.kingDoppelganger:
        return 'Р’СЃРµ РІР°С€Рё РїРµС€РєРё Рё С„РµСЂР·СЊ РІС‹РіР»СЏРґСЏС‚ РєР°Рє РєРѕСЂРѕР»СЊ';
      case GameAbility.kingThrone:
        return 'РџРѕРєР° РІС‹Р±СЂР°РЅРЅС‹Р№ РєРѕСЂРѕР»СЊ СЃС‚РѕРёС‚ РЅР° С‚СЂРѕРЅРµ, С€Р°С… Р·Р°СЃС‡РёС‚С‹РІР°РµС‚СЃСЏ С‚РѕР»СЊРєРѕ РѕС‚ С„РёРіСѓСЂ РЅРµ РґР°Р»СЊС€Рµ 3 РєР»РµС‚РѕРє';
      case GameAbility.kingFamilyUnion:
        return 'Р’С‹Р±СЂР°РЅРЅС‹Р№ РєРѕСЂРѕР»СЊ РјРѕР¶РµС‚ СЃСЉРµСЃС‚СЊ СЃРІРѕСЋ Р»С‘РіРєСѓСЋ С„РёРіСѓСЂСѓ (РєРѕРЅСЏ РёР»Рё СЃР»РѕРЅР°) СЂСЏРґРѕРј Рё РґРѕ РєРѕРЅС†Р° РїР°СЂС‚РёРё С…РѕРґРёС‚СЊ С‚РѕР»СЊРєРѕ РєР°Рє РѕРЅР°';
      case GameAbility.kingPrisonerExchange:
        return 'Р’С‹ РІС‹Р±РёСЂР°РµС‚Рµ РІР·СЏС‚СѓСЋ СЃРѕРїРµСЂРЅРёРєРѕРј СЃРІРѕСЋ С„РёРіСѓСЂСѓ, Р° СЃРѕРїРµСЂРЅРёРє вЂ” РІР·СЏС‚СѓСЋ РІР°РјРё; РѕР±Рµ РІРѕР·РІСЂР°С‰Р°СЋС‚СЃСЏ РЅР° СЃР»СѓС‡Р°Р№РЅС‹Рµ СЃРІРѕР±РѕРґРЅС‹Рµ РєР»РµС‚РєРё';
      case GameAbility.kingRemoveEnemyMod:
        return 'Р’С‹ РІС‹Р±РёСЂР°РµС‚Рµ Рё СѓРґР°Р»СЏРµС‚Рµ РѕРґРЅСѓ РјРѕРґ Сѓ Р»СЋР±РѕР№ РІСЂР°Р¶РµСЃРєРѕР№ С„РёРіСѓСЂС‹';
      case GameAbility.kingAssemblyHall:
        return 'Р¤РёРіСѓСЂС‹ СЂСЏРґРѕРј СЃ РІС‹Р±СЂР°РЅРЅС‹Рј РєРѕСЂРѕР»С‘Рј РЅРµ РјРѕРіСѓС‚ Р±С‹С‚СЊ С†РµР»СЊСЋ СЃР»СѓС‡Р°Р№РЅРѕРіРѕ РІС‹Р±РѕСЂР° РєР°С‚Р°РєР»РёР·РјР°';
      case GameAbility.randomShift:
        return 'Р’РµСЂС‚РёРєР°Р»СЊ ? СЃРґРІРёРіР°РµС‚СЃСЏ РЅР° 1 РєР»РµС‚РєСѓ';
      case GameAbility.randomCalm:
        return 'РќРёС‡РµРіРѕ РЅРµ РїСЂРѕРёСЃС…РѕРґРёС‚';
      case GameAbility.randomQuarantine:
        return 'РЎР»СѓС‡Р°Р№РЅР°СЏ СЃРІРѕР±РѕРґРЅР°СЏ РєР»РµС‚РєР° РЅРµРґРѕСЃС‚СѓРїРЅР° РЅР° 3вЂ“10 С…РѕРґРѕРІ';
      case GameAbility.randomEarthquake:
        return 'Р“РѕСЂРёР·РѕРЅС‚Р°Р»СЊ ? СЃРґРІРёРіР°РµС‚СЃСЏ РІР»РµРІРѕ РёР»Рё РІРїСЂР°РІРѕ РЅР° 1 РєР»РµС‚РєСѓ';
      case GameAbility.randomTyphoon:
        return 'РћР±Р»Р°СЃС‚СЊ 2Г—2 РїРѕРІРѕСЂР°С‡РёРІР°РµС‚СЃСЏ РїРѕ С‡Р°СЃРѕРІРѕР№ СЃС‚СЂРµР»РєРµ';
      case GameAbility.randomWormhole:
        return 'РЎР»СѓС‡Р°Р№РЅР°СЏ РїСѓСЃС‚Р°СЏ РєР»РµС‚РєР° РЅРµРґРѕСЃС‚СѓРїРЅР° РґРѕ РєРѕРЅС†Р° РїР°СЂС‚РёРё';
      case GameAbility.randomClone:
        return 'РќР° РІР°С€РµР№ РїРѕР»РѕРІРёРЅРµ РїРѕСЏРІР»СЏРµС‚СЃСЏ РµС‰С‘ РѕРґРЅР° РїРµС€РєР°';
      case GameAbility.randomNoQueen:
        return 'Р’СЂР°Р¶РµСЃРєРёР№ С„РµСЂР·СЊ РЅР° 2 СЃРІРѕРёС… С…РѕРґР° РїСЂРµРІСЂР°С‰Р°РµС‚СЃСЏ РІ РєРѕРЅСЏ';
      case GameAbility.randomTruce:
        return '3 С…РѕРґР° РЅРµР»СЊР·СЏ Р±СЂР°С‚СЊ С„РёРіСѓСЂС‹; С€Р°С… Рё РјР°С‚ РІСЂРµРјРµРЅРЅРѕ РЅРµ Р·Р°СЃС‡РёС‚С‹РІР°СЋС‚СЃСЏ';
      case GameAbility.randomMeteorRain:
        return 'РќР° 3 СЃР»СѓС‡Р°Р№РЅС‹Рµ РєР»РµС‚РєРё РїР°РґР°СЋС‚ РјРµС‚РµРѕСЂРёС‚С‹, СѓРЅРёС‡С‚РѕР¶Р°СЏ РІСЃРµ С„РёРіСѓСЂС‹, РєСЂРѕРјРµ РєРѕСЂРѕР»РµР№';
      case GameAbility.randomCensus:
        return 'РЈ СЃР»СѓС‡Р°Р№РЅРѕР№ РІСЂР°Р¶РµСЃРєРѕР№ С„РёРіСѓСЂС‹ СЃ РјРѕРґР°РјРё РёСЃС‡РµР·Р°РµС‚ РѕРґРЅР° СЃР»СѓС‡Р°Р№РЅР°СЏ РјРѕРґ';
      case GameAbility.randomExterminatus:
        return 'Р’ С‚РµС‡РµРЅРёРµ СЃР»РµРґСѓСЋС‰РµРіРѕ С…РѕРґР° Сѓ РѕР±РѕРёС… РёРіСЂРѕРєРѕРІ: С€Р°С… РІСЂР°Р¶РµСЃРєРѕРјСѓ РєРѕСЂРѕР»СЋ РјРіРЅРѕРІРµРЅРЅРѕ СѓР±РёРІР°РµС‚ РµРіРѕ';
      case GameAbility.randomGoldenThrone:
        return 'Р•СЃР»Рё РІР°С€Р° РїРµС€РєР° РїРѕРіРёР±Р°РµС‚, РІР°С€ РєРѕСЂРѕР»СЊ РІС‹Р±РёСЂР°РµС‚ СЃРµР±Рµ РјРѕРґ';
      case GameAbility.randomLottery:
        return 'Р”РІРµ РІР°С€Рё СЃР»СѓС‡Р°Р№РЅС‹Рµ С„РёРіСѓСЂС‹ РЅРµ-РєРѕСЂРѕР»Рё РјРµРЅСЏСЋС‚СЃСЏ С‚РёРїР°РјРё';
      case GameAbility.randomPlague:
        return 'РљР°Р¶РґС‹Р№ С…РѕРґ С„РёРіСѓСЂР° СЃ С€Р°РЅСЃРѕРј 1% Р·Р°Р±РѕР»РµРІР°РµС‚ С‡СѓРјРѕР№ Рё СѓРјСЂС‘С‚ С‡РµСЂРµР· 3 С…РѕРґР°; СЂСЏРґРѕРј СЃ Р±РѕР»СЊРЅРѕР№ С€Р°РЅСЃ 10%. РљРѕСЂРѕР»Рё С‚РѕР¶Рµ РјРѕРіСѓС‚ Р·Р°Р±РѕР»РµС‚СЊ';
      case GameAbility.randomMutation:
        return 'РЎР»СѓС‡Р°Р№РЅР°СЏ РІР°С€Р° РїРµС€РєР° СЃС‚Р°РЅРѕРІРёС‚СЃСЏ СЃР»СѓС‡Р°Р№РЅРѕР№ Р»С‘РіРєРѕР№ С„РёРіСѓСЂРѕР№ (РєРѕРЅСЊ РёР»Рё СЃР»РѕРЅ) С‚РѕРіРѕ Р¶Рµ С†РІРµС‚Р°';
      case GameAbility.randomAuction:
        return 'РЎР»СѓС‡Р°Р№РЅР°СЏ РєР»РµС‚РєР° СЃС‚Р°РЅРѕРІРёС‚СЃСЏ Р°СѓРєС†РёРѕРЅРЅРѕР№: РєС‚Рѕ РїРµСЂРІС‹Рј РЅР° РЅРµС‘ РІСЃС‚Р°РЅРµС‚, РїРѕР»СѓС‡РёС‚ 2 РјРѕРґР°';
      case GameAbility.randomRightToMove:
        return 'Р’С‹Р±РµСЂРёС‚Рµ РІСЂР°Р¶РµСЃРєСѓСЋ С„РёРіСѓСЂСѓ: РІ СЃР»РµРґСѓСЋС‰РёР№ С…РѕРґ СЃРѕРїРµСЂРЅРёРє РѕР±СЏР·Р°РЅ СЃС…РѕРґРёС‚СЊ РµР№, РµСЃР»Рё РјРѕР¶РµС‚';
      case GameAbility.randomFurtherMore:
        return 'РЎРµР№С‡Р°СЃ РЅРёС‡РµРіРѕ РЅРµ РїСЂРѕРёСЃС…РѕРґРёС‚; РїСЂРё СЃР»РµРґСѓСЋС‰РµРј РІС‹Р±РѕСЂРµ РІС‹ СЃРјРѕР¶РµС‚Рµ РѕРґРёРЅ СЂР°Р· РѕР±РЅРѕРІРёС‚СЊ РїСЂРµРґР»РѕР¶РµРЅРЅС‹Рµ РјРѕРґС‹';
      case GameAbility.randomWordOfHonor:
        return 'Р’С‹Р±РµСЂРёС‚Рµ РєР»РµС‚РєСѓ: РµСЃР»Рё РІ СЃР»РµРґСѓСЋС‰РёР№ СЃРІРѕР№ С…РѕРґ РІСЃС‚Р°РЅРµС‚Рµ РЅР° РЅРµС‘, РїРѕР»СѓС‡РёС‚Рµ РјРѕРґ, РёРЅР°С‡Рµ РїРѕС‚РµСЂСЏРµС‚Рµ РѕРґРЅСѓ СЃР»СѓС‡Р°Р№РЅСѓСЋ РјРѕРґ';
      case GameAbility.randomSymmetry:
        return 'РЎР»РµРґСѓСЋС‰РёРµ 3 С…РѕРґР° СЃРѕРїРµСЂРЅРёРє РѕР±СЏР·Р°РЅ С…РѕРґРёС‚СЊ С‚РµРјРё Р¶Рµ С‚РёРїР°РјРё С„РёРіСѓСЂ, РєРѕС‚РѕСЂС‹РјРё РїРµСЂРµРґ РЅРёРј С…РѕРґРёР»Рё РІС‹';
      case GameAbility.randomVeto:
        return 'Р’С‹Р±РµСЂРёС‚Рµ РІСЂР°Р¶РµСЃРєСѓСЋ С„РёРіСѓСЂСѓ: СЃР»РµРґСѓСЋС‰РёРµ 3 С…РѕРґР° СЃРѕРїРµСЂРЅРёРє РЅРµ РјРѕР¶РµС‚ С…РѕРґРёС‚СЊ РµСЋ';
      case GameAbility.randomInitiativeIntercept:
        return 'РРіСЂРѕРє СЃ Р±РѕР»РµРµ СЃР»Р°Р±РѕР№ Р°СЂРјРёРµР№ РїРѕР»СѓС‡Р°РµС‚ РґРѕРїРѕР»РЅРёС‚РµР»СЊРЅС‹Р№ С…РѕРґ Р±РµР· РІР·СЏС‚РёСЏ, С€Р°С…Р° Рё РјР°С‚Р°';
      case GameAbility.randomStrike:
        return 'РћР±Р° РёРіСЂРѕРєР° РЅРµ РјРѕРіСѓС‚ РґРІРёРіР°С‚СЊ С„РёРіСѓСЂС‹ СЃР»СѓС‡Р°Р№РЅРѕРіРѕ С‚РёРїР° РІ С‚РµС‡РµРЅРёРµ 3вЂ“10 С…РѕРґРѕРІ';
      case GameAbility.randomBorderClosure:
        return 'РЎР»РµРґСѓСЋС‰РёРµ 2 С…РѕРґР° С„РёРіСѓСЂС‹ РЅРµ РјРѕРіСѓС‚ РїРµСЂРµСЃРµРєР°С‚СЊ СЃРµСЂРµРґРёРЅСѓ РґРѕСЃРєРё';
      case GameAbility.randomMyopia:
        return 'РЎР»РѕРЅС‹, Р»Р°РґСЊРё Рё С„РµСЂР·Рё РІСЂРµРјРµРЅРЅРѕ РІРёРґСЏС‚ Рё С…РѕРґСЏС‚ РЅРµ РґР°Р»СЊС€Рµ 2 РєР»РµС‚РѕРє';
      case GameAbility.randomMagicShutdown:
        return 'РЎР»РµРґСѓСЋС‰РёРµ 3вЂ“10 С…РѕРґРѕРІ РІСЃРµ РјРѕРґС‹ РѕС‚РєР»СЋС‡РµРЅС‹';
      case GameAbility.randomTimeCapsule:
        return 'РџРѕР·РёС†РёСЏ СЃРѕС…СЂР°РЅСЏРµС‚СЃСЏ; РїРѕСЃР»Рµ РґРІСѓС… С…РѕРґРѕРІ РєР°Р¶РґРѕРіРѕ РёРіСЂРѕРєР° РґРѕСЃРєР° РІРѕР·РІСЂР°С‰Р°РµС‚СЃСЏ Рє РЅРµР№, РЅРѕ Р·Р°СЂР°Р±РѕС‚Р°РЅРЅС‹Рµ РјРѕРґС‹ СЃРѕС…СЂР°РЅСЏСЋС‚СЃСЏ';
      case GameAbility.randomSuicideCapture:
        return 'РЎР»РµРґСѓСЋС‰РµРµ РІР·СЏС‚РёРµ СѓРЅРёС‡С‚РѕР¶Р°РµС‚ Рё РІР·СЏС‚СѓСЋ С„РёРіСѓСЂСѓ, Рё С„РёРіСѓСЂСѓ, РєРѕС‚РѕСЂР°СЏ РµС‘ РІР·СЏР»Р°';
      case GameAbility.randomMeatGrinder:
        return 'РЎР»РµРґСѓСЋС‰РёР№ С…РѕРґ РѕР±РѕРёС… РёРіСЂРѕРєРѕРІ РґРѕР»Р¶РµРЅ Р±С‹С‚СЊ РІР·СЏС‚РёРµРј, РµСЃР»Рё РІР·СЏС‚РёРµ РІРѕР·РјРѕР¶РЅРѕ';
      case GameAbility.randomQuicksand:
        return '2вЂ“5 СЃРєСЂС‹С‚С‹С… РєР»РµС‚РѕРє вЂ” Р·С‹Р±СѓС‡РёРµ РїРµСЃРєРё. Р’СЃС‚Р°РІС€Р°СЏ С„РёРіСѓСЂР° РЅРµ С…РѕРґРёС‚ 2вЂ“5 С…РѕРґРѕРІ; РєР»РµС‚РєР° СЂР°СЃРєСЂС‹РІР°РµС‚СЃСЏ РЅР°РІСЃРµРіРґР°';
    }
  }

  PieceType? get primaryPieceType {
    switch (this) {
      case GameAbility.boardPawnsSideways:
      case GameAbility.boardPawnsDiagonal:
      case GameAbility.boardPawnsBackward:
      case GameAbility.boardTide:
      case GameAbility.boardDoubleStart:
      case GameAbility.boardPawnFront:
      case GameAbility.boardCavalry:
      case GameAbility.pawnSideways:
      case GameAbility.pawnInverted:
      case GameAbility.pawnAlwaysDoubleStep:
      case GameAbility.pawnRam:
      case GameAbility.pawnAirborne:
      case GameAbility.pawnBoomerang:
      case GameAbility.pawnKamikaze:
      case GameAbility.pawnCaliph:
      case GameAbility.pawnSticky:
      case GameAbility.pawnPolymorph:
      case GameAbility.pawnInheritance:
      case GameAbility.pawnRansom:
      case GameAbility.pawnForTheKing:
      case GameAbility.pawnCamouflageNet:
      case GameAbility.pawnTrench:
      case GameAbility.pawnSignalFire:
      case GameAbility.pawnAvengeMe:
      case GameAbility.pawnCaravan:
      case GameAbility.pawnFaceControl:
      case GameAbility.randomClone:
        return PieceType.pawn;
      case GameAbility.boardKingSwap:
      case GameAbility.kingRoyalDecree:
      case GameAbility.kingExtraStep:
      case GameAbility.kingShield:
      case GameAbility.kingAura:
      case GameAbility.kingDoppelganger:
      case GameAbility.kingThrone:
      case GameAbility.kingFamilyUnion:
      case GameAbility.kingPrisonerExchange:
      case GameAbility.kingRemoveEnemyMod:
      case GameAbility.kingAssemblyHall:
        return PieceType.king;
      case GameAbility.boardZebras:
      case GameAbility.knightRearing:
      case GameAbility.knightLongJump:
      case GameAbility.knightSecondChance:
      case GameAbility.knightBoomerang:
      case GameAbility.knightGallop:
      case GameAbility.knightDust:
      case GameAbility.knightCentaur:
      case GameAbility.knightTrojan:
      case GameAbility.knightDuel:
      case GameAbility.knightGuard:
      case GameAbility.knightTour:
      case GameAbility.knightDoppelgangerOnce:
      case GameAbility.knightDoppelgangers:
      case GameAbility.knightFifthLeg:
      case GameAbility.knightElusive:
      case GameAbility.knightStomp:
      case GameAbility.knightSurveyor:
      case GameAbility.knightCornerQuest:
      case GameAbility.knightRideMe:
      case GameAbility.knightMagicHooves:
      case GameAbility.knightSignalFire:
        return PieceType.knight;
      case GameAbility.bishopHopAlly:
      case GameAbility.bishopColorChaos:
      case GameAbility.bishopBoomerang:
      case GameAbility.bishopInquisitor:
      case GameAbility.bishopColorVow:
      case GameAbility.bishopBrothers:
      case GameAbility.bishopSanctuary:
      case GameAbility.bishopExcommunication:
      case GameAbility.bishopTithe:
      case GameAbility.bishopPilgrimage:
      case GameAbility.bishopCrusade:
      case GameAbility.bishopPost:
      case GameAbility.bishopParallelWorlds:
      case GameAbility.bishopAlcove:
      case GameAbility.bishopGlassCeiling:
      case GameAbility.bishopElusive:
      case GameAbility.bishopSignalFire:
        return PieceType.bishop;
      case GameAbility.rookHopAlly:
      case GameAbility.rookRam:
      case GameAbility.rookAstronomicon:
      case GameAbility.rookFortress:
      case GameAbility.rookStandardBearer:
      case GameAbility.rookCustoms:
      case GameAbility.rookDrawbridge:
      case GameAbility.rookCurfew:
      case GameAbility.rookSiegeCalculation:
      case GameAbility.rookFerry:
      case GameAbility.rookSignalTower:
      case GameAbility.rookSignalFire:
        return PieceType.rook;
      case GameAbility.queenKnightStep:
      case GameAbility.queenHopAlly:
      case GameAbility.queenSplit:
      case GameAbility.queenMatka:
      case GameAbility.queenShadowEmpress:
      case GameAbility.queenEscape:
      case GameAbility.queenDelayedSentence:
      case GameAbility.queenTrophyEmbargo:
      case GameAbility.queenYouShallNotPass:
        return PieceType.queen;
      case GameAbility.boardLavaRank:
      case GameAbility.boardExtraRank:
      case GameAbility.boardExtraFile:
      case GameAbility.boardFogOfWar:
      case GameAbility.boardSprint:
      case GameAbility.boardFisher:
      case GameAbility.boardFisherMadness:
      case GameAbility.boardNight:
      case GameAbility.boardDay:
      case GameAbility.boardColorblind:
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
      case GameAbility.boardTroopFatigue:
      case GameAbility.boardCombatOptics:
      case GameAbility.boardKingOfHill:
      case GameAbility.boardSecretRoute:
      case GameAbility.boardRoyalPilgrimage:
      case GameAbility.boardMightMakesRight:
      case GameAbility.boardExpeditionaryCorps:
      case GameAbility.boardWitnessProtection:
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
      case GameAbility.randomShift:
      case GameAbility.randomCalm:
      case GameAbility.randomQuarantine:
      case GameAbility.randomEarthquake:
      case GameAbility.randomTyphoon:
      case GameAbility.randomWormhole:
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
      case GameAbility.randomRightToMove:
      case GameAbility.randomFurtherMore:
      case GameAbility.randomWordOfHonor:
      case GameAbility.randomSymmetry:
      case GameAbility.randomVeto:
      case GameAbility.randomInitiativeIntercept:
      case GameAbility.randomStrike:
      case GameAbility.randomBorderClosure:
      case GameAbility.randomMyopia:
      case GameAbility.randomMagicShutdown:
      case GameAbility.randomTimeCapsule:
      case GameAbility.randomSuicideCapture:
      case GameAbility.randomMeatGrinder:
      case GameAbility.randomQuicksand:
        return null;
    }
  }

  bool get isBoardWide =>
      this == GameAbility.boardLavaRank ||
      this == GameAbility.boardExtraRank ||
      this == GameAbility.boardExtraFile ||
      this == GameAbility.boardFogOfWar ||
      this == GameAbility.boardTide ||
      this == GameAbility.boardSprint ||
      this == GameAbility.boardZebras ||
      this == GameAbility.boardFisher ||
      this == GameAbility.boardFisherMadness ||
      this == GameAbility.boardNight ||
      this == GameAbility.boardDay ||
      this == GameAbility.boardColorblind ||
      this == GameAbility.boardPawnFront ||
      this == GameAbility.boardCavalry ||
      this == GameAbility.boardMirror ||
      this == GameAbility.boardGhostCells ||
      this == GameAbility.boardAttraction ||
      this == GameAbility.boardVirus ||
      this == GameAbility.boardInvisibleRegiment ||
      this == GameAbility.boardShuffle ||
      this == GameAbility.boardTeleport ||
      this == GameAbility.boardVanityFair ||
      this == GameAbility.boardMinefield ||
      this == GameAbility.boardGolconda ||
      this == GameAbility.boardUnbridledHorse ||
      this == GameAbility.boardBaskerville ||
      this == GameAbility.boardBloodOath ||
      this == GameAbility.boardSilentFile ||
      this == GameAbility.boardFourHorsemen ||
      this == GameAbility.boardReroll ||
      this == GameAbility.boardPassiveAggression ||
      this == GameAbility.boardSkipTurn ||
      this == GameAbility.boardTroopFatigue ||
      this == GameAbility.boardCombatOptics ||
      this == GameAbility.boardKingOfHill ||
      this == GameAbility.boardSecretRoute ||
      this == GameAbility.boardRoyalPilgrimage ||
      this == GameAbility.boardMightMakesRight ||
      this == GameAbility.boardExpeditionaryCorps ||
      this == GameAbility.boardWitnessProtection ||
      this == GameAbility.boardDeserters ||
      this == GameAbility.boardLetterH ||
      this == GameAbility.boardFullCircle ||
      this == GameAbility.boardArchitect ||
      this == GameAbility.boardBigAssortment ||
      this == GameAbility.boardBlindSpot ||
      this == GameAbility.boardOnlyEqualsKill ||
      this == GameAbility.boardMarseillesChess ||
      this == GameAbility.boardInitiativeFear ||
      this == GameAbility.boardSwamp ||
      this == GameAbility.boardCollectiveMyopia ||
      this == GameAbility.boardTerritoryExpand ||
      this == GameAbility.boardFrostMap ||
      this == GameAbility.boardScorchingSun ||
      this == GameAbility.boardTurncoats ||
      this == GameAbility.randomShift ||
      this == GameAbility.randomCalm ||
      this == GameAbility.randomQuarantine ||
      this == GameAbility.randomEarthquake ||
      this == GameAbility.randomTyphoon ||
      this == GameAbility.randomWormhole ||
      this == GameAbility.randomClone ||
      this == GameAbility.randomNoQueen ||
      this == GameAbility.randomTruce ||
      this == GameAbility.randomMeteorRain ||
      this == GameAbility.randomCensus ||
      this == GameAbility.randomExterminatus ||
      this == GameAbility.randomGoldenThrone ||
      this == GameAbility.randomLottery ||
      this == GameAbility.randomPlague ||
      this == GameAbility.randomMutation ||
      this == GameAbility.randomAuction ||
      group == AbilityGroup.random;

  String descriptionFor({
    PieceColor? forColor,
    int? boardRankCount,
    int? lavaRank,
    int? shiftFile,
    int? shiftDirection,
    bool? extraFileOnLeft,
    int? boardFileCount,
    ExtraFilePlacement boardExtraFile = ExtraFilePlacement.none,
    Square? quarantineSquare,
    int? quarantineMoves,
    int? quakeRank,
    int? quakeDirection,
    Square? typhoonOrigin,
    Square? wormholeSquare,
    Square? cloneSquare,
    int? ghostCellCount,
    int? mineCount,
    Square? teleportA,
    Square? teleportB,
    bool? landOnLight,
    int? silentFile,
    Square? auctionSquare,
    AbilityAxis? axis,
    PieceType? affectedPieceType,
    int? durationMoves,
  }) {
    if (this == GameAbility.rookCustoms && axis != null) {
      final axisName = axis == AbilityAxis.rank ? 'РіРѕСЂРёР·РѕРЅС‚Р°Р»СЊ' : 'РІРµСЂС‚РёРєР°Р»СЊ';
      return 'РЎР»РµРґСѓСЋС‰РёРµ 3 С…РѕРґР° РІСЂР°РіРё РЅРµ РјРѕРіСѓС‚ РІСЃС‚Р°РІР°С‚СЊ РЅР° $axisName Р»Р°РґСЊРё, '
          'РµСЃР»Рё СѓР¶Рµ РЅРµ РЅР°С…РѕРґСЏС‚СЃСЏ РЅР° РЅРµР№';
    }
    if (this == GameAbility.randomStrike &&
        affectedPieceType != null &&
        durationMoves != null) {
      return 'РћР±Р° РёРіСЂРѕРєР° РЅРµ РјРѕРіСѓС‚ РґРІРёРіР°С‚СЊ ${_pieceTypeGenitivePlural(affectedPieceType)} '
          'СЃР»РµРґСѓСЋС‰РёРµ $durationMoves ${_movesWord(durationMoves)}';
    }
    if (this == GameAbility.randomMagicShutdown && durationMoves != null) {
      return 'Р’СЃРµ РјРѕРґС‹ РѕС‚РєР»СЋС‡РµРЅС‹ РЅР° $durationMoves '
          '${_movesWord(durationMoves)}';
    }
    if (this == GameAbility.boardTide && forColor != null) {
      final ranks = boardRankCount ?? 8;
      final rankLabel = forColor == PieceColor.white ? 3 : ranks - 2;
      return 'Р’Р°С€Рё РїРµС€РєРё СЃС‚РѕСЏС‚ РЅР° $rankLabel-Р№ РіРѕСЂРёР·РѕРЅС‚Р°Р»Рё '
          'Рё С…РѕРґСЏС‚ С‚РѕР»СЊРєРѕ РЅР° 1 РєР»РµС‚РєСѓ РІРїРµСЂС‘Рґ';
    }
    if (this == GameAbility.boardLavaRank && lavaRank != null) {
      return 'Р“РѕСЂРёР·РѕРЅС‚Р°Р»СЊ ${lavaRank + 1} РїРѕРєСЂС‹РІР°РµС‚СЃСЏ Р»Р°РІРѕР№. '
          'Р¤РёРіСѓСЂР° РјРѕР¶РµС‚ РїСЂРѕСЃС‚РѕСЏС‚СЊ РЅР° РЅРµР№ РЅРµ Р±РѕР»РµРµ 3 С…РѕРґРѕРІ';
    }
    if (this == GameAbility.randomShift &&
        shiftFile != null &&
        shiftDirection != null) {
      final towardHigherRanks = shiftDirection > 0;
      final String dir;
      if (forColor == PieceColor.black) {
        dir = towardHigherRanks ? 'РЅР°Р·Р°Рґ' : 'РІРїРµСЂС‘Рґ';
      } else {
        dir = towardHigherRanks ? 'РІРїРµСЂС‘Рґ' : 'РЅР°Р·Р°Рґ';
      }
      return 'Р’СЃРµ С„РёРіСѓСЂС‹ РЅР° РІРµСЂС‚РёРєР°Р»Рё '
          '${fileLabel(shiftFile, fileCount: boardFileCount ?? 8, extraFile: boardExtraFile).toUpperCase()} '
          'СЃРґРІРёРіР°СЋС‚СЃСЏ РЅР° 1 РєР»РµС‚РєСѓ $dir';
    }
    if (this == GameAbility.boardExtraFile && extraFileOnLeft != null) {
      if (extraFileOnLeft) {
        return 'РЎР»РµРІР° РїРѕСЏРІР»СЏРµС‚СЃСЏ РЅРѕРІР°СЏ РІРµСЂС‚РёРєР°Р»СЊ z';
      }
      return 'РЎРїСЂР°РІР° РїРѕСЏРІР»СЏРµС‚СЃСЏ РЅРѕРІР°СЏ РІРµСЂС‚РёРєР°Р»СЊ i';
    }
    if (this == GameAbility.boardGhostCells && ghostCellCount != null) {
      final word = (ghostCellCount >= 2 && ghostCellCount <= 4)
          ? 'РєР»РµС‚РєРё'
          : 'РєР»РµС‚РѕРє';
      return '$ghostCellCount $word СЃС‚Р°РЅРѕРІСЏС‚СЃСЏ РїСЂРёР·СЂР°С‡РЅС‹РјРё: '
          'С‡РµСЂРµР· РЅРёС… РјРѕР¶РЅРѕ С…РѕРґРёС‚СЊ, РЅРѕ СЃС‚РѕСЏС‚СЊ РЅРµР»СЊР·СЏ';
    }
    if (this == GameAbility.boardMinefield && mineCount != null) {
      if (mineCount == 1) {
        return 'РќР° 1 СЃРІРѕР±РѕРґРЅСѓСЋ РєР»РµС‚РєСѓ СЃС‚Р°РІРёС‚СЃСЏ РЅРµРІРёРґРёРјР°СЏ РјРёРЅР°: '
            'СЃР»РµРґСѓСЋС‰Р°СЏ С„РёРіСѓСЂР° РЅР° РЅРµР№ СѓРЅРёС‡С‚РѕР¶Р°РµС‚СЃСЏ';
      }
      return 'РќР° $mineCount СЃРІРѕР±РѕРґРЅС‹Рµ РєР»РµС‚РєРё СЃС‚Р°РІСЏС‚СЃСЏ РЅРµРІРёРґРёРјС‹Рµ РјРёРЅС‹: '
          'СЃР»РµРґСѓСЋС‰Р°СЏ С„РёРіСѓСЂР° РЅР° РјРёРЅРµ СѓРЅРёС‡С‚РѕР¶Р°РµС‚СЃСЏ';
    }
    if (this == GameAbility.boardTeleport &&
        teleportA != null &&
        teleportB != null) {
      final a = squareLabel(
        teleportA,
        fileCount: boardFileCount ?? 8,
        extraFile: boardExtraFile,
      );
      final b = squareLabel(
        teleportB,
        fileCount: boardFileCount ?? 8,
        extraFile: boardExtraFile,
      );
      return 'РљР»РµС‚РєРё $a Рё $b СЃРІСЏР·Р°РЅС‹: РІС…РѕРґ РЅР° РѕРґРЅСѓ = РІС‹С…РѕРґ РЅР° РґСЂСѓРіСѓСЋ';
    }
    if (this == GameAbility.randomQuarantine && quarantineSquare != null) {
      final moves = quarantineMoves ?? 5;
      final movesWord = (moves == 3 || moves == 4) ? 'С…РѕРґР°' : 'С…РѕРґРѕРІ';
      return 'РљР»РµС‚РєР° '
          '${squareLabel(quarantineSquare, fileCount: boardFileCount ?? 8, extraFile: boardExtraFile)} '
          'РЅРµРґРѕСЃС‚СѓРїРЅР° СЃР»РµРґСѓСЋС‰РёРµ $moves $movesWord';
    }
    if (this == GameAbility.randomEarthquake &&
        quakeRank != null &&
        quakeDirection != null) {
      final dir = quakeDirection > 0 ? 'РІРїСЂР°РІРѕ' : 'РІР»РµРІРѕ';
      return 'Р“РѕСЂРёР·РѕРЅС‚Р°Р»СЊ ${quakeRank + 1} СЃРґРІРёРіР°РµС‚СЃСЏ РЅР° 1 РєР»РµС‚РєСѓ $dir';
    }
    if (this == GameAbility.randomTyphoon && typhoonOrigin != null) {
      final a = squareLabel(
        typhoonOrigin,
        fileCount: boardFileCount ?? 8,
        extraFile: boardExtraFile,
      );
      final b = squareLabel(
        Square(typhoonOrigin.file + 1, typhoonOrigin.rank + 1),
        fileCount: boardFileCount ?? 8,
        extraFile: boardExtraFile,
      );
      return 'РћР±Р»Р°СЃС‚СЊ $aвЂ“$b РїРѕРІРѕСЂР°С‡РёРІР°РµС‚СЃСЏ РїРѕ С‡Р°СЃРѕРІРѕР№ СЃС‚СЂРµР»РєРµ';
    }
    if (this == GameAbility.randomWormhole && wormholeSquare != null) {
      return 'РљР»РµС‚РєР° '
          '${squareLabel(wormholeSquare, fileCount: boardFileCount ?? 8, extraFile: boardExtraFile)} '
          'РЅРµРґРѕСЃС‚СѓРїРЅР° РґРѕ РєРѕРЅС†Р° РїР°СЂС‚РёРё';
    }
    if (this == GameAbility.randomClone && cloneSquare != null) {
      return 'РџРµС€РєР° РїРѕСЏРІР»СЏРµС‚СЃСЏ РЅР° '
          '${squareLabel(cloneSquare, fileCount: boardFileCount ?? 8, extraFile: boardExtraFile)}';
    }
    if (this == GameAbility.queenShadowEmpress && landOnLight != null) {
      return landOnLight
          ? 'Р¤РµСЂР·СЊ С…РѕРґРёС‚ РµС‰С‘ РєР°Рє РєРѕРЅСЊ, РЅРѕ РјРѕР¶РµС‚ РІСЃС‚Р°РІР°С‚СЊ С‚РѕР»СЊРєРѕ РЅР° СЃРІРµС‚Р»С‹Рµ РєР»РµС‚РєРё'
          : 'Р¤РµСЂР·СЊ С…РѕРґРёС‚ РµС‰С‘ РєР°Рє РєРѕРЅСЊ, РЅРѕ РјРѕР¶РµС‚ РІСЃС‚Р°РІР°С‚СЊ С‚РѕР»СЊРєРѕ РЅР° С‚С‘РјРЅС‹Рµ РєР»РµС‚РєРё';
    }
    if (this == GameAbility.boardSilentFile && silentFile != null) {
      return 'Р’РµСЂС‚РёРєР°Р»СЊ '
          '${fileLabel(silentFile, fileCount: boardFileCount ?? 8, extraFile: boardExtraFile).toUpperCase()} '
          'РЅРµРјР°СЏ: С„РёРіСѓСЂС‹ РЅР° РЅРµР№ РЅРµ РјРѕРіСѓС‚ РґР°С‚СЊ С€Р°С… РёР»Рё РјР°С‚';
    }
    if (this == GameAbility.randomAuction && auctionSquare != null) {
      return 'РљР»РµС‚РєР° '
          '${squareLabel(auctionSquare, fileCount: boardFileCount ?? 8, extraFile: boardExtraFile)} '
          'вЂ” Р°СѓРєС†РёРѕРЅ: РєС‚Рѕ РїРµСЂРІС‹Рј РІСЃС‚Р°РЅРµС‚, РїРѕР»СѓС‡РёС‚ РјРѕРґ';
    }
    return description;
  }
}

String _movesWord(int moves) {
  final lastTwo = moves % 100;
  if (lastTwo >= 11 && lastTwo <= 14) return 'С…РѕРґРѕРІ';
  switch (moves % 10) {
    case 1:
      return 'С…РѕРґ';
    case 2:
    case 3:
    case 4:
      return 'С…РѕРґР°';
    default:
      return 'С…РѕРґРѕРІ';
  }
}

String _pieceTypeGenitivePlural(PieceType type) {
  switch (type) {
    case PieceType.pawn:
      return 'РїРµС€РµРє';
    case PieceType.knight:
      return 'РєРѕРЅРµР№';
    case PieceType.bishop:
      return 'СЃР»РѕРЅРѕРІ';
    case PieceType.rook:
      return 'Р»Р°РґРµР№';
    case PieceType.queen:
      return 'С„РµСЂР·РµР№';
    case PieceType.king:
      return 'РєРѕСЂРѕР»РµР№';
  }
}

String gameAbilityToJson(GameAbility ability) => ability.name;

GameAbility gameAbilityFromJson(String value) {
  return GameAbility.values.firstWhere((a) => a.name == value);
}

enum AbilityApplyMode {
  capturingPiece,
  selectFriendlyPiece,
  allPiecesOfType,
  playerKing,
  boardWide,
}

enum AbilityAxis { rank, file }

enum AbilityTargetSelection {
  none,
  cell,
  friendlyPiece,
  enemyPiece,
  enemyAbility,
  capturedFriendlyPiece,
  secretFriendlyPiece,
  route,
}

class AbilityOffer {
  const AbilityOffer({
    required this.ability,
    required this.applyMode,
    this.isWildcard = false,
    this.lavaRank,
    this.shiftFile,
    this.shiftDirection,
    this.extraFileOnLeft,
    this.boardFileCount,
    this.boardRankCount,
    this.boardExtraFile = ExtraFilePlacement.none,
    this.quarantineSquare,
    this.quarantineMoves,
    this.quakeRank,
    this.quakeDirection,
    this.typhoonOrigin,
    this.wormholeSquare,
    this.cloneSquare,
    this.ghostCellCount,
    this.mineCount,
    this.teleportA,
    this.teleportB,
    this.landOnLight,
    this.silentFile,
    this.auctionSquare,
    this.axis,
    this.affectedPieceType,
    this.durationMoves,
    this.targetSelection = AbilityTargetSelection.none,
    this.targetCell,
    this.route = const [],
    this.hiddenData = const {},
    this.forColor,
    this.rngSeed,
  });

  final GameAbility ability;
  final AbilityApplyMode applyMode;
  final bool isWildcard;
  final int? lavaRank;
  final int? shiftFile;
  final int? shiftDirection;
  final bool? extraFileOnLeft;
  final int? boardFileCount;
  final int? boardRankCount;
  final ExtraFilePlacement boardExtraFile;
  final Square? quarantineSquare;
  final int? quarantineMoves;
  final int? quakeRank;
  final int? quakeDirection;
  final Square? typhoonOrigin;
  final Square? wormholeSquare;
  final Square? cloneSquare;
  final int? ghostCellCount;
  final int? mineCount;
  final Square? teleportA;
  final Square? teleportB;
  final bool? landOnLight;
  final int? silentFile;
  final Square? auctionSquare;
  final AbilityAxis? axis;
  final PieceType? affectedPieceType;
  final int? durationMoves;
  final AbilityTargetSelection targetSelection;
  final Square? targetCell;
  final List<Square> route;
  final Map<String, dynamic> hiddenData;

  /// Р¦РІРµС‚ РёРіСЂРѕРєР°, РєРѕС‚РѕСЂРѕРјСѓ РїСЂРµРґР»Р°РіР°СЋС‚ / РєРѕС‚РѕСЂС‹Р№ РІС‹Р±РёСЂР°РµС‚ РјРѕРґ.
  final PieceColor? forColor;

  /// Seed РґР»СЏ РґРµС‚РµСЂРјРёРЅРёСЂРѕРІР°РЅРЅРѕРіРѕ RNG РїСЂРё РїСЂРёРјРµРЅРµРЅРёРё (РѕРЅР»Р°Р№РЅ-СЃРёРЅС…СЂРѕРЅРёР·Р°С†РёСЏ).
  final int? rngSeed;

  AbilityOffer withChooser(PieceColor color, {int? rankCount}) {
    return AbilityOffer(
      ability: ability,
      applyMode: applyMode,
      isWildcard: isWildcard,
      lavaRank: lavaRank,
      shiftFile: shiftFile,
      shiftDirection: shiftDirection,
      extraFileOnLeft: extraFileOnLeft,
      boardFileCount: boardFileCount,
      boardRankCount: rankCount ?? boardRankCount,
      boardExtraFile: boardExtraFile,
      quarantineSquare: quarantineSquare,
      quarantineMoves: quarantineMoves,
      quakeRank: quakeRank,
      quakeDirection: quakeDirection,
      typhoonOrigin: typhoonOrigin,
      wormholeSquare: wormholeSquare,
      cloneSquare: cloneSquare,
      ghostCellCount: ghostCellCount,
      mineCount: mineCount,
      teleportA: teleportA,
      teleportB: teleportB,
      landOnLight: landOnLight,
      silentFile: silentFile,
      auctionSquare: auctionSquare,
      axis: axis,
      affectedPieceType: affectedPieceType,
      durationMoves: durationMoves,
      targetSelection: targetSelection,
      targetCell: targetCell,
      route: route,
      hiddenData: hiddenData,
      forColor: color,
      rngSeed: rngSeed,
    );
  }

  String get displayDescription => ability.descriptionFor(
    forColor: forColor,
    boardRankCount: boardRankCount,
    lavaRank: lavaRank,
    shiftFile: shiftFile,
    shiftDirection: shiftDirection,
    extraFileOnLeft: extraFileOnLeft,
    boardFileCount: boardFileCount,
    boardExtraFile: boardExtraFile,
    quarantineSquare: quarantineSquare,
    quarantineMoves: quarantineMoves,
    quakeRank: quakeRank,
    quakeDirection: quakeDirection,
    typhoonOrigin: typhoonOrigin,
    wormholeSquare: wormholeSquare,
    cloneSquare: cloneSquare,
    ghostCellCount: ghostCellCount,
    mineCount: mineCount,
    teleportA: teleportA,
    teleportB: teleportB,
    landOnLight: landOnLight,
    silentFile: silentFile,
    auctionSquare: auctionSquare,
    axis: axis,
    affectedPieceType: affectedPieceType,
    durationMoves: durationMoves,
  );

  Map<String, dynamic> toJson() => {
    'ability': ability.name,
    'applyMode': applyMode.name,
    'isWildcard': isWildcard,
    'lavaRank': lavaRank,
    'shiftFile': shiftFile,
    'shiftDirection': shiftDirection,
    'extraFileOnLeft': extraFileOnLeft,
    'boardFileCount': boardFileCount,
    'boardRankCount': boardRankCount,
    'boardExtraFile': boardExtraFile.name,
    'quarantineSquare': _squareToJson(quarantineSquare),
    'quarantineMoves': quarantineMoves,
    'quakeRank': quakeRank,
    'quakeDirection': quakeDirection,
    'typhoonOrigin': _squareToJson(typhoonOrigin),
    'wormholeSquare': _squareToJson(wormholeSquare),
    'cloneSquare': _squareToJson(cloneSquare),
    'ghostCellCount': ghostCellCount,
    'mineCount': mineCount,
    'teleportA': _squareToJson(teleportA),
    'teleportB': _squareToJson(teleportB),
    'landOnLight': landOnLight,
    'silentFile': silentFile,
    'auctionSquare': _squareToJson(auctionSquare),
    'axis': axis?.name,
    'affectedPieceType': affectedPieceType?.name,
    'durationMoves': durationMoves,
    'targetSelection': targetSelection.name,
    'targetCell': _squareToJson(targetCell),
    'route': route.map(_squareToJson).toList(),
    'hiddenData': hiddenData,
    'forColor': forColor?.name,
    'rngSeed': rngSeed,
  };

  factory AbilityOffer.fromJson(Map<String, dynamic> json) {
    T? enumValue<T extends Enum>(List<T> values, Object? name) {
      if (name == null) return null;
      for (final value in values) {
        if (value.name == name) return value;
      }
      return null;
    }

    return AbilityOffer(
      ability: gameAbilityFromJson(json['ability'] as String),
      applyMode:
          enumValue(AbilityApplyMode.values, json['applyMode']) ??
          AbilityApplyMode.capturingPiece,
      isWildcard: json['isWildcard'] as bool? ?? false,
      lavaRank: json['lavaRank'] as int?,
      shiftFile: json['shiftFile'] as int?,
      shiftDirection: json['shiftDirection'] as int?,
      extraFileOnLeft: json['extraFileOnLeft'] as bool?,
      boardFileCount: json['boardFileCount'] as int?,
      boardRankCount: json['boardRankCount'] as int?,
      boardExtraFile:
          enumValue(ExtraFilePlacement.values, json['boardExtraFile']) ??
          ExtraFilePlacement.none,
      quarantineSquare: _squareFromJson(json['quarantineSquare']),
      quarantineMoves: json['quarantineMoves'] as int?,
      quakeRank: json['quakeRank'] as int?,
      quakeDirection: json['quakeDirection'] as int?,
      typhoonOrigin: _squareFromJson(json['typhoonOrigin']),
      wormholeSquare: _squareFromJson(json['wormholeSquare']),
      cloneSquare: _squareFromJson(json['cloneSquare']),
      ghostCellCount: json['ghostCellCount'] as int?,
      mineCount: json['mineCount'] as int?,
      teleportA: _squareFromJson(json['teleportA']),
      teleportB: _squareFromJson(json['teleportB']),
      landOnLight: json['landOnLight'] as bool?,
      silentFile: json['silentFile'] as int?,
      auctionSquare: _squareFromJson(json['auctionSquare']),
      axis: enumValue(AbilityAxis.values, json['axis']),
      affectedPieceType: enumValue(PieceType.values, json['affectedPieceType']),
      durationMoves: json['durationMoves'] as int?,
      targetSelection:
          enumValue(AbilityTargetSelection.values, json['targetSelection']) ??
          AbilityTargetSelection.none,
      targetCell: _squareFromJson(json['targetCell']),
      route:
          (json['route'] as List<dynamic>?)
              ?.map(_squareFromJson)
              .whereType<Square>()
              .toList() ??
          const [],
      hiddenData: Map<String, dynamic>.from(
        json['hiddenData'] as Map? ?? const {},
      ),
      forColor: enumValue(PieceColor.values, json['forColor']),
      rngSeed: json['rngSeed'] as int?,
    );
  }
}

Map<String, int>? _squareToJson(Square? square) =>
    square == null ? null : {'file': square.file, 'rank': square.rank};

Square? _squareFromJson(Object? value) {
  if (value is! Map) return null;
  final file = value['file'];
  final rank = value['rank'];
  if (file is! int || rank is! int) return null;
  return Square(file, rank);
}

/// РњРѕРґ СЃ РЅР°Р·РІР°РЅРёРµРј Рё С‚РµРєСЃС‚РѕРј РґР»СЏ СЌРєСЂР°РЅР° Р°РєС‚РёРІРЅС‹С… РјРѕРґРѕРІ.
class ChosenAbilityInfo {
  const ChosenAbilityInfo({
    required this.ability,
    required this.title,
    required this.description,
  });

  final GameAbility ability;
  final String title;
  final String description;
}

/// РЎРЅРёРјРѕРє СЃС‚Р°СЂС‚РѕРІС‹С… РјРѕРґРѕРІ РґРѕСЃРєРё Рё РІС‹Р±СЂР°РЅРЅС‹С… РїРѕ С…РѕРґСѓ РјРѕРґРѕРІ.
class ActiveAbilitiesSnapshot {
  const ActiveAbilitiesSnapshot({
    this.whiteStart,
    this.blackStart,
    this.whiteChosen = const [],
    this.blackChosen = const [],
  });

  final ChosenAbilityInfo? whiteStart;
  final ChosenAbilityInfo? blackStart;
  final List<ChosenAbilityInfo> whiteChosen;
  final List<ChosenAbilityInfo> blackChosen;
}
