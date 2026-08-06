param(
  # Skip the full ~108MB Stockfish 18 NNUE single-thread engine.
  [switch]$SkipFull,
  # Skip lite engines (~7MB) used as fallback / optional threaded build.
  [switch]$SkipLite,
  # Mirror prefix when github.com release assets are unreachable.
  [string]$MirrorPrefix = "https://ghfast.top/"
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

$dir = "web\stockfish"
New-Item -ItemType Directory -Force -Path $dir | Out-Null

$base = "${MirrorPrefix}https://github.com/nmrugg/stockfish.js/releases/download/v18.0.0"
$files = @()
if (-not $SkipFull) {
  $files += @("stockfish-18-single.js", "stockfish-18-single.wasm")
}
if (-not $SkipLite) {
  $files += @(
    "stockfish-18-lite-single.js",
    "stockfish-18-lite-single.wasm",
    "stockfish-18-lite.js",
    "stockfish-18-lite.wasm"
  )
}

foreach ($f in $files) {
  $out = Join-Path $dir $f
  if ((Test-Path $out) -and (Get-Item $out).Length -gt 1000) {
    Write-Host "Skip (exists): $f ($((Get-Item $out).Length) bytes)"
    continue
  }
  Write-Host "==> $f"
  curl.exe -L --retry 5 --retry-delay 2 --connect-timeout 30 -o $out "$base/$f"
  if (-not (Test-Path $out) -or (Get-Item $out).Length -lt 1000) {
    throw "Failed to download $f"
  }
  Write-Host "OK $f ($((Get-Item $out).Length) bytes)"
}

Write-Host ""
Write-Host "Stockfish 18 assets ready in $dir"
Write-Host "Note: *.wasm is tracked with Git LFS (.gitattributes)."
