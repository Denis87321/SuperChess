#!/usr/bin/env python3
"""Scaffold batch of new GameAbility entries into model files."""
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# name -> (group, title, description, piece_type|None, effect|None, board_wide)
# group: mode|board|random|pawn|knight|bishop|rook|queen|king
# piece_type for preferredPieceType; None => null branch
ABILITIES: list[tuple[str, str, str, str, str | None, str | None, bool]] = [
    # pawn
    ("pawnArchivist", "pawn", "Архивариус",
     "Игрок выбирает одну из своих пешек. Она помнит все клетки, на которые наступала. Раз за партию можно вернуться на одну из них, если клетка свободна.",
     "pawn", "pawnArchivist", False),
    ("pawnPairStep", "pawn", "Парный шаг",
     "Выбранная пешка выбирает союзницу-пешку на соседней клетке: пока обе живы, ход одной может сдвинуть обе вперёд на 1, если путь чист.",
     "pawn", "pawnPairStep", False),
    ("pawnFarsight", "pawn", "Дальнозоркость",
     "Выбранная пешка ходит только на 2 клетки вперёд и бьёт на 2 клетки по диагонали вперёд. Перепрыгивать и бить через фигуры нельзя.",
     "pawn", "pawnFarsight", False),
    ("pawnMortar", "pawn", "Миномет",
     "Выбранная пешка раз в 3 своих хода стреляет на 2 клетки прямо перед собой: фигура там уничтожается. Таймер виден обоим.",
     "pawn", "pawnMortar", False),
    ("pawnSapper", "pawn", "Сапёр",
     "Выбранная пешка обезвреживает скрытую ловушку при входе на клетку и сама не страдает. Появляется только при активных ловушках.",
     "pawn", "pawnSapper", False),
    ("pawnHereditaryEdict", "pawn", "Наследный указ",
     "При превращении пешки соперник может выбрать только тип фигуры, которого у него сейчас нет на доске.",
     "pawn", "pawnHereditaryEdict", False),
    ("pawnInfantryShadow", "pawn", "Тень пехотинца",
     "Пока выбранная пешка жива, клетка прямо за ней (к вашему краю) — укрытие: союзная фигура там не берётся пешкой.",
     "pawn", "pawnInfantryShadow", False),
    ("pawnStarvation", "pawn", "Голодовка",
     "Игрок выбирает вражескую пешку. Если она не ест 6 полуходов владельца — исчезает. Счётчик виден обоим; взятие сбрасывает его.",
     "pawn", "pawnStarvation", False),
    ("pawnSeed", "pawn", "Семечко",
     "После смерти выбранной пешки на клетке остаётся семечко: через 3 полных хода, если клетка свободна, снова ваша пешка без модов.",
     "pawn", "pawnSeed", False),
    ("pawnRockPaperScissors", "pawn", "Цу-е-фа",
     "Появляется, если на доске есть взаимно блокирующие пешки. Игрок выбирает такую пару: камень-ножницы-бумага до победы; проигравшая гибнет. Выбор виден обоим.",
     "pawn", "pawnRockPaperScissors", False),
    ("pawnDoubleLife", "pawn", "Двойная жизнь",
     "У выбранной пешки скрытый второй тип (конь или слон). Раз за партию на один ваш ход она ходит как он, затем снова пешка. Тип тайный для врага.",
     "pawn", "pawnDoubleLife", False),
    ("pawnLittleBrother", "pawn", "Маленький брат",
     "Если прямо перед выбранной пешкой стоит вражеская не-король фигура, та пропускает следующий ход.",
     "pawn", "pawnLittleBrother", False),
    ("pawnSpotlight", "pawn", "Под прожекторами",
     "Если выбранная пешка 6 ходов подряд под атакой вражеских пешек и не съедена, она превращается в лёгкую фигуру на ваш выбор.",
     "pawn", "pawnSpotlight", False),
    ("pawnFuse", "pawn", "Фитиль",
     "Выбранная пешка ставит фитиль на клетке ухода: через 2 хода клетка взрывается (не-короли). Видно обоим.",
     "pawn", "pawnFuse", False),
    # knight / bishop shared
    ("knightMaskSwap", "knight", "Смена масок",
     "Выбранная лёгкая фигура после каждого своего хода чередует тип: конь ↔ слон.",
     "knight", "maskSwap", False),
    ("bishopMaskSwap", "bishop", "Смена масок 1",
     "Выбранная лёгкая фигура после каждого своего хода чередует тип: слон ↔ конь.",
     "bishop", "maskSwap", False),
    ("knightNonAggression", "knight", "Пакт о ненападении",
     "Выберите свою и вражескую лёгкие фигуры: они не атакуют друг друга, но бьют остальных и их бьют остальные.",
     "knight", "nonAggression", False),
    ("bishopNonAggression", "bishop", "Пакт о ненападении 1",
     "Выберите свою и вражескую лёгкие фигуры: они не атакуют друг друга, но бьют остальных и их бьют остальные.",
     "bishop", "nonAggression", False),
    ("knightKingGuard", "knight", "Гвардия короля",
     "При шахе выбранная лёгкая фигура автоматически съедает шахующую или закрывается, если может — это не тратит ваш ход.",
     "knight", "kingGuardAuto", False),
    ("bishopKingGuard", "bishop", "Гвардия короля 1",
     "При шахе выбранная лёгкая фигура автоматически съедает шахующую или закрывается, если может — это не тратит ваш ход.",
     "bishop", "kingGuardAuto", False),
    # knight
    ("knightNightWatch", "knight", "Ночной дозор коня",
     "Только при тумане войны: выбранный конь видит всё в радиусе 2 клеток сквозь туман.",
     "knight", "knightNightWatch", False),
    ("knightGallopContract", "knight", "Контракт галопа",
     "Объявите 3 клетки маршрута. Если выбранный конь проходит их по порядку, гибнет случайная вражеская не-король фигура.",
     "knight", "knightGallopContract", False),
    ("knightTangledTrail", "knight", "Запутанный след",
     "Выбранный конь на один ход раздваивается: выбираются 2 клетки назначения. На следующем ходу оставляете одного коня.",
     "knight", "knightTangledTrail", False),
    ("knightCustomsPath", "knight", "Таможенный досмотр",
     "При ходе конём выбираете один из двух маршрутов прыжка; с врагов на маршруте снимается случайный мод. Маршрут виден как линия.",
     "knight", "knightCustomsPath", False),
    ("knightBucephalus", "knight", "Буцефал",
     "Если выбранный конь съест 3 вражеские фигуры, ваш король один раз за партию сможет сходить как конь.",
     "knight", "knightBucephalus", False),
    ("knightHoofSmoke", "knight", "Дым из под копыт",
     "Все клетки, на которых отныне стоит выбранный конь, покрыты туманом для обоих игроков.",
     "knight", "knightHoofSmoke", False),
    ("knightDonkey", "knight", "Осёл",
     "Клетки, которые посетит выбранный конь, увязывают фигуру на 1 ход (как «болото»).",
     "knight", "knightDonkey", False),
    # bishop
    ("bishopInkTrail", "bishop", "Чернильный след",
     "После хода выбранным слоном по клеткам пути 1 ход вражеские пешки не могут туда встать.",
     "bishop", "bishopInkTrail", False),
    ("bishopGanesha", "bishop", "Ганеша",
     "После хода выбранным слоном он становится ладьёй, затем снова слоном — и так чередуется.",
     "bishop", "bishopGanesha", False),
    ("bishopHeretic", "bishop", "Еретик",
     "Только если ваших фигур меньше, чем у врага: выбранный слон распадается на 4 пешки на вашей половине поля.",
     "bishop", "bishopHeretic", False),
    ("bishopRelicPower", "bishop", "Сила мощей",
     "Если выбранного слона взяли, у вас 3 полухода: встаньте на клетку смерти и уйдите — слон возродится без модов.",
     "bishop", "bishopRelicPower", False),
    ("bishopBlindingSacristy", "bishop", "Слепящая ризница",
     "Взятие выбранным слоном ослепляет клетку: следующий, кто туда встанет (не этот слон), не бьёт 1 ход.",
     "bishop", "bishopBlindingSacristy", False),
    ("bishopLayman", "bishop", "Мирянин",
     "Выбранный слон не бьёт пешек; пешки не бьют его.",
     "bishop", "bishopLayman", False),
    ("bishopProcession", "bishop", "Процессия",
     "Ход выбранного слона может сдвинуть одну союзную пешку на диагонали на 1 вдоль того же луча, если свободно.",
     "bishop", "bishopProcession", False),
    ("bishopSchism", "bishop", "Церковный раскол",
     "Выбранный слон делится на 2 полуслона: каждый ходит только по одной из двух диагоналей.",
     "bishop", "bishopSchism", False),
    ("bishopLambs", "bishop", "Агнцы",
     "Выбранный слон защищает все фигуры в радиусе 1 от катаклизмов (например, метеоритного дождя).",
     "bishop", "bishopLambs", False),
    ("bishopCartographer", "bishop", "Картограф",
     "Только при тумане войны: слон отмечает клетку на своей диагонали — с неё навсегда снимается туман для вас.",
     "bishop", "bishopCartographer", False),
    # rook
    ("rookSeal", "rook", "Пломба",
     "Выбранная ладья выбирает атакуемую вражескую не-король фигуру: та не ходит, пока ладья жива или пока ладья не сделала ход.",
     "rook", "rookSeal", False),
    ("rookIllDrive", "rook", "Довезу",
     "Когда выбранная ладья в следующий раз сходит и затем уйдёт с конечной клетки, между стартом и финишем образуется портал.",
     "rook", "rookIllDrive", False),
    ("rookCannotHide", "rook", "Не скроешь",
     "Только если соперник скрывает моды: выбранная ладья раскрывает моды фигур на своей горизонтали и вертикали.",
     "rook", "rookCannotHide", False),
    # queen
    ("queenCourtIntrigue", "queen", "Придворные интриги",
     "Выбранный ферзь помечает вражескую не-король фигуру вне радиуса 2 от её короля: пока ферзь жив, она не может подойти к своему королю ближе чем на 2.",
     "queen", "queenCourtIntrigue", False),
    ("queenFatherDream", "queen", "Которая и не снилась моему отцу",
     "Если выбранный ферзь получит 5 усиливающих модов, вы сразу побеждаете.",
     "queen", "queenFatherDream", False),
    # king
    ("kingOwnHands", "king", "Своими руками",
     "Если ваш король окажется в радиусе 2 клеток от вражеского короля — вы побеждаете. Мод может быть только у одного игрока.",
     "king", "kingOwnHands", False),
    # mode
    ("modeHolyRandom", "mode", "Святой рандом",
     "Актуален для обоих. После хода фигура с вероятностью 25% меняет тип (тот же цвет). Король не меняется и никто не становится королём.",
     None, None, True),
    ("modeZooShuffle", "mode", "Перетасовка в зоопарке",
     "У каждого игрока кони и слоны меняются местами: кони на c и f, слоны на b и g.",
     None, None, True),
    ("modeInsatiableHunger", "mode", "Неутолимый голод",
     "Ферзи обоих игроков должны брать фигуру каждые 5 своих ходов, иначе погибают. Можно брать и своих, кроме короля.",
     None, None, True),
    ("modeComeOn", "mode", "Давай, давай",
     "Фигура, которая первой на доске сделает взятие, сразу получает мод вне зачёта.",
     None, None, True),
    ("modeVolcano", "mode", "Вулкан",
     "Каждые 2 полных хода на 2 видимых случайных клетках взрывается вулкан, уничтожая фигуру. Затем выбираются новые клетки.",
     None, None, True),
    # board
    ("boardRestlessKings", "board", "Не сидится на месте",
     "В течение 3 следующих полуходов короли обоих игроков должны покинуть свои клетки, иначе проигрывают.",
     None, None, True),
    # cataclysm
    ("randomWarehouse", "random", "Склад",
     "Следующий мод, который соперник потеряет с фигуры, вы можете передать своей фигуре того же типа (если есть); иначе ждёте подходящий.",
     None, None, True),
    ("randomTwilightEclipse", "random", "Сумерки. Сага. Затмение",
     "Случайные 4 ваши фигуры становятся невидимыми для противника на 10 ваших полуходов.",
     None, None, True),
    ("randomGestureMirror", "random", "Зеркало жестов",
     "Следующий ход соперника после вашего должен закончиться на клетке того же цвета, что и ваш последний ход.",
     None, None, True),
    ("randomBlackMark", "random", "Чёрная метка",
     "Случайная вражеская фигура получает метку: следующее ваше взятие этой фигуры даёт два выбора модов подряд.",
     None, None, True),
]


