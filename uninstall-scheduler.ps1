param(
    [string]$TaskPrefix = "TelegramUrgentOrdersReminder"
)

$ErrorActionPreference = "Stop"

$tasks = Get-ScheduledTask -TaskName "$TaskPrefix-*" -ErrorAction SilentlyContinue
if (-not $tasks) {
    Write-Host "No tasks found."
    exit 0
}

foreach ($task in $tasks) {
    Unregister-ScheduledTask -TaskName $task.TaskName -Confirm:$false
    Write-Host "Removed task: $($task.TaskName)"
}

Write-Host "All reminder tasks removed."
