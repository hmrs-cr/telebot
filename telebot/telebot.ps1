param (     
  [String] $TelegramBotKey = $ENV:TELEGRAM_NOTIF_BOT_KEY,
  [String] $TelegramChatId = $ENV:TELEGRAM_NOTIF_CHAT_ID,
  [String] $LogFile = "logs/$($(Get-Date).ToString('yyyyMMddHHmmss')).telebot.log"
)

$global:TelegramBotKey = $TelegramBotKey
$global:TelegramChatId = $TelegramChatId
$global:telegramOffset = 0
$global:telegramTimeout = 60

. ./common.ps1

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

  if ($response.ok) 
  {
    $response.result | ForEach-Object -Process {
      $result = $_ 
      
      if ($result.update_id -ge $global:telegramOffset) 
      {
          $global:telegramOffset = $result.update_id + 1          
      }
    

      if ($result.channel_post.chat.id -ne $global:TelegramChatId) {
         Reply -Message "You are not my master MF!" -ChatId $result.channel_post.chat.id  -ReplyToId $result.channel_post.message_id 
      } else {
        $result.channel_post.text
      }
    }      
  }
}

function Handle-Command {
  [CmdletBinding()]
  param([Parameter(ValueFromPipeline)]$command)
  
  if ($command) {
    Log "Handling Command '$command'"
    try {
      Invoke-Expression -ErrorAction:Ignore  -Command "./telebot-commands/$command.ps1" | Out-Null
    } catch  {
      Reply -Message "Error executing command '$command'" 
      Log "Error executing command '$command': $_" 
      return
    }
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

Reply "Telebot started."
try {  
  while ($true) 
  {  
    Read-BotCommands | Where-Object {$_} | Handle-Command
    Start-Sleep 1
  }
} finally {
  Reply "Telebot terminated"

  $ErrorActionPreference="SilentlyContinue"
  Stop-Transcript
}