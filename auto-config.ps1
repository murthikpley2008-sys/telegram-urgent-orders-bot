param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot "config.json"),
    [string]$TokenPath = (Join-Path $PSScriptRoot "bot-token.txt"),
    [string]$MessagePath = (Join-Path $PSScriptRoot "message.txt"),
    [int]$WaitSeconds = 180
)

$ErrorActionPreference = "Stop"

function Get-BotToken {
    if (-not (Test-Path $TokenPath)) {
        throw "File bot-token.txt not found."
    }

    $token = (Get-Content $TokenPath -Raw -Encoding UTF8).Trim()
    if ([string]::IsNullOrWhiteSpace($token)) {
        throw "File bot-token.txt is empty."
    }

    return $token
}

function Get-ReminderMessage {
    if (Test-Path $MessagePath) {
        $text = (Get-Content $MessagePath -Raw -Encoding UTF8).Trim()
        if (-not [string]::IsNullOrWhiteSpace($text)) {
            return $text
        }
    }

    return "VKLYUCHI SROCHNYE ZAKAZY"
}

function Get-ChatIdFromUpdates {
    param([string]$BotToken)

    $updates = Invoke-RestMethod -Uri "https://api.telegram.org/bot$BotToken/getUpdates" -Method Get

    for ($i = $updates.result.Count - 1; $i -ge 0; $i--) {
        $update = $updates.result[$i]
        if ($update.message -and $update.message.chat.id) {
            return [string]$update.message.chat.id
        }
    }

    return $null
}

function Save-Config {
    param(
        [string]$BotToken,
        [string]$ChatId,
        [string]$Message
    )

    $config = [ordered]@{
        botToken = $BotToken
        chatId   = $ChatId
        timezone = "Europe/Moscow"
        message  = $Message
        hours    = @(9, 12, 15, 18)
    }

    $json = $config | ConvertTo-Json -Depth 3
    [System.IO.File]::WriteAllText($ConfigPath, $json, [System.Text.UTF8Encoding]::new($false))
}

$botToken = Get-BotToken
$reminderMessage = Get-ReminderMessage

if (Test-Path $ConfigPath) {
    $existing = Get-Content $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($existing.chatId -and $existing.botToken) {
        Write-Host "Config already exists. Chat ID: $($existing.chatId)"
        exit 0
    }
}

Write-Host ""
Write-Host "=== Auto setup ==="
Write-Host ""

try {
    $me = Invoke-RestMethod -Uri "https://api.telegram.org/bot$botToken/getMe" -Method Get
    $username = $me.result.username
    Write-Host "Bot found: @$username"
    Write-Host "Link: https://t.me/$username"
}
catch {
    throw "Invalid token or no internet: $($_.Exception.Message)"
}

try {
    Invoke-RestMethod -Uri "https://api.telegram.org/bot$botToken/deleteWebhook" -Method Get | Out-Null
}
catch {
    Write-Host "Warning: could not reset webhook."
}

$chatId = Get-ChatIdFromUpdates -BotToken $botToken

if (-not $chatId) {
    Write-Host ""
    Write-Host "Open the bot in Telegram and press START or send /start"
    Write-Host "Waiting up to $WaitSeconds seconds..."
    Write-Host ""

    $deadline = (Get-Date).AddSeconds($WaitSeconds)
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 3
        $chatId = Get-ChatIdFromUpdates -BotToken $botToken
        if ($chatId) {
            break
        }
        Write-Host "." -NoNewline
    }

    Write-Host ""
}

if (-not $chatId) {
    throw "Chat ID not found. Open https://t.me/$username, press START, then run start.bat again."
}

Save-Config -BotToken $botToken -ChatId $chatId -Message $reminderMessage
Write-Host ""
Write-Host "Done! Chat ID: $chatId"
Write-Host ""
