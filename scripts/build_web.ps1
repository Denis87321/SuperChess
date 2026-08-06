param(
  [string]$ServerUrl = "wss://superchess-api.onrender.com/ws",
  # Also git add / commit / push after build
  [switch]$Push,
  [string]$Message = "Publish web build"
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

# Stockfish 18 NNUE assets (full single ~108MB) must exist under web/stockfish/
$sfPrimary = "web\stockfish\stockfish-18-single.wasm"
if (-not (Test-Path $sfPrimary)) {
  Write-Host "==> Stockfish wasm missing - running fetch_stockfish.ps1"
  & "$PSScriptRoot\fetch_stockfish.ps1"
}

Write-Host "==> flutter pub get"
flutter pub get

Write-Host "==> Building Flutter web (SUPERCHESS_SERVER_URL=$ServerUrl)"
flutter build web --release --dart-define=SUPERCHESS_SERVER_URL=$ServerUrl

if (Test-Path public) {
  Remove-Item -Recurse -Force public
}
Copy-Item -Recurse build\web public
"/*    /index.html   200" | Set-Content -Path "public\_redirects" -Encoding utf8

# Ensure Stockfish 18 workers are present (also copied via web/ -> build/web)
$sfSrcDir = "web\stockfish"
$sfDstDir = "public\stockfish"
if (Test-Path $sfSrcDir) {
  New-Item -ItemType Directory -Force -Path $sfDstDir | Out-Null
  Copy-Item -Path (Join-Path $sfSrcDir "*") -Destination $sfDstDir -Force
  Write-Host "==> Synced stockfish assets into public/stockfish/"
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
Write-Host "Otherwise: Render -> Static Site -> Manual Deploy."
