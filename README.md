# super_chess

Chess with capture abilities — SuperChess (Flutter).

## Play online (local)

```powershell
cd server
dart run bin/server.dart
```

In another terminal:

```powershell
flutter run -d chrome
```

Use **Онлайн** on the home screen. Debug builds connect to `ws://127.0.0.1:8080/ws`.

## Deploy to the world (free)

See [docs/HOSTING.md](docs/HOSTING.md): Flutter Web on Cloudflare Pages + matchmaking WebSocket on Fly.io (`wss://…/ws`). Site and future mobile apps share the same server URL for cross-play.

```powershell
.\scripts\deploy_server.ps1
.\scripts\build_web.ps1 -ServerUrl wss://superchess-api.fly.dev/ws
wrangler pages deploy build/web --project-name=superchess
```

## Tests

```powershell
flutter test
cd server; dart test
```
