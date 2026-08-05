import '../chess/board_labels.dart';
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
      case GameAbility.boardTide:
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
      case GameAbility.boardMarseillesChess:
      case GameAbility.boardInitiativeFear:
        return AbilityGroup.board;
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
        return AbilityGroup.random;
    }
  }

  String get title {
    switch (this) {
      case GameAbility.boardPawnsSideways:
        return 'На распутье';
      case GameAbility.boardPawnsDiagonal:
        return 'Партизаны';
      case GameAbility.boardPawnsBackward:
        return 'Шагу назад';
      case GameAbility.boardKingSwap:
        return 'Королевский указ';
      case GameAbility.boardLavaRank:
        return 'Пол — это лава';
      case GameAbility.boardExtraRank:
        return 'Новый этаж';
      case GameAbility.boardExtraFile:
        return 'Новая вертикаль';
      case GameAbility.boardFogOfWar:
        return 'Туман войны';
      case GameAbility.boardTide:
        return 'Прилив';
      case GameAbility.boardDoubleStart:
        return 'Двойной старт';
      case GameAbility.boardSprint:
        return 'Спринт';
      case GameAbility.boardZebras:
        return 'Зебры';
      case GameAbility.boardFisher:
        return 'Шахматы Фишера';
      case GameAbility.boardFisherMadness:
        return 'Безумие Фишера';
      case GameAbility.boardNight:
        return 'Во тьме ночной';
      case GameAbility.boardDay:
        return 'При свете дня';
      case GameAbility.boardColorblind:
        return 'Дальтоник';
      case GameAbility.boardPawnFront:
        return 'Пешечный фронт';
      case GameAbility.boardCavalry:
        return 'По коням';
      case GameAbility.boardMirror:
        return 'Зеркало';
      case GameAbility.boardGhostCells:
        return 'Призрачные клетки';
      case GameAbility.boardAttraction:
        return 'Притяжение';
      case GameAbility.boardVirus:
        return 'Шахматный вирус';
      case GameAbility.boardInvisibleRegiment:
        return 'Невидимый полк';
      case GameAbility.boardShuffle:
        return 'Перетасовка';
      case GameAbility.boardTeleport:
        return 'Телепорт';
      case GameAbility.boardVanityFair:
        return 'Ярмарка тщеславия';
      case GameAbility.boardMinefield:
        return 'Минное поле';
      case GameAbility.boardGolconda:
        return 'Голконда';
      case GameAbility.boardUnbridledHorse:
        return 'Скакун без узды';
      case GameAbility.boardBaskerville:
        return 'Эффект Баскервилей';
      case GameAbility.boardBloodOath:
        return 'Клятва крови';
      case GameAbility.boardSilentFile:
        return 'Немая вертикаль';
      case GameAbility.boardFourHorsemen:
        return '4 всадника';
      case GameAbility.boardReroll:
        return 'Перевыбор';
      case GameAbility.boardPassiveAggression:
        return 'Пассивная агрессия';
      case GameAbility.boardSkipTurn:
        return 'Я ещё думаю';
      case GameAbility.boardTroopFatigue:
        return 'Усталость войск';
      case GameAbility.boardCombatOptics:
        return 'Боевая оптика';
      case GameAbility.boardKingOfHill:
        return 'Царь горы';
      case GameAbility.boardSecretRoute:
        return 'Тайный маршрут';
      case GameAbility.boardRoyalPilgrimage:
        return 'Королевское паломничество';
      case GameAbility.boardMightMakesRight:
        return 'Право сильного';
      case GameAbility.boardExpeditionaryCorps:
        return 'Разведкорпус';
      case GameAbility.boardWitnessProtection:
        return 'Программа защиты свидетелей';
      case GameAbility.boardDeserters:
        return 'Дезертиры';
      case GameAbility.boardLetterH:
        return 'H';
      case GameAbility.boardFullCircle:
        return 'Полный круг';
      case GameAbility.boardArchitect:
        return 'Архитектор';
      case GameAbility.boardBigAssortment:
        return 'Большой ассортимент';
      case GameAbility.boardBlindSpot:
        return 'Слепая зона';
      case GameAbility.boardOnlyEqualsKill:
        return 'Только равный убьёт';
      case GameAbility.boardMarseillesChess:
        return 'Марсельские шахматы';
      case GameAbility.boardInitiativeFear:
        return 'Боязнь инициативы';
      case GameAbility.pawnSideways:
        return 'Карцинизация';
      case GameAbility.pawnInverted:
        return 'Диагональный ход';
      case GameAbility.pawnAlwaysDoubleStep:
        return 'Длинный шаг';
      case GameAbility.pawnRam:
        return 'На таран';
      case GameAbility.pawnAirborne:
        return 'Десант';
      case GameAbility.pawnBoomerang:
      case GameAbility.knightBoomerang:
      case GameAbility.bishopBoomerang:
        return 'Бумеранг';
      case GameAbility.pawnKamikaze:
        return 'Камикадзе';
      case GameAbility.pawnCaliph:
        return 'Халиф на час';
      case GameAbility.pawnSticky:
        return 'Липота';
      case GameAbility.pawnPolymorph:
        return 'Полиморф';
      case GameAbility.pawnInheritance:
        return 'Наследство';
      case GameAbility.pawnRansom:
        return 'Выкуп';
      case GameAbility.pawnForTheKing:
        return 'Во имя Короля';
      case GameAbility.pawnCamouflageNet:
        return 'Маскировочная сеть';
      case GameAbility.pawnTrench:
        return 'Окоп';
      case GameAbility.pawnSignalFire:
      case GameAbility.knightSignalFire:
      case GameAbility.bishopSignalFire:
      case GameAbility.rookSignalFire:
        return 'Сигнальный костер';
      case GameAbility.pawnAvengeMe:
        return 'Отомсти за меня';
      case GameAbility.pawnCaravan:
        return 'Караван';
      case GameAbility.pawnFaceControl:
        return 'Фейсконтроль';
      case GameAbility.knightRearing:
        return 'Встать на дыбы';
      case GameAbility.knightLongJump:
        return 'Пегас';
      case GameAbility.knightSecondChance:
        return 'Второй шанс';
      case GameAbility.knightGallop:
        return 'Галоп';
      case GameAbility.knightDust:
        return 'Пыль из-под копыт';
      case GameAbility.knightCentaur:
        return 'Кентавр';
      case GameAbility.knightTrojan:
        return 'Троянский конь';
      case GameAbility.knightDuel:
        return 'Вызов на дуэль';
      case GameAbility.knightGuard:
        return 'Караул';
      case GameAbility.knightTour:
        return 'Конный тур';
      case GameAbility.knightDoppelgangerOnce:
        return 'Двойник';
      case GameAbility.knightDoppelgangers:
        return 'Двойники';
      case GameAbility.knightFifthLeg:
        return 'Пятая нога';
      case GameAbility.knightElusive:
      case GameAbility.bishopElusive:
        return 'Неуловимый';
      case GameAbility.knightStomp:
        return 'Топот';
      case GameAbility.knightSurveyor:
        return 'Геодезист';
      case GameAbility.knightCornerQuest:
        return 'Задача не из лёгких';
      case GameAbility.knightRideMe:
        return 'Садись на меня';
      case GameAbility.knightMagicHooves:
        return 'Волшебные копыта';
      case GameAbility.bishopHopAlly:
        return 'Прыжок через своего';
      case GameAbility.bishopColorChaos:
        return 'Цветной хаос';
      case GameAbility.bishopInquisitor:
        return 'Инквизитор';
      case GameAbility.bishopColorVow:
        return 'Цветная клятва';
      case GameAbility.bishopBrothers:
        return 'Братья по разуму';
      case GameAbility.bishopSanctuary:
        return 'Святилище';
      case GameAbility.bishopExcommunication:
        return 'Отлучение';
      case GameAbility.bishopTithe:
        return 'Десятина';
      case GameAbility.bishopPilgrimage:
        return 'Паломничество';
      case GameAbility.bishopCrusade:
        return 'Крестовый поход';
      case GameAbility.bishopPost:
        return 'Пост';
      case GameAbility.bishopParallelWorlds:
        return 'Параллельные миры';
      case GameAbility.bishopAlcove:
        return 'Альков';
      case GameAbility.bishopGlassCeiling:
        return 'Стеклянный потолок';
      case GameAbility.rookHopAlly:
        return 'Прыжок через своего';
      case GameAbility.rookRam:
        return 'На таран';
      case GameAbility.rookAstronomicon:
        return 'Астрономикон';
      case GameAbility.rookFortress:
        return 'Крепость';
      case GameAbility.rookStandardBearer:
        return 'Знаменосец';
      case GameAbility.rookCustoms:
        return 'Таможня';
      case GameAbility.rookDrawbridge:
        return 'Подъёмный мост';
      case GameAbility.rookCurfew:
        return 'Комендантский час';
      case GameAbility.rookSiegeCalculation:
        return 'Осадный расчёт';
      case GameAbility.rookFerry:
        return 'Переправа';
      case GameAbility.rookSignalTower:
        return 'Сигнальная башня';
      case GameAbility.queenKnightStep:
        return 'Конский ход';
      case GameAbility.queenHopAlly:
        return 'Прыжок через своего';
      case GameAbility.queenSplit:
        return 'Разделение';
      case GameAbility.queenMatka:
        return 'Матка';
      case GameAbility.queenShadowEmpress:
        return 'Императрица теней';
      case GameAbility.queenEscape:
        return 'Бегство';
      case GameAbility.queenDelayedSentence:
        return 'Отложенный приговор';
      case GameAbility.queenTrophyEmbargo:
        return 'Эмбарго на трофеи';
      case GameAbility.queenYouShallNotPass:
        return 'Ты не пройдёшь!';
      case GameAbility.kingRoyalDecree:
        return 'Королевский указ';
      case GameAbility.kingExtraStep:
        return 'Длинный шаг';
      case GameAbility.kingShield:
        return 'Щит короля';
      case GameAbility.kingAura:
        return 'Аура';
      case GameAbility.kingDoppelganger:
        return 'Доппельгангер';
      case GameAbility.kingThrone:
        return 'Сила Трона';
      case GameAbility.kingFamilyUnion:
        return 'Объединение семей';
      case GameAbility.kingPrisonerExchange:
        return 'Обмен пленными';
      case GameAbility.kingRemoveEnemyMod:
        return 'Не прежде чем их повесят';
      case GameAbility.kingAssemblyHall:
        return 'Зал заседаний';
      case GameAbility.randomShift:
        return 'Сдвиг';
      case GameAbility.randomCalm:
        return 'Затишье';
      case GameAbility.randomQuarantine:
        return 'Карантин';
      case GameAbility.randomEarthquake:
        return 'Землетрясение';
      case GameAbility.randomTyphoon:
        return 'Тайфун';
      case GameAbility.randomWormhole:
        return 'Червоточина';
      case GameAbility.randomClone:
        return 'Клон';
      case GameAbility.randomNoQueen:
        return 'Без ферзя';
      case GameAbility.randomTruce:
        return 'Перемирие';
      case GameAbility.randomMeteorRain:
        return 'Метеоритный дождь';
      case GameAbility.randomCensus:
        return 'Перепись';
      case GameAbility.randomExterminatus:
        return 'Экстерминатус';
      case GameAbility.randomGoldenThrone:
        return 'Золотой трон';
      case GameAbility.randomLottery:
        return 'Лотерея';
      case GameAbility.randomPlague:
        return 'Чума';
      case GameAbility.randomMutation:
        return 'Мутация';
      case GameAbility.randomAuction:
        return 'Аукцион';
      case GameAbility.randomRightToMove:
        return 'Право хода';
      case GameAbility.randomFurtherMore:
        return 'Дальше — больше';
      case GameAbility.randomWordOfHonor:
        return 'Слово пацана';
      case GameAbility.randomSymmetry:
        return 'Симметрия';
      case GameAbility.randomVeto:
        return 'Право вето';
      case GameAbility.randomInitiativeIntercept:
        return 'Перехват инициативы';
      case GameAbility.randomStrike:
        return 'Забастовка';
      case GameAbility.randomBorderClosure:
        return 'Закрытие границ';
      case GameAbility.randomMyopia:
        return 'Близорукость';
      case GameAbility.randomMagicShutdown:
        return 'Отключение магии';
      case GameAbility.randomTimeCapsule:
        return 'Капсула времени';
      case GameAbility.randomSuicideCapture:
        return 'Смертник';
      case GameAbility.randomMeatGrinder:
        return 'Мясорубка';
    }
  }

  String get description {
    switch (this) {
      case GameAbility.boardPawnsSideways:
        return 'Ваши пешки могут ходить прямо, налево и направо';
      case GameAbility.boardPawnsDiagonal:
        return 'Ваши пешки: ход по диагонали, взятие по прямой';
      case GameAbility.boardPawnsBackward:
        return 'Ваши пешки могут ходить на назад';
      case GameAbility.boardKingSwap:
        return 'Вместо рокировки король и ладья меняются местами, даже если между ними есть фигуры';
      case GameAbility.boardLavaRank:
        return 'Горизонталь ? покрывается лавой';
      case GameAbility.boardExtraRank:
        return 'Между горизонталями 4 и 5 появляется новая пустая горизонталь';
      case GameAbility.boardExtraFile:
        return 'Появляется новая вертикаль ?';
      case GameAbility.boardFogOfWar:
        return 'Видны только клетки вокруг ваших фигур и клетки, на которые они могут сходить';
      case GameAbility.boardTide:
        return 'Ваши пешки выдвигаются вперёд и ходят только на 1 клетку вперёд';
      case GameAbility.boardDoubleStart:
        return 'Пешки с начальной линии один раз за партию могут пройти 3 клетки вперёд';
      case GameAbility.boardSprint:
        return 'На выбор модификации даётся 10 секунд вместо 30';
      case GameAbility.boardZebras:
        return 'Все кони становятся общими: оба игрока ходят ими в свой ход. Этими конями нельзя дать шах или мат';
      case GameAbility.boardFisher:
        return 'Только на старте: расстановка обоих игроков по правилам шахмат Фишера: '
            'пешки на месте, слоны на разных цветах, король между ладьями, '
            'стороны зеркальны друг другу';
      case GameAbility.boardFisherMadness:
        return 'Только на старте: все фигуры обоих игроков перемешиваются между собой. Слоны на разных цветах, без рокировки';
      case GameAbility.boardNight:
        return 'Следующие 3 хода фигуры могут вставать только на тёмные клетки';
      case GameAbility.boardDay:
        return 'Следующие 3 хода фигуры могут вставать только на светлые клетки';
      case GameAbility.boardColorblind:
        return 'Все фигуры переливаются случайными цветами. По цвету нельзя понять, кому принадлежит фигура';
      case GameAbility.boardPawnFront:
        return 'Все ваши пешки продвигаются на 1 клетку вперёд, если путь свободен';
      case GameAbility.boardCavalry:
        return 'Все ваши пешки на 3 хода становятся конями, затем снова превращаются в пешки';
      case GameAbility.boardMirror:
        return 'Левая и правая границы доски соединяются';
      case GameAbility.boardGhostCells:
        return 'Несколько случайных клеток становятся призрачными: через них можно ходить, но стоять нельзя';
      case GameAbility.boardAttraction:
        return 'Каждые 10 ходов все фигуры сдвигаются на 1 клетку к центру доски (d4, d5, e4, e5), если это возможно';
      case GameAbility.boardVirus:
        return 'После взятия фигура заражает соседнюю вражескую: та теряет одну модификацию';
      case GameAbility.boardInvisibleRegiment:
        return 'Оба игрока не видят пешки соперника, пока те не сделают взятие или не дойдут до 4-й линии (для чёрных — до 5-й)';
      case GameAbility.boardShuffle:
        return 'Каждая клетка доски случайно становится светлой или тёмной — чередование цветов пропадает';
      case GameAbility.boardTeleport:
        return 'Две случайные клетки связаны: вход на одну = выход на другую';
      case GameAbility.boardVanityFair:
        return 'Каждая ваша лёгкая фигура (конь или слон) с вероятностью 50% становится другой лёгкой фигурой';
      case GameAbility.boardMinefield:
        return 'На 1–3 случайные свободные клетки ставятся невидимые мины: следующая фигура на мине уничтожается';
      case GameAbility.boardGolconda:
        return 'В начале каждого хода с вероятностью 1% на свободную клетку падает пешка, конь или слон игрока, чей сейчас ход';
      case GameAbility.boardUnbridledHorse:
        return 'В начале хода с вероятностью 5% случайный ваш конь сам делает ход на случайную доступную клетку';
      case GameAbility.boardBaskerville:
        return 'Для обоих игроков: если игрок поставит вражескому королю 2 шаха за партию, король умрёт от страха';
      case GameAbility.boardBloodOath:
        return 'При мате король может съесть свою фигуру рядом и встать на её место, чтобы избежать мата';
      case GameAbility.boardSilentFile:
        return 'Фигуры на выбранной вертикали не могут дать шах или мат';
      case GameAbility.boardFourHorsemen:
        return 'Первое взятие каждого коня превращает жертву в вашу фигуру: оба остаются на клетке, пока кто-то не уйдёт';
      case GameAbility.boardReroll:
        return 'Все игроки до конца игры могут обновлять предложенные модификации';
      case GameAbility.boardPassiveAggression:
        return 'Каждый игрок должен поставить шах хотя бы раз за 10 своих ходов, иначе он проигрывает; после шаха счётчик снова равен 10';
      case GameAbility.boardSkipTurn:
        return 'Оба игрока могут пропустить ход и передать его сопернику';
      case GameAbility.boardTroopFatigue:
        return 'Одной фигурой нельзя ходить два своих хода подряд';
      case GameAbility.boardCombatOptics:
        return 'Слон, ладья и ферзь без взятия ходят не дальше 3 клеток, а при взятии — без ограничения';
      case GameAbility.boardKingOfHill:
        return 'Посещённые клетки окрашиваются в цвет игрока; окрашивание более 48 клеток из 64 приносит победу';
      case GameAbility.boardSecretRoute:
        return 'Каждый игрок получает скрытый маршрут из трёх клеток; посещение всех трёх приносит победу';
      case GameAbility.boardRoyalPilgrimage:
        return 'Король, достигший крайней горизонтали соперника без шаха, приносит своему игроку победу';
      case GameAbility.boardMightMakesRight:
        return 'Фигура может брать только фигуры не дороже себя; король может брать всех, и все могут атаковать короля';
      case GameAbility.boardExpeditionaryCorps:
        return 'Фигура на половине соперника не может вернуться на свою половину, пока не сделает хотя бы одно взятие';
      case GameAbility.boardWitnessProtection:
        return 'Оба игрока тайно выбирают одну свою фигуру, кроме короля; её первое взятие отменяется';
      case GameAbility.boardDeserters:
        return 'У каждого игрока тайно есть пешка-дезертир; на вражеской половине она меняет цвет';
      case GameAbility.boardLetterH:
        return 'Составьте букву H из 7 своих фигур — победа';
      case GameAbility.boardFullCircle:
        return 'Ладья, посетившая все 4 угловые клетки, приносит победу';
      case GameAbility.boardArchitect:
        return 'Между случайными соседними клетками появляются 3–8 стен: через них нельзя ходить и атаковать';
      case GameAbility.boardBigAssortment:
        return 'До конца игры вы выбираете из 4 модификаций';
      case GameAbility.boardBlindSpot:
        return 'Модификации соперника скрыты знаками вопроса; свои видны как обычно';
      case GameAbility.boardOnlyEqualsKill:
        return 'Пять взятий фигур того же типа, что и взявшая, приносят победу';
      case GameAbility.boardMarseillesChess:
        return 'За один ход игрок делает два последовательных движения. В сбалансированном варианте белые на первом ходу делают только одно движение';
      case GameAbility.boardInitiativeFear:
        return 'Первый игрок, чья фигура будет съедена, дополнительно выбирает модификацию вне обычной волны раз в 3 хода';
      case GameAbility.pawnSideways:
        return 'Выбранная пешка может сходить на 1 клетку вбок';
      case GameAbility.pawnInverted:
        return 'Выбранная пешка ходит по диагонали и ест по прямой';
      case GameAbility.pawnAlwaysDoubleStep:
        return 'Выбранная пешка всегда может пройти 2 клетки вперёд';
      case GameAbility.pawnRam:
        return 'Выбранная пешка ходит и ест только вперёд, не по диагонали';
      case GameAbility.pawnAirborne:
        return 'Выбранная пешка один раз может перепрыгнуть фигуру прямо перед собой';
      case GameAbility.pawnBoomerang:
      case GameAbility.knightBoomerang:
      case GameAbility.bishopBoomerang:
        return 'После следующего взятия выбранная фигура сразу возвращается на клетку, с которой ходила';
      case GameAbility.pawnKamikaze:
        return 'В ваш следующий ход выбранная пешка взрывается и отбрасывает соседние фигуры на 1 клетку от себя, если возможно';
      case GameAbility.pawnCaliph:
        return 'На 1 ваш ход выбранная пешка становится ферзем, затем снова пешкой';
      case GameAbility.pawnSticky:
        return 'Вражеская фигура, съевшая выбранную пешку, на свой следующий ход не сможет ходить';
      case GameAbility.pawnPolymorph:
        return 'После взятия выбранная пешка на 1 следующий ход становится типом съеденной фигуры и ходит как она';
      case GameAbility.pawnInheritance:
        return 'После гибели выбранной пешки все её модификации переходят ближайшей своей пешке';
      case GameAbility.pawnRansom:
        return 'При попытке взять выбранную пешку можно уничтожить одну её модификацию и отменить взятие';
      case GameAbility.pawnForTheKing:
        return 'Если выбранная пешка погибает на мине, ваш король получает выбор модификации';
      case GameAbility.pawnCamouflageNet:
        return 'Фигура, окружённая тремя или более вашими пешками, невидима для соперника';
      case GameAbility.pawnTrench:
        return 'Если выбранная пешка не ходила 5 и более своих ходов, её можно взять только при двух и более атаках';
      case GameAbility.pawnSignalFire:
      case GameAbility.knightSignalFire:
      case GameAbility.bishopSignalFire:
      case GameAbility.rookSignalFire:
        return 'Случайная клетка под туманом войны навсегда открывается для вас';
      case GameAbility.pawnAvengeMe:
        return 'Если выбранную пешку взяли, любая соседняя союзная пешка может взять взявшую фигуру даже необычным ходом';
      case GameAbility.pawnCaravan:
        return 'Сдвоенные или строенные пешки с выбранной на одной вертикали ходят вперёд одновременно';
      case GameAbility.pawnFaceControl:
        return 'Вражеская фигура прямо перед выбранной пешкой пропускает следующий свой ход';
      case GameAbility.knightRearing:
        return 'На клетку выбранного коня могут вставать другие фигуры; этого коня нельзя съесть';
      case GameAbility.knightLongJump:
        return 'Выбранный конь прыгает только на 3+1, а не на 2+1';
      case GameAbility.knightSecondChance:
        return 'При взятии выбранный конь возвращается на предыдущую клетку, если она свободна';
      case GameAbility.knightGallop:
        return 'После хода выбранный конь может сразу сделать второй прыжок на свободную клетку';
      case GameAbility.knightDust:
        return 'Клетка, с которой ушёл выбранный конь, на 1 ход недоступна никому';
      case GameAbility.knightCentaur:
        return 'Выбранный конь также может ходить как король на 1 клетку';
      case GameAbility.knightTrojan:
        return 'Через 3 хода выбранный конь взрывается и уничтожает все окружающие фигуры; отсчёт виден у коня';
      case GameAbility.knightDuel:
        return 'Выбранный конь выбирает вражескую фигуру; пока один из дуэлянтов не погибнет, они могут брать только друг друга';
      case GameAbility.knightGuard:
        return 'Выбранный конь выбирает доступную клетку и 3 хода защищает её: вставшую туда вражескую фигуру он сразу берёт вне хода';
      case GameAbility.knightTour:
        return 'Посетив 8 разных клеток, выбранный конь получает дополнительную модификацию';
      case GameAbility.knightDoppelgangerOnce:
        return 'После хода выбранный конь один раз оставляет иллюзию на стартовой клетке; её видит только соперник';
      case GameAbility.knightDoppelgangers:
        return 'После каждого хода выбранный конь оставляет иллюзию на старте; их видит только соперник';
      case GameAbility.knightFifthLeg:
        return 'Выбранный конь ходит на 2+2 клетки вместо 2+1';
      case GameAbility.knightElusive:
      case GameAbility.bishopElusive:
        return 'Выбранную фигуру можно взять только если её атакуют не менее двух вражеских фигур';
      case GameAbility.knightStomp:
        return 'После следующего хода выбранного коня соседние вражеские пешки по возможности отходят от него';
      case GameAbility.knightSurveyor:
        return 'Клетки, посещённые выбранным конём, защищены от случайных катаклизмов';
      case GameAbility.knightCornerQuest:
        return 'Если выбранный конь посетит любые 3 из 4 угловых клеток — победа';
      case GameAbility.knightRideMe:
        return 'Перед ходом выбранного коня выберите соседнюю пешку: она поедет с ним, сохраняя относительную позицию';
      case GameAbility.knightMagicHooves:
        return 'Следующий ход выбранного коня создаёт портал со стартовой клетки на конечную';
      case GameAbility.bishopHopAlly:
        return 'Выбранный слон может перепрыгнуть одну свою фигуру';
      case GameAbility.bishopColorChaos:
        return 'Один раз выбранный слон может встать на соседнюю пустую клетку, сменив цвет поля';
      case GameAbility.bishopInquisitor:
        return 'Вместо взятия выбранный слон может снять одну модификацию с атакуемой вражеской фигуры, оставаясь на месте';
      case GameAbility.bishopColorVow:
        return 'Выбранный слон привязан к цвету своей клетки и погибает на другом цвете; зато может рикошетить на 1 клетку от края доски';
      case GameAbility.bishopBrothers:
        return 'Если у вас 2+ слона, ход выбранного сдвигает всех ваших слонов тем же вектором, где это возможно';
      case GameAbility.bishopSanctuary:
        return 'Выбранный слон выбирает союзника, кроме короля; при следующем взятии подзащитного вместо него погибает слон';
      case GameAbility.bishopExcommunication:
        return 'После взятия фигуры выбранным слоном другие враги того же типа до следующего хода этого слона не могут брать его';
      case GameAbility.bishopTithe:
        return 'Модифицированный враг, покинувший диагональ выбранного слона, до следующего хода этого слона теряет одну модификацию';
      case GameAbility.bishopPilgrimage:
        return 'Посетив все четыре четверти доски, выбранный слон выбирает союзника и защищает его от следующего взятия';
      case GameAbility.bishopCrusade:
        return 'После двух взятий выбранным слоном на доске срабатывает случайный катаклизм';
      case GameAbility.bishopPost:
        return 'Три хода выбранного слона без взятий дают два выбора модификаций подряд';
      case GameAbility.bishopParallelWorlds:
        return 'Выбранный слон один раз меняется местами с союзной фигурой на той же диагонали';
      case GameAbility.bishopAlcove:
        return 'Выбранный слон один раз может создать одну клетку за краем доски и встать на неё';
      case GameAbility.bishopGlassCeiling:
        return 'Выбранный слон может перепрыгнуть через одну вражескую фигуру вместо взятия; та пропускает ход';
      case GameAbility.rookHopAlly:
        return 'Выбранная ладья может перепрыгнуть одну свою фигуру';
      case GameAbility.rookRam:
        return 'Выбранная ладья может толкнуть свою фигуру на 1 клетку дальше и занять её место';
      case GameAbility.rookAstronomicon:
        return 'Если вертикаль выбранной ладьи пуста кроме неё, ладья прожигает её на 3 хода: враг на вертикали уничтожается, король не может туда встать';
      case GameAbility.rookFortress:
        return 'Клетка перед выбранной ладьёй — укрепление: вражеские пешки и лёгкие фигуры не могут съесть фигуру на ней';
      case GameAbility.rookStandardBearer:
        return 'Фигуры на восьми клетках вокруг выбранной ладьи нельзя перемещать принудительными эффектами модификаций';
      case GameAbility.rookCustoms:
        return 'Следующие 3 хода враги не могут вставать на выбранную случайно горизонталь или вертикаль ладьи, если уже не находятся на ней';
      case GameAbility.rookDrawbridge:
        return 'Союзные фигуры могут проходить сквозь выбранную ладью';
      case GameAbility.rookCurfew:
        return 'Враг рядом с выбранной ладьёй не может отойти от неё 3 своих хода, пока ладья сама не отойдёт';
      case GameAbility.rookSiegeCalculation:
        return 'Если выбранная ладья 3 хода подряд может взять одну и ту же вражескую фигуру, но не берёт её, эта фигура исчезает';
      case GameAbility.rookFerry:
        return 'Для выбранной ладьи левая и правая границы доски соединяются, как у Зеркала';
      case GameAbility.rookSignalTower:
        return 'Выбранная ладья раскрывает туман войны на своей вертикали и горизонтали';
      case GameAbility.queenKnightStep:
        return 'Выбранный ферзь дополнительно ходит как конь';
      case GameAbility.queenHopAlly:
        return 'Выбранный ферзь может перепрыгнуть одну свою фигуру';
      case GameAbility.queenSplit:
        return 'Выбранный ферзь исчезает: на клетке остаются слон и ладья одновременно';
      case GameAbility.queenMatka:
        return 'Выбранный ферзь не может никого съесть, но каждые 3 ваших хода вокруг него на случайной свободной клетке появляется пешка';
      case GameAbility.queenShadowEmpress:
        return 'Выбранный ферзь дополнительно ходит как конь (2+1), но может вставать только на клетки одного цвета (выбирается случайно)';
      case GameAbility.queenEscape:
        return 'Если выбранного ферзя съедят, на случайной свободной клетке появится ваш слон или ладья (50%), без шаха и мата вражескому королю';
      case GameAbility.queenDelayedSentence:
        return 'Выбранный ферзь отмечает атакуемого врага; после хода соперника тот погибает, если всё ещё находится под атакой ферзя';
      case GameAbility.queenTrophyEmbargo:
        return 'Взятие на клетке под контролем выбранного ферзя больше не даёт награды (правило совместимости; волны модификаций от взятий не зависят)';
      case GameAbility.queenYouShallNotPass:
        return 'Вражеская фигура, взявшая выбранного ферзя, тоже уничтожается';
      case GameAbility.kingRoyalDecree:
        return 'Выбранный король и ладья меняются местами, даже если между ними есть фигуры';
      case GameAbility.kingExtraStep:
        return 'Выбранный король может ходить на 2 клетки в любую сторону';
      case GameAbility.kingShield:
        return 'Один раз выбранный король избегает мата, телепортируясь на случайную свободную клетку';
      case GameAbility.kingAura:
        return 'Выбранному королю нельзя поставить мат пешкой';
      case GameAbility.kingDoppelganger:
        return 'Все ваши пешки и ферзь выглядят как король';
      case GameAbility.kingThrone:
        return 'Пока выбранный король стоит на троне, шах засчитывается только от фигур не дальше 3 клеток';
      case GameAbility.kingFamilyUnion:
        return 'Выбранный король может съесть свою лёгкую фигуру (коня или слона) рядом и до конца партии ходить только как она';
      case GameAbility.kingPrisonerExchange:
        return 'Вы выбираете взятую соперником свою фигуру, а соперник — взятую вами; обе возвращаются на случайные свободные клетки';
      case GameAbility.kingRemoveEnemyMod:
        return 'Вы выбираете и удаляете одну модификацию у любой вражеской фигуры';
      case GameAbility.kingAssemblyHall:
        return 'Фигуры рядом с выбранным королём не могут быть целью случайного выбора катаклизма';
      case GameAbility.randomShift:
        return 'Вертикаль ? сдвигается на 1 клетку';
      case GameAbility.randomCalm:
        return 'Ничего не происходит';
      case GameAbility.randomQuarantine:
        return 'Случайная свободная клетка недоступна на 3–10 ходов';
      case GameAbility.randomEarthquake:
        return 'Горизонталь ? сдвигается влево или вправо на 1 клетку';
      case GameAbility.randomTyphoon:
        return 'Область 2×2 поворачивается по часовой стрелке';
      case GameAbility.randomWormhole:
        return 'Случайная пустая клетка недоступна до конца партии';
      case GameAbility.randomClone:
        return 'На вашей половине появляется ещё одна пешка';
      case GameAbility.randomNoQueen:
        return 'Вражеский ферзь на 2 своих хода превращается в коня';
      case GameAbility.randomTruce:
        return '3 хода нельзя брать фигуры; шах и мат временно не засчитываются';
      case GameAbility.randomMeteorRain:
        return 'На 3 случайные клетки падают метеориты, уничтожая все фигуры, кроме королей';
      case GameAbility.randomCensus:
        return 'У случайной вражеской фигуры с модификациями исчезает одна случайная модификация';
      case GameAbility.randomExterminatus:
        return 'В течение следующего хода у обоих игроков: шах вражескому королю мгновенно убивает его';
      case GameAbility.randomGoldenThrone:
        return 'Если ваша пешка погибает, ваш король выбирает себе модификацию';
      case GameAbility.randomLottery:
        return 'Две ваши случайные фигуры не-короли меняются типами';
      case GameAbility.randomPlague:
        return 'Каждый ход фигура с шансом 1% заболевает чумой и умрёт через 3 хода; рядом с больной шанс 10%. Короли тоже могут заболеть';
      case GameAbility.randomMutation:
        return 'Случайная ваша пешка становится случайной лёгкой фигурой (конь или слон) того же цвета';
      case GameAbility.randomAuction:
        return 'Случайная клетка становится аукционной: кто первым на неё встанет, получит модификацию';
      case GameAbility.randomRightToMove:
        return 'Выберите вражескую фигуру: в следующий ход соперник обязан сходить ей, если может';
      case GameAbility.randomFurtherMore:
        return 'Сейчас ничего не происходит; при следующем выборе вы сможете один раз обновить предложенные модификации';
      case GameAbility.randomWordOfHonor:
        return 'Выберите клетку: если в следующий свой ход встанете на неё, получите модификацию, иначе потеряете одну случайную модификацию';
      case GameAbility.randomSymmetry:
        return 'Следующие 3 хода соперник обязан ходить теми же типами фигур, которыми перед ним ходили вы';
      case GameAbility.randomVeto:
        return 'Выберите вражескую фигуру: следующие 3 хода соперник не может ходить ею';
      case GameAbility.randomInitiativeIntercept:
        return 'Игрок с более слабой армией получает дополнительный ход без взятия, шаха и мата';
      case GameAbility.randomStrike:
        return 'Оба игрока не могут двигать фигуры случайного типа в течение 3–10 ходов';
      case GameAbility.randomBorderClosure:
        return 'Следующие 2 хода фигуры не могут пересекать середину доски';
      case GameAbility.randomMyopia:
        return 'Слоны, ладьи и ферзи временно видят и ходят не дальше 2 клеток';
      case GameAbility.randomMagicShutdown:
        return 'Следующие 3–10 ходов все модификации отключены';
      case GameAbility.randomTimeCapsule:
        return 'Позиция сохраняется; после двух ходов каждого игрока доска возвращается к ней, но заработанные модификации сохраняются';
      case GameAbility.randomSuicideCapture:
        return 'Следующее взятие уничтожает и взятую фигуру, и фигуру, которая её взяла';
      case GameAbility.randomMeatGrinder:
        return 'Следующий ход обоих игроков должен быть взятием, если взятие возможно';
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
      final axisName = axis == AbilityAxis.rank ? 'горизонталь' : 'вертикаль';
      return 'Следующие 3 хода враги не могут вставать на $axisName ладьи, '
          'если уже не находятся на ней';
    }
    if (this == GameAbility.randomStrike &&
        affectedPieceType != null &&
        durationMoves != null) {
      return 'Оба игрока не могут двигать ${_pieceTypeGenitivePlural(affectedPieceType)} '
          'следующие $durationMoves ${_movesWord(durationMoves)}';
    }
    if (this == GameAbility.randomMagicShutdown && durationMoves != null) {
      return 'Все модификации отключены на $durationMoves '
          '${_movesWord(durationMoves)}';
    }
    if (this == GameAbility.boardTide && forColor != null) {
      final ranks = boardRankCount ?? 8;
      final rankLabel = forColor == PieceColor.white ? 3 : ranks - 2;
      return 'Ваши пешки стоят на $rankLabel-й горизонтали '
          'и ходят только на 1 клетку вперёд';
    }
    if (this == GameAbility.boardLavaRank && lavaRank != null) {
      return 'Горизонталь ${lavaRank + 1} покрывается лавой. '
          'Фигура может простоять на ней не более 3 ходов';
    }
    if (this == GameAbility.randomShift &&
        shiftFile != null &&
        shiftDirection != null) {
      final towardHigherRanks = shiftDirection > 0;
      final String dir;
      if (forColor == PieceColor.black) {
        dir = towardHigherRanks ? 'назад' : 'вперёд';
      } else {
        dir = towardHigherRanks ? 'вперёд' : 'назад';
      }
      return 'Все фигуры на вертикали '
          '${fileLabel(shiftFile, fileCount: boardFileCount ?? 8, extraFile: boardExtraFile).toUpperCase()} '
          'сдвигаются на 1 клетку $dir';
    }
    if (this == GameAbility.boardExtraFile && extraFileOnLeft != null) {
      if (extraFileOnLeft) {
        return 'Слева появляется новая вертикаль z';
      }
      return 'Справа появляется новая вертикаль i';
    }
    if (this == GameAbility.boardGhostCells && ghostCellCount != null) {
      final word = (ghostCellCount >= 2 && ghostCellCount <= 4)
          ? 'клетки'
          : 'клеток';
      return '$ghostCellCount $word становятся призрачными: '
          'через них можно ходить, но стоять нельзя';
    }
    if (this == GameAbility.boardMinefield && mineCount != null) {
      if (mineCount == 1) {
        return 'На 1 свободную клетку ставится невидимая мина: '
            'следующая фигура на ней уничтожается';
      }
      return 'На $mineCount свободные клетки ставятся невидимые мины: '
          'следующая фигура на мине уничтожается';
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
      return 'Клетки $a и $b связаны: вход на одну = выход на другую';
    }
    if (this == GameAbility.randomQuarantine && quarantineSquare != null) {
      final moves = quarantineMoves ?? 5;
      final movesWord = (moves == 3 || moves == 4) ? 'хода' : 'ходов';
      return 'Клетка '
          '${squareLabel(quarantineSquare, fileCount: boardFileCount ?? 8, extraFile: boardExtraFile)} '
          'недоступна следующие $moves $movesWord';
    }
    if (this == GameAbility.randomEarthquake &&
        quakeRank != null &&
        quakeDirection != null) {
      final dir = quakeDirection > 0 ? 'вправо' : 'влево';
      return 'Горизонталь ${quakeRank + 1} сдвигается на 1 клетку $dir';
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
      return 'Область $a–$b поворачивается по часовой стрелке';
    }
    if (this == GameAbility.randomWormhole && wormholeSquare != null) {
      return 'Клетка '
          '${squareLabel(wormholeSquare, fileCount: boardFileCount ?? 8, extraFile: boardExtraFile)} '
          'недоступна до конца партии';
    }
    if (this == GameAbility.randomClone && cloneSquare != null) {
      return 'Пешка появляется на '
          '${squareLabel(cloneSquare, fileCount: boardFileCount ?? 8, extraFile: boardExtraFile)}';
    }
    if (this == GameAbility.queenShadowEmpress && landOnLight != null) {
      return landOnLight
          ? 'Ферзь ходит ещё как конь, но может вставать только на светлые клетки'
          : 'Ферзь ходит ещё как конь, но может вставать только на тёмные клетки';
    }
    if (this == GameAbility.boardSilentFile && silentFile != null) {
      return 'Вертикаль '
          '${fileLabel(silentFile, fileCount: boardFileCount ?? 8, extraFile: boardExtraFile).toUpperCase()} '
          'немая: фигуры на ней не могут дать шах или мат';
    }
    if (this == GameAbility.randomAuction && auctionSquare != null) {
      return 'Клетка '
          '${squareLabel(auctionSquare, fileCount: boardFileCount ?? 8, extraFile: boardExtraFile)} '
          '— аукцион: кто первым встанет, получит модификацию';
    }
    return description;
  }
}

String _movesWord(int moves) {
  final lastTwo = moves % 100;
  if (lastTwo >= 11 && lastTwo <= 14) return 'ходов';
  switch (moves % 10) {
    case 1:
      return 'ход';
    case 2:
    case 3:
    case 4:
      return 'хода';
    default:
      return 'ходов';
  }
}

String _pieceTypeGenitivePlural(PieceType type) {
  switch (type) {
    case PieceType.pawn:
      return 'пешек';
    case PieceType.knight:
      return 'коней';
    case PieceType.bishop:
      return 'слонов';
    case PieceType.rook:
      return 'ладей';
    case PieceType.queen:
      return 'ферзей';
    case PieceType.king:
      return 'королей';
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

  /// Цвет игрока, которому предлагают / который выбирает модификацию.
  final PieceColor? forColor;

  /// Seed для детерминированного RNG при применении (онлайн-синхронизация).
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

/// Модификация с названием и текстом для экрана активных модификаций.
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

/// Снимок стартовых модификаций доски и выбранных по ходу модификаций.
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
