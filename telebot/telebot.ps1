param (     
  [String] $TelegramBotKey = $ENV:TELEGRAM_NOTIF_BOT_KEY,
  [String] $TelegramChatId = $ENV:TELEGRAM_NOTIF_CHAT_ID,
  [Switch] $KillExistingInstance,
  [String] $LogFile = "logs/$($(Get-Date).ToString('yyyyMMddHHmmss')).telebot.log"
)

$global:TelegramBotKey = $TelegramBotKey
$global:TelegramChatId = $TelegramChatId
$global:telegramOffset = 0
$global:telegramTimeout = 60

. ./common.ps1

if (-not $global:TelegramBotKey) {
  Write-Host "No telegram bot key found."
  exit 1 
}

if (-not $global:TelegramChatId) {
  Write-Host "No telegram chat id found."
  exit 1
}

function Read-BotCommands
{
  try 
  {    
    $TelegramUpdateUrl = "$global:TelegramBotUrl/getUpdates?timeout=$global:telegramTimeout&offset=$global:telegramOffset&allowed_updates=['channel_post']"        
    $response = $(Invoke-RestMethod -ErrorAction:Ignore -Uri $TelegramUpdateUrl)     
  }
  catch 
  {
      $_.Exception     
      $response =$_.Exception.Response
  }
  
  if ($response.ok -and $response.result -and $response.result.Length) 
  {
    $response.result | ForEach-Object -Process {
      $result = $_ 
      
      if ($result.update_id -ge $global:telegramOffset) 
      {
          $global:telegramOffset = $result.update_id + 1          
          Log "New Telegram Offset: $global:telegramOffset"
      }
    
      if ($result.channel_post -and $result.channel_post.chat.id -eq $global:TelegramChatId) {
        $result.channel_post
      } 
    }      
  } else {
    Log "Response has no messages: $response"
  }
}

function Handle-Command {
  [CmdletBinding()]
  param([Parameter(ValueFromPipeline)]$command)
  
  if ($command) {
    Log "Handling Command '$($command.text)'"
    try {
      $messageId = $command.message_id
      
      $command = $command.text.Split(" ", 2)
      $params = $command[1]
      $commandName = $command[0] -Replace '[\W]', ''
      $command = "./telebot-commands/$commandName.ps1"

      if (Test-Path $command -PathType leaf) {
        Invoke-Expression -ErrorAction:Ignore  -Command "$command -Params ""$params"" -MessageId $messageId" | Out-Null
      } else {
          Reply -Message "Unknown command '$commandName'" -ReplyToId $messageId
      }
    } catch  {      
      Reply -Message "Error executing command '$commandName'" -ReplyToId $messageId
      Log "Error executing command '$commandName': $_" 
      return
    }
  }
}

$instance = Find-Running-Instance
if ($instance) {
  if ($KillExistingInstance) {
    Log "Script already running. Killing running instance."
    Terminate-Process-Wait $instance | Out-Null
  } else {
    Log "Script already running. Use -KillExistingInstance to kill running instance and start a new one."
    exit 1
  }
}

Write-PID

if ($LogFile) 
{
    New-Item -Path $(Split-Path -Path $LogFile) -ItemType Directory -Force  | Out-Null
    $ErrorActionPreference="SilentlyContinue"
    Stop-Transcript -ErrorAction:Ignore | Out-Null    
    $ErrorActionPreference = "Continue"
    Start-Transcript -Path $LogFile -Append
}

Reply "Telebot started."
try {  
  while ($true) 
  {  
    Read-BotCommands | Handle-Command
    Start-Sleep 1
  }
} finally {
  Reply "Telebot terminated"
  Delete-PID
  $ErrorActionPreference="SilentlyContinue"
  Stop-Transcript
}