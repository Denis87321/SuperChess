param(
  [string]$AppName = "superchess-api"
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..\server

if (-not (Get-Command fly -ErrorAction SilentlyContinue) -and
    -not (Get-Command flyctl -ErrorAction SilentlyContinue)) {
  Write-Host "Installing flyctl..."
  iwr https://fly.io/install.ps1 -useb | iex
  $env:Path = "$env:USERPROFILE\.fly\bin;$env:Path"
}

$fly = if (Get-Command fly -ErrorAction SilentlyContinue) { "fly" } else { "flyctl" }

Write-Host "Deploying matchmaking server as $AppName ..."
& $fly deploy --config fly.toml --app $AppName

Write-Host ""
Write-Host "Health:  https://$AppName.fly.dev/health"
Write-Host "WSS:     wss://$AppName.fly.dev/ws"
Write-Host "Then rebuild web:  ..\scripts\build_web.ps1 -ServerUrl wss://$AppName.fly.dev/ws"
