param(
  [string]$ServerUrl = "wss://superchess-api.fly.dev/ws"
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

Write-Host "Building Flutter web with SUPERCHESS_SERVER_URL=$ServerUrl"

flutter build web --release `
  --dart-define=SUPERCHESS_SERVER_URL=$ServerUrl

# SPA fallback for deep links on Cloudflare / static hosts
$redirects = Join-Path "build\web" "_redirects"
"/*    /index.html   200" | Set-Content -Path $redirects -Encoding utf8

Write-Host "Web build ready: build/web"
Write-Host "Deploy: wrangler pages deploy build/web --project-name=superchess"
