param(
    [string]$RepoUrl = ""
)

$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot

function Ensure-Git {
    $git = Get-Command git -ErrorAction SilentlyContinue
    if ($git) {
        return $git.Source
    }

    $candidates = @(
        "C:\Program Files\Git\bin\git.exe",
        "C:\Program Files\Git\cmd\git.exe"
    )

    foreach ($path in $candidates) {
        if (Test-Path $path) {
            $env:Path = (Split-Path $path -Parent) + ";" + $env:Path
            return $path
        }
    }

    throw "Git not found. Install from https://git-scm.com/download/win and run this script again."
}

function Test-SecretsInGit {
    param([string]$Root)

    $tracked = & git -C $Root ls-files 2>$null
    $danger = @("config.json", "bot-token.txt", ".env", "bot.log", "state.json")

    foreach ($file in $danger) {
        if ($tracked -contains $file) {
            throw "Security error: $file is tracked by git. Remove it before pushing."
        }
    }
}

Set-Location $ProjectRoot
Ensure-Git | Out-Null

Write-Host ""
Write-Host "=== Deploy Telegram bot to GitHub ==="
Write-Host ""

if (-not (Test-Path (Join-Path $ProjectRoot "config.json"))) {
    Write-Host "config.json not found. Run start.bat or setup.ps1 first."
    exit 1
}

$config = Get-Content (Join-Path $ProjectRoot "config.json") -Raw -Encoding UTF8 | ConvertFrom-Json

Write-Host "GitHub Secrets (add in repo Settings -> Secrets -> Actions):"
Write-Host ""
Write-Host "  TELEGRAM_BOT_TOKEN = $($config.botToken)"
Write-Host "  TELEGRAM_CHAT_ID   = $($config.chatId)"
Write-Host ""

if (-not (Test-Path (Join-Path $ProjectRoot ".git"))) {
    Write-Host "Initializing git repository..."
    git init
    git branch -M main
}

Test-SecretsInGit -Root $ProjectRoot

$status = git status --porcelain
if ($status) {
    git add .
    git commit -m "Add Telegram reminder bot with GitHub Actions cloud schedule"
    Write-Host "Commit created."
}
else {
    Write-Host "No new changes to commit."
}

$remote = git remote get-url origin 2>$null
if (-not $remote -and $RepoUrl) {
    git remote add origin $RepoUrl
    $remote = $RepoUrl
}

Write-Host ""
if ($remote) {
    Write-Host "Remote: $remote"
    Write-Host ""
    Write-Host "Pushing to GitHub..."
    git push -u origin main
    Write-Host ""
    Write-Host "Done. Next steps:"
    Write-Host "1. Add secrets on GitHub (values shown above)"
    Write-Host "2. Actions -> Telegram reminders -> Run workflow"
    Write-Host "3. Stop local bot: .\stop.bat"
}
else {
    Write-Host "Remote not configured yet."
    Write-Host ""
    Write-Host "1. Create repo: https://github.com/new"
    Write-Host "2. Then run:"
    Write-Host ""
    Write-Host "   git remote add origin https://github.com/YOUR_USER/telegram-urgent-orders-bot.git"
    Write-Host "   git push -u origin main"
    Write-Host ""
    Write-Host "Or rerun with URL:"
    Write-Host "   .\deploy-github.ps1 -RepoUrl https://github.com/YOUR_USER/telegram-urgent-orders-bot.git"
    Write-Host ""
    Write-Host "Full guide: GITHUB-DEPLOY.md"
}

Write-Host ""
