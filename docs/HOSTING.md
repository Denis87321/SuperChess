# Hosting SuperChess (бесплатно)

## Архитектура

- **Сайт**: Flutter Web (папка `public/` в git) → **Render Static Site**
- **Сервер**: Dart (WebSocket + auth HTTP) → **Render Web Service** `wss://superchess-api.onrender.com/ws`
- **БД**: Render Postgres (`DATABASE_URL`) для аккаунтов (ник + пароль)
- **Redis** (опционально): `REDIS_URL` — pub/sub для нескольких инстансов API (`sc:*`)
- Cloudflare Pages лучше не использовать как основной сайт из РФ (часто нужен VPN)

## Важно: API на Render засыпает

Web Service на free **засыпает ~после 15 минут**. Первый «Онлайн» после сна может ждать **30–60 секунд**. Статический сайт обычно открывается сразу.

---

## Важно: два разных деплоя

| Что | Как попадает на прод |
|-----|----------------------|
| **Сайт** (Flutter Web) | `.\scripts\build_web.ps1 -Push` → папка `public/` в git |
| **API** (матчмейкинг, auth, Elo, authority) | обычный `git push` кода в `server/` (+ `packages/super_chess_engine/`) → Render Web Service `superchess-api` сам пересобирает Docker |

`build_web.ps1` **не** обновляет API. Без пуша `server/` на GitHub Render продолжает крутить старый бэкенд.

**Docker context API:** в Render для `superchess-api` Build Context должен быть **корень репо** (`.`), не `./server` — иначе не видно `packages/super_chess_engine`. Это уже в `render.yaml`; если сервис создавался вручную раньше, в Dashboard → Settings поменяй **Docker Build Context Directory** на `.` (пусто / root) и сделай **Manual Deploy**.

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

- `https://superchess-api.onrender.com/health` → `{"ok":true,"auth":true,...}`  
  (`auth:false` = нет БД / ошибка подключения; `redis:true` = multi-instance fanout)

### Redis (несколько инстансов WS)

Без `REDIS_URL` сервер работает в single-instance режиме (как раньше).

С Redis:

1. Поднять Redis (Upstash / Render Redis / локально).
2. В Environment API: `REDIS_URL=redis://:password@host:6379` (или `rediss://…`).
3. Опционально `INSTANCE_ID` — читаемый id инстанса в логах и `/health`.

Поведение:

- Владелец партии пишет `sc:game:{id}:owner`.
- События партии публикуются в `sc:game:{id}`; чужие инстансы доставляют локально подключённым клиентам.
- Ход / resume с не-owner инстанса → `sc:game:{id}:ingress` → owner.
- Presence: ключ `sc:presence:{userId}` (TTL ~90s).

### Fair-play (облачный движок во время партии)

В **rated**-партиях сервер асинхронно сравнивает ходы с Stockfish (короткий movetime). Высокий match-rate → soft-флаг в БД и WS `fairplay_alert` (без автобана).

- `GET /games/:id/fairplay` — отчёт (sides + recent samples)
- `GET /fairplay/flags` — список soft-флагов (auth)
- Health: `"anticheat": true` (сэмплер всегда включён; нужен Stockfish)

### Push (FCM)

Клиент регистрирует токен в `POST /user/devices`. Сервер шлёт push, если задан `FCM_SERVER_KEY` (legacy FCM HTTP). Без ключа — no-op.

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

## Против Stockfish (серверный движок)

Клиент шлёт по `/ws`:

```json
{ "type": "stockfish_ping" }
{ "type": "stockfish_go", "id": "1", "fen": "...", "movetime": 3000 }
```

Ответы: `stockfish_pong` / `stockfish_bestmove`.

Локально (Windows): поставь [Stockfish](https://stockfishchess.org/download/) в PATH или задай `STOCKFISH_PATH`. Без бинарника на вебе останется WASM-fallback; на Android нужен задеплоенный API.

RU/EN выбирается по языку системы/браузера; на главном экране можно переключить вручную (иконка глобуса). Ник в партии: аккаунт или «Аноним» / `Anonymous`.

## Рейтинг, история и дуэли

- Elo обновляется только если **оба** игрока залогинены.
- История партий и прогресс модов — для залогиненного в каждой его партии (в т.ч. vs аноним, без Elo).
- **Счёт дуэлей** (`rivalries`): между двумя залогиненными хранится W–L–D; смотреть в профиле → «Счёт с соперниками».
- **Реплеи**: последние **20** партий залогиненного с ходами и модами (`match_replays`); API `GET /user/matches/:gameId`.
- Достижение **Коллекционер** (`all_abilities`): использовать все моды за карьеру в logged-in играх.
- Профиль: иконка человека на главном / тап по нику.
- Конец партии (веб): результат и причина в панели ходов справа; кнопки «Реванш» / «Найти другого».
- **Против Stockfish**: клиент подключается к API по WebSocket (`stockfish_ping` / `stockfish_go`). Движок крутится **на сервере** (пакет `stockfish` в Docker). На вебе при недоступности API возможен запасной локальный WASM. В APK нативного Stockfish нет — размер маленький.
- На сервере нужен бинарник: Debian `apt install stockfish`, или `STOCKFISH_PATH`. Health: `GET /health` → `"stockfish": true`.
- Первый запрос после сна Render может ждать **30–60 с** (пробуждение + старт движка).

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
