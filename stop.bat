@echo off
chcp 65001 >nul
taskkill /F /IM powershell.exe /FI "WINDOWTITLE eq *run-bot*" >nul 2>&1
wmic process where "commandline like '%%run-bot.ps1%%'" delete >nul 2>&1
echo Бот остановлен.
timeout /t 3 >nul
