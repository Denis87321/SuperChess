# super_chess

Chess with capture abilities — SuperChess (Flutter).

## Play online (local)

```powershell
cd server
dart run bin/server.dart
```

In another terminal:

```powershell
flutter run -d edge
```

Use **Онлайн** on the home screen. Debug builds connect to `ws://127.0.0.1:8080/ws`.

## Deploy (free)

See [docs/HOSTING.md](docs/HOSTING.md):

1. **Render** — matchmaking WebSocket (`wss://superchess-api.onrender.com/ws`)
2. **Cloudflare Pages** — Flutter web (`build/web`)

```powershell
.\scripts\build_web.ps1 -ServerUrl wss://superchess-api.onrender.com/ws
.\scripts\deploy_pages.ps1 -ServerUrl wss://superchess-api.onrender.com/ws
```

## Tests

```powershell
flutter test
cd server; dart test
```
