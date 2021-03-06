<#
    .SYNOPSIS
    Gets help.
#>

param([string] $Params, [int]$messageId)

$helpText = ""
Get-ChildItem -Path "./telebot-commands/*.ps1" | ForEach-Object -Process {    
    $command = $_.BaseName    
    $helpText = $helpText + "$command`n"
}
Reply -Message $helpText -ReplyToId $messageId