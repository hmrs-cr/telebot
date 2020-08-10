param([string] $Params, [int]$messageId)
$process = $(Get-Process -ErrorAction:Ignore logonui)
if ($process) {
    Reply -Message "Screen is locked." -ReplyToId $messageId
} else {
    Reply -Message "Screen is NOT locked!" -ReplyToId $messageId
}