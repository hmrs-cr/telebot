param (      
    [String] $SourceFolder = $ENV:GC_MOVE_SOURCE,
    [String] $DestinationFolder = $ENV:GC_MOVE_DESTINATION,
    [String] $LogFile = "logs/$($(Get-Date).ToString('yyyyMMddHHmmss')).gsmove.log",
    [String] $TelegramBotKey = $ENV:TELEGRAM_NOTIF_BOT_KEY,
    [String] $TelegramChatId = $ENV:TELEGRAM_NOTIF_CHAT_ID
 )

 $pidFile = "$HOME/.hmsoft/gc-move.pid"

 function Log {
    param (
       [string] $msg
    )
    $dt = $(Get-Date)
    "$($dt.ToString('yyyy-MM-dd HH:mm:ss')) $msg"
}


 $runningPid = Get-Content -Path $pidFile  -ErrorAction:Ignore
 if ($runningPid) {
   $process = Get-Process -Id $runningPid  -ErrorAction:Ignore
   if ($process -and $process.ProcessName -and $process.ProcessName -in "pwsh", "powershell" ) {        
     Log "Script already running."
     exit 1
   }
 }

 if ($LogFile) 
 {
    New-Item -Path $(Split-Path -Path $LogFile) -ItemType Directory -Force  | Out-Null
    $ErrorActionPreference="SilentlyContinue"
    Stop-Transcript -ErrorAction:Ignore | Out-Null    
    $ErrorActionPreference = "Continue"
    Start-Transcript -Path $LogFile -Append
 }

 $MAX_FILE_SIZE=9000000000

 Function Format-FileSize() {
    param ([long]$size)
    if     ($size -gt 1TB) {[string]::Format("{0:0.00} TB", $size / 1TB)}
    elseif ($size -gt 1GB) {[string]::Format("{0:0.00} GB", $size / 1GB)}
    elseif ($size -gt 1MB) {[string]::Format("{0:0.00} MB", $size / 1MB)}
    elseif ($size -gt 1KB) {[string]::Format("{0:0.00} kB", $size / 1KB)}
    elseif ($size -gt 0)   {[string]::Format("{0:0.00} B", $size)}
    else                   {"0B"}
}

if (-not $SourceFolder) {
    "Please enter a source folder"
    exit 1
}

if (-not $DestinationFolder) {
    "Please enter a destination folder"
    exit 1
}

New-Item -Path $(Split-Path -Path $pidFile) -ItemType Directory -Force -ErrorAction:Ignore | Out-Null
Set-Content -Path  $pidFile -Value $PID -ErrorAction:Ignore

do 
{
    $muxFound = $false;
    while ($(Get-Process -ErrorAction:Ignore obs-ffmpeg-mux)) 
    {
        if (-not $muxFound) 
        {
            Log "MUX Process found. Waiting for recording to end."
            $muxFound = $true    
        }

        Start-Sleep 1
    }

    if ($muxFound) 
    {
        Start-Sleep 300
    }
} while ($muxFound)


$obsProcess = $(Get-Process -ErrorAction:Ignore obs64)
if ($obsProcess) 
{
    Log "Clossing OBS Studio"
    if (-not $obsProcess.CloseMainWindow()) 
    {
        Stop-Process $obsProcess
    }
}

Log "Starting to move files"

$count = 0
$errorCount = 0
$byteCount = 0L
$startDate = $(Get-Date)
Get-ChildItem -Path "$SourceFolder/*.mkv" | Sort-Object -Property Length | ForEach-Object -Process {
    $fileToMove = $_    

    try 
    {     
        $newPath = $(Join-Path $DestinationFolder $fileToMove.CreationTime.ToString('yyyy-MM-dd'))
        $destSubFolder = $(New-Item -Path  $newPath -ItemType Directory -Force)    

        if ($fileToMove.Length -gt $MAX_FILE_SIZE) 
        {        
            $chunkSize = [long](($fileToMove.Length / ([long][Math]::Ceiling($fileToMove.Length / $MAX_FILE_SIZE))))
            Log "File $fileToMove is too big. Splitting... (Chunk size: $chunkSize. Parts: $($fileToMove.Length / $chunkSize))"
            mkvmerge --split $chunkSize -o "$destSubFolder/$($fileToMove.Name)" "$fileToMove"
            if($?) 
            {
                Log "Removing file $fileToMove..."
                Remove-Item $fileToMove
            }
        }
        else 
        {            
            Log "Moving $fileToMove to $destSubFolder"
            Move-Item -Path $fileToMove -Destination $destSubFolder   
        }    
        $count = $count + 1
        $byteCount = $byteCount + $fileToMove.Length 
    } 
    catch 
    {
        $errorCount = $errorCount + 1
        $_.Exception
    }
}

$endDate = $(Get-Date)
$duration = $($endDate - $startDate).ToString('hh\:mm\:ss')

if ($count -eq 0 -and $errorCount -eq 0)
{
    $telegramText = "Script executed but nothing moved."
} 
elseif ($count -eq 0 -and $errorCount -gt 0) 
{
    $telegramText="*Nothing moved. $errorCount errors!*`nDuration: $duration"
}
else 
{
    $telegramText="Moved $count files with $errorCount errors.`nDuration: $duration"
}

$byteCount = Format-FileSize($byteCount)
$telegramText = "$telegramText`nSize: $byteCount`nFrom: '$SourceFolder' `nTo: '$DestinationFolder'"

if ($TelegramBotKey -and $TelegramChatId) 
{   
    $response = $(Invoke-WebRequest -ErrorAction:Ignore -Uri "https://api.telegram.org/bot$TelegramBotKey/sendMessage?parse_mode=Markdown&chat_id=$TelegramChatId&text=$telegramText")
}


$telegramText
"----------------------------------------------------------------"
""

Remove-Item $pidFile -ErrorAction:Ignore
Stop-Transcript