param([string] $Params, [int]$messageId)

$obsProcName = "obs64"
$obspath="C:\Program Files\obs-studio\bin\64bit\$obsProcName.exe"

$obsProcess = $(Get-Process -ErrorAction:Ignore $obsProcName)
if ($obsProcess) {
    Reply -Message "OBS already running."
} else {
    Log "Opening $obspath"
    Start-Process -FilePath $obspath -WorkingDirectory $(Split-Path -Path $obspath)
    Start-Sleep 2

    $count = 0;
    while ((-not ($obsProcess = $(Get-Process -ErrorAction:Ignore $obsProcName))) -and $count -le 5) {
        Start-Sleep 1
        $count = $count + 1
    }

    if($obsProcess) {
        Reply -Message "OBS is now running." -ReplyToId $messageId
    } else {
        Reply -Message "OBS is not running." -ReplyToId $messageId
    }
}