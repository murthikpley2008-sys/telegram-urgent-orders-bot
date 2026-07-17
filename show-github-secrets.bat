@echo off
chcp 65001 >nul
cd /d "%~dp0"

if not exist config.json (
    echo config.json not found. Run start.bat first.
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$c = Get-Content '.\config.json' -Raw -Encoding UTF8 | ConvertFrom-Json; Write-Host ''; Write-Host 'Use these values in GitHub Secrets:'; Write-Host ''; Write-Host ('TELEGRAM_BOT_TOKEN = ' + $c.botToken); Write-Host ('TELEGRAM_CHAT_ID   = ' + $c.chatId); Write-Host ''"
pause
