param(
  [string]$ServerUrl = "wss://superchess-api.onrender.com/ws",
  # Also git add / commit / push after build
  [switch]$Push,
  [string]$Message = "Publish web build"
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

Write-Host "==> flutter pub get"
flutter pub get

Write-Host "==> Building Flutter web (SUPERCHESS_SERVER_URL=$ServerUrl)"
flutter build web --release --dart-define=SUPERCHESS_SERVER_URL=$ServerUrl

if (Test-Path public) {
  Remove-Item -Recurse -Force public
}
Copy-Item -Recurse build\web public
"/*    /index.html   200" | Set-Content -Path "public\_redirects" -Encoding utf8

# Ensure Stockfish worker is present (also copied via web/ → build/web)
$sfSrc = "web\stockfish\stockfish.js"
$sfDst = "public\stockfish\stockfish.js"
if ((Test-Path $sfSrc) -and -not (Test-Path $sfDst)) {
  New-Item -ItemType Directory -Force -Path "public\stockfish" | Out-Null
  Copy-Item $sfSrc $sfDst -Force
  Write-Host "==> Copied stockfish.js into public/stockfish/"
}

Write-Host ""
Write-Host "Build ready in public/"

if (-not $Push) {
  Write-Host "Next (or re-run with -Push):"
  Write-Host "  git add -A"
  Write-Host "  git commit -m `"$Message`""
  Write-Host "  git push origin main"
  exit 0
}

Write-Host "==> git commit + push"
git add -A
$status = git status --porcelain
if (-not $status) {
  Write-Host "Nothing to commit (already up to date)."
  exit 0
}
git commit -m $Message
git push origin main
Write-Host ""
Write-Host "Pushed. If Render Static Site uses auto-deploy from main, wait ~1 min."
Write-Host "Otherwise: Render → Static Site → Manual Deploy."
