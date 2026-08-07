#!/usr/bin/env python3
"""Apply priority title/description overrides into game_ability.dart."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
dart = ROOT / 'lib' / 'l10n' / 'models' / 'game_ability.dart'
mods = ROOT / 'docs' / 'modifications.txt'

text = dart.read_text(encoding='utf-8')

# Parse modifications.txt
entries = {}
cur_id = None
cur_title = None
cur_desc_lines = []
for line in mods.read_text(encoding='utf-8').splitlines():
    m = re.match(r'^\d+\.\s+(.+)$', line)
    if m and not line.strip().startswith('id:'):
        if cur_id and cur_title is not None:
            desc = ' '.join(cur_desc_lines).strip()
            if desc:
                entries[cur_id] = (cur_title, desc)
        cur_title = m.group(1).strip()
        cur_id = None
        cur_desc_lines = []
        continue
    m = re.match(r'^\s+id:\s+(\w+)\s*$', line)
    if m:
        cur_id = m.group(1)
        continue
    if cur_id and line.startswith('   ') and not line.strip().startswith('id:'):
        cur_desc_lines.append(line.strip())
if cur_id and cur_title is not None:
    desc = ' '.join(cur_desc_lines).strip()
    if desc:
        entries[cur_id] = (cur_title, desc)

# Chat overrides (highest priority)
overrides = {
    'modeTimeZone': (
        'Часовая зона',
        # description getter stays neutral; descriptionFor handles colors
        'В нечётные ходы фигуры белых ходят как обычно, а чёрных — максимум на 1 клетку; в чётные — наоборот.',
    ),
    'modeMateVeto': (
        'Статист',
        'Тайно выберите вражескую фигуру — она не может поставить мат (атаковать клетку короля можно).',
    ),
    'modeDebtPit': (
        'Долговая яма',
        'Взятие вражеских фигур увеличивает ваш долг на 1, а потеря фигуры — уменьшает на 1. При долге 6 — проигрыш.',
    ),
    'modeWasteland': (
        'Бесплодные земли',
        'После хода Вы оставляете бесплодную землю — вражеская фигура, ступившая на клетку, пропускает следующий ход.',
    ),
    'modeBus': (
        'Автобус',
        'В случае пата выигрывает игрок, у которого меньше фигур на доске.',
    ),
    'modeShopToken': (
        'Во имя высшей цели',
        'Игроки могут продать одну свою фигуру за жетон. Жетон тратится на отмену одного вашего хода.',
    ),
    'modeSeasons': (
        'Времена года',
        'Каждые 6 ходов меняется погода: вначале Вулкан.',
    ),
    'boardLavaRank': (
        'Пол — это лава',
        'Случайная горизонталь покрывается лавой',
    ),
    'boardExtraFile': (
        'Новая вертикаль',
        'Появляется новая вертикаль',
    ),
}
entries.update(overrides)

def esc(s: str) -> str:
    return s.replace("\\", "\\\\").replace("'", "\\'")


def replace_case_return(getter_start: str, getter_end: str, ability: str, new_value: str) -> None:
    global text
    start = text.find(getter_start)
    end = text.find(getter_end, start + 1)
    if start < 0 or end < 0:
        raise SystemExit(f'missing getter range {getter_start}')
    chunk = text[start:end]
    pat = rf"(case GameAbility\.{ability}:\s*\n\s*return )((?:'[^']*'\s*)+);"

    def repl(m):
        return m.group(1) + f"'{esc(new_value)}';"

    new_chunk, n = re.subn(pat, repl, chunk, count=1)
    if n != 1:
        # try multiline already single
        print('WARN no replace', ability, getter_start[:20])
        return
    text = text[:start] + new_chunk + text[end:]


for ability, (title, desc) in entries.items():
    replace_case_return('String get title {', 'String get description {', ability, title)
    replace_case_return('String get description {', 'PieceType? get primaryPieceType', ability, desc)

dart.write_text(text, encoding='utf-8')
print(f'updated {len(entries)} abilities')
