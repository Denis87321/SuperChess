import re
from pathlib import Path
from collections import defaultdict

src = Path('lib/l10n/models/game_ability.dart').read_text(encoding='utf-8')
enums = re.findall(
    r'^\s+(board\w+|mode\w+|pawn\w+|knight\w+|bishop\w+|rook\w+|queen\w+|king\w+|random\w+),',
    src,
    re.M,
)


def extract_map(start_marker: str, end_marker: str | None = None) -> dict[str, str]:
    start = src.find(start_marker)
    if start < 0:
        return {}
    end = len(src)
    if end_marker:
        e = src.find(end_marker, start + len(start_marker))
        if e > 0:
            end = e
    chunk = src[start:end]
    out = {}
    for m in re.finditer(
        r"case GameAbility\.(\w+):\s*\n\s*return '([^']+)';",
        chunk,
    ):
        out[m.group(1)] = m.group(2)
    # also multi-line returns: return 'a' 'b';
    for m in re.finditer(
        r"case GameAbility\.(\w+):\s*\n\s*return ((?:'[^']*'\s*)+);",
        chunk,
    ):
        name = m.group(1)
        if name in out:
            continue
        parts = re.findall(r"'([^']*)'", m.group(2))
        if parts:
            out[name] = ''.join(parts)
    return out


title_map = extract_map('String get title {', 'String get description')
desc_map = extract_map('String get description {', 'PieceType? get primaryPieceType')
if len(desc_map) < 50:
    desc_map = extract_map('String get description {', 'String descriptionFor')

# (removed old desc_start block)


def group_of(name: str) -> str:
    if name.startswith('board'):
        return 'Доска'
    if name.startswith('mode'):
        return 'Режим'
    if name.startswith('pawn'):
        return 'Пешка'
    if name.startswith('knight'):
        return 'Конь'
    if name.startswith('bishop'):
        return 'Слон'
    if name.startswith('rook'):
        return 'Ладья'
    if name.startswith('queen'):
        return 'Ферзь'
    if name.startswith('king'):
        return 'Король'
    if name.startswith('random'):
        return 'Катаклизм'
    return 'Прочее'


ordered_groups = [
    'Режим',
    'Доска',
    'Пешка',
    'Конь',
    'Слон',
    'Ладья',
    'Ферзь',
    'Король',
    'Катаклизм',
    'Прочее',
]
by = defaultdict(list)
for name in enums:
    by[group_of(name)].append(name)

gem = Path('lib/chess/game_end_messages.dart').read_text(encoding='utf-8')
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
    f'Всего: {len(enums)}',
    '',
    'Актуальные названия и описания из кода (GameAbility).',
    'Поведение в партии: lib/chess/chess_game.dart и board_cataclysm_state.dart.',
    '',
]
for g in ordered_groups:
    items = by.get(g) or []
    if not items:
        continue
    lines.append(f'=== {g} ({len(items)}) ===')
    lines.append('')
    for i, name in enumerate(items, 1):
        title = title_map.get(name, name)
        desc = desc_map.get(name, '(описание см. в игре / descriptionFor)')
        lines.append(f'{i}. {title}')
        lines.append(f'   id: {name}')
        lines.append(f'   {desc}')
        lines.append('')

lines.append('=== Причины окончания партии ===')
lines.append('')
lines.append(
    'В UI: справа в панели ходов (счёт + формулировка). API: reason + reasonDetail.'
)
lines.append('')
for i, (rid, title, body) in enumerate(reasons, 1):
    lines.append(f'{i}. {title} ({rid})')
    lines.append(f'   {body}')
    lines.append('')

Path('docs/modifications.txt').write_text('\n'.join(lines), encoding='utf-8')
print('titles', len(title_map), 'descs', len(desc_map), 'reasons', len(reasons))
print('sample', title_map.get('modeTimeZone'), '|', (desc_map.get('modeTimeZone') or '')[:60])
