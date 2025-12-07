<#
Simple Windows-friendly jpackage wrapper.

Usage (from repo root):
  powershell -ExecutionPolicy Bypass -File .\scripts\package-with-jpackage.ps1 -IconPath '.\resources\favicon.ico' -EmbedRuntime

This script expects a jar named `SchereSteinPapier.jar` in `dist/` (created by the build step).
It will call `jpackage` to create a Windows EXE installer and place outputs into `installer/`.

Optional environment variables for signing (CI):
  SIGN_PFX_B64  - base64-encoded PFX file
  SIGN_PFX_PASSWORD - password for the PFX
#>

Set-StrictMode -Version Latest
Pop-Location
Write-Ok "Packaging complete."
Write-Ok "jpackage succeeded. Installers are in: $outDir"

# Optional signing: if SIGN_PFX_B64 + SIGN_PFX_PASSWORD provided, sign produced EXEs
if ($env:SIGN_PFX_B64 -and $env:SIGN_PFX_PASSWORD) {
    $signtool = Get-Command signtool -ErrorAction SilentlyContinue
    if (-not $signtool) { Write-Err "signtool not found on PATH; skipping signing." }
    else {
        $tmpPfx = Join-Path $env:TEMP "repo_signing.pfx"
        Write-Info "Decoding SIGN_PFX_B64 to $tmpPfx"
        [System.IO.File]::WriteAllBytes($tmpPfx, [System.Convert]::FromBase64String($env:SIGN_PFX_B64))

        $exes = Get-ChildItem -Path $outDir -Filter '*.exe' -Recurse -File -ErrorAction SilentlyContinue
        foreach ($e in $exes) {
            Write-Info "Signing $($e.FullName)"
            & signtool sign /f $tmpPfx /p $env:SIGN_PFX_PASSWORD /tr http://timestamp.digicert.com /td sha256 /fd sha256 $e.FullName
            if ($LASTEXITCODE -ne 0) { Write-Err "signtool failed for $($e.FullName)" }
            else { Write-Ok "Signed $($e.FullName)" }
        }

        Remove-Item -Force $tmpPfx
    }
}

Pop-Location
Write-Ok "Packaging complete."
<#
Create a Windows EXE installer using jpackage (clean, single-copy script)

Usage (from project root):
    powershell -ExecutionPolicy Bypass -File .\scripts\package-with-jpackage.ps1 -IconPath ".\resources\app.ico"

Requirements:
- `jpackage` must be available on PATH (JDK with jpackage).
- Run on Windows.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Defaults
<#
Simple Windows-friendly jpackage wrapper.

Usage (from repo root):
  powershell -ExecutionPolicy Bypass -File .\scripts\package-with-jpackage.ps1 -IconPath '.\resources\favicon.ico' -EmbedRuntime

This script expects a jar named `SchereSteinPapier.jar` in `dist/` (created by the build step).
It will call `jpackage` to create a Windows EXE installer and place outputs into `installer/`.

Optional environment variables for signing (CI):
  SIGN_PFX_B64  - base64-encoded PFX file
  SIGN_PFX_PASSWORD - password for the PFX
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

