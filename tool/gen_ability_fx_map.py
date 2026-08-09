from pathlib import Path

abilities = Path("tmp_abilities.txt").read_text(encoding="utf-8").strip().splitlines()

E = {
    "boardReroll",
    "boardPassiveAggression",
    "boardSkipTurn",
    "boardBigAssortment",
    "modeMateVeto",
    "modeDebtPit",
    "modeShopToken",
    "modeCallOf22",
    "modeHolyRandom",
    "modeComeOn",
    "pawnRansom",
    "pawnHereditaryEdict",
    "kingRemoveEnemyMod",
    "randomCensus",
    "randomLottery",
    "randomRightToMove",
    "randomFurtherMore",
    "randomInitiativeIntercept",
    "randomWarehouse",
}

explicit: dict[str, tuple[str, str]] = {}


def set_many(names: list[str], layer: str, skin: str) -> None:
    for n in names:
        explicit[n] = (layer, skin)


set_many(
    [
        "boardExtraRank",
        "boardExtraFile",
        "modeAtomic",
        "modeZooShuffle",
        "pawnKamikaze",
        "pawnMortar",
        "pawnSapper",
        "pawnRockPaperScissors",
        "knightStomp",
        "knightMagicHooves",
        "knightTangledTrail",
        "bishopParallelWorlds",
        "bishopAlcove",
        "rookIllDrive",
        "queenSplit",
        "kingRoyalDecree",
        "kingPrisonerExchange",
        "randomShift",
        "randomEarthquake",
        "randomTyphoon",
        "randomClone",
        "randomNoQueen",
        "randomMeteorRain",
        "randomMutation",
        "randomSuicideCapture",
        "randomMoveSteal",
        "randomTwentyOne",
        "randomGestureMirror",
    ],
    "burst",
    "burstImpact",
)

set_many(["boardLavaRank"], "square", "lavaGlow")
set_many(["boardGhostCells"], "square", "ghostFade")
set_many(
    [
        "boardTeleport",
        "randomWormhole",
        "boardGravityWell",
        "randomKansasHurricanes",
    ],
    "square",
    "portalSpin",
)
set_many(["boardMinefield"], "square", "mineSpike")
set_many(
    [
        "boardSilentFile",
        "boardForbiddenLetter",
        "boardLetterH",
        "bishopGlassCeiling",
    ],
    "square",
    "hazardStripe",
)
set_many(
    ["boardKingOfHill", "boardTerritoryExpand", "modeWasteland"],
    "square",
    "territoryPaint",
)
set_many(
    [
        "boardSecretRoute",
        "knightCornerQuest",
        "knightGallopContract",
        "rookCustoms",
    ],
    "square",
    "routeLine",
)
set_many(["boardArchitect", "queenYouShallNotPass"], "square", "wallBeam")
set_many(["boardInkBlot", "bishopInkTrail"], "square", "inkBleed")
set_many(["boardRiver"], "square", "riverFlow")
set_many(
    [
        "boardEarnedRest",
        "modePrioritySetup",
        "modeKingCenter",
        "modeDuckChess",
        "modeCrazyhouse",
        "pawnAvengeMe",
        "pawnFuse",
        "knightGuard",
        "knightSurveyor",
        "bishopRelicPower",
        "bishopBlindingSacristy",
        "rookAstronomicon",
        "rookSignalTower",
        "kingThrone",
        "randomQuarantine",
        "randomAuction",
        "randomWordOfHonor",
        "randomDisinfo",
    ],
    "square",
    "markerBadge",
)
set_many(["modeVolcano"], "square", "volcanoGlow")
set_many(["boardScorchingSun"], "square", "heatPulse")
set_many(["knightDust", "knightHoofSmoke"], "square", "dustCloud")
set_many(["knightDonkey", "boardSwamp"], "square", "swampMurk")
set_many(["pawnSeed"], "square", "seedSprout")
set_many(["randomQuicksand"], "square", "sandSink")
set_many(["modeDuckChess"], "square", "duckMarker")

set_many(
    [
        "boardFogOfWar",
        "boardInvisibleRegiment",
        "boardBlindSpot",
        "boardCollectiveMyopia",
        "boardCombatOptics",
        "modeKriegspiel",
        "randomMyopia",
    ],
    "board",
    "ghostFade",
)
set_many(
    [
        "boardSprint",
        "boardFisher",
        "boardFisherMadness",
        "boardNight",
        "boardDay",
        "boardColorblind",
        "boardMirror",
        "boardShuffle",
        "boardGolconda",
        "boardBaskerville",
        "boardBloodOath",
        "boardMightMakesRight",
        "boardOnlyEqualsKill",
        "boardMarseillesChess",
        "boardInitiativeFear",
        "boardIdealSymmetry",
        "boardCenterTax",
        "modeBus",
        "modeBloodFeud",
        "modeBrokenPerspective",
        "randomCalm",
        "randomTruce",
        "randomExterminatus",
        "randomSymmetry",
        "randomMagicShutdown",
    ],
    "board",
    "boardWash",
)
set_many(["boardAttraction"], "board", "attractionPull")
set_many(["boardVirus"], "board", "virusSpark")
set_many(["boardFrostMap"], "board", "iceGrow")
set_many(["modeTimeZone", "randomTimeCapsule"], "board", "timeWarp")
set_many(["modeSeasons"], "board", "seasonWash")
set_many(["randomBorderClosure"], "board", "borderWall")
set_many(["randomMeatGrinder"], "board", "meatGrinder")
set_many(["randomTwilightEclipse"], "board", "eclipseDim")

