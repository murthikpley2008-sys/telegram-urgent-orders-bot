param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot "config.json")
)

$ErrorActionPreference = "Stop"

function Get-Config {
    if (-not (Test-Path $ConfigPath)) {
        throw "Config not found. Run setup.ps1 first."
    }

    return Get-Content $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Send-TelegramMessage {
    param(
        [string]$BotToken,
        [string]$ChatId,
        [string]$Text
    )

    $uri = "https://api.telegram.org/bot$BotToken/sendMessage"
    $body = @{
        chat_id = $ChatId
        text    = $Text
    }

    Invoke-RestMethod -Uri $uri -Method Post -Body $body | Out-Null
}

$config = Get-Config
$message = if ($config.message) { $config.message } else { "ВКЛЮЧИ СРОЧНЫЕ ЗАКАЗЫ" }

Send-TelegramMessage -BotToken $config.botToken -ChatId $config.chatId -Text $message
Write-Host "Reminder sent at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
