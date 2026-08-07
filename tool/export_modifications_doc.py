#!/usr/bin/env python3
"""Rebuild docs/modifications.txt from game_ability.dart titles/descriptions/groups."""
from __future__ import annotations

import re
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
src = (ROOT / 'lib/l10n/models/game_ability.dart').read_text(encoding='utf-8')

enums = re.findall(
    r'^\s+(board\w+|mode\w+|pawn\w+|knight\w+|bishop\w+|rook\w+|queen\w+|king\w+|random\w+),',
    src,
    re.M,
)


def extract_map(start_marker: str, end_marker: str) -> dict[str, str]:
    start = src.find(start_marker)
    end = src.find(end_marker, start + 1)
    chunk = src[start:end]
    out: dict[str, str] = {}
    for m in re.finditer(
        r"case GameAbility\.(\w+):\s*\n\s*return ((?:'[^']*'\s*)+);",
        chunk,
    ):
        out[m.group(1)] = ''.join(re.findall(r"'([^']*)'", m.group(2)))
    return out


titles = extract_map('String get title {', 'String get description {')
descs = extract_map('String get description {', 'PieceType? get primaryPieceType')

# Parse primary group switch
group_of: dict[str, str] = {}
gstart = src.find('AbilityGroup get group {')
gend = src.find('Set<AbilityGroup> get catalogGroups', gstart)
gchunk = src[gstart:gend]
current: list[str] = []
for line in gchunk.splitlines():
    m = re.match(r'\s+case GameAbility\.(\w+):', line)
    if m:
        current.append(m.group(1))
        continue
    m = re.match(r'\s+return AbilityGroup\.(\w+);', line)
    if m and current:
        label = {
            'mode': 'Режим',
            'board': 'Доска',
            'pawn': 'Пешка',
            'knight': 'Конь',
            'bishop': 'Слон',
            'rook': 'Ладья',
            'queen': 'Ферзь',
            'king': 'Король',
            'random': 'Катаклизм',
        }[m.group(1)]
        for name in current:
            group_of[name] = label
        current = []

# Extra shelves from catalogGroups
extra: dict[str, set[str]] = defaultdict(set)
cstart = src.find('Set<AbilityGroup> get catalogGroups')
cend = src.find('String get title {', cstart)
cchunk = src[cstart:cend]
# boardKingSwap -> king, rook; boardCavalry -> pawn, knight
extra['boardKingSwap'].update(['Король', 'Ладья'])
extra['boardCavalry'].update(['Пешка', 'Конь'])

order = ['Режим', 'Доска', 'Пешка', 'Конь', 'Слон', 'Ладья', 'Ферзь', 'Король', 'Катаклизм']
by: dict[str, list[str]] = defaultdict(list)
seen_in: dict[str, set[str]] = defaultdict(set)
for name in enums:
    shelves = {group_of.get(name, 'Прочее')} | extra.get(name, set())
    for s in shelves:
        if name not in seen_in[s]:
            by[s].append(name)
            seen_in[s].add(name)

gem = (ROOT / 'lib/chess/game_end_messages.dart').read_text(encoding='utf-8')
reasons = []
for m in re.finditer(
    r"\(\s*id: '([^']+)',\s*title: '([^']+)',\s*body:\s*((?:'[^']*'\s*)+),?\s*\)",
    gem,
    re.S,
):
    body = ''.join(re.findall(r"'([^']*)'", m.group(3)))
    reasons.append((m.group(1), m.group(2), body))

lines = [
    'Моды SuperChess',
    f'Всего уникальных: {len(enums)}',
    '',
    'Источник: lib/l10n/models/game_ability.dart (названия и описания).',
    'Моды в нескольких группах — один и тот же мод (без удвоения шанса выпадения).',
    '',
]
for g in order:
    items = by.get(g) or []
    if not items:
        continue
    lines.append(f'=== {g} ({len(items)}) ===')
    lines.append('')
    for i, name in enumerate(items, 1):
        title = titles.get(name, name)
        desc = descs.get(name, '(см. в игре)')
        lines.append(f'{i}. {title}')
        lines.append(f'   id: {name}')
        lines.append(f'   {desc}')
        lines.append('')

lines.append('=== Причины окончания партии ===')
lines.append('')
for i, (rid, title, body) in enumerate(reasons, 1):
    lines.append(f'{i}. {title} ({rid})')
    lines.append(f'   {body}')
    lines.append('')

(ROOT / 'docs/modifications.txt').write_text('\n'.join(lines), encoding='utf-8')
print('groups', {k: len(v) for k, v in by.items() if v})
print('ok', len(enums))
