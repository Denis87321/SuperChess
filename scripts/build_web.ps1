param(
  [string]$ServerUrl = "wss://superchess-api.onrender.com/ws"
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

Write-Host "Building Flutter web with SUPERCHESS_SERVER_URL=$ServerUrl"
flutter build web --release --dart-define=SUPERCHESS_SERVER_URL=$ServerUrl

if (Test-Path public) {
  Remove-Item -Recurse -Force public
}
Copy-Item -Recurse build\web public
"/*    /index.html   200" | Set-Content -Path "public\_redirects" -Encoding utf8

Write-Host ""
Write-Host "Done. Commit and push public/ then redeploy the Render Static Site."
Write-Host "  git add public"
Write-Host "  git commit -m `"Update web build for Render`""
Write-Host "  git push"
