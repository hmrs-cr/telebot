param([string] $Params, [int]$messageId)
Close-Process -ProcTitle "OBS Studio" -ProcName "obs64" -MessageId $messageId
Execute-Process -ProcTitle "OBS Studio" -ProcPath "C:\Program Files\obs-studio\bin\64bit" -ProcName "obs64" -MessageId $messageId