# super_chess

Chess with mods — SuperChess (Flutter).

## Docs

| Document | About |
|----------|--------|
| [docs/HOSTING.md](docs/HOSTING.md) | Deploy (Render, web build) |
| [docs/MOBILE_PUSH.md](docs/MOBILE_PUSH.md) | Mobile push notifications |
| [docs/ASSETS.md](docs/ASSETS.md) | Visual assets — **chess piece art from Lichess Caliente** |
| [docs/modifications.txt](docs/modifications.txt) | List of mods / abilities |

Piece SVGs: [`assets/pieces/caliente/`](assets/pieces/caliente/) — sourced from [lichess-org/lila `public/piece/caliente`](https://github.com/lichess-org/lila/tree/master/public/piece/caliente) (CC BY-NC-SA 4.0). Details in [docs/ASSETS.md](docs/ASSETS.md).

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
