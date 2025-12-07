<#
Clean jpackage packaging script (alternative filename) - creates Windows EXE installer
Usage (from project root):
    powershell -ExecutionPolicy Bypass -File .\scripts\jpackage-package.ps1 -IconPath ".\resources\app.ico"
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$AppName = 'SchereSteinPapier'
$IconPath = ''
$Type = 'exe'

for ($i = 0; $i -lt $args.Length; $i++) {
    switch ($args[$i]) {
        '-AppName' { if ($i + 1 -lt $args.Length) { $i++; $AppName = $args[$i] } }
        '-IconPath' { if ($i + 1 -lt $args.Length) { $i++; $IconPath = $args[$i] } }
        '-Type' { if ($i + 1 -lt $args.Length) { $i++; $Type = $args[$i] } }
    }
}

function Info($m){ Write-Host $m -ForegroundColor Cyan }
function Ok($m){ Write-Host $m -ForegroundColor Green }
function Err($m){ Write-Host $m -ForegroundColor Red }

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition | Split-Path -Parent
Push-Location $projectRoot

Info "Project root: $projectRoot"

if (-not (Get-Command jpackage -ErrorAction SilentlyContinue)) {
    Err "jpackage not found in PATH. Install a JDK with jpackage and retry."
    Pop-Location
    exit 1
}

if (-not (Test-Path 'bin')) { New-Item -ItemType Directory -Path 'bin' | Out-Null }
if (-not (Test-Path 'dist')) { New-Item -ItemType Directory -Path 'dist' | Out-Null }

if (Get-Command javac -ErrorAction SilentlyContinue) {
    Info "Compiling sources..."
    javac -d bin -sourcepath src src\App.java
    Ok "Compilation finished."
} else { Info "javac not found; skipping compilation." }

if (Get-Command jar -ErrorAction SilentlyContinue -and (Test-Path 'bin')) {
    $jarPath = Join-Path $projectRoot "dist\$AppName.jar"
    Info "Creating runnable JAR: $jarPath"
    jar cfe $jarPath App -C bin .
    Ok "JAR created: $jarPath"
} else { Info "jar tool missing or bin absent; ensure runnable jar available in dist/." }

$installerOut = Join-Path $projectRoot 'installer'
if (-not (Test-Path $installerOut)) { New-Item -ItemType Directory -Path $installerOut | Out-Null }

$jpackageArgs = @('--type', $Type, '--input', 'dist', '--name', $AppName, '--main-jar', "$AppName.jar", '--main-class', 'App', '--dest', 'installer', '--app-version', '1.0', '--win-shortcut')
if ($IconPath -and (Test-Path $IconPath)) { $jpackageArgs += @('--icon', $IconPath) }

Info "Running jpackage: $($jpackageArgs -join ' ')"
try {
    jpackage @jpackageArgs
    Ok "jpackage finished. See installer folder: $installerOut"
}
catch {
    Err "jpackage failed: $($_.Exception.Message)"
    Pop-Location
    exit 1
}

Pop-Location
Ok "Packaging complete."
