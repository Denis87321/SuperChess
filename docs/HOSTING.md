# Hosting SuperChess (бесплатно)

## Архитектура

- **Сайт**: Flutter Web (папка `public/` в git) → **Render Static Site**
- **Сервер матчей**: Dart WebSocket → **Render Web Service** `wss://superchess-api.onrender.com/ws`
- Cloudflare Pages лучше не использовать как основной сайт из РФ (часто нужен VPN)

## Важно: API на Render засыпает

Web Service на free **засыпает ~после 15 минут**. Первый «Онлайн» после сна может ждать **30–60 секунд**. Статический сайт обычно открывается сразу.

---

## 1. Сервер матчей (уже сделано)

`https://superchess-api.onrender.com/health` → `{"ok":true}`

---

## 2. Сайт на Render (без Flutter на сервере)

На Render **нет** команды `flutter`. Сайт собирается **у тебя на ПК**, результат кладётся в `public/` и пушится в GitHub.

### Один раз / после изменений UI

```powershell
cd C:\Users\SRV\Documents\Proga\SuperChess
flutter build web --release --dart-define=SUPERCHESS_SERVER_URL=wss://superchess-api.onrender.com/ws

# скопировать в public (или scripts\build_web.ps1 после Bypass policy)
if (Test-Path public) { Remove-Item -Recurse -Force public }
Copy-Item -Recurse build\web public

git add public render.yaml docs scripts lib
git commit -m "Publish prebuilt web for Render Static Site"
git push origin main
```

### Настройки Static Site в Render

1. Dashboard → твой Static Site (или **New → Static Site**)
2. Репозиторий: SuperChess, ветка `main`
3. **Build Command:** оставь пустым **или** `echo skip`
4. **Publish Directory:** `public`
5. Сохрани → **Manual Deploy** → Deploy latest commit

Сайт будет вида: `https://superchess-web.onrender.com` (имя смотри в Render).

Открой **без VPN** и зайди в Онлайн.

---

## 3. Локально

```powershell
cd server
dart run bin/server.dart
```

```powershell
flutter run -d edge
```

---

## Файлы

| Путь | Назначение |
|------|------------|
| `public/` | Готовый сайт для Render (коммитить) |
| `server/Dockerfile` | API |
| `render.yaml` | Blueprint |
| `lib/online/server_config.dart` | URL `wss://…` |
| `scripts/build_web.ps1` | Сборка → `public/` |
