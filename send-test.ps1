$ErrorActionPreference = "Stop"

$configPath = Join-Path $PSScriptRoot "config.json"
$config = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json

$messagePath = Join-Path $PSScriptRoot "message.txt"
$text = "Test: bot is working!"
if (Test-Path $messagePath) {
    $reminder = (Get-Content $messagePath -Raw -Encoding UTF8).Trim()
    if ($reminder) {
        $text = $reminder
    }
}

$uri = "https://api.telegram.org/bot$($config.botToken)/sendMessage"
Invoke-RestMethod -Uri $uri -Method Post -Body @{ chat_id = $config.chatId; text = $text } | Out-Null
Write-Host "Test message sent to Telegram."
