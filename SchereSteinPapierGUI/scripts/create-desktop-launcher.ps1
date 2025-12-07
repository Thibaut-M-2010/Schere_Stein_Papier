
<#
Create a desktop launcher for Windows

What it does:
- Compiles `src\App.java` to `bin` if needed and `javac` is available.
- Attempts to create a runnable JAR `dist\SchereSteinPapier.jar` using the `jar` tool.
- If JAR creation isn't possible, it falls back to creating a desktop shortcut that runs `java -cp "<project>\bin" App`.
- Places a shortcut `SchereSteinPapier.lnk` on the current user's desktop.

Usage (from project root):
    powershell -ExecutionPolicy Bypass -File .\scripts\create-desktop-launcher.ps1

Note: Java must be installed for the resulting launcher to work. If you don't have Java, run the installer script first: `scripts\install-jdk-and-run.ps1`.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Info($msg) { Write-Host $msg -ForegroundColor Cyan }
function Write-Ok($msg) { Write-Host $msg -ForegroundColor Green }

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$projectRoot = Split-Path -Parent $scriptDir

Write-Info "Project root: $projectRoot"

Push-Location $projectRoot

if (-not (Test-Path 'src\App.java')) {
    Write-Host "Cannot find src\App.java in project root. Abort." -ForegroundColor Red
    Pop-Location
    exit 1
}

if (-not (Test-Path 'bin')) { New-Item -ItemType Directory -Path 'bin' | Out-Null }

# Compile if possible
$javac = Get-Command javac -ErrorAction SilentlyContinue
if ($javac) {
    Write-Info "Compiling src\App.java..."
    javac -d bin -sourcepath src src\App.java
    Write-Ok "Compilation complete."
}
else {
    Write-Info "javac not found — skipping compilation. Ensure classes exist in bin or install a JDK."
}

# Prepare dist folder
if (-not (Test-Path 'dist')) { New-Item -ItemType Directory -Path 'dist' | Out-Null }
$jarPath = Join-Path $projectRoot 'dist\SchereSteinPapier.jar'

$jarTool = Get-Command jar -ErrorAction SilentlyContinue
$createdJar = $false
if ($jarTool -and (Test-Path 'bin')) {
    try {
        Write-Info "Creating runnable JAR at $jarPath..."
        # Create jar with entry point App
        & jar cfe "$jarPath" App -C bin .
        Write-Ok "JAR created: $jarPath"
        $createdJar = $true
    }
    catch {
        Write-Host "Failed to create JAR: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}
else {
    Write-Info "jar tool not found or bin missing — will create a desktop shortcut that runs classes from bin."
}

# Create desktop shortcut
$desktop = [Environment]::GetFolderPath('Desktop')
$shortcutPath = Join-Path $desktop 'SchereSteinPapier.lnk'

$wsh = New-Object -ComObject WScript.Shell
$shortcut = $wsh.CreateShortcut($shortcutPath)

if ($createdJar) {
    $shortcut.TargetPath = 'java'
    $shortcut.Arguments = "-jar `"$jarPath`""
    $shortcut.WorkingDirectory = $projectRoot
    $shortcut.IconLocation = "$jarPath,0"
    Write-Ok "Created desktop shortcut (runs jar): $shortcutPath"
}
else {
    # Find java path for the TargetPath if available
    $javaCmd = Get-Command java -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue
    if ($javaCmd) { $shortcut.TargetPath = $javaCmd } else { $shortcut.TargetPath = 'java' }
    $binPath = Join-Path $projectRoot 'bin'
    $shortcut.Arguments = "-cp `"$binPath`" App"
    $shortcut.WorkingDirectory = $projectRoot
    Write-Ok "Created desktop shortcut (runs classes from bin): $shortcutPath"
}

$shortcut.Save()

Write-Host "Launcher created. Double-click the shortcut on your Desktop to start the app." -ForegroundColor Green

Pop-Location
