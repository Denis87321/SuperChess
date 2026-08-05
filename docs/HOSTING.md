# Hosting SuperChess (free path)

## Architecture

- **Website**: Flutter Web → Cloudflare Pages (`https://….pages.dev`)
- **Matchmaking**: Dart WebSocket server → Fly.io (`wss://superchess-api.fly.dev/ws`)
- **Mobile later**: same Flutter app, same `wss://` URL → cross-play with web

## One-time setup

### 1. Matchmaking server (Fly.io)

1. Create account at https://fly.io and install CLI (`scripts/deploy_server.ps1` can install flyctl).
2. From repo:

```powershell
cd server
fly auth login
fly launch --name superchess-api --region ams --no-deploy --copy-config
fly deploy
```

Or: `.\scripts\deploy_server.ps1`

3. Check: open `https://superchess-api.fly.dev/health` → `{"ok":true,...}`
4. If the app name differs, update `kProductionServerUrl` in
   [lib/online/server_config.dart](../lib/online/server_config.dart)
   and rebuild clients.

### 2. Website (Cloudflare Pages)

```powershell
.\scripts\deploy_pages.ps1 -ServerUrl wss://superchess-api.fly.dev/ws
```

Or step by step:

```powershell
.\scripts\build_web.ps1 -ServerUrl wss://superchess-api.fly.dev/ws
npm i -g wrangler
wrangler login
wrangler pages deploy build/web --project-name=superchess
```

Or upload the `build/web` folder in the Cloudflare dashboard (Workers & Pages → Create → Direct Upload).

### 3. Local development

```powershell
cd server
dart run bin/server.dart
# other terminal:
flutter run -d chrome
# Online matchmaking uses ws://127.0.0.1:8080/ws in debug mode
```

Override any time:

```powershell
flutter run -d chrome --dart-define=SUPERCHESS_SERVER_URL=wss://superchess-api.fly.dev/ws
```

## Cross-play checklist

1. Two browsers on the production site → matched online.
2. Phone (debug/release APK) with the same `SUPERCHESS_SERVER_URL` / release default → matched with a browser.
3. Both must use **`wss://`** when the site is **`https://`**.

## Files

| Path | Role |
|------|------|
| `server/Dockerfile` | Container image for Fly |
| `server/fly.toml` | Fly app config + health check |
| `lib/online/server_config.dart` | WS URL selection |
| `scripts/build_web.ps1` | Release web build |
| `scripts/deploy_server.ps1` | Fly deploy helper |
| `wrangler.toml` | Cloudflare Pages project hint |
