<#
Clean Windows-focused jpackage implementation (standalone).

Usage:
  powershell -ExecutionPolicy Bypass -File .\scripts\package-with-jpackage-clean.ps1 -IconPath '.\resources\favicon.ico' -EmbedRuntime
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Simple argument parsing via $args (avoids param() issues in some environments)
$AppName = 'SchereSteinPapier'
$IconPath = ''
$Type = 'exe'
$EmbedRuntime = $false

for ($i = 0; $i -lt $args.Length; $i++) {
    switch ($args[$i]) {
        '-AppName' { if ($i + 1 -lt $args.Length) { $i++; $AppName = $args[$i] } }
        '-IconPath' { if ($i + 1 -lt $args.Length) { $i++; $IconPath = $args[$i] } }
        '-Type' { if ($i + 1 -lt $args.Length) { $i++; $Type = $args[$i] } }
        '-EmbedRuntime' { $EmbedRuntime = $true }
    }
}

function Write-Info($m) { Write-Host $m -ForegroundColor Cyan }
function Write-Ok($m) { Write-Host $m -ForegroundColor Green }
function Write-Err($m) { Write-Host $m -ForegroundColor Red }

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$projectRoot = Split-Path -Parent $scriptDir
Push-Location $projectRoot

Write-Info "Project root: $projectRoot"

# Locate JAR
$expected = Join-Path $PWD 'dist\SchereSteinPapier.jar'
if (-not (Test-Path $expected)) {
    $jar = Get-ChildItem -Path target -Filter '*-shaded.jar' -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $jar) { $jar = Get-ChildItem -Path target -Filter '*.jar' -Recurse -File | Where-Object { $_.Name -notlike '*original*' } | Select-Object -First 1 }
    if (-not $jar) { Write-Err "No JAR found. Run 'mvn -DskipTests package' first."; Pop-Location; exit 1 }
    if (-not (Test-Path (Join-Path $PWD 'dist'))) { New-Item -ItemType Directory -Path (Join-Path $PWD 'dist') | Out-Null }
    Copy-Item $jar.FullName -Destination $expected -Force
}

# Ensure jpackage
if (-not (Get-Command jpackage -ErrorAction SilentlyContinue)) { Write-Err "jpackage not found on PATH"; Pop-Location; exit 1 }

$outDir = Join-Path $PWD 'installer'
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

$jpkgArgs = @('--type', $Type, '--name', $AppName, '--input', (Join-Path $PWD 'dist'), '--main-jar', 'SchereSteinPapier.jar', '--main-class', 'App', '--dest', $outDir)
if ($IconPath -and (Test-Path $IconPath)) { $jpkgArgs += @('--icon', (Resolve-Path $IconPath).Path) }

Write-Info "Running jpackage..."
& jpackage @jpkgArgs
if ($LASTEXITCODE -ne 0) { Write-Err "jpackage failed with exit code $LASTEXITCODE"; Pop-Location; exit $LASTEXITCODE }

Write-Ok "Installer created in: $outDir"
Pop-Location
