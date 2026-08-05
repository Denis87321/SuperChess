param(
  [string]$ProjectName = "superchess",
  [string]$ServerUrl = "wss://superchess-api.fly.dev/ws"
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

& "$PSScriptRoot\build_web.ps1" -ServerUrl $ServerUrl

if (-not (Get-Command wrangler -ErrorAction SilentlyContinue)) {
  Write-Host "Installing wrangler (npm -g)..."
  npm i -g wrangler
}

Write-Host "Deploying build/web to Cloudflare Pages project '$ProjectName'..."
Write-Host "(If prompted, run: wrangler login)"
wrangler pages deploy build/web --project-name=$ProjectName

Write-Host ""
Write-Host "Site will be at https://$ProjectName.pages.dev (or your custom domain)."
