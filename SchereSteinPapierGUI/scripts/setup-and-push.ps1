
<#
Helper script: initialize remote origin (if needed), commit, push and create tag.

Usage (from project root):
  powershell -ExecutionPolicy Bypass -File .\scripts\setup-and-push.ps1

This script will:
  - Initialize a Git repo (if needed)
  - Add and commit local changes
  - Add or update the 'origin' remote URL
  - Push the current branch
  - Optionally create and push a tag

The script will not store credentials; when `git push` requires authentication, Git will prompt
you (Credential Manager / PAT / SSH as configured on your machine).
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

param(
    [string]$GitPath
)

function Write-Info($m) { Write-Host $m -ForegroundColor Cyan }
function Write-Ok($m) { Write-Host $m -ForegroundColor Green }
function Write-Err($m) { Write-Host $m -ForegroundColor Red }

# Determine git command to use (either provided path or 'git' on PATH)
if ($GitPath) {
    # If a folder was provided, allow both folder\git.exe and full path
    if (Test-Path $GitPath -PathType Leaf) { $gitCmd = $GitPath }
    elseif (Test-Path (Join-Path $GitPath 'git.exe')) { $gitCmd = Join-Path $GitPath 'git.exe' }
    else { Write-Err "Provided GitPath not found: $GitPath"; exit 1 }
}
else { $gitCmd = 'git' }

# Ensure script runs from repo root (parent of scripts folder)
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$projectRoot = Split-Path -Parent $scriptDir
Set-Location $projectRoot

Write-Info "Working directory: $projectRoot"

# Check git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Err "git not found. Install Git for Windows: https://git-scm.com/download/win"
    exit 1
}

# Initialize repo if needed
if (-not (Test-Path .git)) {
    Write-Info "No .git found - initializing repository"
    & $gitCmd init
    Write-Ok "Repository initialized."
}
else { Write-Info ".git found - existing repository" }

# Show status
& $gitCmd status --porcelain

# Add all and commit if there are changes
$status = & $gitCmd status --porcelain
if ($status) {
    Write-Info "Staging changes and creating commit..."
    & $gitCmd add -A
    $msg = Read-Host "Commit message (default: 'Prepare release')"
    if (-not $msg) { $msg = 'Prepare release' }
    & $gitCmd commit -m $msg
    Write-Ok "Committed changes: $msg"
}
else { Write-Info "No changes to commit." }

# Determine current branch
$branch = (& $gitCmd rev-parse --abbrev-ref HEAD) 2>$null
if (-not $branch -or $branch -eq 'HEAD') {
    Write-Info "No current branch (detached HEAD) - creating 'main' and switching"
    & $gitCmd checkout -b main
    $branch = 'main'
}
Write-Info "Current branch: $branch"

# Remote setup
$remotes = (& $gitCmd remote)
if ($remotes -match 'origin') {
    Write-Info "Remote 'origin' already exists:"; & $gitCmd remote -v | Select-String 'origin'
    $change = Read-Host "Do you want to change the origin URL? (y/N)"
    if ($change -match '^[Yy]') {
        $url = Read-Host "Enter GitHub repo URL (https://github.com/username/repo.git)"
        if ($url) { & $gitCmd remote set-url origin $url; Write-Ok "origin set to $url" }
    }
}
else {
    $url = Read-Host "Enter GitHub repo URL to add as origin (e.g. https://github.com/username/repo.git)"
    if (-not $url) { Write-Err "No URL provided, cannot add origin. Exiting."; exit 1 }
    & $gitCmd remote add origin $url
    Write-Ok "Added origin: $url"
}

# Push branch
Write-Info "Pushing branch $branch to origin..."
try {
    & $gitCmd push -u origin $branch
    Write-Ok "Pushed branch $branch to origin"
}
catch {
    Write-Err "git push failed: $($_.Exception.Message)"; exit 1
}

# Create and push tag (optional)
$doTag = Read-Host "Create a release tag now? (y/N)"
if ($doTag -match '^[Yy]') {
    $tag = Read-Host "Tag name (default: v1.0.0)"
    if (-not $tag) { $tag = 'v1.0.0' }
    & $gitCmd tag $tag
    Write-Info "Pushing tag $tag..."
    try { & $gitCmd push origin $tag; Write-Ok "Tag pushed: $tag" }
    catch { Write-Err "Failed to push tag: $($_.Exception.Message)" }
}
else { Write-Info "Skipping tag creation." }

Write-Ok "Done. Visit your GitHub repository to confirm the push and/or release."
