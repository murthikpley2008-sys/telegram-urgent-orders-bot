@echo off
chcp 65001 >nul
title Telegram Reminder Bot
cd /d "%~dp0"

echo.
echo  ========================================
echo   Telegram Reminder Bot
echo  ========================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0auto-config.ps1"
if errorlevel 1 (
    echo.
    echo  Setup failed. See message above.
    echo.
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-autostart.ps1"

echo.
echo  Starting bot in background...
start "" wscript.exe "%~dp0run-hidden.vbs"

echo.
echo  Done!
echo  - Bot is running in background
echo  - Autostart enabled on Windows login
echo  - Reminders at 9:00, 12:00, 15:00, 18:00
echo.
echo  Check Telegram for "Bot started..." message
echo.
timeout /t 8 >nul
