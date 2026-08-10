import json
import re
from pathlib import Path

text = Path("lib/l10n/models/game_ability.dart").read_text(encoding="utf-8")


def extract_switch(getter_name: str) -> dict[str, str]:
    m = re.search(rf"String get {getter_name} \{{", text)
    if not m:
        return {}
    start = m.end()
    depth = 1
    i = start
    while i < len(text) and depth:
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
        i += 1
    body = text[start:i]
    cases: dict[str, str] = {}
    for cm in re.finditer(
        r"case GameAbility\.(\w+):\s*return\s*((?:'(?:\\.|[^'\\])*'|\s*\+\s*)+);",
        body,
        re.S,
    ):
        name = cm.group(1)
        lit = cm.group(2)
        parts = re.findall(r"'((?:\\.|[^'\\])*)'", lit)
        s = "".join(parts)
        s = (
            s.replace(r"\\", "\0")
            .replace(r"\'", "'")
            .replace(r"\n", "\n")
            .replace("\0", "\\")
        )
        cases[name] = s
    return cases


titles = extract_switch("title")
descs = extract_switch("description")
out = Path("tool/abilities_ru.json")
out.write_text(
    json.dumps({"titles": titles, "descriptions": descs}, ensure_ascii=False, indent=2),
    encoding="utf-8",
)
print("titles", len(titles), "descs", len(descs), "->", out)
