# Builds flutter-fastapi-auth-starter.zip for Gumroad.
# Uses `git archive`, so only committed files are included — .git, marketing/,
# build outputs, .env and everything else in .gitignore are excluded automatically.
# Run from the repo root:  .\package.ps1

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $repoRoot

$dirty = git status --porcelain
if ($dirty) {
    Write-Warning "Uncommitted changes exist and will NOT be included in the zip:"
    $dirty | ForEach-Object { Write-Warning "  $_" }
}

$zip = Join-Path $repoRoot 'flutter-fastapi-auth-starter.zip'
if (Test-Path $zip) { Remove-Item $zip }

git archive --format=zip --prefix=flutter-fastapi-auth-starter/ -o $zip HEAD

$size = [math]::Round((Get-Item $zip).Length / 1MB, 2)
Write-Output "Created $zip ($size MB)"
