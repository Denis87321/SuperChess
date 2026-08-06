# Hosting SuperChess (бесплатно)

## Архитектура

- **Сайт**: Flutter Web (папка `public/` в git) → **Render Static Site**
- **Сервер**: Dart (WebSocket + auth HTTP) → **Render Web Service** `wss://superchess-api.onrender.com/ws`
- **БД**: Render Postgres (`DATABASE_URL`) для аккаунтов (ник + пароль)
- Cloudflare Pages лучше не использовать как основной сайт из РФ (часто нужен VPN)

## Важно: API на Render засыпает

Web Service на free **засыпает ~после 15 минут**. Первый «Онлайн» после сна может ждать **30–60 секунд**. Статический сайт обычно открывается сразу.

---

## 1. Postgres + API

В [render.yaml](../render.yaml) уже описаны `superchess-db` и `DATABASE_URL` / `JWT_SECRET` для `superchess-api`.

Если сервисы создавались вручную раньше:

1. Dashboard → **New → PostgreSQL** (free), регион как у API.
2. У Web Service `superchess-api` → Environment:
   - `DATABASE_URL` = Internal Database URL из Postgres
   - `JWT_SECRET` = длинная случайная строка
3. **Manual Deploy** API после пуша.

Проверка:

- `https://superchess-api.onrender.com/health` → `{"ok":true,"auth":true}`  
  (`auth:false` = нет БД / ошибка подключения)

Auth endpoints:

- `POST /auth/register` `{ "username", "password" }`
- `POST /auth/login` `{ "username", "password" }`
- `GET /auth/me` + header `Authorization: Bearer <token>`

Без `DATABASE_URL` матчмейкинг работает, регистрация отвечает **503**.

---

## 2. Сайт на Render (без Flutter на сервере)

На Render **нет** команды `flutter`. Сайт собирается **у тебя на ПК**, результат кладётся в `public/` и пушится в GitHub.

### После изменений UI / Stockfish

Одна команда (сборка → `public/`):

```powershell
cd C:\Users\SRV\Documents\Proga\SuperChess
.\scripts\build_web.ps1
```

Сразу закоммитить и запушить на GitHub (Render подхватит `public/`):

```powershell
.\scripts\build_web.ps1 -Push -Message "Publish web"
```

### Вручную (то же самое)

```powershell
cd C:\Users\SRV\Documents\Proga\SuperChess
flutter build web --release --dart-define=SUPERCHESS_SERVER_URL=wss://superchess-api.onrender.com/ws

if (Test-Path public) { Remove-Item -Recurse -Force public }
Copy-Item -Recurse build\web public

git add -A
git commit -m "Publish web"
git push origin main
```

### Настройки Static Site в Render

1. Dashboard → Static Site
2. **Publish Directory:** `public`
3. **Manual Deploy** после пуша

---

## 3. Локально

```powershell
cd server
dart run bin/server.dart
```

Без Postgres auth будет `503`, онлайн как аноним работает.

По умолчанию клиент ходит на Render. Локальный сервер:

```powershell
flutter run -d edge --dart-define=SUPERCHESS_SERVER_URL=ws://127.0.0.1:8080/ws
```

---

## Язык

RU/EN выбирается по языку системы/браузера; на главном экране можно переключить вручную (иконка глобуса). Ник в партии: аккаунт или «Аноним» / `Anonymous`.

## Рейтинг и достижения

- Elo обновляется только если **оба** игрока залогинены.
- История и прогресс модов — для залогиненного в каждой его партии (в т.ч. vs аноним, без Elo).
- Достижение **Коллекционер** (`all_abilities`): использовать все моды за карьеру в logged-in играх.
- Профиль: иконка человека на главном / тап по нику.
- **Против Stockfish**: в браузере — **Stockfish 18 NNUE lite** (`stockfish-18-lite-single.*`, ~7MB; при сбое — full ~108MB). На Android/iOS — плагин `stockfish`. Игрок выбирает моды, Stockfish — нет. Запасного бота нет: без движка ход не делается.
- Wasm лежит в Git LFS. После клона: `git lfs pull`. Если файлов нет: `.\scripts\fetch_stockfish.ps1`.
- Первый запуск режима «против Stockfish» может долго грузить wasm (десятки секунд на медленной сети).
- `.\scripts\build_web.ps1` сам подтягивает движок при необходимости и копирует `web/stockfish/` → `public/stockfish/`.

---

## Файлы

| Путь | Назначение |
|------|------------|
| `public/` | Готовый сайт для Render |
| `server/Dockerfile` | API |
| `server/lib/` | auth + postgres + elo |
| `render.yaml` | Blueprint (API + DB + static) |
| `lib/online/server_config.dart` | WS + HTTP base URL |
| `lib/auth/` | клиентская сессия |
| `lib/l10n/` | RU/EN строки оболочки |
| `lib/screens/profile_screen.dart` | рейтинг / достижение |
| `lib/screens/history_screen.dart` | история партий |
| `lib/chess/computer_player.dart` | локальный шахматный бот |
