param([string] $Params, [int]$messageId)
Execute-Process -ProcTitle "OBS Studio" -ProcPath "C:\Program Files\obs-studio\bin\64bit" -ProcName "obs64" -MessageId $messageId