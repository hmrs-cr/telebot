
$global:TelegramBotUrl = "https://api.telegram.org/bot$global:TelegramBotKey"
$global:procExtension=".exe"

function Reply {
   param (
     [string] $Message,
     [string] $ChatId = $TelegramChatId,
     [string] $ReplyToId
   )

   Log "SM: $Message"

  try {
    $response = $(Invoke-WebRequest -ErrorAction:Ignore -Uri "$global:TelegramBotUrl/sendMessage?parse_mode=Markdown&chat_id=$ChatId&text=$Message&reply_to_message_id=$ReplyToId")
  } catch {
    Log "Error sending message."
    $_.Exception
  }
  
}

function Log {
  param (
     [string] $Msg
  )
  $dt = $(Get-Date)
  Write-Host "$($dt.ToString('yyyy-MM-dd HH:mm:ss')) : $msg"
}

function Debug {
  param (
     [string] $Msg
  )
  $VerbosePreference = 'Continue'
  $dt = $(Get-Date)
  Write-Verbose "$($dt.ToString('yyyy-MM-dd HH:mm:ss')) : $msg"
}

function Execute-Process {
  param(
    [string] $procTitle,
    [string] $procPath,
    [string] $procName,
    [int] $messageId 
  )
  
  $procPath=$(Join-Path $procPath "$procName$global:procExtension")

  $process = $(Get-Process -ErrorAction:Ignore $procName)
  if ($process) {
      Reply -Message "$procTitle already running."
  } else {
      Log "Opening $procPath"
      Start-Process -FilePath $procPath -WorkingDirectory $(Split-Path -Path $procPath)
      Start-Sleep 2

      $count = 0;
      while ((-not ($process = $(Get-Process -ErrorAction:Ignore $procName))) -and $count -le 5) {
          Start-Sleep 1
          $count = $count + 1
      }

      if($process) {
          Reply -Message "$procTitle is now running." -ReplyToId $messageId
      } else {
          Reply -Message "$procTitle is not running." -ReplyToId $messageId
      }
  }
}

function Close-Process {
  param(
    [string] $procTitle,
    [string] $procName,
    [int] $messageId 
  )

  $process = $(Get-Process -ErrorAction:Ignore $procName)
  if ($process) 
  {
      Log "Clossing $procTitle."
      
      $process = Terminate-Process-Wait $process

      if ($process) {
          Reply -Message "$procTitle is still running." -ReplyToId $messageId
      } else {
          Reply -Message "$procTitle is not running anymore." -ReplyToId $messageId
      }
  }
  else {
      Reply -Message "$procTitle is not running." -ReplyToId $messageId
  }
}

function Terminate-Process-Wait {
  param($process)

  if (-not $process.CloseMainWindow()) 
  {
      Stop-Process $process
  }
  
  $count = 0;
  while (($process = $(Get-Process -ErrorAction:Ignore $process.ProcessName)) -and $count -le 5) {
      Start-Sleep 1
      $count = $count + 1
  }

  return $process
}


function Is-Process-Running {
  param(
    [string] $procTitle,
    [string] $procName,
    [int] $messageId 
  )

  $process = $(Get-Process -ErrorAction:Ignore $procName)
  if ($process) 
  {
      Reply -Message "$procTitle is running!" -ReplyToId $messageId
  } 
  else 
  {
      Reply -Message "$procTitle is NOT running." -ReplyToId $messageId
  }
}

$pidFile = "$HOME/.hmsoft/telebot.pid"

function Write-PID {
  New-Item -Path $(Split-Path -Path $pidFile) -ItemType Directory -Force -ErrorAction:Ignore | Out-Null
  Set-Content -Path $pidFile -Value $PID -ErrorAction:Ignore   
}

function Delete-PID {
  Remove-Item $pidFile -ErrorAction:Ignore
}

function Find-Running-Instance {  
  $runningPid = Get-Content -Path $pidFile  -ErrorAction:Ignore
  if ($runningPid) {
    $process = Get-Process -Id $runningPid  -ErrorAction:Ignore
    if ($process -and $process.ProcessName -and $process.ProcessName -in "pwsh", "powershell" ) {        
      return $process
    }
  }

  return $null
}