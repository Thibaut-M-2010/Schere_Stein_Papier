<#
Create and push an annotated Git tag safely.

Usage (run locally where `git` is available):
  powershell -ExecutionPolicy Bypass -File .\scripts\create-and-push-tag.ps1

The script will prompt for a tag name (e.g. v1.0.0-test) and a message,
show the git status and the exact commands it will run, then ask for confirmation.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Check-Git {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Error "git is not available on PATH. Run this script on your machine with Git installed."
        exit 1
    }
}

Check-Git

$branch = (& git rev-parse --abbrev-ref HEAD).Trim()
Write-Host "Current branch: $branch"

Write-Host "Git status (short):"
git status --porcelain

$tag = Read-Host "Enter tag name to create (e.g. v1.0.0-test)"
if (-not $tag) { Write-Error "No tag provided. Aborting."; exit 1 }

$msg = Read-Host "Enter tag message (short)"
if (-not $msg) { $msg = "Release $tag" }

Write-Host "The script will run these commands:" -ForegroundColor Cyan
Write-Host "  git tag -a $tag -m \"$msg\""
Write-Host "  git push origin --tags"

$ok = Read-Host "Create and push tag now? (y/N)"
if ($ok.ToLower() -ne 'y') { Write-Host "Aborted by user."; exit 0 }

Write-Host "Creating annotated tag..."
git tag -a $tag -m "$msg"

Write-Host "Pushing tags to origin..."
git push origin --tags

Write-Host "Tag pushed: $tag" -ForegroundColor Green
