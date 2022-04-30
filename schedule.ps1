# Schedule Task

$action = New-ScheduledTaskAction -Execute 'logCleanup.ps1'
$trigger = New-ScheduledTaskTrigger -Daily -At 11am
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "Powershell-Scheduler"