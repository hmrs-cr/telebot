param([string] $Params, [int]$messageId)
rundll32.exe user32.dll,LockWorkStation

$count = 0;
while (-not ($process = $(Get-Process -ErrorAction:Ignore logonui)) -and $count -le 5) {
    Start-Sleep 1
    $count = $count + 1
}

if ($process) {
    Reply -Message "Screen is locked." -ReplyToId $messageId
} else {
    Reply -Message "Screen is NOT locked!" -ReplyToId $messageId
}