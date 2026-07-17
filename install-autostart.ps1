param(
    [string]$ProjectRoot = $PSScriptRoot
)

$ErrorActionPreference = "Stop"

$startupFolder = [Environment]::GetFolderPath("Startup")
$vbsPath = Join-Path $ProjectRoot "run-hidden.vbs"
$shortcutPath = Join-Path $startupFolder "TelegramReminderBot.lnk"

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "wscript.exe"
$shortcut.Arguments = "`"$vbsPath`""
$shortcut.WorkingDirectory = $ProjectRoot
$shortcut.WindowStyle = 7
$shortcut.Description = "Telegram reminder bot"
$shortcut.Save()

Write-Host "Autostart added: $shortcutPath"
