
$global:TelegramBotUrl = "https://api.telegram.org/bot$global:TelegramBotKey"
$global:procExtension=".exe"

function Reply {
   param (
     [string] $Message,
     [string] $ChatId = $TelegramChatId,
     [string] $ReplyToId
   )

   Log $Message
   $response = $(Invoke-WebRequest -ErrorAction:Ignore -Uri "$global:TelegramBotUrl/sendMessage?parse_mode=Markdown&chat_id=$ChatId&text=$Message&reply_to_message_id=$ReplyToId")
}

function Log {
  param (
     [string] $msg
  )
  $dt = $(Get-Date)
  Write-Host "$($dt.ToString('yyyy-MM-dd HH:mm:ss')) : $msg"
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
      if (-not $process.CloseMainWindow()) 
      {
          Stop-Process $obsPrprocessocess
      }
      
      $count = 0;
      while (($process = $(Get-Process -ErrorAction:Ignore $procName)) -and $count -le 5) {
          Start-Sleep 1
          $count = $count + 1
      }

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