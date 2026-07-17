param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot "config.json"),
    [string]$StatePath = (Join-Path $PSScriptRoot "state.json"),
    [string]$LogPath = (Join-Path $PSScriptRoot "bot.log"),
    [string]$MessagePath = (Join-Path $PSScriptRoot "message.txt")
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Text)

    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Text"
    Add-Content -Path $LogPath -Value $line -Encoding UTF8
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

function Initialize-Config {
    $autoConfig = Join-Path $PSScriptRoot "auto-config.ps1"
    if (-not (Test-Path $autoConfig)) {
        throw "config.json not found. Run start.bat"
    }

    & $autoConfig -ConfigPath $ConfigPath
    if (-not (Test-Path $ConfigPath)) {
        throw "Could not create config.json. Run start.bat"
    }
}

function Get-LastSentKey {
    if (-not (Test-Path $StatePath)) {
        return $null
    }

    $state = Get-Content $StatePath -Raw -Encoding UTF8 | ConvertFrom-Json
    return $state.lastSentKey
}

function Set-LastSentKey {
    param([string]$Key)

    $json = @{ lastSentKey = $Key } | ConvertTo-Json
    [System.IO.File]::WriteAllText($StatePath, $json, [System.Text.UTF8Encoding]::new($false))
}

function Format-Schedule {
    param([int[]]$Hours)

    return ($Hours | ForEach-Object { '{0:D2}:00' -f $_ }) -join ', '
}

function Get-ReminderMessage {
    param([object]$Config)

    if ($Config.message) {
        return [string]$Config.message
    }

    if (Test-Path $MessagePath) {
        $text = (Get-Content $MessagePath -Raw -Encoding UTF8).Trim()
        if (-not [string]::IsNullOrWhiteSpace($text)) {
            return $text
        }
    }

    return "VKLYUCHI SROCHNYE ZAKAZY"
}

if (-not (Test-Path $ConfigPath)) {
    Initialize-Config
}

$config = Get-Content $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
$hours = @($config.hours)
if ($hours.Count -eq 0) {
    $hours = @(9, 12, 15, 18)
}

$message = Get-ReminderMessage -Config $config
$schedule = Format-Schedule -Hours $hours

Write-Host ""
Write-Host "=== Telegram Reminder Bot ==="
Write-Host "Message: $message"
Write-Host "Schedule: $schedule"
Write-Host ""
Write-Log "Bot started. Schedule: $schedule"

try {
    Send-TelegramMessage -BotToken $config.botToken -ChatId $config.chatId -Text ("Bot started. Reminders: " + $schedule)
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Startup message sent."
    Write-Log "Startup message sent."
}
catch {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Send error: $($_.Exception.Message)"
    Write-Log "Startup error: $($_.Exception.Message)"
    if ($Host.Name -eq "ConsoleHost") {
        Read-Host "Press Enter to exit"
    }
    exit 1
}

while ($true) {
    $now = Get-Date
    $hour = $now.Hour
    $minute = $now.Minute

    if ($minute -eq 0 -and $hours -contains $hour) {
        $sentKey = "{0:yyyy-MM-dd}-{1}" -f $now, $hour

        if ((Get-LastSentKey) -ne $sentKey) {
            try {
                Send-TelegramMessage -BotToken $config.botToken -ChatId $config.chatId -Text $message
                Set-LastSentKey -Key $sentKey
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Reminder sent."
                Write-Log "Reminder sent."
            }
            catch {
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Error: $($_.Exception.Message)"
                Write-Log "Reminder error: $($_.Exception.Message)"
            }
        }
    }

    Start-Sleep -Seconds 30
}
