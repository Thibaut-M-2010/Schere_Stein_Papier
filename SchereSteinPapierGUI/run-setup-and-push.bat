@echo off
REM Wrapper to run the interactive setup-and-push PowerShell script with ExecutionPolicy Bypass
REM Place this file in the project root and double-click it, or run from the command line.

SETLOCAL
SET SCRIPT=%~dp0scripts\setup-and-push.ps1

IF NOT EXIST "%SCRIPT%" (
  echo Script not found: "%SCRIPT%"
  pause
  exit /b 1
)

echo Running setup-and-push using PowerShell (ExecutionPolicy Bypass)

powershell -NoProfile -ExecutionPolicy Bypass -Command "
$script = '%SCRIPT%';
if (-not (Test-Path $script)) { Write-Host 'Script not found:' $script; Pause; exit 1 }
$git = (Get-Command git -ErrorAction SilentlyContinue).Source
if (-not $git) {
  $candidates = @('C:\\Program Files\\Git\\cmd\\git.exe','C:\\Program Files (x86)\\Git\\cmd\\git.exe','C:\\tools\\portable-git\\cmd\\git.exe')
  foreach ($c in $candidates) { if (Test-Path $c) { $git = $c; break } }
}
if ($git) { Write-Host 'Using git:' $git; & $script -GitPath $git }
else { Write-Host 'No git found on PATH or common locations; attempting to run script using "git" (may prompt)'; & $script }
Pause
"

ENDLOCAL
