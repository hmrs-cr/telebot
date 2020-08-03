param([string] $Params, [int]$messageId)

$obsProcName = "obs64"

$obsProcess = $(Get-Process -ErrorAction:Ignore $obsProcName)
if ($obsProcess) 
{
    Reply -Message "OBS is running!" -ReplyToId $messageId
} 
else 
{
    Reply -Message "OBS is NOT running." -ReplyToId $messageId
}