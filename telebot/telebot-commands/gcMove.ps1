$gcMovePath="D:\Share\Scripts\gc-move\scheduled.cmd"
Log "Executing $gcMovePath"
Start-Process $gcMovePath -WorkingDirectory $(Split-Path -Path $gcMovePath)