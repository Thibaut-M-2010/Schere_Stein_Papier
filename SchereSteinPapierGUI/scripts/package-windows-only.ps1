<#
Simple wrapper to produce a Windows-only installer (EXE) using the
existing `package-with-jpackage.ps1` script in this repo.

Usage (from repository root):
  powershell -ExecutionPolicy Bypass -File .\scripts\package-windows-only.ps1 -IconPath '.\resources\favicon.ico'

Requirements:
- JDK with `jpackage` and `jlink` available on PATH (or use a full JDK bin path)
- Maven (`mvn`) installed if you want the wrapper to run the build step
- Run on a Windows machine (for EXE/signtool signing)

This wrapper calls `package-with-jpackage.ps1` with sensible defaults to
produce a single `.exe` installer with an embedded runtime.
#>
param(
    [string] $IconPath = '',
    [switch] $SkipBuild = $false,
    [switch] $BundleJavaFX = $false,
    [string] $JavaFXVersion = '21',
    [switch] $EmbedRuntime = $true
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$packScript = Join-Path $scriptDir 'package-with-jpackage-clean.ps1'
if (-not (Test-Path $packScript)) {
    Write-Error "Packaging script not found: $packScript"
    exit 1
}

# Optionally run Maven build first
if (-not $SkipBuild) {
    if (Get-Command mvn -ErrorAction SilentlyContinue) {
        Write-Host "Running 'mvn -DskipTests package'..."
        & mvn -DskipTests package
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Maven build failed. Fix build errors and retry."
            exit $LASTEXITCODE
        }
    }
    else {
        Write-Warning "Maven (mvn) not found on PATH. Skipping build. Ensure your JAR is present in target/ before running packaging."
    }
}

# Ensure dist exists and try to find/copy a JAR from target/ to dist/ if needed
$distDir = Join-Path (Get-Location) 'dist'
if (-not (Test-Path $distDir)) { New-Item -ItemType Directory -Path $distDir | Out-Null }
$expectedDistJar = Join-Path $distDir 'SchereSteinPapier.jar'
if (-not (Test-Path $expectedDistJar)) {
    Write-Host "No JAR found in 'dist/'. Searching 'target/' for built JAR..."
    $candidates = Get-ChildItem -Path .\target -Recurse -Filter *.jar -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch 'sources|javadoc' }
    if ($candidates -and $candidates.Count -gt 0) {
        # Prefer shaded/fat JARs if present
        $fat = $candidates | Where-Object { $_.Name -match 'jar-with-dependencies|uber|shadow' } | Select-Object -First 1
        $pick = $fat
        if (-not $pick) { $pick = $candidates | Select-Object -First 1 }
        Write-Host "Found JAR: $($pick.FullName). Copying to $expectedDistJar"
        Copy-Item -Path $pick.FullName -Destination $expectedDistJar -Force
    }
    else {
        Write-Error "No JAR found. Run 'mvn -DskipTests package' locally or copy your built JAR to 'dist\SchereSteinPapier.jar' and retry."
        exit 1
    }
}

# Build argument list for the main packaging script
$argsList = @()
$argsList += '-Type'; $argsList += 'exe'
if ($EmbedRuntime) { $argsList += '-EmbedRuntime' }
if ($BundleJavaFX) { $argsList += '-BundleJavaFX'; $argsList += '-JavaFXVersion'; $argsList += $JavaFXVersion }
if ($IconPath -and (Test-Path $IconPath)) { $argsList += '-IconPath'; $argsList += (Resolve-Path $IconPath).Path }

Write-Host "Invoking packaging script with: $($argsList -join ' ')"
& powershell -ExecutionPolicy Bypass -File $packScript @argsList

if ($LASTEXITCODE -ne 0) {
    Write-Error "Packaging script failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

Write-Host "Windows installer packaging completed. Check the 'installer' folder for results."