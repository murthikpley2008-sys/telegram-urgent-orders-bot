param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot "config.json"),
    [string]$TaskPrefix = "TelegramUrgentOrdersReminder"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $ConfigPath)) {
    throw "Config not found. Run setup.ps1 first."
}

$config = Get-Content $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
$scriptPath = Join-Path $PSScriptRoot "send-reminder.ps1"
$hours = @($config.hours)

if ($hours.Count -eq 0) {
    $hours = @(9, 12, 15, 18)
}

Write-Host "Creating scheduled tasks for hours: $($hours -join ', ')"
Write-Host "Timezone from config: $($config.timezone)"
Write-Host ""

foreach ($hour in $hours) {
    $taskName = "$TaskPrefix-$hour"
    $existing = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existing) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }

    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    $trigger = New-ScheduledTaskTrigger -Daily -At ([datetime]::Today.AddHours($hour))
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel LeastPrivilege

    Register-ScheduledTask `
        -TaskName $taskName `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Principal $principal `
        -Description "Send Telegram reminder: $($config.message)" | Out-Null

    Write-Host "Created task: $taskName at $("{0:D2}:00" -f $hour)"
}

Write-Host ""
Write-Host "Done. Reminders will be sent daily at: $(($hours | ForEach-Object { '{0:D2}:00' -f $_ }) -join ', ')"
Write-Host "To test now, run: .\send-reminder.ps1"
