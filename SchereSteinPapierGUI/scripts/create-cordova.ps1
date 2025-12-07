<#
Create a Cordova project scaffold that wraps the `web/` folder so you can build an Android APK.

Usage (run THIS LOCALLY; Android SDK + Cordova required):
  powershell -ExecutionPolicy Bypass -File .\scripts\create-cordova.ps1 -AppId "com.example.ssp" -AppName "SchereSteinPapierMobile"

What it does:
 - checks for `cordova`
 - creates a Cordova project under `scripts/cordova-app`
 - copies the current `web/` files into the Cordova `www/` directory
 - adds the Android platform

Notes:
 - Building the final APK requires Android SDK/Gradle installed locally and configured for Cordova.
 - This script is a convenience to scaffold — you still must run `cordova build android` locally.
#>

param(
    [string] $AppId = 'com.example.ssp',
    [string] $AppName = 'SchereSteinPapierMobile'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Check-Cordova {
    if (-not (Get-Command cordova -ErrorAction SilentlyContinue)) {
        Write-Error "Cordova CLI not found. Install with: npm install -g cordova"
        exit 1
    }
}

Check-Cordova

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$out = Join-Path $scriptDir 'cordova-app'

if (Test-Path $out) {
    Write-Host "Removing existing scaffold at $out"
    Remove-Item -Recurse -Force -Path $out
}

Write-Host "Creating Cordova project at $out"
cordova create $out $AppId $AppName

Write-Host "Copying web/ contents into Cordova www/"
$srcWeb = Join-Path (Split-Path -Parent $scriptDir) 'web'
$destWww = Join-Path $out 'www'
Copy-Item -Path (Join-Path $srcWeb '*') -Destination $destWww -Recurse -Force

Push-Location $out
Write-Host "Adding Android platform (this may download Android platforms via Cordova)..."
cordova platform add android
Pop-Location

Write-Host "Cordova scaffold created: $out"
Write-Host "To build locally, run:`n  cd $out`n  cordova build android`" -ForegroundColor Cyan