set_many(["boardZebras"], "piece", "zebraStripe")
set_many(["boardVanityFair", "bishopColorChaos"], "piece", "vanityHue")
set_many(
    [
        "boardShadowRight",
        "pawnInfantryShadow",
        "knightDoppelgangerOnce",
        "knightDoppelgangers",
        "kingDoppelganger",
        "queenShadowEmpress",
    ],
    "piece",
    "shadowTwin",
)
set_many(["pawnSticky"], "piece", "stickyDrip")
set_many(["pawnStarvation", "randomPlague"], "piece", "poisonPulse")
set_many(
    [
        "pawnSignalFire",
        "knightSignalFire",
        "bishopSignalFire",
        "rookSignalFire",
    ],
    "piece",
    "torchFlame",
)
explicit["knightTrojan"] = ("piece", "fuseTick")
set_many(
    [
        "knightDuel",
        "knightNonAggression",
        "bishopNonAggression",
        "rookCurfew",
        "rookSeal",
        "queenCourtIntrigue",
    ],
    "piece",
    "chainLink",
)
set_many(
    [
        "bishopSanctuary",
        "knightKingGuard",
        "bishopKingGuard",
        "rookFortress",
        "kingShield",
    ],
    "piece",
    "wardShield",
)
set_many(["rookSiegeCalculation"], "piece", "siegeTick")
set_many(["modeInsatiableHunger"], "piece", "hungerGnaw")
set_many(["randomSnailTrail"], "piece", "slimeTrail")
set_many(["boardTroopFatigue"], "piece", "statusBadge")

for n in [
    "boardPawnsSideways",
    "boardPawnsDiagonal",
    "boardPawnsBackward",
    "boardTide",
    "boardDoubleStart",
    "boardPawnFront",
    "boardCavalry",
    "boardUnbridledHorse",
    "boardWalkingCastle",
]:
    explicit[n] = ("piece", "modAura")

for n in [
    "boardKingSwap",
    "boardFourHorsemen",
    "boardRoyalPilgrimage",
    "boardExpeditionaryCorps",
    "boardWitnessProtection",
    "boardDeserters",
    "boardFullCircle",
    "boardTurncoats",
    "boardInvisibleHand",
    "boardRestlessKings",
    "pawnCaliph",
    "pawnPolymorph",
    "pawnInheritance",
    "pawnTrench",
    "pawnDoubleLife",
    "pawnSpotlight",
    "knightTour",
    "bishopColorVow",
    "bishopExcommunication",
    "bishopPilgrimage",
    "queenMatka",
    "queenDelayedSentence",
    "kingAura",
    "randomGoldenThrone",
    "randomVeto",
    "randomStrike",
    "randomSerialManiac",
    "randomFamilyContract",
    "randomLoneWarrior",
    "randomBlackMark",
]:
    explicit.setdefault(n, ("piece", "statusBadge"))

rows = []
for a in abilities:
    if a in E:
        rows.append((a, "none", "none"))
        continue
    if a in explicit:
        rows.append((a, *explicit[a]))
        continue
    if a.startswith(("mode", "board", "random")):
        rows.append((a, "board", "boardWash"))
        continue
    rows.append((a, "piece", "modAura"))

skins = sorted(
    {r[2] for r in rows if r[2] != "none"}
    | {
        "modAura",
        "statusBadge",
        "iceGrow",
        "heatPulse",
        "lavaGlow",
        "sandSink",
        "dustCloud",
        "inkBleed",
        "poisonPulse",
        "virusSpark",
        "chainLink",
        "wardShield",
        "torchFlame",
        "siegeTick",
        "portalSpin",
        "ghostFade",
        "mineSpike",
        "territoryPaint",
        "swampMurk",
        "slimeTrail",
        "riverFlow",
        "volcanoGlow",
        "boardWash",
        "seasonWash",
        "hazardStripe",
        "markerBadge",
        "wallBeam",
        "routeLine",
        "burstImpact",
        "attractionPull",
        "eclipseDim",
        "borderWall",
        "meatGrinder",
        "timeWarp",
        "shadowTwin",
        "stickyDrip",
        "fuseTick",
        "seedSprout",
        "zebraStripe",
        "vanityHue",
        "hungerGnaw",
        "duckMarker",
        "none",
    }
)

out = [
    "import 'fx_skin.dart';",
    "import '../l10n/models/game_ability.dart';",
    "",
    "export 'fx_skin.dart';",
    "",
    "class AbilityFxProfile {",
    "  const AbilityFxProfile(this.layer, this.skin);",
    "  final FxLayer layer;",
    "  final FxSkin skin;",
    "}",
    "",
    "const Map<GameAbility, AbilityFxProfile> kAbilityFx = {",
]
out += [
    f"  GameAbility.{a}: AbilityFxProfile(FxLayer.{layer}, FxSkin.{skin}),"
    for a, layer, skin in rows
]
out += [
    "};",
    "",
    "AbilityFxProfile fxProfileFor(GameAbility ability) =>",
    "    kAbilityFx[ability] ??",
    "    const AbilityFxProfile(FxLayer.piece, FxSkin.modAura);",
    "",
]

Path("lib/chess/ability_fx_map.dart").write_text(
    "\n".join(out), encoding="utf-8"
)
from collections import Counter

print(dict(Counter(r[1] for r in rows)), "total", len(rows))
print("none count", sum(1 for r in rows if r[1] == "none"))

