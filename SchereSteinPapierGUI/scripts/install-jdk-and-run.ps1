<#
One-click elevated installer + runner for Windows (PowerShell)
What it does:
- Ensures the script runs elevated (relaunches as Admin if needed)
- Tries to install Temurin JDK 17 using `winget` (preferred) or `choco`
- Detects the installed JDK and sets `JAVA_HOME` and updates PATH (temporary + persistent)
- Verifies `java` and `javac` are available
- Compiles `src\App.java` into `bin` and runs `App`

Run with: (from project root)
powershell -ExecutionPolicy Bypass -File .\scripts\install-jdk-and-run.ps1
#>

function Is-Administrator {
    $current = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($current)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Relaunch elevated if not admin
if (-not (Is-Administrator)) {
    Write-Host "Script is not running elevated. Relaunching as Administrator..." -ForegroundColor Yellow
    Start-Process -FilePath powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Try-Run($cmd, $args) {
    Write-Host "Running: $cmd $args"
    & $cmd $args
}

# Prefer winget, fallback to choco
$winget = Get-Command winget -ErrorAction SilentlyContinue
$choco = Get-Command choco -ErrorAction SilentlyContinue

try {
    if ($winget) {
        Write-Host "Using winget to install Temurin 17..." -ForegroundColor Cyan
        # Accept agreements to run non-interactively
        winget install --id EclipseAdoptium.Temurin.17 -e --silent --accept-package-agreements --accept-source-agreements
    }
    elseif ($choco) {
        Write-Host "winget not found; using Chocolatey to install Temurin 17..." -ForegroundColor Cyan
        choco install temurin17 -y
    }
    else {
        Write-Warning "Neither winget nor choco found. Please install a JDK manually from https://adoptium.net and re-run this script."
    }
}
catch {
    Write-Warning "Package install step failed: $($_.Exception.Message)"
}

# Attempt to locate Java installation
$javaExe = Get-Command java -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue
$javacExe = Get-Command javac -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue

if (-not $javaExe -or -not $javacExe) {
    # Try to discover typical Temurin/Adoptium locations
    $candidates = @(
        'C:\Program Files\Eclipse Adoptium',
        'C:\Program Files\Adoptium',
        'C:\Program Files\Temurin',
        'C:\Program Files\Java',
        'C:\Program Files (x86)\Java'
    )

    $found = $null
    foreach ($base in $candidates) {
        if (Test-Path $base) {
            try {
                $dirs = Get-ChildItem -Path $base -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'jdk|temurin|adoptium|jdk-17|17' }
                if ($dirs -and $dirs.Count -gt 0) {
                    $found = $dirs[0].FullName
                    break
                }
            }
            catch {
                # ignore
            }
        }
    }

    if ($found) {
        Write-Host "Detected JDK path: $found" -ForegroundColor Green
        $installPath = $found
    }
    else {
        # Try to find any java.exe under Program Files (may be slow but acceptable)
        Write-Host "Searching Program Files for a java installation..." -ForegroundColor Yellow
        $javaExePath = Get-ChildItem 'C:\Program Files' -Recurse -ErrorAction SilentlyContinue -Filter java.exe | Select-Object -First 1 -ExpandProperty FullName
        if ($javaExePath) {
            $installPath = Split-Path -Parent (Split-Path -Parent $javaExePath)
            Write-Host "Found java.exe at: $javaExePath" -ForegroundColor Green
        }
    }
}
else {
    # Use detected commands
    Write-Host "Detected java at: $javaExe" -ForegroundColor Green
    $installPath = Split-Path -Parent (Split-Path -Parent $javaExe)
}

if (-not $installPath) {
    Write-Warning "Could not automatically determine JDK install path. Please ensure JDK is installed and in PATH, or set JAVA_HOME manually."
    Write-Host "You can install Temurin manually from: https://adoptium.net" -ForegroundColor Cyan
    exit 1
}

# Normalize path (remove trailing backslash)
$installPath = $installPath.TrimEnd('\')

# Set environment variables for current process
$env:JAVA_HOME = $installPath
$env:PATH = "$($env:JAVA_HOME)\bin;" + $env:PATH

Write-Host "Temporarily set JAVA_HOME=$env:JAVA_HOME" -ForegroundColor Green

# Persist JAVA_HOME and PATH system-wide (requires admin)
try {
    Write-Host "Persisting JAVA_HOME and updating system PATH (setx)" -ForegroundColor Cyan
    setx /M JAVA_HOME "$installPath" | Out-Null

    # Append JAVA_HOME\bin to system PATH safely
    $currentSystemPath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    if ($currentSystemPath -notlike "*%JAVA_HOME%*" -and $currentSystemPath -notlike "*$installPath*") {
        $newSystemPath = $currentSystemPath + ";$installPath\bin"
        setx /M PATH "$newSystemPath" | Out-Null
        Write-Host "System PATH updated." -ForegroundColor Green
    }
    else {
        Write-Host "System PATH already contains Java bin." -ForegroundColor Green
    }
}
catch {
    Write-Warning "Failed to persist environment variables: $($_.Exception.Message)"
}

# Verify
Write-Host "Verifying java and javac versions..." -ForegroundColor Cyan
java -version 2>&1 | Write-Host
javac -version 2>&1 | Write-Host

# Compile and run the Swing App
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Definition)
# If script is in scripts/, project root is parent of scripts
if (Test-Path (Join-Path $projectRoot 'src\App.java')) {
    Push-Location $projectRoot
}
elseif (Test-Path (Join-Path (Get-Location) 'src\App.java')) {
    # already in project root
    $projectRoot = Get-Location
}
else {
    Write-Warning "Could not find src\App.java automatically. Ensure you run this from the project root or the script is in scripts/ under the project root.";
}

if (-not (Test-Path 'src\App.java')) {
    Write-Error "Cannot find src\App.java. Aborting compile/run."
    exit 1
}

if (-not (Test-Path 'bin')) { New-Item -ItemType Directory -Path 'bin' | Out-Null }

try {
    Write-Host "Compiling src\App.java..." -ForegroundColor Cyan
    javac -d bin -sourcepath src src\App.java
    Write-Host "Compilation finished." -ForegroundColor Green
}
catch {
    Write-Error "Compilation failed: $($_.Exception.Message)"
    exit 1
}

Write-Host "Running App... (close window to finish)" -ForegroundColor Cyan
try {
    java -cp bin App
}
catch {
    Write-Error "Failed to run App: $($_.Exception.Message)"
    exit 1
}

Write-Host "Done." -ForegroundColor Green
