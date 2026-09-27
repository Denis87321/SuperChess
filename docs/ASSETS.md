# Ассеты и визуал SuperChess

## Шахматные фигуры (доска)

**Визуал наших шахматных фигур взят из набора Caliente проекта Lichess.**

| | |
|---|---|
| **Источник** | [lichess-org/lila — `public/piece/caliente`](https://github.com/lichess-org/lila/tree/master/public/piece/caliente) |
| **Набор** | Caliente |
| **Автор набора** | [avi](https://github.com/avi-0/caliente) |
| **Лицензия** | [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) |
| **Файлы в репозитории** | `assets/pieces/caliente/` (`wP`…`wK`, `bP`…`bK` — SVG) |
| **Использование в коде** | `lib/widgets/chess_piece_widget.dart` → `ChessPieceWidget.assetFor` |

Именно эти SVG (пешка, конь, слон, ладья, ферзь, король — белые и чёрные) отображаются на доске в клиенте Flutter. Копия лицензии лежит рядом с ассетами: `assets/pieces/caliente/LICENSE.txt`.

### Что мы взяли

- Внешний вид (графику) всех 12 стандартных фигур набора **Caliente** из указанного каталога Lichess.
- Файлы без изменения стиля набора; подключение — через `flutter_svg` и путь `assets/pieces/caliente/…`.

### Что не из Caliente

- Доска, UI, эффекты модов, анимации и прочий визуал приложения — собственные или из других источников (не Caliente).
- Правила, моды и игровая логика SuperChess к этому набору не относятся.

### Атрибуция (кратко)

При распространении клиента / сборок с этими фигурами сохраняйте указание источника и лицензии CC BY-NC-SA 4.0 (см. `LICENSE.txt` в папке ассетов).
