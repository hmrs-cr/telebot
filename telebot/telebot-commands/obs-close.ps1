param([string] $Params, [int]$messageId)


$obsProcName = "obs64"

$obsProcess = $(Get-Process -ErrorAction:Ignore $obsProcName)
if ($obsProcess) 
{
    Log "Clossing OBS Studio."
    if (-not $obsProcess.CloseMainWindow()) 
    {
        Stop-Process $obsProcess
    }
    
    $count = 0;
    while (($obsProcess = $(Get-Process -ErrorAction:Ignore $obsProcName)) && $count <= 5) {
        Start-Sleep 1
        $count = $count + 1
    }

    if ($obsProcess) {
        Reply -Message "OBS is still running." -ReplyToId $messageId
    } else {
        Reply -Message "OBS is not running anymore." -ReplyToId $messageId
    }
}
else {
    Reply -Message "OBS is not running." -ReplyToId $messageId
}