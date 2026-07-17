param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot "config.json")
)

$ErrorActionPreference = "Stop"

Write-Host "Telegram reminder bot setup"
Write-Host ""

$botToken = Read-Host "Enter BOT_TOKEN from @BotFather"
if ([string]::IsNullOrWhiteSpace($botToken)) {
    throw "BOT_TOKEN is required."
}

Write-Host ""
Write-Host "1. Open your bot in Telegram"
Write-Host "2. Send the command: /start"
Write-Host ""
Read-Host "Press Enter after you sent /start"

$updatesUri = "https://api.telegram.org/bot$botToken/getUpdates"
$updates = Invoke-RestMethod -Uri $updatesUri -Method Get

$chatId = $null
foreach ($update in $updates.result) {
    $text = $update.message.text
    if ($text -eq "/start") {
        $chatId = [string]$update.message.chat.id
        break
    }
}

if (-not $chatId) {
    throw "Could not find /start message. Send /start to the bot and run setup again."
}

$timezone = Read-Host "Timezone [Europe/Moscow]"
if ([string]::IsNullOrWhiteSpace($timezone)) {
    $timezone = "Europe/Moscow"
}

$config = [ordered]@{
    botToken = $botToken
    chatId   = $chatId
    timezone = $timezone
    message  = "ВКЛЮЧИ СРОЧНЫЕ ЗАКАЗЫ"
    hours    = @(9, 12, 15, 18)
}

$config | ConvertTo-Json -Depth 3 | Set-Content -Path $ConfigPath -Encoding UTF8

Write-Host ""
Write-Host "Saved config to $ConfigPath"
Write-Host "Chat ID: $chatId"
Write-Host ""
Write-Host "Next step: run install-scheduler.ps1"