param(
    [string] $AppName = 'SchereSteinPapier',
    [string] $IconPath = '',
    [string] $Type = 'exe',
    <#
    Simple Windows-friendly jpackage wrapper.

    Usage (from repo root):
      powershell -ExecutionPolicy Bypass -File .\scripts\package-with-jpackage.ps1 -IconPath '.\resources\favicon.ico' -EmbedRuntime

    This script expects a jar named `SchereSteinPapier.jar` in `dist/` (created by the build step).
    It will call `jpackage` to create a Windows EXE installer and place outputs into `installer/`.

    Optional environment variables for signing (CI):
      SIGN_PFX_B64  - base64-encoded PFX file
      SIGN_PFX_PASSWORD - password for the PFX
    #>

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    param(
        [string] $AppName = 'SchereSteinPapier',
        [string] $IconPath = '',
        [string] $Type = 'exe',
        [switch] $EmbedRuntime = $false,
        [switch] $BundleJavaFX = $false,
        [string] $JavaFXVersion = '21'
    )

    function Write-Info($m) { Write-Host $m -ForegroundColor Cyan }
    function Write-Ok($m) { Write-Host $m -ForegroundColor Green }
    function Write-Err($m) { Write-Host $m -ForegroundColor Red }

    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
    $projectRoot = Split-Path -Parent $scriptDir
    Push-Location $projectRoot

    Write-Info "Project root: $projectRoot"

    # Locate JAR (prefer dist/SchereSteinPapier.jar, else find in target)
    $expected = Join-Path $PWD 'dist\SchereSteinPapier.jar'
    if (-not (Test-Path $expected)) {
        Write-Info "dist/SchereSteinPapier.jar not found, searching target/ for a JAR..."
        $jar = Get-ChildItem -Path target -Filter '*-shaded.jar' -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $jar) { $jar = Get-ChildItem -Path target -Filter '*.jar' -Recurse -File | Where-Object { $_.Name -notlike '*original*' } | Select-Object -First 1 }
        if (-not $jar) { Write-Err "No JAR found in target/. Build the project first."; Pop-Location; exit 1 }
        Write-Info "Found JAR: $($jar.FullName)"
        if (-not (Test-Path (Join-Path $PWD 'dist'))) { New-Item -ItemType Directory -Path (Join-Path $PWD 'dist') | Out-Null }
        Copy-Item $jar.FullName -Destination $expected -Force
    }
    else {
        Write-Info "Using existing JAR: $expected"
    }

    # Verify jpackage
    $jpackage = Get-Command jpackage -ErrorAction SilentlyContinue
    if (-not $jpackage) { Write-Err "jpackage not found on PATH. Install a JDK (17+) that includes jpackage."; Pop-Location; exit 1 }

    # Optionally create a runtime image via jlink
    $runtimeImagePath = $null
    if ($EmbedRuntime) {
        $jlink = Get-Command jlink -ErrorAction SilentlyContinue
        if (-not $jlink) { Write-Err "jlink not found on PATH; cannot embed runtime." }
        else {
            $runtimeImagePath = Join-Path $PWD 'runtime-image'
            if (Test-Path $runtimeImagePath) { Remove-Item -Recurse -Force $runtimeImagePath }
            Write-Info "Creating runtime image via jlink..."
            & jlink --add-modules java.desktop --output $runtimeImagePath --strip-debug --no-man-pages --no-header-files
            if ($LASTEXITCODE -ne 0) { Write-Err "jlink failed"; Pop-Location; exit $LASTEXITCODE }
            Write-Ok "Runtime image created: $runtimeImagePath"
        }
    }

    # Prepare jpackage args
    $distJarName = 'SchereSteinPapier.jar'
    $inputDir = Join-Path $PWD 'dist'
    $outDir = Join-Path $PWD 'installer'
    if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

    $jpkgArgs = @(
        '--type', $Type,
        '--name', $AppName,
        '--input', $inputDir,
        '--main-jar', $distJarName,
        '--main-class', 'App',
        '--dest', $outDir,
        '--verbose'
    )

    if ($IconPath -and (Test-Path $IconPath)) { $jpkgArgs += @('--icon', (Resolve-Path $IconPath).Path) }
    if ($runtimeImagePath) { $jpkgArgs += @('--runtime-image', $runtimeImagePath) }

    if ($BundleJavaFX) {
        Write-Info "BundleJavaFX requested, but this simplified script does not auto-download OpenJFX. Ensure JavaFX modules are on module-path if needed."
    }

    Write-Info "Running jpackage: jpackage $($jpkgArgs -join ' ')"
    & jpackage @jpkgArgs
    if ($LASTEXITCODE -ne 0) { Write-Err "jpackage failed with exit code $LASTEXITCODE"; Pop-Location; exit $LASTEXITCODE }

    Write-Ok "jpackage succeeded. Installers are in: $outDir"

    # Optional signing: if SIGN_PFX_B64 + SIGN_PFX_PASSWORD provided, sign produced EXEs
    if ($env:SIGN_PFX_B64 -and $env:SIGN_PFX_PASSWORD) {
        $signtool = Get-Command signtool -ErrorAction SilentlyContinue
        if (-not $signtool) { Write-Err "signtool not found on PATH; skipping signing." }
        else {
            $tmpPfx = Join-Path $env:TEMP "repo_signing.pfx"
            Write-Info "Decoding SIGN_PFX_B64 to $tmpPfx"
            [System.IO.File]::WriteAllBytes($tmpPfx, [System.Convert]::FromBase64String($env:SIGN_PFX_B64))

            $exes = Get-ChildItem -Path $outDir -Filter '*.exe' -Recurse -File -ErrorAction SilentlyContinue
            foreach ($e in $exes) {
                Write-Info "Signing $($e.FullName)"
                & signtool sign /f $tmpPfx /p $env:SIGN_PFX_PASSWORD /tr http://timestamp.digicert.com /td sha256 /fd sha256 $e.FullName
                if ($LASTEXITCODE -ne 0) { Write-Err "signtool failed for $($e.FullName)" }
                else { Write-Ok "Signed $($e.FullName)" }
            }

            Remove-Item -Force $tmpPfx
        }
    }

    Pop-Location
    Write-Ok "Packaging complete."
