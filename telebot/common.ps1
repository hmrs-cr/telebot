

$global:TelegramBotUrl = "https://api.telegram.org/bot$global:TelegramBotKey"

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