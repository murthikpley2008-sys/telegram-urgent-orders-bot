@echo off
chcp 65001 >nul
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0auto-config.ps1"
if errorlevel 1 pause & exit /b 1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0send-test.ps1"
pause
