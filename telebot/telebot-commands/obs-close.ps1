$obsProcName = "obs64"

$obsProcess = $(Get-Process -ErrorAction:Ignore $obsProcName)
if ($obsProcess) 
{
    Log "Clossing OBS Studio."
    if (-not $obsProcess.CloseMainWindow()) 
    {
        Stop-Process $obsProcess
    }

    Start-Sleep 5
    $obsProcess = $(Get-Process -ErrorAction:Ignore $obsProcName)
    if ($obsProcess) {
        Reply -Message "OBS is still running."
    } else {
        Reply -Message "OBS is not running anymore."
    }
}
else {
    Reply -Message "OBS is not running."
}