# Hosting SuperChess (бесплатно)

## Архитектура

- **Сайт**: Flutter Web → Cloudflare Pages
- **Сервер матчей**: Dart WebSocket → **Render** (free), URL вида `wss://superchess-api.onrender.com/ws`
- **Телефон позже**: тот же `wss://` URL

## Важно: Render засыпает

На free-плане сервис **засыпает ~после 15 минут без запросов**. Первый вход в «Онлайн» после сна может занять **30–60 секунд** (пока сервер просыпается). Потом работает нормально.

---

## 1. Сервер на Render

### Подготовка репозитория

Код должен быть на GitHub (Render читает репо). Если ещё не запушено:

```powershell
cd C:\Users\SRV\Documents\Proga\SuperChess
git add -A
git status
git commit -m "Add Render hosting for matchmaking server"
git push origin main
```

### Создать Web Service

1. Зайди на https://dashboard.render.com и зарегистрируйся (можно через GitHub).
2. **New** → **Web Service**.
3. Подключи репозиторий **SuperChess**.
4. Настройки:
   - **Name**: `superchess-api`
   - **Region**: Frankfurt (или ближайший)
   - **Runtime**: **Docker**
   - **Dockerfile Path**: `server/Dockerfile`
   - **Docker Context**: `./server` (если поле есть)
   - **Instance type**: **Free**
   - **Health Check Path**: `/health`
5. **Create Web Service** → дождись Deploy (несколько минут).
6. Проверка в браузере:  
   `https://superchess-api.onrender.com/health`  
   → должно быть `{"ok":true,"service":"superchess"}`  
   (первый раз может подождать, пока сервис проснётся).

Адрес WebSocket: **`wss://superchess-api.onrender.com/ws`**

Если Render дал другое имя (например `superchess-api-xxxx`), поменяй URL в  
[lib/online/server_config.dart](../lib/online/server_config.dart) (`kProductionServerUrl`)  
или всегда передавай его в `-ServerUrl` при сборке сайта.

Альтернатива: **New → Blueprint** и указать `render.yaml` в корне репо.

---

## 2. Сайт на Cloudflare Pages

```powershell
cd C:\Users\SRV\Documents\Proga\SuperChess
.\scripts\build_web.ps1 -ServerUrl wss://superchess-api.onrender.com/ws
```

Потом:

- Cloudflare → **Workers & Pages** → **Create** → **Pages** → **Direct Upload** → загрузить папку `build\web`  
  **или**
```powershell
npm i -g wrangler
wrangler login
.\scripts\deploy_pages.ps1 -ServerUrl wss://superchess-api.onrender.com/ws
```

Открой выданный адрес `https://….pages.dev`.

---

## 3. Локально (без Render)

**Терминал 1:**
```powershell
cd C:\Users\SRV\Documents\Proga\SuperChess\server
dart run bin/server.dart
```

**Терминал 2:**
```powershell
cd C:\Users\SRV\Documents\Proga\SuperChess
flutter run -d edge
```

Онлайн в debug ходит на `ws://127.0.0.1:8080/ws`.

Проверка против уже залитого Render:
```powershell
flutter run -d edge --dart-define=SUPERCHESS_SERVER_URL=wss://superchess-api.onrender.com/ws
```

---

## Файлы

| Путь | Назначение |
|------|------------|
| `server/Dockerfile` | Образ сервера для Render |
| `render.yaml` | Blueprint Render |
| `lib/online/server_config.dart` | URL сервера |
| `scripts/build_web.ps1` | Сборка сайта |
| `scripts/deploy_pages.ps1` | Загрузка на Cloudflare |