def insert_before(text: str, marker: str, insertion: str) -> str:
    if marker not in text:
        raise SystemExit(f"Marker not found: {marker!r}")
    return text.replace(marker, insertion + marker, 1)


def main() -> None:
    ga_path = ROOT / "lib/l10n/models/game_ability.dart"
    ef_path = ROOT / "lib/l10n/models/ability_effects.dart"
    cat_path = ROOT / "lib/l10n/models/ability_catalog.dart"

    ga = ga_path.read_text(encoding="utf-8")
    ef = ef_path.read_text(encoding="utf-8")
    cat = cat_path.read_text(encoding="utf-8")

    existing = set()
    for line in ga.splitlines():
        line = line.strip()
        if line.endswith(",") and not line.startswith("//") and " " not in line.split(",")[0]:
            name = line.rstrip(",").strip()
            if name and name[0].islower():
                existing.add(name)

    new = [a for a in ABILITIES if a[0] not in existing]
    if not new:
        print("All abilities already present")
        return

    # --- enum inserts by group ---
    by_group: dict[str, list] = {}
    for a in new:
        by_group.setdefault(a[1], []).append(a)

    enum_anchors = {
        "mode": "  modeDuckChess,\n",
        "board": "  boardEarnedRest,\n",
        "pawn": "  pawnFaceControl,\n",
        "knight": "  knightSignalFire,\n",
        "bishop": "  bishopSignalFire,\n",
        "rook": "  rookSignalFire,\n",
        "queen": "  queenYouShallNotPass,\n",
        "king": "  kingAssemblyHall,\n",
        "random": "  randomTwentyOne,\n",
    }
    for group, items in by_group.items():
        block = "".join(f"  {name},\n" for name, *_ in items)
        # insert AFTER the anchor line
        anchor = enum_anchors[group]
        if anchor not in ga:
            raise SystemExit(f"Enum anchor missing for {group}: {anchor!r}")
        ga = ga.replace(anchor, anchor + block, 1)

    # --- group switch ---
    group_case_map = {
        "mode": "      case GameAbility.modeDuckChess:\n        return AbilityGroup.mode;",
        "board": "      case GameAbility.boardEarnedRest:\n        return AbilityGroup.board;",
        "pawn": None,  # find pawnFaceControl in pawn group
        "knight": None,
        "bishop": None,
        "rook": None,
        "queen": None,
        "king": None,
        "random": None,
    }
    # Simpler: insert cases before return AbilityGroup.X after last known case of that group
    group_insert_markers = {
        "mode": ("      case GameAbility.modeDuckChess:\n", "        return AbilityGroup.mode;"),
        "board": ("      case GameAbility.boardEarnedRest:\n", "        return AbilityGroup.board;"),
        "pawn": ("      case GameAbility.pawnFaceControl:\n", "        return AbilityGroup.pawn;"),
        "knight": ("      case GameAbility.knightSignalFire:\n", "        return AbilityGroup.knight;"),
        "bishop": ("      case GameAbility.bishopSignalFire:\n", "        return AbilityGroup.bishop;"),
        "rook": ("      case GameAbility.rookSignalFire:\n", "        return AbilityGroup.rook;"),
        "queen": ("      case GameAbility.queenYouShallNotPass:\n", "        return AbilityGroup.queen;"),
        "king": ("      case GameAbility.kingAssemblyHall:\n", "        return AbilityGroup.king;"),
        "random": ("      case GameAbility.randomTwentyOne:\n", "        return AbilityGroup.random;"),
    }
    for group, items in by_group.items():
        first, second = group_insert_markers[group]
        marker = first + second
        cases = "".join(f"      case GameAbility.{name}:\n" for name, *_ in items)
        if marker not in ga:
            # try multi-line with only last case before return
            # find `case GameAbility.LAST:\n        return AbilityGroup.GROUP;`
            last_name = {
                "mode": "modeDuckChess",
                "board": "boardEarnedRest",
                "pawn": "pawnFaceControl",
                "knight": "knightSignalFire",
                "bishop": "bishopSignalFire",
                "rook": "rookSignalFire",
                "queen": "queenYouShallNotPass",
                "king": "kingAssemblyHall",
                "random": "randomTwentyOne",
            }[group]
            marker2 = f"      case GameAbility.{last_name}:\n        return AbilityGroup.{group};"
            if marker2 not in ga:
                raise SystemExit(f"Group marker missing for {group}")
            ga = ga.replace(
                marker2,
                f"      case GameAbility.{last_name}:\n"
                + cases
                + f"        return AbilityGroup.{group};",
                1,
            )
        else:
            ga = ga.replace(
                marker,
                first + cases + second,
                1,
            )

    # --- titles ---
    title_marker = "      case GameAbility.randomTwentyOne:\n        return 'Двадцать одно';"
    # Insert all new titles before end of title switch - find last title case
    # We'll insert after kingAssemblyHall title and after randomTwentyOne etc.
    for name, group, title, desc, piece, effect, board_wide in new:
        needle = None
        # insert before closing of title getter - after matching sibling
        pass

    # Append titles by inserting before a unique end sentinel in title switch.
    # Find `String get title` section end via first ability that we know is last alphabetically in file order: randomTwentyOne
    last_title = "      case GameAbility.randomTwentyOne:\n        return 'Двадцать одно';"
    if last_title not in ga:
        # search flexibly
        idx = ga.find("case GameAbility.randomTwentyOne:")
        if idx < 0:
            raise SystemExit("title randomTwentyOne missing")
        end = ga.find(";", idx)
        last_title = ga[idx : end + 1]
        # include leading spaces and return line
        line_start = ga.rfind("\n", 0, idx) + 1
        last_title = ga[line_start : end + 1]

    title_block = "\n".join(
        f"      case GameAbility.{name}:\n        return '{title}';"
        for name, group, title, *_ in new
    )
    ga = ga.replace(last_title, last_title + "\n" + title_block, 1)

    # --- descriptions (String get description, not descriptionFor) ---
    desc_getter = ga.find("  String get description {")
    if desc_getter < 0:
        raise SystemExit("description getter missing")
    idx = ga.find("case GameAbility.randomTwentyOne:", desc_getter)
    if idx < 0:
        raise SystemExit("desc randomTwentyOne missing")
    line_start = ga.rfind("\n", 0, idx) + 1
    end = ga.find("\n    }", idx)
    last_desc_block = ga[line_start:end]
    desc_block = "\n".join(
        f"      case GameAbility.{name}:\n        return '{desc}';"
        for name, group, title, desc, *_ in new
    )
    ga = ga.replace(last_desc_block, last_desc_block + "\n" + desc_block, 1)

    # --- preferred piece type ---
    piece_insert_after = {
        "pawn": "      case GameAbility.pawnFaceControl:\n",
        "knight": "      case GameAbility.knightSignalFire:\n",
        "bishop": "      case GameAbility.bishopSignalFire:\n",
        "rook": "      case GameAbility.rookSignalFire:\n",
        "queen": "      case GameAbility.queenYouShallNotPass:\n",
        "king": "      case GameAbility.kingAssemblyHall:\n",
    }
    for piece, anchor in piece_insert_after.items():
        items = [a for a in new if a[4] == piece]
        if not items:
            continue
        if anchor not in ga:
            raise SystemExit(f"primaryPieceType anchor missing: {piece}")
        cases = "".join(f"      case GameAbility.{name}:\n" for name, *_ in items)
        ga = ga.replace(anchor, anchor + cases, 1)

    # null piece types (board/mode/random)
    null_items = [a for a in new if a[4] is None]
    if null_items:
        anchor = "      case GameAbility.modeDuckChess:\n"
        if anchor not in ga:
            raise SystemExit("null piece type anchor missing")
        # only first occurrence in primaryPieceType (after king return)
        pt = ga.find("PieceType? get primaryPieceType")
        idx = ga.find(anchor, pt)
        if idx < 0:
            raise SystemExit("modeDuckChess in primaryPieceType missing")
        cases = "".join(f"      case GameAbility.{name}:\n" for name, *_ in null_items)
        ga = ga[:idx] + cases + ga[idx:]

    # --- isBoardWide ---
    bw_items = [a for a in new if a[6]]
    if bw_items:
        m = "      this == GameAbility.boardEarnedRest ||\n"
        if m in ga:
            extra = "".join(f"      this == GameAbility.{name} ||\n" for name, *_ in bw_items)
            ga = ga.replace(m, m + extra, 1)
        else:
            m2 = "this == GameAbility.modeDuckChess ||"
            if m2 in ga:
                extra = "\n".join(f"      this == GameAbility.{name} ||" for name, *_ in bw_items)
                ga = ga.replace(m2, m2 + "\n" + extra, 1)

    ga_path.write_text(ga, encoding="utf-8")

    # --- ability_effects.dart ---
    effects_needed = []
    seen_eff = set()
    for name, group, title, desc, piece, effect, board_wide in new:
        if effect and effect not in seen_eff:
            seen_eff.add(effect)
            effects_needed.append(effect)

    # insert enum effects before closing of AbilityEffect enum (before assemblyHall,)
    eff_anchor = "  assemblyHall,\n}"
    if eff_anchor not in ef:
        eff_anchor = "  assemblyHall,\n}\n"
    eff_block = "".join(f"  {e},\n" for e in effects_needed)
    if eff_anchor in ef:
        ef = ef.replace(eff_anchor, eff_block + eff_anchor.replace(eff_block, ""), 1)
        # fix if duplicated - simpler:
    ef = ef_path.read_text(encoding="utf-8")
    if "pawnArchivist" not in ef:
        ef = ef.replace(
            "  assemblyHall,\n}",
            "  assemblyHall,\n" + "".join(f"  {e},\n" for e in effects_needed) + "}",
            1,
        )

    # mapping: add piece-bound before empty return cluster
    map_lines = []
    for name, group, title, desc, piece, effect, board_wide in new:
        if effect:
            map_lines.append(
                f"      case GameAbility.{name}:\n        return {{AbilityEffect.{effect}}};"
            )
        else:
            map_lines.append(f"      case GameAbility.{name}:")
    # empty ones need to join the return {} group
    with_eff = [a for a in new if a[5]]
    without = [a for a in new if not a[5]]
    map_block = "\n".join(
        f"      case GameAbility.{name}:\n        return {{AbilityEffect.{effect}}};"
        for name, group, title, desc, piece, effect, board_wide in with_eff
    )
    empty_cases = "".join(f"      case GameAbility.{name}:\n" for name, *_ in without)
    # insert map_block before `case GameAbility.randomSnailTrail:` empty group or at end before closing
    insert_at = "      case GameAbility.randomTwentyOne:\n        return {};"
    if insert_at in ef:
        ef = ef.replace(
            insert_at,
            map_block + "\n" + empty_cases + "      case GameAbility.randomTwentyOne:\n        return {};",
            1,
        )
    else:
        # append before final closing of switch
        ef = ef.replace(
            "        return {};\n    }\n  }\n}",
            map_block
            + "\n"
            + empty_cases
            + "        return {};\n    }\n  }\n}",
            1,
        )

    ef_path.write_text(ef, encoding="utf-8")

    # --- catalog lists ---
    list_anchors = {
        "mode": "    GameAbility.modeDuckChess,\n  ];",
        "board": "    GameAbility.boardEarnedRest,\n  ];",
        "random": "    GameAbility.randomTwentyOne,\n  ];",
        "pawn": "    GameAbility.pawnFaceControl,\n  ];",
        "knight": "    GameAbility.knightSignalFire,\n  ];",
        "bishop": "    GameAbility.bishopSignalFire,\n  ];",
        "rook": "    GameAbility.rookSignalFire,\n  ];",
        "queen": "    GameAbility.queenYouShallNotPass,\n  ];",
        "king": "    GameAbility.kingAssemblyHall,\n  ];",
    }
    for group, items in by_group.items():
        anchor = list_anchors[group]
        if anchor not in cat:
            print(f"WARN: catalog list anchor missing for {group}")
            continue
        block = "".join(f"    GameAbility.{name},\n" for name, *_ in items)
        cat = cat.replace(anchor, block + anchor, 1)

    # target selections
    target_inserts = """
      case GameAbility.pawnStarvation:
      case GameAbility.knightNonAggression:
      case GameAbility.bishopNonAggression:
      case GameAbility.queenCourtIntrigue:
      case GameAbility.rookSeal:
        return AbilityTargetSelection.enemyPiece;
      case GameAbility.pawnPairStep:
      case GameAbility.bishopProcession:
        return AbilityTargetSelection.friendlyPiece;
      case GameAbility.knightGallopContract:
      case GameAbility.bishopCartographer:
      case GameAbility.bishopHeretic:
        return AbilityTargetSelection.cell;
"""
    cat = cat.replace(
        "      default:\n        return AbilityTargetSelection.none;",
        target_inserts + "      default:\n        return AbilityTargetSelection.none;",
        1,
    )

    # eligibility filters
    filt = """
    if (!fogOfWarActive) {
      pool
        ..remove(GameAbility.knightNightWatch)
        ..remove(GameAbility.bishopCartographer);
    }
    if (!minesActive) {
      pool.remove(GameAbility.pawnSapper);
    }
"""
    # only add once near existing fog filter
    if "knightNightWatch" not in cat:
        cat = cat.replace(
            "        ..remove(GameAbility.rookSignalTower);\n    }",
            "        ..remove(GameAbility.rookSignalTower)\n"
            "        ..remove(GameAbility.knightNightWatch)\n"
            "        ..remove(GameAbility.bishopCartographer);\n    }",
            1,
        )
        cat = cat.replace(
            "    if (!minesActive) {\n      pool.remove(GameAbility.pawnForTheKing);\n    }",
            "    if (!minesActive) {\n      pool.remove(GameAbility.pawnForTheKing);\n"
            "      pool.remove(GameAbility.pawnSapper);\n    }",
            1,
        )

    cat_path.write_text(cat, encoding="utf-8")
    print(f"Added {len(new)} abilities:")
    for name, *_ in new:
        print(" ", name)


if __name__ == "__main__":
    main()
