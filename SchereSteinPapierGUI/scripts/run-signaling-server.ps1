<#
Run the signaling server (helper).

Usage (PowerShell):
  powershell -ExecutionPolicy Bypass -File .\scripts\run-signaling-server.ps1

The script will:
 - check for Node.js
 - run `npm install` inside `scripts/` (which contains `signaling-server-package.json`)
 - start the server with `node signaling-server.js`

Run this locally on a machine with Node installed.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Check-Node {
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Error "Node.js (node) not found on PATH. Install Node.js and try again."
        exit 1
    }
}

Check-Node

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Push-Location $scriptDir

Write-Host "Installing dependencies in $scriptDir..."
if (Get-Command npm -ErrorAction SilentlyContinue) {
    npm --prefix . install --no-audit --no-fund
}
else {
    Write-Warning "npm not found on PATH. Skipping npm install — make sure dependencies are installed manually in scripts/."
}

Write-Host "Starting signaling server (node signaling-server.js)..."
node .\signaling-server.js

Pop-Location
